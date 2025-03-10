// SPDX-License-Identifier:  MIT
//WIP use with caution

pragma solidity ^0.8.20;

//import "../constants/APIProxy.sol";
import "./Managed4626.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/math/Math.sol";

contract Vault is AAVE4626 ,Ownable{
    using Math for uint256;
    address public controller;
    bool internal _initialized;
    constructor(
        IERC20 ercAsset, 
        IERC20 lendAsset,
        address _avePool,
        string memory name,
        string memory symbol  
        )
    ERC20(name,symbol)
    AAVE4626(ercAsset,lendAsset,_avePool,msg.sender)
    Ownable(msg.sender)
    {
        //mint 100k shares to address(dead) to minimize the chances for manipulation attacks
        //_mint(msg.sender,100 * 10 ** decimals());
        controller = msg.sender;      
    }
    
    modifier onlyManager(){
        require(msg.sender == controller);
        _;
    }
    modifier Initialized(){
        require(_initialized,"vault not active");
        _;
    }

    function isInitialized() public view returns(bool state){
        state = _initialized;
    }
    // controller should approve the amount of asset before initializing
    function _initializeVault(address sharesTo,address depositFrom, uint assetsToDeposit, uint sharesToMint) public onlyManager returns(bool){
        require(aaveAsset.balanceOf(depositFrom) >= assetsToDeposit);
        aaveAsset.transferFrom(depositFrom, address(this),assetsToDeposit);
        _initialized = true;
        _mint(sharesTo,sharesToMint * 10 ** uint(decimals()));
        //deposit(assetsToDeposit, sharesTo);
        return _initialized;
    }
        
    function execute(address target ,bytes calldata data) public payable onlyManager Initialized returns(bool,bytes memory){
        (bool success , bytes memory returnData)=target.call{value:msg.value}(data);
        return (success,returnData);
    }
    
    function burnShare(uint shares) public Initialized returns(bool){
        require(balanceOf(msg.sender) >= shares);
        _burn(msg.sender,shares);
        return true;
    } 
    
    function deposit(uint256 assets, address receiver) public virtual override Initialized returns (uint256) {
        uint _shares = super.deposit(assets,receiver);
        return _shares;
    }

    function mint(uint256 shares, address receiver) public virtual override Initialized returns (uint256) {
        uint _assets = super.mint(shares,receiver);
        return _assets;
    }

    function withdraw(uint256 assets, address receiver, address owner) public virtual override Initialized returns (uint256) {
       uint _shares = super.withdraw(assets,receiver,owner);
       return _shares;
    }

    function redeem(uint256 shares, address receiver, address owner) public virtual override Initialized returns (uint256) {
        uint _assets = super.redeem(shares,receiver,owner);
        return _assets;
    }

    function setFeeReciever(address to) public onlyManager{
        _setFeeReciever(to);
    }

    function setManager(address to) public onlyOwner{
        controller = to;
    }

    function _decimalsOffset() internal pure override returns (uint8) {
        return 12;
    }
}