// SPDX-License-Identifier:  MIT
//WIP use with caution

pragma solidity ^0.8.20;

//import "../constants/APIProxy.sol";
import "./MultiVault.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/math/Math.sol";

contract BethVault is Multi4626V1 ,Ownable{
    bool internal initalized = false;
    constructor(
        address[] memory assetsList, 
        address[] memory _oracleList,
        uint8[] memory decimalList,
        uint24[] memory _feeVals, 
        IERC20 USDCAddress, 
        address swapRouter_, 
        address swapQuoter_, 
        address swapPoolFactory_,
        string memory _name,
        string memory _tick
        )
    Multi4626V1(
        assetsList, 
        _oracleList,
        decimalList,
        _feeVals, 
        USDCAddress, 
        swapRouter_, 
        swapQuoter_, 
        swapPoolFactory_
    )
    ERC20(_name,_tick)
    Ownable(msg.sender)
    {
       // _mint(msg.sender,100000 * 10 ** uint(decimals()));
    }
    modifier isInitialized(){
        require(initalized,"Not Initialized");
        _;
    }

    function initialize(address to,uint sharesToMint ,uint[] memory initialAssets) public onlyOwner{
        require(initalized == false);
        for(uint i=0; i< initialAssets.length; i++){
            if(IERC20(_assets[i]).balanceOf(msg.sender) < initialAssets[i]){
                revert("Bal Err");
            }
            SafeERC20.safeTransferFrom(IERC20(_assets[i]),msg.sender,address(this),initialAssets[i]);
            _assetBalances[_assets[i]] += initialAssets[i];
        }
        _mint(to,sharesToMint);
        initalized = true;
    }
    function execute(address target ,bytes calldata data) public payable onlyOwner isInitialized returns(bool,bytes memory){
        (bool success , bytes memory returnData)=target.call{value:msg.value}(data);
        return (success,returnData);
    }

    function withdrawFee(address token , uint amount) public onlyOwner{
        _withdrawFee(token,amount);
    }

    function changeStates(
        address[] memory assetsList, 
        address[] memory _oracleList,
        uint8[] memory decimalList,
        uint24[] memory _feeVals, 
        IERC20 USDCAddress, 
        address swapRouter_, 
        address swapQuoter_, 
        address swapPoolFactory_
    ) public onlyOwner{
        _assets = assetsList;
        _orcales = _oracleList;
        _usdc = USDCAddress;
        _assetDecimals = decimalList;
        s_okuRouter = ISwapRouter(swapRouter_);
        s_okuQuoter = IQuoterV2(swapQuoter_);
        s_okuFactory = IUniswapV3Factory(swapPoolFactory_);
        feeValues = _feeVals;
    }

    function setSlippage(uint num) public onlyOwner{
        _setSlippage(num);
    }
}