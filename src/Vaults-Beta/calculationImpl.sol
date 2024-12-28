// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ShareWithdrawal {
    uint totalSupply = 10 * 10 ** 26;
    function totalAssets() public pure returns(uint){
        return 10 * 10 ** 18;
    }

    function pricePerShare() public view returns(uint){
        return ((totalAssets() * 10 ** 26)/(totalSupply));
    }
    // returns btc & eth amounts normalized to 18 decimals
    function returnValues() public view returns(uint[] memory){
        uint[] memory amountsRcv = new uint[](2);
        uint [] memory prices = new uint[](2);
        uint [] memory _assetDecimals = new uint[](2);
        prices[0] = 97842 * 10**18;
        prices[1] = 3681 * 10 ** 18;
        _assetDecimals[0] = 8;
        _assetDecimals[1] = 18;
        uint _pricePerShare = pricePerShare();
        for(uint i =0; i< 2;i++){
            uint shareC = (_pricePerShare)/2;
            uint rcv = (shareC)/(prices[i] / 10 **18);
            amountsRcv[i] = rcv;
        }
        return  (amountsRcv);
    }

    function totalAssetValue() public pure returns(uint){
        uint[] memory balances = new uint[](2);
        uint[] memory prices = new uint[](2);
        uint[] memory decimals = new uint[](2);
        uint totalValue =0;
        decimals[0]=10 **8;
        decimals[1]= 10 ** 18;
        prices[0] = 3700 * 10 ** 18;
        prices[1] = 98000 * 10 ** 18;
        balances[0]=1 * 10 ** 8;
        balances[1]=1 * 10 ** 18;
        for(uint i=0; i< balances.length;i++)
        {
            totalValue += (balances[i] * prices[i])/decimals[i];
        }
        return totalValue;
    }
}
