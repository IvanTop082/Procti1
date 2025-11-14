// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {MockUSDC} from "../src/MockUSDC.sol";
import {SafePool} from "../src/SafePool.sol";
import {YieldPool} from "../src/YieldPool.sol";

contract PoolsTest is Test {
    MockUSDC public usdc;
    SafePool public safePool;
    YieldPool public yieldPool;
    
    address public user = address(0x1);
    uint256 public constant INITIAL_BALANCE = 1000000e6; // 1M USDC (6 decimals)

    function setUp() public {
        usdc = new MockUSDC(INITIAL_BALANCE);
        safePool = new SafePool(address(usdc));
        yieldPool = new YieldPool(address(usdc));
        
        // Give user some USDC
        usdc.mint(user, INITIAL_BALANCE);
        vm.prank(user);
        usdc.approve(address(safePool), type(uint256).max);
        vm.prank(user);
        usdc.approve(address(yieldPool), type(uint256).max);
    }

    function test_SafePoolDeposit() public {
        uint256 amount = 1000e6; // 1000 USDC
        
        vm.prank(user);
        safePool.deposit(amount);
        
        assertEq(safePool.balances(user), amount, "User balance should be updated");
        assertEq(safePool.getTotalBalance(), amount, "Total deposits should be updated");
        assertEq(usdc.balanceOf(address(safePool)), amount, "SafePool should hold USDC");
    }

    function test_SafePoolWithdrawAll() public {
        uint256 amount = 1000e6;
        
        vm.prank(user);
        safePool.deposit(amount);
        
        uint256 withdrawn = safePool.withdrawAll();
        assertEq(withdrawn, amount, "Should withdraw all deposited amount");
        assertEq(safePool.getTotalBalance(), 0, "Total deposits should be zero");
        assertEq(usdc.balanceOf(address(safePool)), 0, "SafePool should be empty");
    }

    function test_YieldPoolDeposit() public {
        uint256 amount = 1000e6;
        
        vm.prank(user);
        yieldPool.deposit(amount);
        
        assertEq(yieldPool.balances(user), amount, "User balance should be updated");
        assertEq(yieldPool.getTotalBalance(), amount, "Total deposits should be updated");
        assertEq(usdc.balanceOf(address(yieldPool)), amount, "YieldPool should hold USDC");
    }

    function test_YieldPoolWithdrawAll() public {
        uint256 amount = 1000e6;
        
        vm.prank(user);
        yieldPool.deposit(amount);
        
        uint256 withdrawn = yieldPool.withdrawAll();
        assertEq(withdrawn, amount, "Should withdraw principal amount");
        assertEq(yieldPool.getTotalBalance(), 0, "Total deposits should be zero");
    }

    function test_MultipleDeposits() public {
        uint256 amount1 = 500e6;
        uint256 amount2 = 300e6;
        
        vm.prank(user);
        safePool.deposit(amount1);
        vm.prank(user);
        safePool.deposit(amount2);
        
        assertEq(safePool.getTotalBalance(), amount1 + amount2, "Total should be sum of deposits");
    }
}

