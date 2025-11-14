// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./OracleFeed.sol";
import "./SafePool.sol";
import "./YieldPool.sol";

/**
 * @title SentinelVault
 * @dev Main vault contract that manages user deposits and automatically rebalances based on oracle price
 * @notice Switches between Farming and Defensive modes based on USDC price stability
 */
contract SentinelVault {
    // Mode constants
    uint256 public constant MODE_FARMING = 0;    // Normal mode - funds in YieldPool
    uint256 public constant MODE_DEFENSIVE = 1;  // Risk mode - funds in SafePool
    uint256 public constant MODE_EMERGENCY = 2;   // Emergency mode - funds held in vault

    // USDC token interface
    IERC20 public immutable usdc;

    // External contracts
    OracleFeed public immutable oracle;
    SafePool public immutable safePool;
    YieldPool public immutable yieldPool;

    // Current mode
    uint256 public currentMode;

    // User deposit tracking
    mapping(address => uint256) public userDeposits;

    // Total deposits in the vault
    uint256 public totalDeposits;

    // Price threshold for switching modes (0.999e18 = $0.999)
    uint256 public constant PRICE_THRESHOLD = 0.999e18;

    // Events
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event ModeChanged(uint256 oldMode, uint256 newMode);
    event Rebalanced(uint256 mode, uint256 amount);

    /**
     * @dev Constructor initializes all contract addresses
     * @param _usdc Address of USDC token
     * @param _oracle Address of OracleFeed contract
     * @param _safePool Address of SafePool contract
     * @param _yieldPool Address of YieldPool contract
     */
    constructor(
        address _usdc,
        address _oracle,
        address _safePool,
        address _yieldPool
    ) {
        require(_usdc != address(0), "SentinelVault: Invalid USDC address");
        require(_oracle != address(0), "SentinelVault: Invalid Oracle address");
        require(_safePool != address(0), "SentinelVault: Invalid SafePool address");
        require(_yieldPool != address(0), "SentinelVault: Invalid YieldPool address");

        usdc = IERC20(_usdc);
        oracle = OracleFeed(_oracle);
        safePool = SafePool(_safePool);
        yieldPool = YieldPool(_yieldPool);

        // Start in Farming mode
        currentMode = MODE_FARMING;
    }

    /**
     * @dev Deposit USDC into the vault
     * @param amount Amount of USDC to deposit (must be approved first)
     */
    function deposit(uint256 amount) external {
        require(amount > 0, "SentinelVault: Amount must be greater than 0");
        
        // Transfer USDC from user
        require(usdc.transferFrom(msg.sender, address(this), amount), "SentinelVault: Transfer failed");
        
        // Update user balance
        userDeposits[msg.sender] += amount;
        totalDeposits += amount;
        
        // Automatically allocate to current mode's pool
        if (currentMode == MODE_FARMING) {
            // Approve and deposit into YieldPool
            require(usdc.approve(address(yieldPool), amount), "SentinelVault: Approval failed");
            yieldPool.deposit(amount);
        } else if (currentMode == MODE_DEFENSIVE) {
            // Approve and deposit into SafePool
            require(usdc.approve(address(safePool), amount), "SentinelVault: Approval failed");
            safePool.deposit(amount);
        }
        // In emergency mode, funds stay in the vault
        
        emit Deposited(msg.sender, amount);
    }

    /**
     * @dev Withdraw USDC from the vault
     * @param amount Amount of USDC to withdraw
     */
    function withdraw(uint256 amount) external {
        require(amount > 0, "SentinelVault: Amount must be greater than 0");
        require(userDeposits[msg.sender] >= amount, "SentinelVault: Insufficient balance");
        
        // Update user balance
        userDeposits[msg.sender] -= amount;
        totalDeposits -= amount;
        
        // Withdraw from current mode's pool
        if (currentMode == MODE_FARMING) {
            // Withdraw from YieldPool
            uint256 withdrawn = yieldPool.withdrawAll();
            require(withdrawn >= amount, "SentinelVault: Insufficient funds in YieldPool");
            // If we need less than what was withdrawn, deposit the rest back
            if (withdrawn > amount) {
                uint256 remaining = withdrawn - amount;
                require(usdc.approve(address(yieldPool), remaining), "SentinelVault: Approval failed");
                yieldPool.deposit(remaining);
            }
            // Transfer requested amount to user
            require(usdc.transfer(msg.sender, amount), "SentinelVault: Transfer failed");
        } else if (currentMode == MODE_DEFENSIVE) {
            // Withdraw from SafePool
            uint256 withdrawn = safePool.withdrawAll();
            require(withdrawn >= amount, "SentinelVault: Insufficient funds in SafePool");
            // If we need less than what was withdrawn, deposit the rest back
            if (withdrawn > amount) {
                uint256 remaining = withdrawn - amount;
                require(usdc.approve(address(safePool), remaining), "SentinelVault: Approval failed");
                safePool.deposit(remaining);
            }
            // Transfer requested amount to user
            require(usdc.transfer(msg.sender, amount), "SentinelVault: Transfer failed");
        } else {
            // Emergency mode - transfer directly from vault
            require(usdc.balanceOf(address(this)) >= amount, "SentinelVault: Insufficient vault balance");
            require(usdc.transfer(msg.sender, amount), "SentinelVault: Transfer failed");
        }
        
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @dev Get the current mode
     * @return Current mode (0 = Farming, 1 = Defensive, 2 = Emergency)
     */
    function getMode() public view returns (uint256) {
        return currentMode;
    }

    /**
     * @dev Simulate risk by checking what would happen with a new price
     * @param newPrice The price to simulate
     * @return Would trigger mode change (true if price < threshold)
     */
    function simulateRisk(uint256 newPrice) external view returns (bool) {
        return newPrice < PRICE_THRESHOLD;
    }

    /**
     * @dev Rebalance funds based on current oracle price
     * @notice Checks price and switches between Farming and Defensive modes
     */
    function rebalance() external {
        uint256 currentPrice = oracle.getPrice();
        uint256 oldMode = currentMode;
        
        if (currentPrice < PRICE_THRESHOLD) {
            // Switch to Defensive mode
            if (currentMode == MODE_FARMING) {
                // Withdraw all from YieldPool
                uint256 amount = yieldPool.withdrawAll();
                
                // Deposit into SafePool
                if (amount > 0) {
                    require(usdc.approve(address(safePool), amount), "SentinelVault: Approval failed");
                    safePool.deposit(amount);
                }
                
                currentMode = MODE_DEFENSIVE;
                emit ModeChanged(oldMode, MODE_DEFENSIVE);
                emit Rebalanced(MODE_DEFENSIVE, amount);
            }
        } else {
            // Switch to Farming mode
            if (currentMode == MODE_DEFENSIVE) {
                // Withdraw all from SafePool
                uint256 amount = safePool.withdrawAll();
                
                // Deposit into YieldPool
                if (amount > 0) {
                    require(usdc.approve(address(yieldPool), amount), "SentinelVault: Approval failed");
                    yieldPool.deposit(amount);
                }
                
                currentMode = MODE_FARMING;
                emit ModeChanged(oldMode, MODE_FARMING);
                emit Rebalanced(MODE_FARMING, amount);
            }
        }
    }

    /**
     * @dev Get user's deposit balance
     * @param user Address of the user
     * @return User's deposit amount
     */
    function getBalance(address user) external view returns (uint256) {
        return userDeposits[user];
    }
}

