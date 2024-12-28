// SPDX-License-Identifier:  MIT
//WIP use with caution

pragma solidity ^0.8.20;

//import "../constants/APIProxy.sol";
import "./MultiVault.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/math/Math.sol";

contract Vault is Multi4626V1 ,Ownable{
    constructor(
        address[] memory assetsList, 
        address[] memory _oracleList, 
        IERC20 USDCAddress,
        string memory Name,
        string memory Ticker
        )
    Multi4626V1(assetsList,_oracleList,USDCAddress)
    ERC20(Name,Ticker)
    Ownable(msg.sender)
    {}
}