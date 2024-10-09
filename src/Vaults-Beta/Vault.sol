// SPDX-License-Identifier:  MIT

pragma solidity ^0.8.20;

//import "../constants/APIProxy.sol";
import "./Managed4626.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/math/Math.sol";

contract Vault is Managed4626 ,Ownable{
    using Math for uint256;
    uint public fee = 5; // 0.05 % fee on deposits & withdrawals
    uint public fractionalReserve = 30; // Shares follow fractional reserves
    uint internal _currentWithdrawn;
    constructor(
        IERC20 ercAsset, 
        string memory name,
        string memory symbol,
        address owner
    )
    ERC20(name,symbol)
    Managed4626(ercAsset)
    Ownable(msg.sender)
    {
        //mint 100k shares to Manager contract for Initial Boostrap
        _mint(msg.sender, 100000 * 10 ** decimal());
        managers[msg.sender] = true;        
    }
    mapping(address => bool) public managers;

    modifier onlyManager(){
        require(managers[msg.sender]);
        _;
    }

    function addManager(address user,bool state) public onlyOwner{
        managers[user] = state;
    }
    // safeWithdraw by manager of Assets , max 30% of _assetBalances . Does not take account balanceOf(address(this))
    function withdrawAssets(address to, uint amount) public onlyManager{
        require(_asset.balanceOf(address(this)) >= amount);
        uint tWithdrawable = _assetBalances * fractionalReserve / 100;
        require(tWithdrawable - _currentWithdrawn >= amount); 
        SafeERC20.safeTransfer(_asset,to,amount);
        _currentWithdrawn += amount;
    }
    
    // safeDeposit by manager of assets , if deposit exceeds currentWithdrawn adds in favour of vault
    // call from contract : // approve => depositAssets
    function depositAssets(uint amount) public onlyManager{
        require(_asset.balanceOf(msg.sender) >= amount);
        SafeERC20.safeTransferFrom(_asset, caller, address(this), assets);
        _assetBalances += amount;
        if(_currentWithdrawn != 0){
            _currentWithdrawn -= amount;
        }
    }
    // share controls for manager
    function mintShare(address at,uint shares) public onlyManager{
        _mint(at,shares);
    }

    function burnShare(uint shares) public onlyManager{
        require(balanceOf(msg.sender) >= shares);
        _burn(msg.sender,shares);
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
        return 18;
    }
}