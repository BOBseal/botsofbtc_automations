
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/ERC4626.sol)
/// WIP use with caution
pragma solidity ^0.8.20;

import {IERC20, IERC20Metadata, ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import "../constants/APIProxy.sol";
//import "../modules/BaseSwapOku.sol";
import { ISwapRouter } from "../interfaces/ISwapRouter.sol";
import { IQuoterV2 } from "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";
import { IUniswapV3Factory  } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/**
 Modifications : Using Orcales to aggregate value for multiple underlying assets and issue a Unified share token representing those 

 Problems on V1 : 
 1: Decimal Offset & handling underlying assets with different decimal value , however since using oracle data with taking usd value to calculate the shares solves that and introduces another problem : 
    => Volatility in USD values of an asset can lead to various attack vectors on the issued share
    Possible Solution => User buys the share in USDC , USDC gets swapped 50-50 to Underlying assets via Dex and issue shares based on the value of outToken from dex/swap
    problems introduced => more gas cost & volatility of assets can be a trigger for manipulation
 2: Gas Efficiency : Using an oracle to get USD values for the assets, introduces the problem for added gas costs on calls
 */
abstract contract Multi4626V1 is ERC20 {
    using Math for uint256;
    address[] public _assets;
    uint8[] public _assetDecimals;
    address[] internal _orcales;
    IERC20 internal _usdc;
    uint internal slippage = 20;
    uint divisor = 2;
    uint internal _txFee = 100; 
    mapping(address=>uint) internal _assetBalances;
    mapping(address=>uint) internal _feeBalances;
    uint24[] public feeValues;// for the MAINNET are 500 (0.05%), 3000 (0.3%), and 10000 (1%), other than that tx will revert;

    address internal constant EMPTY_POOL = 0x0000000000000000000000000000000000000000;
    ISwapRouter internal s_okuRouter;
    IQuoterV2 internal s_okuQuoter;
    IUniswapV3Factory internal s_okuFactory;

    //error SwapFailed(address reciever, uint shares);
    error ERC4626ExceededMaxMint(address receiver, uint256 shares, uint256 max);
    error ERC4626ExceededMaxRedeem(address owner, uint256 shares, uint256 max);
    constructor(
        address[] memory assetsList, 
        address[] memory _oracleList,
        uint8[] memory decimalList,
        uint24[] memory _feeVals, 
        IERC20 USDCAddress, 
        address swapRouter_, 
        address swapQuoter_, 
        address swapPoolFactory_
        ) 
    {
        _assets = assetsList;
        _orcales = _oracleList;
        _usdc = USDCAddress;
        _assetDecimals = decimalList;
        s_okuRouter = ISwapRouter(swapRouter_);
        s_okuQuoter = IQuoterV2(swapQuoter_);
        s_okuFactory = IUniswapV3Factory(swapPoolFactory_);
        feeValues = _feeVals;
    }
    
    function feeRaised(address token) public view returns(uint){
        return _feeBalances[token];
    }

    function decimals() public view virtual override(ERC20) returns (uint8) {
        return 18 + _decimalsOffset();
    }

    /** returns underlying assets array */
    function asset() public view virtual returns (address[] memory) {
        return _assets;
    }

    /** Returns Underlying Assets Balances */
    function totalAssetBalances() public view virtual returns (uint256[] memory) {
        uint length = _assets.length;
        uint256[] memory amounts = new uint256[](length);
        for(uint i = 0; i < length;++i){
            amounts[i]=_assetBalances[_assets[i]];
        }
        return amounts;
    }
    // returns value for total underlying assets in usd , 18 decimal places and returns prices array for assets
    function totalAssets() public view virtual returns(uint, uint[] memory){
        uint[] memory values_ = new  uint[](_assets.length);
        uint value =0;
        for(uint i=0; i< _assets.length;++i){
            (int224 aValue,) = IProxy(_orcales[i]).read();
            if(aValue < 0){
                revert();
            }
            values_[i]=uint(int(aValue));
            value += (uint(int(aValue)) * _assetBalances[_assets[i]])/ 10 ** _assetDecimals[i];
        }
        return (value,values_);
    }
    // returns share price per share at 18 decimal places
    function pricePerShare() public view returns(uint){
        (uint total,) = totalAssets(); 
        return ((total * 10 ** decimals())/totalSupply());
    }
    // returns an array of prices for each asset per asset * 10 ** _underlyingDecimals
    function pricesForAssets() public view returns(uint[] memory){
        uint[] memory values_ = new  uint[](_assets.length);
        for(uint i=0; i< _assets.length;++i){
            (int224 aValue,) = IProxy(_orcales[i]).read();
            if(aValue <0){
                revert();
            }
            int x = int(aValue);
            values_[i]=uint(x);
        }
        return values_;
    }
    // returns amount of assets needed to recieve for needed shares 
    /*
    Function is not to be called from a contract
     */
    function previewMint(uint shares) public view returns(uint){
        uint s = (pricePerShare()/10** (18 - 6)) * (shares / 10 ** decimals());
        uint sAdjust = s + ((s/1000)* slippage);
        return sAdjust;
    }
    // returns amount of assets returned after redeeming shares 
    /*
    Function is not to be called from a contract
     */
    function previewRedeem(uint shares) public view returns(uint){
        uint value=0;
        uint[] memory rtVals = returnValues(shares);
        for(uint i=0; i< rtVals.length;++i){
            (int224 aValue,) = IProxy(_orcales[i]).read();
            if(aValue < 0){
                revert();
            }
            int val = int(aValue);
            value += (uint(val) * rtVals[i])/ 10 ** _assetDecimals[i];
        }
        return value;
    }

    /** @dev See {IERC4626-maxMint}. */
    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max - totalSupply();
    }

    /** @dev See {IERC4626-maxRedeem}. */
    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf(owner);
    }

    /** @dev See {IERC4626-mint}.
     *
     * As opposed to {deposit}, minting is allowed even if the vault is in a state where the price of a share is zero.
     * In this case, the shares will be minted without requiring any assets to be deposited.
     */
    function mint(uint256 shares, address receiver) public virtual returns (uint256) {
        uint256 maxShares = maxMint(receiver);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxMint(receiver, shares, maxShares);
        }
        uint usdcCost = previewMint(shares);
        //uint[] memory rtVals = returnValues(shares);
        SafeERC20.safeTransferFrom(_usdc,msg.sender,address(this),usdcCost);
        _usdc.approve(address(s_okuRouter),usdcCost);
        if((usdcCost/2) <= 0) revert();
        for(uint i =0 ; i<_assets.length;++i){
            bytes memory path = _getSwapPath(address(_usdc),feeValues[i],_assets[i]);
            uint amountOut= _quoteExactInput(path,usdcCost/2);
            if(amountOut == 0) revert("pool error 1");
            uint poolBalance = _poolExistsExactInput(address(_usdc),_assets[i],feeValues[i],amountOut);
            if(poolBalance<amountOut) revert("pool error 2");
            uint amt = _executeOkuSwap(path,usdcCost/2,amountOut);
            _assetBalances[_assets[i]] += amt;
        }
        uint sharesToMint = _processFee(shares);
        _mint(receiver, sharesToMint);
        return usdcCost;
    }

    /*
    Unsafe => Swaps needs to be handled from UnderlyingAssets (BTC & ETH)->EndAsset (USDC) before _redeem is called
    @assets is asset , ie usdc rcv provided from aggregator API and is vulnerable to steep slippages 
    */

    function redeem(uint256 shares, address receiver) public virtual returns (uint256) {
        uint256 maxShares = maxRedeem(msg.sender);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxRedeem(msg.sender, shares, maxShares);
        }
        uint sharesRedeem = _processFee(shares);
        uint[] memory rtVals = returnValues(sharesRedeem);        
        uint assets = 0;
        _burn(msg.sender, shares);
        for(uint i=0 ; i< 2;++i){
            IERC20(_assets[i]).approve(address(s_okuRouter),rtVals[i]);
            bytes memory path = _getSwapPath(_assets[i],feeValues[i],address(_usdc));
            uint amountOut= _quoteExactInput(path,rtVals[i]);
            if(amountOut == 0) revert("pool error");
            uint poolBalance = _poolExistsExactInput(_assets[i],address(_usdc),feeValues[i],amountOut);
            if(poolBalance<amountOut) revert("pool error 2");
            uint amts = _executeOkuSwap(path,rtVals[i],amountOut);
            assets += amts;
            _assetBalances[_assets[i]] -= rtVals[i];
        }
        if(assets >0 && _usdc.balanceOf(address(this))>= assets){
            SafeERC20.safeTransfer(_usdc,receiver,assets);
        }else revert("swap error 1");          
        return assets;
    }

    function _decimalsOffset() internal pure virtual returns (uint8) {
        return 8;
    }

    function _withdrawFee(uint amount, address to) internal {
            require(balanceOf(address(this))>= amount);
            _transfer(address(this),to,amount);
            _feeBalances[address(this)] -= amount;
    }
    
    // adds shares to fee balances , returns share amounts after deduction
    function _processFee(uint shares) internal returns(uint) {
        uint _feeAmts = (shares/10000)*_txFee;
        _mint(address(this),_feeAmts);
        _feeBalances[address(this)] += _feeAmts;
        return (shares - _feeAmts);
    }

    function _poolExistsExactInput(address tokenIn,address tokenOut,uint24 fee, uint minAmountOut) internal view returns(uint poolBalance) {
         address poolAddr = s_okuFactory.getPool(tokenIn, tokenOut,fee);
         if(poolAddr == EMPTY_POOL) {
            poolBalance = 0;
         } 
         uint bal = IERC20(tokenOut).balanceOf(poolAddr);
         if(bal >= minAmountOut){
            poolBalance = bal;
         }
         if(bal <= minAmountOut){
            poolBalance =0;
         }
    }

    // executes swap where recipient is the contract
    // unsafe , check if pool exists before calling _executeOkuSwap
    function _executeOkuSwap(bytes memory path,uint amountIn,uint amountOut) internal returns(uint){
        if(amountIn <= 0 || amountOut <= 0) revert();
        if(path.length == 0) revert();
        ISwapRouter.ExactInputParams memory swapParams = ISwapRouter.ExactInputParams({
            path: path,
            recipient: address(this),
            amountIn: amountIn,
            amountOutMinimum: amountOut // minAmountOut (minimum amount of tokenOut user would gets from the pool)
        });
        // perform the swap / calling exactInput swap
        uint256 outAmount = s_okuRouter.exactInput(swapParams);
        return outAmount;
    }

    // returns the recievable underlying assets for shares with 1% slippage assumption & v1 hardcoded for only btc-eth in one order of initialisation
    function returnValues(uint sharesAmount) internal view returns(uint[] memory){
        uint[] memory amountsRcv = new uint[](_assets.length);
        (uint totalVal , uint [] memory prices) = totalAssets();
        uint shareC = ((totalVal * (10 ** decimals()))/ totalSupply())/divisor;
        for(uint i =0; i< _assets.length;++i){
            uint rcvadjust = (shareC * 10 ** 18)/prices[i];
            // always assume a slippage of slippage()
            uint rcv = rcvadjust - ((rcvadjust/1000) * slippage);
            if (i == 0) {
                // Scale BTC value to 8 decimals
                amountsRcv[i] = ((rcv / 10 ** 10) * sharesAmount / 10 ** decimals());
            } else {
                // ETH remains with 18 decimals
                amountsRcv[i] = (rcv * sharesAmount / 10 ** decimals());
            }
        }
        return amountsRcv;
    }

    function _quoteExactInput(bytes memory path,uint amountIn) internal returns(uint amountOut){
        (amountOut, , ,) = s_okuQuoter.quoteExactInput(path,amountIn);
    }


    function _getSwapPath(address tokenIn , uint24 fee, address tokenOut) internal pure returns(bytes memory path){
        path = abi.encodePacked(tokenIn,fee,tokenOut);
    }

    function _setSlippage(uint num) internal {
        slippage = num;
    }

    function _setFee(uint num) internal {
        _txFee = num;
    }
}

