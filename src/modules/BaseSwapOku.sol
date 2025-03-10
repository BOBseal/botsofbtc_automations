// SPDX-License-Identifier: MIT
/*
pragma solidity ^0.8.20;

import { ISwapRouter } from "../interfaces/ISwapRouter.sol";
import { IQuoterV2 } from "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";
import { IUniswapV3Factory  } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

abstract contract OkuSwap{

    error BaseSwap_InvalidCaller(address caller);
    //error BaseSwap_ExactInputSwapFailed(address user, uint256 amountOut);
    error BaseSwap_ExactOutputSwapFailed(address user, uint256 amountIn);
    error BaseSwap_InvalidToken(address tokenIn, address tokenOut);
    error BaseSwap_NotEnoughAmount(uint256 amount);
    error BaseSwap_InvalidRecipient(address rec);

    address private constant EMPTY_POOL = 0x0000000000000000000000000000000000000000;
    ISwapRouter private s_okuRouter;
    IQuoterV2 private s_okuQuoter;
    IUniswapV3Factory private s_okuFactory;

    // ---------------------------------------------- EVENTS ---------------------------------------------------------
    //event SwapExactInputSuccessfull(address tokenA, address tokenB, uint256 amountOut, address recipient);
    //event SwapExactOutputSuccessfull(address tokenA, address tokenB, uint256 maxAmountIn, address recipient);

    constructor(address swapRouter_, address swapQuoter_, address swapPoolFactory_) {
        s_okuRouter = ISwapRouter(swapRouter_);
        s_okuQuoter = IQuoterV2(swapQuoter_);
        s_okuFactory = IUniswapV3Factory(swapPoolFactory_);
    }
    // --------------------------------------------- STRUCTS ---------------------------------------------------------
    // all these params grouped together to avoid stack too deep error from EVM
    struct ExactInputParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        address recipient;
        // supported fee rates:
        // for the MAINNET are 500 (0.05%), 3000 (0.3%), and 10000 (1%), other than that tx will revert;
        uint24 fee;
    }

    struct PoolCheckParamsExactInput {
        address tokenIn;
        address tokenOut; 
        uint24 fee;
        uint256 amountIn; 
        uint256 minAmtOut;
    }

    struct ExactOutputParams {
        address tokenIn;
        address tokenOut;
        uint256 amountOut;
        address recipient;
        // supported fee rates:
        // for the MAINNET are 500 (0.05%), 3000 (0.3%), and 10000 (1%), other than that tx will revert;
        uint24 fee;
    }

    struct PoolCheckParamsExactOutput {
        address tokenIn;
        address tokenOut; 
        uint24 fee;
        uint256 amountOut; 
        uint256 maxAmtIn;
    }

     // --------------------------------------------INTERNAL & PRIVATE FUNCTIONS -------------------------------------------------------
    function _poolExistsExactInput(PoolCheckParamsExactInput memory poolParams) internal view {
         address poolAddr = s_okuFactory.getPool(poolParams.tokenIn, poolParams.tokenOut, poolParams.fee);
         if(poolAddr == EMPTY_POOL) revert("pool not exists");
         uint256 poolTokenBBal = IERC20(poolParams.tokenOut).balanceOf(poolAddr);
         if(poolTokenBBal <= poolParams.minAmtOut) revert("pool tokens liquidity is less than the expected token amount");
    }
    
    //    @dev check if the pool exist or not, if pool not exist the swap will fail

     function _poolExistsExactOutput(PoolCheckParamsExactOutput memory poolParams) internal view {
         address poolAddr = s_okuFactory.getPool(poolParams.tokenIn, poolParams.tokenOut, poolParams.fee);
         if(poolAddr == EMPTY_POOL) revert("pool not exists");
        uint256 poolTokenBBal = IERC20(poolParams.tokenOut).balanceOf(poolAddr);
        if(poolTokenBBal <= poolParams.amountOut) revert("pool tokens liquidity is less than the expected token amount");
     }
    
    function quoteExactInput(bytes memory path,uint amountIn) public view returns(uint amountOut){
        (amountOut, , ,) = s_okuQuoter.quoteExactInput(path, params.amountIn);
    }
    
    //    @notice uses sswapAmount function from izumiFinance to make a exactInput swap
    //    @dev IMPORTANT! - make sure the pool exist and has enough liq
    //    @param params - see @ExactInputParams struct for params
    //    @return amtOut - an amount user gets after swapping
    function exactInputSwap(ExactInputParams memory params) internal returns(uint256 amtOut) {
        // swap path in abi.encoded bytes
        bytes memory path = abi.encodePacked(params.tokenIn, uint24(params.fee), params.tokenOut);

        // address check
        if(params.tokenIn == address(0) || params.tokenOut == address(0)) revert BaseSwap_InvalidToken(params.tokenIn, params.tokenOut);
        if(params.recipient == address(0)) revert BaseSwap_InvalidRecipient(params.recipient);
        if(params.amountIn <= 0) revert BaseSwap_NotEnoughAmount(params.amountIn);
        
        if(IERC20(params.tokenIn).balanceOf(address(this)) < params.amountIn) revert("LB");
        // the caller must approve this contract to pull the tokenIn amount
        //IERC20(params.tokenIn).transferFrom(msg.sender, address(this), params.amountIn);
        // approving oku Router to pull the tokenIn amount from this contract
        IERC20(params.tokenIn).approve(address(s_okuRouter), params.amountIn);

        // call swap quoter here to get the minAcquired/minAmountOut tokenOut from the given amountIn of tokenIn
        (uint256 amountOut, , ,) = s_okuQuoter.quoteExactInput(path, params.amountIn);
        // swap params
        ISwapRouter.ExactInputParams memory swapParams = ISwapRouter.ExactInputParams({
            path: path,
            recipient: params.recipient,
            amountIn: params.amountIn,
            amountOutMinimum: amountOut // minAmountOut (minimum amount of tokenOut user would gets from the pool)
        });
        // pool checking, check if the pool existed or not
        _poolExistsExactInput(PoolCheckParamsExactInput({tokenIn: params.tokenIn, tokenOut: params.tokenOut, fee: params.fee, amountIn: params.amountIn, minAmtOut: amountOut}));
        // perform the swap / calling exactInput swap
        uint256 outAmount = s_okuRouter.exactInput(swapParams);

        if(outAmount <= 0) revert BaseSwap_ExactInputSwapFailed(params.recipient, outAmount);
        //emit SwapExactInputSuccessfull(params.tokenIn, params.tokenOut, outAmount, params.recipient);
        amtOut = outAmount;
    }
     
     
     //  @dev call this function for exactOutput swap, for params see @ExactOutputParams struct
     //  @return amtIn - an amount of tokenIn user needs to pay for swapped
    function exactOutputSwap(ExactOutputParams memory params) internal returns(uint256 amtIn) {
        //  supported fees for testnet is 400
        // swap path for exactOutput in reverse order  
        bytes memory path = abi.encodePacked(params.tokenOut, uint24(params.fee), params.tokenIn);
        // address check
        if(params.tokenIn == address(0) || params.tokenOut == address(0)) revert BaseSwap_InvalidToken(params.tokenIn, params.tokenOut);
        if(params.recipient == address(0)) revert BaseSwap_InvalidRecipient(params.recipient);
        if(params.amountOut <= 0) revert("amount out should be more than 0");

        // quoting the swap, before actually calling swap
        (uint256 amountIn, , ,) = s_okuQuoter.quoteExactOutput(path, params.amountOut);
        // balances check , revert on unmatch
        if(IERC20(params.tokenIn).balanceOf(address(this)) < amountIn) revert("LB");
        // the caller must approve this contract to pull the tokenIn amount, (cost = maxAmountIn)
        //IERC20(params.tokenIn).transferFrom(msg.sender, address(this), amountIn);
        // approving okuRouter to pull the tokenIn amount from this contract
        IERC20(params.tokenIn).approve(address(s_okuRouter), amountIn);

        ISwapRouter.ExactOutputParams memory swapParams = ISwapRouter.ExactOutputParams({
            path: path,
            recipient: params.recipient,
            amountOut: params.amountOut, // amountOut
            amountInMaximum: amountIn // maxAmountIn
        });
        _poolExistsExactOutput(PoolCheckParamsExactOutput({ tokenIn: params.tokenIn, tokenOut: params.tokenOut, fee: params.fee, amountOut: params.amountOut, maxAmtIn: amountIn }));
        // calling exactOutput swap
        uint256 maxAmountIn = s_okuRouter.exactOutput(swapParams);
        if(maxAmountIn <= 0) revert BaseSwap_ExactInputSwapFailed(params.recipient, amountIn);
        //emit SwapExactOutputSuccessfull(params.tokenIn, params.tokenOut, maxAmountIn, params.recipient);
        amtIn = maxAmountIn;
    }
    
    //    @dev inherited contract can update the izumi router, quoter, and factory addresses using this function
    function updateOku(address newRouter, address newQuoter, address newPoolFactory) internal returns(address, address, address) {
        if(newRouter == address(0) || newQuoter == address(0) || newPoolFactory == address(0)) revert("one of the address cannot be zero");
        s_okuRouter = ISwapRouter(newRouter);
        s_okuQuoter = IQuoterV2(newQuoter);
        s_okuFactory = IUniswapV3Factory(newPoolFactory);

        return (address(s_okuRouter), address(s_okuQuoter), address(s_okuFactory));
    }

    // -------------------------------------------------------------- PUBLIC & EXTERNAL FUNCTIONS ----------------------------------------

    
    //  @dev getting an address of this contract, needed by its child
    
    function _getContractAddress() public view returns(address) {
        return address(this);
    }

}
*/