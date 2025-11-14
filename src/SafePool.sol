// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @title SafePool
 * @dev Simple vault that holds USDC deposits safely
 * @notice No yield, just secure storage for defensive mode
 */
contract SafePool {
    // USDC token interface
    IERC20 public immutable usdc;

    // Mapping to track deposits per user (for tracking purposes)
    mapping(address => uint256) public balances;

    // Total USDC held in this pool
    uint256 public totalDeposits;

    // Events
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    /**
     * @dev Constructor sets the USDC token address
     * @param _usdc Address of the USDC token contract
     */
    constructor(address _usdc) {
        require(_usdc != address(0), "SafePool: Invalid USDC address");
        usdc = IERC20(_usdc);
    }

    /**
     * @dev Deposit USDC into the safe pool
     * @param amount Amount of USDC to deposit (must be approved first)
     */
    function deposit(uint256 amount) external {
        require(amount > 0, "SafePool: Amount must be greater than 0");
        
        // Transfer USDC from caller to this contract
        require(usdc.transferFrom(msg.sender, address(this), amount), "SafePool: Transfer failed");
        
        // Update balances
        balances[msg.sender] += amount;
        totalDeposits += amount;
        
        emit Deposited(msg.sender, amount);
    }

    /**
     * @dev Withdraw all USDC from the pool (for SentinelVault to call)
     * @return Amount withdrawn
     */
    function withdrawAll() external returns (uint256) {
        uint256 amount = totalDeposits;
        require(amount > 0, "SafePool: No funds to withdraw");
        
        // Reset total deposits
        totalDeposits = 0;
        
        // Transfer all USDC to caller
        require(usdc.transfer(msg.sender, amount), "SafePool: Transfer failed");
        
        emit Withdrawn(msg.sender, amount);
        return amount;
    }

    /**
     * @dev Get the total USDC balance in this pool
     * @return Total USDC held
     */
    function getTotalBalance() external view returns (uint256) {
        return totalDeposits;
    }
}

