pragma solidity ^0.8.20;

import {Script} from 'forge-std/Script.sol';
//import "../BotsOracleEndpoint/src/prices.sol";
contract Manager is Script{
    function run() external{
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);
        vm.stopBroadcast();
    }
}
