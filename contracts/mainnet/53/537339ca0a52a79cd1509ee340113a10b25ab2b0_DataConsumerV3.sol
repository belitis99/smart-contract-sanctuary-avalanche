/**
 *Submitted for verification at snowtrace.io on 2023-07-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

contract DataConsumerV3 {
    /**
     * Returns the latest answer from the specified aggregator.
     */
    function getLatestDataFrom(
        address aggregator
    )
        public
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        AggregatorV3Interface dataFeed = AggregatorV3Interface(aggregator);
        return dataFeed.latestRoundData();
    }
}