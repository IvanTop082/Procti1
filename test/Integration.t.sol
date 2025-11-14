// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {MockUSDC} from "../src/MockUSDC.sol";
import {OracleFeed} from "../src/OracleFeed.sol";
import {SafePool} from "../src/SafePool.sol";
import {YieldPool} from "../src/YieldPool.sol";
import {SentinelVault} from "../src/SentinelVault.sol";

/**
 * @title IntegrationTest
 * @dev Full integration test simulating a complete user flow
 */
contract IntegrationTest is Test {
    MockUSDC public usdc;
    OracleFeed public oracle;
    SafePool public safePool;
    YieldPool public yieldPool;
    SentinelVault public sentinelVault;
    
    address public user = address(0x1);
    uint256 public constant INITIAL_BALANCE = 1000000e6;

    function setUp() public {
        // Deploy all contracts
        usdc = new MockUSDC(INITIAL_BALANCE);
        oracle = new OracleFeed();
        safePool = new SafePool(address(usdc));
        yieldPool = new YieldPool(address(usdc));
        sentinelVault = new SentinelVault(
            address(usdc),
            address(oracle),
            address(safePool),
            address(yieldPool)
        );
        
        // Setup user
        usdc.mint(user, INITIAL_BALANCE);
        vm.prank(user);
        usdc.approve(address(sentinelVault), type(uint256).max);
        
        // Approve vault to use pools
        vm.prank(address(sentinelVault));
        usdc.approve(address(safePool), type(uint256).max);
        vm.prank(address(sentinelVault));
        usdc.approve(address(yieldPool), type(uint256).max);
    }

    function test_FullFlow() public {
        console.log("=== Starting Full Integration Test ===");
        
        // Step 1: User deposits USDC (Farming mode)
        uint256 depositAmount = 10000e6; // 10,000 USDC
        console.log("Step 1: User deposits", depositAmount / 1e6, "USDC");
        
        vm.prank(user);
        sentinelVault.deposit(depositAmount);
        
        assertEq(sentinelVault.getMode(), 0, "Should be in Farming mode");
        assertEq(sentinelVault.userDeposits(user), depositAmount, "User deposit recorded");
        assertEq(yieldPool.getTotalBalance(), depositAmount, "Funds in YieldPool");
        console.log("  Mode: Farming");
        console.log("  Funds in YieldPool:", yieldPool.getTotalBalance() / 1e6);
        
        // Step 2: Price drops below threshold
        console.log("\nStep 2: Oracle price drops to $0.998");
        oracle.setPrice(0.998e18);
        assertTrue(sentinelVault.simulateRisk(0.998e18), "Should detect risk");
        
        // Step 3: Rebalance triggers Defensive mode
        console.log("Step 3: Rebalancing...");
        sentinelVault.rebalance();
        
        assertEq(sentinelVault.getMode(), 1, "Should switch to Defensive mode");
        assertEq(safePool.getTotalBalance(), depositAmount, "Funds moved to SafePool");
        assertEq(yieldPool.getTotalBalance(), 0, "YieldPool emptied");
        console.log("  Mode: Defensive");
        console.log("  Funds in SafePool:", safePool.getTotalBalance() / 1e6);
        
        // Step 4: User deposits more in Defensive mode
        uint256 additionalDeposit = 5000e6; // 5,000 USDC
        console.log("\nStep 4: User deposits additional", additionalDeposit / 1e6, "USDC");
        
        vm.prank(user);
        sentinelVault.deposit(additionalDeposit);
        
        assertEq(sentinelVault.userDeposits(user), depositAmount + additionalDeposit, "Total deposits updated");
        assertEq(safePool.getTotalBalance(), depositAmount + additionalDeposit, "All funds in SafePool");
        console.log("  Total user deposits:", sentinelVault.userDeposits(user) / 1e6);
        
        // Step 5: Price recovers
        console.log("\nStep 5: Oracle price recovers to $1.001");
        oracle.setPrice(1.001e18);
        assertFalse(sentinelVault.simulateRisk(1.001e18), "Should not detect risk");
        
        // Step 6: Rebalance back to Farming mode
        console.log("Step 6: Rebalancing back to Farming...");
        sentinelVault.rebalance();
        
        assertEq(sentinelVault.getMode(), 0, "Should be back in Farming mode");
        assertEq(yieldPool.getTotalBalance(), depositAmount + additionalDeposit, "Funds back in YieldPool");
        assertEq(safePool.getTotalBalance(), 0, "SafePool emptied");
        console.log("  Mode: Farming");
        console.log("  Funds in YieldPool:", yieldPool.getTotalBalance() / 1e6);
        
        // Step 7: User withdraws
        uint256 withdrawAmount = 3000e6; // 3,000 USDC
        console.log("\nStep 7: User withdraws", withdrawAmount / 1e6, "USDC");
        
        uint256 userBalanceBefore = usdc.balanceOf(user);
        vm.prank(user);
        sentinelVault.withdraw(withdrawAmount);
        uint256 userBalanceAfter = usdc.balanceOf(user);
        
        assertEq(userBalanceAfter - userBalanceBefore, withdrawAmount, "User received USDC");
        assertEq(sentinelVault.userDeposits(user), depositAmount + additionalDeposit - withdrawAmount, "Balance updated");
        console.log("  Remaining balance:", sentinelVault.userDeposits(user) / 1e6);
        
        console.log("\n=== Integration Test Complete ===");
    }

    function test_MultipleRebalances() public {
        uint256 amount = 5000e6;
        
        vm.prank(user);
        sentinelVault.deposit(amount);
        
        // Multiple price fluctuations
        oracle.setPrice(0.998e18);
        sentinelVault.rebalance();
        assertEq(sentinelVault.getMode(), 1);
        
        oracle.setPrice(1.001e18);
        sentinelVault.rebalance();
        assertEq(sentinelVault.getMode(), 0);
        
        oracle.setPrice(0.997e18);
        sentinelVault.rebalance();
        assertEq(sentinelVault.getMode(), 1);
        
        oracle.setPrice(1.002e18);
        sentinelVault.rebalance();
        assertEq(sentinelVault.getMode(), 0);
        
        // Final state should have funds in YieldPool
        assertEq(yieldPool.getTotalBalance(), amount);
    }
}

