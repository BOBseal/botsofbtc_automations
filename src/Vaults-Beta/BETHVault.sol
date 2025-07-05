// SPDX-License-Identifier:  MIT
//WIP use with caution

pragma solidity ^0.8.20;

//import "../constants/APIProxy.sol";
import "./MultiVault.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/math/Math.sol";

contract BethVault is Multi4626V1 ,Ownable{
    bool internal initalized = false;
    address public operator;
    //uint public opAccessiblePortion = 50;
    mapping(address=>uint) public totalUtilised;
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
        operator = msg.sender;
       // _mint(msg.sender,100000 * 10 ** uint(decimals()));
    }
    modifier isInitialized(){
        require(initalized,"Not Initialized");
        _;
    }
    // operator is responsible for fund utilisation & fee management/distribution
    modifier isOp(){
        require(msg.sender == operator);
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

    function opWithdrawAssets(address token,uint amount,address to) public isOp isInitialized returns(bool){
        require(IERC20(token).balanceOf(address(this)) >= amount);
        IERC20(token).transfer(to,amount);
        totalUtilised[token] += amount;
        return true;
    }

    function opDepositAssets(address token, uint amount , address from) public isOp isInitialized returns(bool){
        require(IERC20(token).balanceOf(from)>= amount);
        if(token == _assets[0] || token == _assets[1]){
            //require(IERC20(token).balanceOf(from)>= amount);
            IERC20(token).transferFrom(from,address(this),amount);
            totalUtilised[token] -= amount;
            return true;
        } else return false;
    }

    function opDepositYield(address token, uint amount, address from) public isOp isInitialized returns(bool){
        if(token == _assets[0] || token == _assets[1]){
            require(IERC20(token).balanceOf(from)>= amount);
            IERC20(token).transferFrom(from,address(this),amount);
            _assetBalances[token] += amount;
            return true;
        } else return false;
    }

    function withdrawFee(uint amount,address to) public isOp{
        _withdrawFee(amount, to);
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

    function setFee(uint num) public onlyOwner{
        _setFee(num);
    }

    function setOperator(address to) public onlyOwner{
        operator = to;
    }    
}