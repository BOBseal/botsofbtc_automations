// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library BOTSOFBTC {
    
    struct User {
        bytes32 uniqueId; // onchain BOTS ID
        bytes username; // onchain name
        int tgIg; // important - must be int , tg id can be negative
        uint totalSlots; // totalSlots being used
    }

    struct DataSlot{
        bytes32 slotId; // hash of uniqueId + slot no
        bytes primedata; // primary byte data to execute as primary slot
        bytes nonPrimeData; // non primary bytes data for later parsing
        uint dataUnit; // uint extra data for later parse 
        int dataInt; // int extra data for later parse
        bool dataBool; // bool extra data for later parse
        bytes12 dataHash; // metahash data
        bytes parseData; // parse instruction data for data slot
    }
}