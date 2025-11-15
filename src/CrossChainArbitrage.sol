// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title CrossChainArbitrage
 * @dev Cross-chain USDC arbitrage and rebalancing with simulated bridging
 * @notice Simulated bridging for demo purposes only
 */
contract CrossChainArbitrage {
    // Supported chains
    string[] public supportedChains = ["Arc", "Ethereum", "Arbitrum", "Base", "Optimism"];

    // Chain data storage
    mapping(string => uint256) public chainPrices;      // USDC price per chain (scaled 1e18)
    mapping(string => uint256) public chainYields;     // APR per chain (scaled 1e18, e.g., 0.05e18 = 5%)
    mapping(string => uint256) public chainRiskScores; // Risk score 0-100 (lower is better)

    // Active chain tracking
    string public activeChain;

    // Profit threshold for arbitrage (scaled 1e18)
    uint256 public constant PROFIT_THRESHOLD = 0.001e18; // 0.1% minimum profit

    // Events
    event ChainPriceUpdated(string indexed chain, uint256 price, uint256 timestamp);
    event ChainYieldUpdated(string indexed chain, uint256 yield, uint256 timestamp);
    event ChainRiskUpdated(string indexed chain, uint256 riskScore, uint256 timestamp);
    event CrossChainMove(
        string fromChain,
        string toChain,
        uint256 amount,
        uint256 timestamp
    );
    event ArbitrageDetected(
        string chainA,
        string chainB,
        int256 profit,
        uint256 timestamp
    );
    event CrossChainDecision(
        string newChain,
        uint256 timestamp,
        string reason
    );

    /**
     * @dev Constructor initializes default values
     */
    constructor() {
        // Initialize default prices (all $1.00)
        chainPrices["Arc"] = 1e18;
        chainPrices["Ethereum"] = 1e18;
        chainPrices["Arbitrum"] = 1e18;
        chainPrices["Base"] = 1e18;
        chainPrices["Optimism"] = 1e18;

        // Initialize default yields (5% APR)
        chainYields["Arc"] = 0.05e18;
        chainYields["Ethereum"] = 0.05e18;
        chainYields["Arbitrum"] = 0.05e18;
        chainYields["Base"] = 0.05e18;
        chainYields["Optimism"] = 0.05e18;

        // Initialize default risk scores (50 = medium risk)
        chainRiskScores["Arc"] = 50;
        chainRiskScores["Ethereum"] = 50;
        chainRiskScores["Arbitrum"] = 50;
        chainRiskScores["Base"] = 50;
        chainRiskScores["Optimism"] = 50;

        // Initialize active chain to "Arc"
        activeChain = "Arc";
    }

    /**
     * @dev Set price for a specific chain
     * @param chain Chain name (must be supported)
     * @param price USDC price scaled by 1e18
     */
    function setChainPrice(string calldata chain, uint256 price) external {
        require(_isSupportedChain(chain), "CrossChainArbitrage: Unsupported chain");
        chainPrices[chain] = price;
        emit ChainPriceUpdated(chain, price, block.timestamp);
    }

    /**
     * @dev Set yield (APR) for a specific chain
     * @param chain Chain name (must be supported)
     * @param apr APR scaled by 1e18 (e.g., 0.05e18 = 5%)
     */
    function setChainYield(string calldata chain, uint256 apr) external {
        require(_isSupportedChain(chain), "CrossChainArbitrage: Unsupported chain");
        chainYields[chain] = apr;
        emit ChainYieldUpdated(chain, apr, block.timestamp);
    }

    /**
     * @dev Set risk score for a specific chain
     * @param chain Chain name (must be supported)
     * @param riskScore Risk score 0-100 (lower is better)
     */
    function setChainRisk(string calldata chain, uint256 riskScore) external {
        require(_isSupportedChain(chain), "CrossChainArbitrage: Unsupported chain");
        require(riskScore <= 100, "CrossChainArbitrage: Risk score must be <= 100");
        chainRiskScores[chain] = riskScore;
        emit ChainRiskUpdated(chain, riskScore, block.timestamp);
    }

    /**
     * @dev Detect arbitrage opportunity between two chains
     * @param chainA First chain to compare
     * @param chainB Second chain to compare
     * @param bridgeFee Bridge fee scaled by 1e18
     * @return profitable True if arbitrage is profitable
     * @return profit Potential profit amount (can be negative)
     */
    function detectArbitrage(
        string calldata chainA,
        string calldata chainB,
        uint256 bridgeFee
    ) public view returns (bool profitable, int256 profit) {
        require(_isSupportedChain(chainA), "CrossChainArbitrage: Unsupported chainA");
        require(_isSupportedChain(chainB), "CrossChainArbitrage: Unsupported chainB");

        uint256 priceA = chainPrices[chainA];
        uint256 priceB = chainPrices[chainB];

        // Calculate price difference
        int256 priceDiff;
        if (priceA > priceB) {
            // Buy on B, sell on A
            priceDiff = int256(priceA) - int256(priceB);
        } else {
            // Buy on A, sell on B
            priceDiff = int256(priceB) - int256(priceA);
        }

        // Calculate profit after bridge fee
        profit = priceDiff - int256(bridgeFee);

        // Check if profitable (above threshold)
        profitable = profit > int256(PROFIT_THRESHOLD);

        return (profitable, profit);
    }

    /**
     * @dev Find the best chain based on risk-weighted scoring
     * @return Best chain name
     */
    function bestChain() public view returns (string memory) {
        string memory best = supportedChains[0];
        uint256 bestScore = _calculateChainScore(supportedChains[0]);

        for (uint256 i = 1; i < supportedChains.length; i++) {
            uint256 score = _calculateChainScore(supportedChains[i]);
            if (score > bestScore) {
                bestScore = score;
                best = supportedChains[i];
            }
        }

        return best;
    }

    /**
     * @dev Calculate risk-weighted score for a chain
     * @param chain Chain name
     * @return Score (higher is better)
     */
    function _calculateChainScore(string memory chain) internal view returns (uint256) {
        uint256 yield = chainYields[chain];
        uint256 risk = chainRiskScores[chain];
        uint256 price = chainPrices[chain];

        // Price stability index: abs(price - 1e18), inverted (higher stability = higher score)
        // Closer to 1e18 = more stable = higher score
        uint256 priceDeviation;
        if (price > 1e18) {
            priceDeviation = price - 1e18;
        } else {
            priceDeviation = 1e18 - price;
        }
        // Invert: higher deviation = lower score
        // Max deviation we consider is 0.01 (1%), so normalize
        uint256 maxDeviation = 0.01e18; // 1%
        if (priceDeviation > maxDeviation) {
            priceDeviation = maxDeviation;
        }
        // Calculate stability score: 1e18 - (deviation * 100)
        uint256 priceStability = 1e18 - ((priceDeviation * 1e18) / maxDeviation);

        // Score = (Yield * 40%) + ((100 - Risk) * 30%) + (PriceStability * 30%)
        uint256 yieldComponent = (yield * 40) / 100;
        uint256 riskComponent = ((100 - risk) * 1e16 * 30) / 100; // Scale risk to 1e18
        uint256 stabilityComponent = (priceStability * 30) / 100;

        return yieldComponent + riskComponent + stabilityComponent;
    }

    /**
     * @dev Switch to the best chain as computed by bestChain()
     * @notice Updates activeChain and emits CrossChainDecision event
     */
    function switchToBestChain() external {
        string memory chain = bestChain();

        activeChain = chain;

        emit CrossChainDecision(
            chain,
            block.timestamp,
            "Switching active chain to best chain"
        );
    }

    /**
     * @dev Simulate bridging USDC to another chain (demo only - no real bridging)
     * @param toChain Target chain name
     * @param amount Amount of USDC to move
     * @notice Only updates activeChain and emits event for frontend visualization
     */
    function simulateBridge(string calldata toChain, uint256 amount) external {
        require(_isSupportedChain(toChain), "CrossChainArbitrage: Unsupported chain");
        string memory fromChain = activeChain;
        emit CrossChainMove(fromChain, toChain, amount, block.timestamp);
        activeChain = toChain;
    }

    /**
     * @dev Execute cross-chain move (simulated - no real bridging)
     * @param destinationChain Target chain name
     * @param amount Amount of USDC to move
     * @notice This function is kept for backward compatibility, uses simulateBridge
     */
    function executeCrossChainMove(
        string calldata destinationChain,
        uint256 amount
    ) external {
        require(_isSupportedChain(destinationChain), "CrossChainArbitrage: Unsupported chain");
        require(amount > 0, "CrossChainArbitrage: Amount must be greater than 0");

        // Use simulateBridge for backward compatibility
        emit CrossChainMove(activeChain, destinationChain, amount, block.timestamp);
        activeChain = destinationChain;
    }


    /**
     * @dev Check if chain is supported
     * @param chain Chain name to check
     * @return True if supported
     */
    function _isSupportedChain(string memory chain) internal view returns (bool) {
        for (uint256 i = 0; i < supportedChains.length; i++) {
            if (keccak256(bytes(supportedChains[i])) == keccak256(bytes(chain))) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Get all supported chains
     * @return Array of supported chain names
     */
    function getSupportedChains() external view returns (string[] memory) {
        return supportedChains;
    }

    /**
     * @dev Get chain score (for frontend display)
     * @param chain Chain name
     * @return Score value
     */
    function getChainScore(string calldata chain) external view returns (uint256) {
        require(_isSupportedChain(chain), "CrossChainArbitrage: Unsupported chain");
        return _calculateChainScore(chain);
    }
}

