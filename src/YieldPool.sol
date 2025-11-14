// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @title YieldPool
 * @dev Simulated yield vault that generates returns on USDC deposits
 * @notice For hackathon demo - uses simple multiplier to simulate yield
 */
contract YieldPool {
    // USDC token interface
    IERC20 public immutable usdc;

    // Mapping to track deposits per user
    mapping(address => uint256) public balances;

    // Total USDC deposited
    uint256 public totalDeposits;

    // Simple yield multiplier (1e18 = 1x, 1.05e18 = 5% yield)
    // For demo purposes, we'll simulate yield by tracking deposits
    uint256 public constant YIELD_MULTIPLIER = 1.05e18; // 5% APY simulation

    // Events
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    /**
     * @dev Constructor sets the USDC token address
     * @param _usdc Address of the USDC token contract
     */
    constructor(address _usdc) {
        require(_usdc != address(0), "YieldPool: Invalid USDC address");
        usdc = IERC20(_usdc);
    }

    /**
     * @dev Deposit USDC into the yield pool
     * @param amount Amount of USDC to deposit (must be approved first)
     */
    function deposit(uint256 amount) external {
        require(amount > 0, "YieldPool: Amount must be greater than 0");
        
        // Transfer USDC from caller to this contract
        require(usdc.transferFrom(msg.sender, address(this), amount), "YieldPool: Transfer failed");
        
        // Update balances
        balances[msg.sender] += amount;
        totalDeposits += amount;
        
        emit Deposited(msg.sender, amount);
    }

    /**
     * @dev Withdraw all USDC from the yield pool (for SentinelVault to call)
     * @return Amount withdrawn (includes simulated yield)
     * @notice For demo, returns principal + simulated yield
     */
    function withdrawAll() external returns (uint256) {
        uint256 principal = totalDeposits;
        require(principal > 0, "YieldPool: No funds to withdraw");
        
        // Simulate yield: calculate amount with multiplier
        // For simplicity, we return principal + 5% yield
        uint256 amountWithYield = (principal * YIELD_MULTIPLIER) / 1e18;
        
        // Reset total deposits
        totalDeposits = 0;
        
        // Transfer USDC to caller (in real scenario, yield would come from external source)
        // For demo, we transfer the principal amount
        // Note: In production, you'd need actual yield generation mechanism
        require(usdc.transfer(msg.sender, principal), "YieldPool: Transfer failed");
        
        emit Withdrawn(msg.sender, principal);
        return principal;
    }

    /**
     * @dev Get the total USDC balance in this pool
     * @return Total USDC held
     */
    function getTotalBalance() external view returns (uint256) {
        return totalDeposits;
    }
}

