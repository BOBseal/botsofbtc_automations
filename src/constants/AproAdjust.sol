// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

contract Adjustor {
    AggregatorV3Interface internal priceFeed;

    constructor(address feed){
        priceFeed = AggregatorV3Interface(feed);
    }

    function read() external view returns (int224 value, uint32 timestamp){
       (
        /* uint80 roundId */,
        int256 answer,
        /*uint256 startedAt*/,
        /*uint256 timeStamp*/,
        /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return (int224(answer * 10 ** 10), uint32(block.timestamp));
    }
}