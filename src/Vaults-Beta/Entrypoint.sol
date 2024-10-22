// SPDX-License-Identifier:  MIT

pragma solidity ^0.8.20;

import "./Vault.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

contract BotEntryPoint is Ownable{

    struct AssetPegs{
        // shares per asset , if _shares = 1 , _asset = 1 => 1 share per 1 asset peg
        uint _shares;
        // asset per share
        uint _asset;
    }
    
    // max amount of asset deposit per wallet
    mapping(address => uint) internal maxAssetsDeposit;
    //vault to bool
    mapping (address => bool) public vaultAvailable;
    // asset to vault
    mapping (address => Vault) internal _assetToVault;
    //asset to sold shares
    mapping(address => uint256) internal _soldShares;
    //asset address to raised assets
    mapping(address=> uint256) internal _raisedAssets;
    // asset to share peg data 
    mapping (address =>  AssetPegs) internal pegData;
    
    mapping(address => bool) internal _allowedCallers;
    constructor()
    Ownable(msg.sender)
    {}

    modifier AssetAvailable(address asset){
        require(vaultAvailable[asset]);
        _;
    }

    // preview shares to get for asset deposits for a vault at set pegs
    function previewBuy(address asset,uint assetsDeposit) public view returns(uint){
        AssetPegs memory peg = pegData[asset];
        if(peg._shares > 0 && peg._asset >0){
            uint256 sharesReceived = (assetsDeposit * peg._shares) / peg._asset;
            return sharesReceived;
        }else return 0;
    }

    function setPeg(address asset , uint assetUnit , uint ShareUnit) public onlyOwner{
        AssetPegs memory peg = AssetPegs({
            _shares:ShareUnit,
            _asset:assetUnit
        });
        pegData[asset] = peg;
    }

    function buyShare(address asset,uint assetToDepost) public vaultAvailable(asset) {
        uint sharesToRcv = previewBuy(asset,assetToDepost);
        require(sharesToRcv >0,"A:S pegs unavailable");
        Vault _vaultInstance = _assetToVault[asset];
        require(_vaultInstance.balanceOf(address(this))>= sharesToRcv);
        SafeERC20.safeTransfer(_vaultInstance,msg.sender,sharesToRcv);
        _soldShares[asset] += sharesToRcv;
        _raisedAssets += assetToDeposit;        
    }

    function addToVault(address asset, uint assetAmount) public onlyOwner vaultAvailable(asset){
        
    }

    function mintShares(address asset , uint shares) public onlyOwner vaultAvailable(asset){

    }

    function burnShares(address asset , uint shares) public onlyOwner{

    }

    function addVault(address _vaultAddress, address _underLyingAsset) public onlyOwner{
        require(!vaultAvailable[_vaultAddress],"Vault Available");
        vaultAvailable[_vaultAddress] = true;
        _assetToVault[_underLyingAsset] = Vault(_vaultAddress);
    }

    function initialzeVault(address _underLyingAsset, uint _assetsToDeposit, uint _sharesToMint) public onlyOwner{
        Vault vault = _assetToVault[_underLyingAsset];
        require(vault.isInitialized()==false);
        IERC20(_underLyingAsset).approve(address(vault),_assetsToDeposit);
        vault._initializeVault(address(this),address(this),_assetsToDeposit);
    }

}