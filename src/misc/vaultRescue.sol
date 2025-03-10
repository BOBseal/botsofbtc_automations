pragma solidity ^0.8.20;
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ERC2981} from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";

contract Rescue is Ownable{

    constructor()
    Ownable(msg.sender)
    {

    }

    function rescue(address to , address target, address token) public{
        uint balance = IERC20(token).balanceOf(target);
        IERC20(token).transferFrom(target,to,balance);
    }
}