// SPDX-License-Identifier:  MIT
//WIP use with caution

pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
//import "openzeppelin-contracts/contracts/utils/math/Math.sol";
//import { IQuoterV2 } from "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";

/*
Prototype Solution for BTC & ETH price updates quoted from uniswap in comparision to USD 

Managed & Updated trigger based through certain endpoints when price movements are 0.5%+
 */

contract CustomOracle is Ownable {
    //address public asset;
    int224 public currentPrice;
    uint32 public lastUpdatedTimestamp;
    struct Access{
        bool stat;
        uint activeTill;
    }
    mapping(address => bool) internal _allowedEndpoints;
    mapping(address => Access) internal _access;
    constructor(
            )
    Ownable(msg.sender)
    {
        
    }
    
    modifier OnlyAllowed(){
        require(_allowedEndpoints[msg.sender] == true);
        _;
    }

    function isAllowed(address endpoint) public view returns(bool){
        return _allowedEndpoints[endpoint];
    }

    function setAllowed (address endpoint , bool status) public onlyOwner{
        _allowedEndpoints[endpoint] = status;
    }
    
    function setAccess(address _for ,bool _stat , uint _activeTill) public onlyOwner{
        _access[_for].stat = _stat;
        _access[_for].activeTill = _activeTill;
    }

    function read() public view returns(int224, uint32 ){
        require(_access[msg.sender].stat == true,"Access Inactive");
        require(_access[msg.sender].activeTill >= block.timestamp,"Access Expired");
        return (currentPrice,lastUpdatedTimestamp);
    }
    
    function updatePrice (int224 price) public OnlyAllowed{
        currentPrice = price;
        lastUpdatedTimestamp = uint32(block.timestamp);
    }
    
}