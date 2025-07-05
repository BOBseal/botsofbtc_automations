pragma solidity ^0.8.20;

import {IERC20, IERC20Metadata, ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Script} from 'forge-std/Script.sol';
//import "../src/swap/swap.sol";
import "../src/Vaults-Beta/BETHVault.sol";
//import "../src/Vaults-Beta/Vault.sol";
import "../src/misc/vaultRescue.sol";
//import "../src/interfaces/IAAVEFaucet.sol";
import "../src/constants/AproAdjust.sol";
import {CustomOracle} from  "../src/oracle/uniswapOracle.sol";
//import { IQuoterV2 } from "@uniswap/v3-periphery/contracts/interfaces/IQuoterV2.sol";

contract Manager is Script{

  /*
  Init Sequence = WBTC -> WETH
   */
    function run() external{
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);
        
        address wbtc = 0x03C7054BCB39f7b2e5B2c7AcB37583e32D70Cfa3;
        IERC20 weth = IERC20(0x4200000000000000000000000000000000000006);
        
        vm.stopBroadcast(); 
    }
}