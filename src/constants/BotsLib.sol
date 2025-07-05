// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library BOTSOFBTC {
    /*
    Struct User is mapped to address
     */
    struct User {
        bytes32 uniqueId; // onchain BOTS ID
        bytes username; // onchain name
        int tgIg; // important - must be int , tg id can be negative
        uint totalSlots; // totalSlots being used
        mapping(bytes32 => DataSlot) slots; // mappings of slot ids to Dataslots
        mapping(uint => bool) slotInactive; // returns true for a disabled storage slot
    }

    struct Exectuables{
        uint numSlot;
        bytes32 slotId; 
        address[] targets;
        bytes[] executionData;
        ExecutionConfig executionConfig;
    }

    struct ExecutionConfig{
        uint maxExecutions;/// max execution for data
        uint currentExecutions; // current executions completed
        uint initTimestamp; /// block timestamp for initial execution
        uint timestampDelay; /// block timestamp for delay per execution
    }

    struct ExecutionFeeConfigs{
        uint maxGasPerExecution; /// maximum wei per execution
        uint gasPricePerExecution; /// maximum gas price in wei per execution
    }
/*
    // Thirdparty/DLT executor entries
    struct ExecutorData{

    }
*/
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