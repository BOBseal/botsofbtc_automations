// SPDX-License-Identifier:  MIT
//WIP use with caution

pragma solidity ^0.8.20;

//import "../constants/APIProxy.sol";
import "./Managed4626.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/math/Math.sol";

contract Vault is Managed4626 ,Ownable{
    using Math for uint256;
    uint public fee = 50; // 0.05 % fee on deposits & withdrawals
    uint public fractionalReserve = 30; // Shares follow fractional reserves
    uint internal _currentWithdrawn;
    address public controller;
    bool internal _initialized;
    constructor(
        IERC20 ercAsset, 
        string memory name,
        string memory symbol,
        address _owner   
        )
    ERC20(name,symbol)
    Managed4626(ercAsset)
    Ownable(_owner)
    {
        //mint 100k shares to address(dead) to minimize the chances for manipulation attacks
        _mint(0x000000000000000000000000000000000000dEaD,100000 * 10** decimals());
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
    // must take in accordance with each asset's decimals , decimal offset + underlying decimal = share decimal
    // controller should approve the amount of asset before initializing
    function _initializeVault(address sharesTo,address depositFrom, uint assetsToDeposit) public onlyManager returns(bool){
        require(_asset.balanceOf(depositFrom) >= assetsToDeposit);
        SafeERC20.safeTransferFrom(_asset,depositFrom,address(this),assetsToDeposit);
        deposit(assetsToDeposit, sharesTo);        
        _initialized = true;
        return _initialized;
    }
        
    function execute(address target ,bytes calldata data) public payable onlyManager Initialized returns(bool,bytes memory){
        (bool success , bytes memory returnData)=target.call{value:msg.value}(data);
        return (success,returnData);
    }
    /// returns withdrawable fraction for one case and zero for rest
    /*
    function getWithdrawable() public view returns(uint){
        uint tWithdrawable = _assetBalances * fractionalReserve / 100;
        if(_currentWithdrawn < tWithdrawable){
            return (tWithdrawable - _currentWithdrawn);
        } else return 0;
    }
    function depositAssets(uint amount) public onlyManager Initialized returns(bool){
        require(_asset.balanceOf(msg.sender) >= amount);
        SafeERC20.safeTransferFrom(_asset, msg.sender, address(this), amount);
        _assetBalances += amount;
        if(_currentWithdrawn != 0){
            _currentWithdrawn -= amount;
        }
        return true;
    }
    */
    function burnShare(uint shares) public Initialized returns(bool){
        require(balanceOf(msg.sender) >= shares);
        _burn(msg.sender,shares);
        return true;
    } 

    function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
        uint256 fee_ = _feeOnTotal(assets);
        return super.previewDeposit(assets - fee_);
    }

    /// @dev Preview adding an entry fee on mint. See {IERC4626-previewMint}.
    function previewMint(uint256 shares) public view virtual override returns (uint256) {
        uint256 assets = super.previewMint(shares);
        return assets + _feeOnRaw(assets);
    }

    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        uint256 fee_ = _feeOnRaw(assets);
        return super.previewWithdraw(assets + fee_);
    }
    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        uint256 assets = super.previewRedeem(shares);
        return assets - _feeOnTotal(assets);
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

    function _fee() internal view returns(uint){
        return fee;
    }

    function _feeOnRaw(uint256 assets) private view returns (uint256) {
        return assets.mulDiv(_fee(), 10000, Math.Rounding.Ceil);
    }

    function _feeOnTotal(uint256 assets) private view returns (uint256) {
        return assets.mulDiv(_fee(), _fee() + 10000, Math.Rounding.Ceil);
    }

    function _decimalsOffset() internal pure override returns (uint8) {
        return 8;
    }
}