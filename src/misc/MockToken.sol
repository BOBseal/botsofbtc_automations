pragma solidity ^0.8.20;
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
//import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
//import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
//import {ERC2981} from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";

contract TOKENMOCK is ERC20,Ownable{
    uint8 internal __decimals;
    constructor(string memory name_ , string memory symbol_ , uint8 decimals , uint256 supply)
    Ownable(msg.sender)
    ERC20(name_,symbol_)
    {
        _mint(msg.sender,supply);
    }

    function decimals() public view override returns (uint8) {
        return __decimals;
    }
}