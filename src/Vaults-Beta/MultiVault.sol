
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/ERC4626.sol)
/// WIP use with caution
pragma solidity ^0.8.20;

import {IERC20, IERC20Metadata, ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import "../constants/APIProxy.sol";
/**
 Modifications : Using Orcales to aggregate value for multiple underlying assets and issue a Unified share token representing those 

 Problems on V1 : 
 1: Decimal Offset & handling underlying assets with different decimal value , however since using oracle data with taking usd value to calculate the shares solves that and introduces another problem : 
    => Volatility in USD values of an asset can lead to various attack vectors on the issued share
    Possible Solution => User buys the share in USDC , USDC gets swapped 50-50 to Underlying assets via Dex and issue shares based on the value of outToken from dex/swap
    problems introduced => more gas cost & volatility of assets can be a trigger for manipulation
 2: Gas Efficiency : Using an oracle to get USD values for the assets, introduces the problem for added gas costs on calls
 */
abstract contract Multi4626V1 is ERC20 {
    using Math for uint256;
    
    address[] internal _assets;
    uint8[] internal _assetDecimals;
    address[] internal _orcales;
    IERC20 internal _usdc;
    uint divisor = 2;
    mapping(address=>uint) internal _assetBalances;

    event Withdraw(
        address indexed receiver,
        uint256[] assets,
        uint256 shares,
        uint amount
    );
    event Deposit(address indexed reciever, uint256[] assets, uint256 shares, uint amount);

    error SwapFailed(address reciever, uint shares);
    /**
     * @dev Attempted to mint more shares than the max amount for `receiver`.
     */
    error ERC4626ExceededMaxMint(address receiver, uint256 shares, uint256 max);

    /**
     * @dev Attempted to redeem more shares than the max amount for `receiver`.
     */
    error ERC4626ExceededMaxRedeem(address owner, uint256 shares, uint256 max);

    /**
     * @dev Set the underlying asset contract. This must be an ERC20-compatible contract (ERC20 or ERC777).
     */
    constructor(address[] memory assetsList, address[] memory _oracleList, IERC20 USDCAddress) {
        _assets = assetsList;
        _orcales = _oracleList;
        _usdc = USDCAddress;
        for(uint i =0; i<assetsList.length;i++){
            (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(IERC20(assetsList[i]));
            if(success)
            {_assetDecimals[i] =uint8(assetDecimals);} else 
            {_assetDecimals[i] = uint8(18);}
        }
    }

    /**
     * @dev Attempts to fetch the asset decimals. A return value of false indicates that the attempt failed in some way.
     */
    function _tryGetAssetDecimals(IERC20 asset_) private view returns (bool, uint8) {
        (bool success, bytes memory encodedDecimals) = address(asset_).staticcall(
            abi.encodeCall(IERC20Metadata.decimals, ())
        );
        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return (true, uint8(returnedDecimals));
            }
        }
        return (false, 0);
    }

    /**
     * @dev Decimals are computed by adding the decimal offset on top of the underlying asset's decimals. This
     * "original" value is cached during construction of the vault contract. If this read operation fails (e.g., the
     * asset has not been created yet), a default of 18 is used to represent the underlying asset's decimals.
     *
     * See {IERC20Metadata-decimals}.
     */
    function decimals() public view virtual override(ERC20) returns (uint8) {
        return 18 + _decimalsOffset();
    }

    /** returns underlying assets array */
    function asset() public view virtual returns (address[] memory) {
        return _assets;
    }

    /** Returns Underlying Assets Balances */
    function totalAssetBalances() public view virtual returns (uint256[] memory) {
        uint length = _assets.length;
        uint256[] memory amounts = new uint256[](length);
        for(uint i = 0; i < length;i++){
            amounts[i]=_assetBalances[_assets[i]];
        }
        return amounts;
    }
    // returns value for total underlying assets in usd , 18 decimal places
    function totalAssets() public view virtual returns(uint){
        uint value ;
        for(uint i=0; i< _assets.length;i++){
            (int224 aValue,) = IProxy(_orcales[i]).read();
            if(aValue < 0){
                revert();
            }
            int val = int(aValue);
            value += (uint(val) * _assetBalances[_assets[i]])/ 10 ** _assetDecimals[i];
        }
        return value;
    }
    // returns share price per share at 18 decimal places
    function pricePerShare() public view returns(uint){
        return ((totalAssets() * 10 ** decimals())/totalSupply());
    }
    // returns an array of prices for each asset per asset * 10 ** _underlyingDecimals
    function pricesForAssets() public view returns(uint[] memory){
        uint[] memory values_ = new  uint[](_assets.length);
        for(uint i=0; i< _assets.length;i++){
            (int224 aValue,) = IProxy(_orcales[i]).read();
            if(aValue <0){
                revert();
            }
            int x = int(aValue);
            values_[i]=uint(x);
        }
        return values_;
    }
    // returns the recievable underlying assets for shares with 1% slippage assumption
    function returnValues(uint sharesAmount) internal view returns(uint[] memory){
        uint[] memory amountsRcv = new uint[](_assets.length);
        uint [] memory prices = pricesForAssets();
        for(uint i =0; i< _assets.length;i++){
            uint shareC = pricePerShare()/divisor;
            uint rcv = (shareC)/(prices[i]/10 ** 18);
            // always assume a slippage of 1%
            uint rcvSlippage = rcv - (rcv/100 * 1);
            if (i == 0) {
                // Scale BTC value to 8 decimals
                amountsRcv[i] = (rcvSlippage / 10 ** 10) * sharesAmount;
            } else {
                // ETH remains with 18 decimals
                amountsRcv[i] = rcvSlippage * sharesAmount;
            }
        }
        return amountsRcv;
    }
    

    /** @dev See {IERC4626-maxMint}. */
    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxRedeem}. */
    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf(owner);
    }

    /** @dev See {IERC4626-mint}.
     *
     * As opposed to {deposit}, minting is allowed even if the vault is in a state where the price of a share is zero.
     * In this case, the shares will be minted without requiring any assets to be deposited.
     */
    function _mintShares(uint256 shares, address receiver,address target,bytes[] memory data) internal virtual returns (uint256) {
        uint256 maxShares = maxMint(receiver);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxMint(receiver, shares, maxShares);
        }
        uint usdcCost = (pricePerShare()/10** (18 -6)) * shares;
        uint[] memory rtVals = returnValues(shares);
        SafeERC20.safeTransferFrom(_usdc,receiver,address(this),usdcCost);
        for(uint8 i ; i< data.length;i++){
            _usdc.approve(target,usdcCost);
            (bool success ,)=target.call{value:msg.value}(data[i]);
            if(success){
                _assetBalances[_assets[i]] += rtVals[i];
            } else {
                revert SwapFailed(receiver,shares);
            }
        }
        _mint(receiver, shares);
        emit Deposit(receiver, rtVals, shares,usdcCost);
        //_deposit(_msgSender(), receiver, assets[], shares);

        return usdcCost;
    }

    /*
    Unsafe => Swaps needs to be handled from UnderlyingAssets (BTC & ETH)->EndAsset (USDC) before _redeem is called
    @assets is asset , ie usdc rcv provided from aggregator API and is vulnerable to steep slippages 

    Uses IceCreamAPI=> 
    shares => Shares that represent underlying assets
    reciever => where usdc is transferred to after swapping BTC eth for x amount shares USDC 
    target => router target provided by ICECREAM 
    data[]=> executable array data for the swaps provided by ICECREAM
    */

    function _redeemShares(uint256 shares, address receiver,address target,bytes[] memory data) internal virtual returns (uint256) {
        require(data.length <2,"length exceed");
        uint256 maxShares = maxRedeem(receiver);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxRedeem(receiver, shares, maxShares);
        }
        uint[] memory rtVals = returnValues(shares);
        uint usdcCost = (pricePerShare()/10** (18 -6)) * shares;
        // account a fix 1% slippage
        uint assets = usdcCost - (usdcCost/100 * 1);
        _burn(receiver, shares);
        for(uint8 i ; i< data.length;i++){
            IERC20(_assets[i]).approve(target,rtVals[i]);
            (bool success ,)=target.call{value:msg.value}(data[i]);
            if(success)
            {
                _assetBalances[_assets[i]] -= rtVals[i];
            }
            else{
                revert SwapFailed(receiver,shares);
            }
        }
        SafeERC20.safeTransfer(_usdc,receiver,assets);                
        emit Withdraw(receiver, rtVals, shares, assets);
        return assets;
    }
    function _decimalsOffset() internal pure virtual returns (uint8) {
        return 8;
    }
}

