pragma solidity ^0.8.20;

import {IERC20, IERC20Metadata, ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Script} from 'forge-std/Script.sol';
//import "../src/swap/swap.sol";
import "../src/Vaults-Beta/BETHVault.sol";
//import "../src/Vaults-Beta/Vault.sol";
import "../src/misc/vaultRescue.sol";
//import "../src/interfaces/IAAVEFaucet.sol";
import "../src/constants/AproAdjust.sol";

contract Manager is Script{

  /*
  Init Sequence = WBTC -> WETH
   */
    function run() external{
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);
        //address me = 0xcdA2fDB452FF4F5D7Ba1C3d5dFCc9CB926A5eb7D;
        //address me2 = 0x0426E6B29Ec78c8d43502EC8DECbDb76551e7D60;
        //address payable receiver = payable(me2);
        /*
        for(uint i = 0; i<10000;i++){
            receiver.transfer(1);
        }
        */
        
        IERC20 wbtc = IERC20(0x03C7054BCB39f7b2e5B2c7AcB37583e32D70Cfa3);
        IERC20 weth = IERC20(0x4200000000000000000000000000000000000006);
        IERC20 usdt = IERC20(0x05D032ac25d322df992303dCa074EE7392C117b9);
        //address wbtcOracle = 0x1Ff2fFada49646fB9b326EdF8A91446d3cf9a291;
        //Adjustor btcAdjust = new Adjustor(wbtcOracle);
        //address wethOracle = 0x97CB85Eb5F892Dd02866672EAB137b3C34501b7b;
        //Adjustor wethAdjust = new Adjustor(wethOracle);

        address wbtcOracle = 0x041a131Fa91Ad61dD85262A42c04975986580d50;
        address wethOracle = 0x5b0cf2b36a65a6BB085D501B971e4c102B9Cd473;
        address okuRouter = 0x807F4E281B7A3B324825C64ca53c69F0b418dE40;
        address okuQuoter = 0x6Aa54a43d7eEF5b239a18eed3Af4877f46522BCA;
        address okuFactory = 0xcb2436774C3e191c85056d248EF4260ce5f27A9D;
        address[] memory _assetList = new address[](2);
        address[] memory _oracleList = new address[](2);
        uint8 [] memory _decimalList = new uint8[](2);
        uint24 [] memory _feeList = new uint24[](2);
        _feeList[0] = uint24(3000);
        _feeList[1] = uint24(3000);
        _assetList[0] = address(wbtc);
        _assetList[1] = address(weth);
        _oracleList[0] = address(wbtcOracle);
        _oracleList[1] = address(wethOracle);
        _decimalList[0] = uint8(8);
        _decimalList[1] = uint8(18);
        
        /////////////////////////////////////////////////////////////////
        /*
        BethVault vault = new BethVault(
            _assetList,
            _oracleList,
            _decimalList,
            _feeList,
            usdt,
            okuRouter,
            okuQuoter,
            okuFactory,
            "BTC-ETH",
            "BETH"
        );
        */
       BethVault vault = BethVault(0x3153e271b6abbe85db54A175eD5Cf5A5fc981E8f);
        /*
        vault.changeStates(
            _assetList,
            _oracleList,
            _decimalList,
            _feeList,
            IERC20(0x05D032ac25d322df992303dCa074EE7392C117b9),
            okuRouter,
            okuQuoter,
            okuFactory
            );
        */
        //usdt.approve(address(vault),type(uint256).max);
        //wbtc.approve(address(vault),type(uint256).max);
        //weth.approve(address(vault),type(uint256).max);
        vault.setSlippage(15);
        uint wethBalance = weth.balanceOf(0xcdA2fDB452FF4F5D7Ba1C3d5dFCc9CB926A5eb7D);
        uint wbtcBalance = wbtc.balanceOf(0xcdA2fDB452FF4F5D7Ba1C3d5dFCc9CB926A5eb7D);
        //uint wethBalance = weth.balanceOf(address(vault));
        //uint wbtcBalance = wbtc.balanceOf(address(vault));
        //vault.adminWithdraw(0x03C7054BCB39f7b2e5B2c7AcB37583e32D70Cfa3,wbtcBalance,0xcdA2fDB452FF4F5D7Ba1C3d5dFCc9CB926A5eb7D);
        //vault.adminWithdraw(0x4200000000000000000000000000000000000006,wethBalance,0xcdA2fDB452FF4F5D7Ba1C3d5dFCc9CB926A5eb7D);
        /*
        uint aproveAmount = type(uint).max;
        Rescue rescueCa = new Rescue();
        bytes memory dataExecApprove= abi.encodeWithSignature(
          "approve(address,uint256)",
            address(rescueCa),
            aproveAmount
        );
        
        for(uint i =0 ; i <2; i++){
            vault.execute(_assetList[i],dataExecApprove);
            rescueCa.rescue(0xcdA2fDB452FF4F5D7Ba1C3d5dFCc9CB926A5eb7D,address(vault),_assetList[i]);
        }
        */
        
        uint8 decimals = vault.decimals();
        //uint toMint = 100 * 10 ** decimals;
        uint sharesToMint = 6700 * 10 ** decimals;
        uint[] memory depositAmounts = new uint[](2);
        depositAmounts[0] = wbtcBalance;
        depositAmounts[1] = wethBalance;
        //vault.initialize(0xcdA2fDB452FF4F5D7Ba1C3d5dFCc9CB926A5eb7D,sharesToMint,depositAmounts);
        //vault.redeem(toMint,0xcdA2fDB452FF4F5D7Ba1C3d5dFCc9CB926A5eb7D);
        //vault.mint(toMint,0xcdA2fDB452FF4F5D7Ba1C3d5dFCc9CB926A5eb7D);
        
        vm.stopBroadcast(); 
    }
}