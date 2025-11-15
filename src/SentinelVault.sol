// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./OracleFeed.sol";
import "./SafePool.sol";
import "./YieldPool.sol";
import "./CrossChainArbitrage.sol";

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

    // Risk profile enum
    enum RiskProfile { Conservative, Balanced, Aggressive }

    // USDC token interface
    IERC20 public immutable usdc;

    // External contracts
    OracleFeed public immutable oracle;
    SafePool public immutable safePool;
    YieldPool public immutable yieldPool;
    
    // Cross-chain arbitrage module
    CrossChainArbitrage public arb;
    
    // Owner for setting arbitrage module
    address public owner;

    // Current mode
    uint256 public currentMode;

    // User deposit tracking
    mapping(address => uint256) public userDeposits;

    // User risk profile mapping
    mapping(address => RiskProfile) public userRiskProfile;

    // Total deposits in the vault
    uint256 public totalDeposits;

    // Vault balance tracking per chain (for unified balance view)
    mapping(string => uint256) public vaultBalance;

    // Price threshold for switching modes (0.999e18 = $0.999)
    // Note: This is now a default for Balanced profile, actual thresholds are dynamic
    uint256 public constant PRICE_THRESHOLD = 0.999e18;

    // Events
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event ModeChanged(
        uint256 newMode,
        uint256 price,
        uint256 timestamp,
        string reason
    );
    event Rebalanced(uint256 mode, uint256 amount);
    event CrossChainDecision(
        string selectedChain,
        uint256 price,
        uint256 timestamp,
        string reason
    );

    /**
     * @dev Internal helper function to switch modes cleanly
     * @param newMode The new mode to set
     * @param price The oracle price at the time of mode change
     * @param reason The reason for the mode change
     */
    function _setMode(uint256 newMode, uint256 price, string memory reason) internal {
        if (newMode == currentMode) {
            return;
        }

        currentMode = newMode;

        emit ModeChanged(
            newMode,
            price,
            block.timestamp,
            reason
        );
    }

    /**
     * @dev Modifier to restrict function to owner only
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "SentinelVault: Only owner can call this");
        _;
    }

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
        
        // Set deployer as owner
        owner = msg.sender;

        // Start in Farming mode - emit initial mode event
        uint256 initialPrice = oracle.getPrice();
        _setMode(MODE_FARMING, initialPrice, "FARMING: initial deployment");
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
            _safeApprove(address(yieldPool), amount);
            yieldPool.deposit(amount);
        } else if (currentMode == MODE_DEFENSIVE) {
            // Approve and deposit into SafePool
            _safeApprove(address(safePool), amount);
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
                _safeApprove(address(yieldPool), remaining);
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
                _safeApprove(address(safePool), remaining);
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
     * @dev Internal helper to safely approve USDC spending
     * @notice Resets approval to 0 first (required by some tokens like USDC)
     */
    function _safeApprove(address spender, uint256 amount) internal {
        // Reset approval to 0 first (required by some ERC20 tokens)
        usdc.approve(spender, 0);
        // Then set new approval
        require(usdc.approve(spender, amount), "SentinelVault: Approval failed");
    }

    /**
     * @dev Rebalance funds based on current oracle price
     * @notice Checks price and switches between Farming, Defensive, and Emergency modes
     * @notice Uses caller's risk profile to determine thresholds
     * @notice Always emits Rebalanced event, even if no mode change occurs
     */
    function rebalance() public {
        uint256 price = oracle.getPrice();
        
        // Get caller's risk profile (defaults to Conservative/0 if not set)
        RiskProfile profile = userRiskProfile[msg.sender];
        
        // Set dynamic thresholds based on profile
        uint256 defensiveThreshold;
        uint256 emergencyThreshold;
        
        if (profile == RiskProfile.Conservative) {
            defensiveThreshold = 999200000000000000;   // 0.9992
            emergencyThreshold = 996000000000000000;   // 0.996
        } else if (profile == RiskProfile.Balanced) {
            defensiveThreshold = 999000000000000000;   // 0.999
            emergencyThreshold = 995000000000000000;   // 0.995
        } else {
            // Aggressive
            defensiveThreshold = 998500000000000000;   // 0.9985
            emergencyThreshold = 994000000000000000;   // 0.994
        }
        
        bool modeChanged = false;
        uint256 amountMoved = 0;
        
        // Determine new mode based on price and thresholds
        if (price < emergencyThreshold) {
            // Emergency mode - move funds to vault (not in pools)
            if (currentMode == MODE_FARMING) {
                amountMoved = yieldPool.withdrawAll();
                // In emergency mode, funds stay in vault (don't deposit to SafePool)
                _setMode(MODE_EMERGENCY, price, "EMERGENCY: depeg detected");
                modeChanged = true;
            } else if (currentMode == MODE_DEFENSIVE) {
                // Already in defensive, move to emergency
                amountMoved = safePool.withdrawAll();
                // In emergency mode, funds stay in vault (already withdrawn from SafePool)
                _setMode(MODE_EMERGENCY, price, "EMERGENCY: depeg detected");
                modeChanged = true;
            }
            // If already in Emergency mode, emit event with current state
            if (!modeChanged) {
                emit Rebalanced(MODE_EMERGENCY, 0);
            } else {
                emit Rebalanced(MODE_EMERGENCY, amountMoved);
            }
        } else if (price < defensiveThreshold) {
            // Defensive mode - move funds to safe pool
            if (currentMode == MODE_FARMING) {
                amountMoved = yieldPool.withdrawAll();
                if (amountMoved > 0) {
                    _safeApprove(address(safePool), amountMoved);
                    safePool.deposit(amountMoved);
                }
                _setMode(MODE_DEFENSIVE, price, "DEFENSIVE: risk detected");
                modeChanged = true;
            } else if (currentMode == MODE_EMERGENCY) {
                // Moving from emergency to defensive
                amountMoved = usdc.balanceOf(address(this));
                if (amountMoved > 0) {
                    _safeApprove(address(safePool), amountMoved);
                    safePool.deposit(amountMoved);
                }
                _setMode(MODE_DEFENSIVE, price, "DEFENSIVE: risk detected");
                modeChanged = true;
            }
            // If already in Defensive mode, emit event with current state
            if (!modeChanged) {
                emit Rebalanced(MODE_DEFENSIVE, 0);
            } else {
                emit Rebalanced(MODE_DEFENSIVE, amountMoved);
            }
        } else {
            // Farming mode - move funds to yield pool
            if (currentMode == MODE_DEFENSIVE) {
                amountMoved = safePool.withdrawAll();
                if (amountMoved > 0) {
                    _safeApprove(address(yieldPool), amountMoved);
                    yieldPool.deposit(amountMoved);
                }
                _setMode(MODE_FARMING, price, "FARMING: normal conditions");
                modeChanged = true;
            } else if (currentMode == MODE_EMERGENCY) {
                // Moving from emergency to farming
                amountMoved = usdc.balanceOf(address(this));
                if (amountMoved > 0) {
                    _safeApprove(address(yieldPool), amountMoved);
                    yieldPool.deposit(amountMoved);
                }
                _setMode(MODE_FARMING, price, "FARMING: normal conditions");
                modeChanged = true;
            }
            // If already in Farming mode, emit event with current state
            if (!modeChanged) {
                emit Rebalanced(MODE_FARMING, 0);
            } else {
                emit Rebalanced(MODE_FARMING, amountMoved);
            }
        }
    }

    /**
     * @dev Set user's risk profile and automatically rebalance
     * @param profile The risk profile to set (0 = Conservative, 1 = Balanced, 2 = Aggressive)
     * @notice Automatically triggers rebalance() after setting the profile to apply new thresholds
     */
    function setRiskProfile(RiskProfile profile) external {
        userRiskProfile[msg.sender] = profile;
        // Automatically rebalance after profile change to apply new thresholds
        rebalance();
    }

    /**
     * @dev Get user's deposit balance
     * @param user Address of the user
     * @return User's deposit amount
     */
    function getBalance(address user) external view returns (uint256) {
        return userDeposits[user];
    }

    /**
     * @dev Set the arbitrage module address
     * @param arbAddress Address of CrossChainArbitrage contract
     */
    function setArbitrageModule(address arbAddress) external onlyOwner {
        require(arbAddress != address(0), "SentinelVault: Invalid arbitrage module address");
        arb = CrossChainArbitrage(arbAddress);
    }

    /**
     * @dev Trigger switch to best chain
     * @notice Calls switchToBestChain() on the arbitrage module
     */
    function triggerBestChainSwitch() external {
        require(address(arb) != address(0), "SentinelVault: Arbitrage module not set");
        arb.switchToBestChain();
    }

    /**
     * @dev Check for cross-chain arbitrage opportunities
     * @notice Queries arbitrage module for best chain and executes move if needed
     * @notice Integrates with user risk profile - won't switch to chains with prices below user's thresholds
     * @notice If best chain price is risky, will trigger rebalance to SafePool instead
     */
    function checkForCrossChainOpportunities() external {
        require(address(arb) != address(0), "SentinelVault: Arbitrage module not set");

        // Get best chain from arbitrage module
        string memory bestChainName = arb.bestChain();

        // Check if best chain is not Arc (current chain)
        bytes memory arcBytes = bytes("Arc");
        bytes memory bestChainBytes = bytes(bestChainName);
        
        bool isArc = keccak256(arcBytes) == keccak256(bestChainBytes);

        // Get price for best chain
        uint256 bestChainPrice = arb.chainPrices(bestChainName);
        
        // Get caller's risk profile to check if best chain price is acceptable
        RiskProfile profile = userRiskProfile[msg.sender];
        
        // Set dynamic thresholds based on profile
        uint256 defensiveThreshold;
        uint256 emergencyThreshold;
        
        if (profile == RiskProfile.Conservative) {
            defensiveThreshold = 999200000000000000;   // 0.9992
            emergencyThreshold = 996000000000000000;   // 0.996
        } else if (profile == RiskProfile.Balanced) {
            defensiveThreshold = 999000000000000000;   // 0.999
            emergencyThreshold = 995000000000000000;   // 0.995
        } else {
            // Aggressive
            defensiveThreshold = 998500000000000000;   // 0.9985
            emergencyThreshold = 994000000000000000;   // 0.994
        }

        // Check if best chain's price is too risky for user's profile
        if (bestChainPrice < emergencyThreshold) {
            // Best chain price is in emergency zone - don't switch, trigger rebalance to SafePool
            if (currentMode != MODE_DEFENSIVE && currentMode != MODE_EMERGENCY) {
                // If we're in Farming mode, switch to Defensive due to best chain risk
                rebalance();
            }
            
            emit CrossChainDecision(
                bestChainName,
                bestChainPrice,
                block.timestamp,
                "Best chain price too risky for user profile - staying on current chain"
            );
            return;
        }

        if (!isArc) {
            // Best chain is not Arc and price is acceptable
            // Check if best chain price would require Defensive mode
            if (bestChainPrice < defensiveThreshold) {
                // Best chain price is below defensive threshold
                // Switch to best chain but ensure we're in Defensive mode
                if (currentMode == MODE_FARMING) {
                    rebalance(); // This will switch to Defensive mode
                }
                
                // Switch to best chain
                arb.switchToBestChain();
                
                // Get current vault balance for simulated move
                uint256 currentBalance = usdc.balanceOf(address(this));
                if (currentMode == MODE_FARMING) {
                    currentBalance = yieldPool.getTotalBalance();
                } else if (currentMode == MODE_DEFENSIVE) {
                    currentBalance = safePool.getTotalBalance();
                }

                // Execute cross-chain move (simulated)
                if (currentBalance > 0) {
                    uint256 moveAmount = currentBalance / 4; // Move 25% for demo
                    arb.simulateBridge(bestChainName, moveAmount);
                }

                emit CrossChainDecision(
                    bestChainName,
                    bestChainPrice,
                    block.timestamp,
                    "Switching to best chain (Defensive mode due to price risk)"
                );
            } else {
                // Best chain price is safe - can use Farming mode
                // Ensure we're in Farming mode if price allows
                uint256 localPrice = oracle.getPrice();
                if (localPrice >= defensiveThreshold && currentMode != MODE_FARMING) {
                    rebalance(); // This will switch to Farming if local price allows
                }
                
                // Switch to best chain
                arb.switchToBestChain();
                
                // Get current vault balance for simulated move
                uint256 currentBalance = usdc.balanceOf(address(this));
                if (currentMode == MODE_FARMING) {
                    currentBalance = yieldPool.getTotalBalance();
                } else if (currentMode == MODE_DEFENSIVE) {
                    currentBalance = safePool.getTotalBalance();
                }

                // Execute cross-chain move (simulated)
                if (currentBalance > 0) {
                    uint256 moveAmount = currentBalance / 4; // Move 25% for demo
                    arb.simulateBridge(bestChainName, moveAmount);
                }

                emit CrossChainDecision(
                    bestChainName,
                    bestChainPrice,
                    block.timestamp,
                    "Cross-chain arbitrage opportunity detected - switching to best chain"
                );
            }
        } else {
            // Best chain is Arc - check if we need to rebalance based on local price
            uint256 localPrice = oracle.getPrice();
            if (localPrice < defensiveThreshold && currentMode == MODE_FARMING) {
                // Local price dropped, switch to Defensive
                rebalance();
            }
            
            // Emit decision
            emit CrossChainDecision(
                "Arc",
                bestChainPrice,
                block.timestamp,
                "Arc is the optimal chain"
            );
        }
    }

    /**
     * @dev Get unified vault balance across all chains
     * @notice Sums all vault balances across all supported chains
     * @return Total balance across all chains
     */
    function getUnifiedVaultBalance() external view returns (uint256) {
        uint256 total = 0;

        // Get supported chains from arbitrage module if available
        if (address(arb) != address(0)) {
            string[] memory chains = arb.getSupportedChains();
            for (uint256 i = 0; i < chains.length; i++) {
                string memory chain = chains[i];
                total += vaultBalance[chain];
            }
        } else {
            // Fallback to default chains if arbitrage module not set
            total += vaultBalance["Arc"];
            total += vaultBalance["Ethereum"];
            total += vaultBalance["Arbitrum"];
            total += vaultBalance["Base"];
            total += vaultBalance["Optimism"];
        }

        return total;
    }
}

