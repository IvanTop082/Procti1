// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {OracleFeed} from "../src/OracleFeed.sol";

contract OracleFeedTest is Test {
    OracleFeed public oracle;

    function setUp() public {
        oracle = new OracleFeed();
    }

    function test_InitialPrice() public {
        uint256 price = oracle.getPrice();
        assertEq(price, 1e18, "Initial price should be 1e18 ($1.00)");
    }

    function test_SetPrice() public {
        uint256 newPrice = 0.998e18; // $0.998
        oracle.setPrice(newPrice);
        assertEq(oracle.getPrice(), newPrice, "Price should be updated");
    }

    function test_SetPriceMultipleTimes() public {
        oracle.setPrice(0.999e18);
        assertEq(oracle.getPrice(), 0.999e18);
        
        oracle.setPrice(0.995e18);
        assertEq(oracle.getPrice(), 0.995e18);
        
        oracle.setPrice(1.001e18);
        assertEq(oracle.getPrice(), 1.001e18);
    }

    function test_PriceEvent() public {
        uint256 newPrice = 0.997e18;
        vm.expectEmit(true, true, true, true);
        emit OracleFeed.PriceUpdated(newPrice);
        oracle.setPrice(newPrice);
    }
}

