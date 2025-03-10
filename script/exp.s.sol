pragma solidity ^0.8.20;

import {IERC20, IERC20Metadata, ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Script} from 'forge-std/Script.sol';
//import "../src/swap/swap.sol";
//import "../src/Vaults-Beta/BETHVault.sol";
import "../src/Vaults-Beta/Vault.sol";
import "../src/misc/vaultRescue.sol";
import "../src/interfaces/IAAVEFaucet.sol";

contract Manager is Script{

  /*
  Sepolia -- usdt
   */
    function run() external{
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);
        address me = 0xcdA2fDB452FF4F5D7Ba1C3d5dFCc9CB926A5eb7D;
        address me2 = 0x0426E6B29Ec78c8d43502EC8DECbDb76551e7D60;
        IERC20 usdt = IERC20(0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0);
        IERC20 aaveUsdt = IERC20(0xAF0F6e8b0Dc5c913bbF4d14c22B4E78Dd14310B6);
        IERC20 usdc = IERC20(0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8);
        IERC20 aaveUsdc = IERC20(0x16dA4541aD1807f4443d92D26044C1147406EB80);
        address toMint = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;
        IAAVEFaucet faucet = IAAVEFaucet(0xC959483DBa39aa9E78757139af0e9a2EDEb3f42D);
        /*
        for(uint i=0; i<40; i++){
          faucet.mint(toMint,me2,10000*10 **6);
          faucet.mint(address(usdt),me2,10000*10 **6);
        }
        */
        /*
        Vault lVault = Vault(0xD51b286aD70a7b1c0E9DE8755b260c1eF055B79A);
        uint aproveAmount = type(uint).max;
        Rescue rescueCa = new Rescue();
        bytes memory dataExecApprove= abi.encodeWithSignature(
          "approve(address,uint256)",
            address(rescueCa),
            aproveAmount
        );
        lVault.execute(address(aaveUsdc),dataExecApprove);
        rescueCa.rescue(me,address(lVault),address(aaveUsdc));
        */
        
        //Vault lVault = Vault(0xCF821f1Af225b69758EB997e148642a165383da1);
        //Vault usdcVault = Vault(0xCF821f1Af225b69758EB997e148642a165383da1);
        //usdcVault.burnShare(100000 * 10 ** 18);
        //Vault usdcVault = new Vault(usdc,aaveUsdc,0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951,"AAVE LEND USDC", "lnUSDC");
        //aaveUsdc.approve(address(usdcVault),type(uint).max);
        //usdc.approve(address(usdcVault),type(uint).max);
        //usdcVault._initializeVault(me,me,400000 * 10 ** 6, 4000000);
        /*
        Vault usdtVault = new Vault(usdt,aaveUsdt,0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951,"AAVE LEND USDT", "lnUSDT");
        aaveUsdt.approve(address(usdtVault),type(uint).max);
        usdt.approve(address(usdtVault),type(uint).max);
        usdtVault._initializeVault(me,me,400000 * 10 ** 6, 4000000);
        */
        //lVault.redeem(500 * 10 ** 18, me, me);
        //lVault.redeem(1179021465362437749517,me,me);
        vm.stopBroadcast(); 
    }
}