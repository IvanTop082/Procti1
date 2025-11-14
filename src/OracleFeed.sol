// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title OracleFeed
 * @dev Simple price feed contract to simulate USDC price changes
 * @notice Used for hackathon demo - allows manual price setting
 */
contract OracleFeed {
    // Current USDC price (scaled by 1e18, so 1e18 = $1.00)
    uint256 private price;

    // Events
    event PriceUpdated(uint256 newPrice);

    /**
     * @dev Constructor sets initial price to $1.00 (1e18)
     */
    constructor() {
        price = 1e18;
    }

    /**
     * @dev Set the USDC price (for demo purposes)
     * @param _price New price scaled by 1e18 (e.g., 1e18 = $1.00, 0.999e18 = $0.999)
     */
    function setPrice(uint256 _price) external {
        price = _price;
        emit PriceUpdated(_price);
    }

    /**
     * @dev Get the current USDC price
     * @return Current price scaled by 1e18
     */
    function getPrice() external view returns (uint256) {
        return price;
    }
}

