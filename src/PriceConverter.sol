// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title PriceConverter Library
 * @notice A library for converting prices using Chainlink price feeds
 */
library PriceConverter {
    /**
     * @dev Gets the latest price from the Chainlink price feed
     * @param priceFeed The Chainlink price feed contract
     * @return The latest price in ETH with 18 decimals
     */
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        uint256 decimals = (18 - priceFeed.decimals());
        uint256 ethPrice = uint256(answer) * (10 ** decimals);
        return ethPrice;
    }

    /**
     * @dev Converts the specified USD amount to ETH based on the current price feed
     * @param usdAmount The amount in USD to convert
     * @param priceFeed The Chainlink price feed contract
     * @return The equivalent amount in ETH with 18 decimals
     */
    function getUsdToEth(uint256 usdAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 usdAmountInEth = (usdAmount * 10 ** 36) / ethPrice;
        return usdAmountInEth;
    }
}
