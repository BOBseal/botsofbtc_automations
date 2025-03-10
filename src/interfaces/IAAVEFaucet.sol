pragma solidity ^0.8.20;

interface IAAVEFaucet {
    function mint(address token, address to, uint256 amount) external returns (uint256);
}