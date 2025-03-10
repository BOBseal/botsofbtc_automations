// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IBaseSwap {

    struct ExactInputParams  {
        address tokenIn;
        address tokenOut;
        uint128 amountIn;
        address recipient;
        // supported fee rates:
        // for the MAINNET are 500 (0.05%), 3000 (0.3%), and 10000 (1%), other than that tx will revert;
        // for the TESTNET are 400 (0.04%), 2000 (0.2%) and 10000 (1%)
        uint24 fee;
    }

    struct ExactOutputParams {
        address tokenIn;
        address tokenOut;
        uint128 amountOut;
        address recipient;
        // supported fee rates:
        // for the MAINNET are 500 (0.05%), 3000 (0.3%), and 10000 (1%), other than that tx will revert;
        // for the TESTNET are 400 (0.04%), 2000 (0.2%) and 10000 (1%)
        uint24 fee;
    }

     function exactInputSwap(ExactInputParams memory params) external returns(uint256 amtOut);

    function exactOutputSwap(ExactOutputParams memory params) external returns(uint256 amtOut);

}