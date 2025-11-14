// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {MockUSDC} from "../src/MockUSDC.sol";
import {OracleFeed} from "../src/OracleFeed.sol";
import {SafePool} from "../src/SafePool.sol";
import {YieldPool} from "../src/YieldPool.sol";
import {SentinelVault} from "../src/SentinelVault.sol";

contract SentinelVaultTest is Test {
    MockUSDC public usdc;
    OracleFeed public oracle;
    SafePool public safePool;
    YieldPool public yieldPool;
    SentinelVault public sentinelVault;
    
    address public user = address(0x1);
    uint256 public constant INITIAL_BALANCE = 1000000e6; // 1M USDC

    function setUp() public {
        // Deploy contracts
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
        
        // Give user some USDC and approve
        usdc.mint(user, INITIAL_BALANCE);
        vm.prank(user);
        usdc.approve(address(sentinelVault), type(uint256).max);
        
        // Approve vault to use pools
        vm.prank(address(sentinelVault));
        usdc.approve(address(safePool), type(uint256).max);
        vm.prank(address(sentinelVault));
        usdc.approve(address(yieldPool), type(uint256).max);
    }

    function test_InitialState() public {
        assertEq(sentinelVault.getMode(), 0, "Should start in Farming mode");
        assertEq(sentinelVault.totalDeposits(), 0, "Initial deposits should be zero");
    }

    function test_DepositInFarmingMode() public {
        uint256 amount = 1000e6;
        
        vm.prank(user);
        sentinelVault.deposit(amount);
        
        assertEq(sentinelVault.userDeposits(user), amount, "User deposit should be recorded");
        assertEq(sentinelVault.totalDeposits(), amount, "Total deposits should be updated");
        assertEq(sentinelVault.getMode(), 0, "Should still be in Farming mode");
        assertEq(yieldPool.getTotalBalance(), amount, "Funds should be in YieldPool");
    }

    function test_WithdrawFromFarmingMode() public {
        uint256 depositAmount = 1000e6;
        uint256 withdrawAmount = 500e6;
        
        // Deposit
        vm.prank(user);
        sentinelVault.deposit(depositAmount);
        
        // Withdraw
        uint256 userBalanceBefore = usdc.balanceOf(user);
        vm.prank(user);
        sentinelVault.withdraw(withdrawAmount);
        uint256 userBalanceAfter = usdc.balanceOf(user);
        
        assertEq(userBalanceAfter - userBalanceBefore, withdrawAmount, "User should receive USDC");
        assertEq(sentinelVault.userDeposits(user), depositAmount - withdrawAmount, "User balance should decrease");
    }

    function test_RebalanceToDefensiveMode() public {
        uint256 amount = 1000e6;
        
        // Deposit in Farming mode
        vm.prank(user);
        sentinelVault.deposit(amount);
        assertEq(sentinelVault.getMode(), 0);
        assertEq(yieldPool.getTotalBalance(), amount);
        
        // Set price below threshold
        oracle.setPrice(0.998e18); // $0.998 < $0.999
        
        // Rebalance
        sentinelVault.rebalance();
        
        assertEq(sentinelVault.getMode(), 1, "Should switch to Defensive mode");
        assertEq(safePool.getTotalBalance(), amount, "Funds should be in SafePool");
        assertEq(yieldPool.getTotalBalance(), 0, "YieldPool should be empty");
    }

    function test_RebalanceBackToFarmingMode() public {
        uint256 amount = 1000e6;
        
        // Deposit and switch to Defensive
        vm.prank(user);
        sentinelVault.deposit(amount);
        oracle.setPrice(0.998e18);
        sentinelVault.rebalance();
        assertEq(sentinelVault.getMode(), 1);
        
        // Set price back above threshold
        oracle.setPrice(1.001e18); // $1.001 >= $0.999
        
        // Rebalance back
        sentinelVault.rebalance();
        
        assertEq(sentinelVault.getMode(), 0, "Should switch back to Farming mode");
        assertEq(yieldPool.getTotalBalance(), amount, "Funds should be back in YieldPool");
        assertEq(safePool.getTotalBalance(), 0, "SafePool should be empty");
    }

    function test_SimulateRisk() public {
        // Price above threshold
        bool wouldTrigger = sentinelVault.simulateRisk(1.001e18);
        assertFalse(wouldTrigger, "Price above threshold should not trigger");
        
        // Price below threshold
        wouldTrigger = sentinelVault.simulateRisk(0.998e18);
        assertTrue(wouldTrigger, "Price below threshold should trigger");
        
        // Price exactly at threshold
        wouldTrigger = sentinelVault.simulateRisk(0.999e18);
        assertFalse(wouldTrigger, "Price at threshold should not trigger");
    }

    function test_DepositAfterRebalance() public {
        uint256 amount1 = 500e6;
        uint256 amount2 = 300e6;
        
        // Initial deposit in Farming mode
        vm.prank(user);
        sentinelVault.deposit(amount1);
        
        // Switch to Defensive
        oracle.setPrice(0.998e18);
        sentinelVault.rebalance();
        
        // Deposit more in Defensive mode
        vm.prank(user);
        sentinelVault.deposit(amount2);
        
        assertEq(sentinelVault.userDeposits(user), amount1 + amount2, "Total user deposits should be correct");
        assertEq(safePool.getTotalBalance(), amount1 + amount2, "All funds should be in SafePool");
    }

    function test_WithdrawFromDefensiveMode() public {
        uint256 depositAmount = 1000e6;
        uint256 withdrawAmount = 300e6;
        
        // Deposit and switch to Defensive
        vm.prank(user);
        sentinelVault.deposit(depositAmount);
        oracle.setPrice(0.998e18);
        sentinelVault.rebalance();
        
        // Withdraw
        uint256 userBalanceBefore = usdc.balanceOf(user);
        vm.prank(user);
        sentinelVault.withdraw(withdrawAmount);
        uint256 userBalanceAfter = usdc.balanceOf(user);
        
        assertEq(userBalanceAfter - userBalanceBefore, withdrawAmount, "User should receive USDC");
        assertEq(sentinelVault.userDeposits(user), depositAmount - withdrawAmount, "User balance should decrease");
    }

    function test_MultipleUsers() public {
        address user2 = address(0x2);
        usdc.mint(user2, INITIAL_BALANCE);
        vm.prank(user2);
        usdc.approve(address(sentinelVault), type(uint256).max);
        
        uint256 amount1 = 500e6;
        uint256 amount2 = 300e6;
        
        vm.prank(user);
        sentinelVault.deposit(amount1);
        vm.prank(user2);
        sentinelVault.deposit(amount2);
        
        assertEq(sentinelVault.userDeposits(user), amount1);
        assertEq(sentinelVault.userDeposits(user2), amount2);
        assertEq(sentinelVault.totalDeposits(), amount1 + amount2);
        assertEq(yieldPool.getTotalBalance(), amount1 + amount2);
    }

    function test_RebalanceNoOpWhenAlreadyInCorrectMode() public {
        uint256 amount = 1000e6;
        
        vm.prank(user);
        sentinelVault.deposit(amount);
        
        // Price is above threshold, already in Farming mode
        oracle.setPrice(1.001e18);
        uint256 yieldBalanceBefore = yieldPool.getTotalBalance();
        sentinelVault.rebalance();
        uint256 yieldBalanceAfter = yieldPool.getTotalBalance();
        
        // Should not change anything
        assertEq(sentinelVault.getMode(), 0);
        assertEq(yieldBalanceBefore, yieldBalanceAfter);
    }
}

