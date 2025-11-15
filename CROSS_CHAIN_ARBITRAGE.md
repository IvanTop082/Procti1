# Cross-Chain Arbitrage Module

Complete guide for the cross-chain USDC arbitrage and rebalancing system integrated into ArcSentinel.

---

## 📋 Overview

The CrossChainArbitrage module simulates multi-chain monitoring and arbitrage opportunities for USDC across multiple chains. This is a **hackathon-safe, demo-driven** implementation that simulates cross-chain operations without actual bridging.

---

## 🏗️ Architecture

### Contracts

1. **CrossChainArbitrage.sol** - Main arbitrage module
2. **SentinelVault.sol** - Enhanced with cross-chain integration

### Supported Chains

- **Arc** (current chain)
- **Ethereum**
- **Arbitrum**
- **Base**
- **Optimism**

---

## 🔧 CrossChainArbitrage Contract

### Storage

```solidity
mapping(string => uint256) public chainPrices;      // USDC price per chain
mapping(string => uint256) public chainYields;     // APR per chain
mapping(string => uint256) public chainRiskScores; // Risk score 0-100
```

### Key Functions

#### 1. Set Chain Data

```solidity
// Set price for a chain
function setChainPrice(string calldata chain, uint256 price) external;

// Set yield (APR) for a chain
function setChainYield(string calldata chain, uint256 apr) external;

// Set risk score for a chain
function setChainRisk(string calldata chain, uint256 riskScore) external;
```

**Example:**
```javascript
// Set Ethereum price to $0.999
await arb.setChainPrice("Ethereum", ethers.parseUnits("0.999", 18));

// Set Arbitrum yield to 7% APR
await arb.setChainYield("Arbitrum", ethers.parseUnits("0.07", 18));

// Set Base risk score to 30 (low risk)
await arb.setChainRisk("Base", 30);
```

#### 2. Detect Arbitrage

```solidity
function detectArbitrage(
    string calldata chainA,
    string calldata chainB,
    uint256 bridgeFee
) public view returns (bool profitable, int256 profit);
```

**Example:**
```javascript
const bridgeFee = ethers.parseUnits("0.001", 18); // 0.1% bridge fee
const [profitable, profit] = await arb.detectArbitrage(
    "Arc",
    "Ethereum",
    bridgeFee
);

if (profitable) {
    console.log(`Arbitrage opportunity! Profit: ${ethers.formatUnits(profit, 18)}`);
}
```

#### 3. Best Chain Selector

```solidity
function bestChain() public view returns (string memory);
```

**Scoring Formula:**
```
Score = (Yield * 40%) + ((100 - RiskScore) * 30%) + (PriceStability * 30%)
```

**Example:**
```javascript
const bestChain = await arb.bestChain();
console.log(`Best chain: ${bestChain}`);
```

#### 4. Execute Cross-Chain Move

```solidity
function executeCrossChainMove(
    string calldata destinationChain,
    uint256 amount
) external;
```

**Note:** This is **simulated** - no actual bridging occurs. It only emits events.

---

## 🔗 SentinelVault Integration

### New Functions

#### 1. Set Arbitrage Module

```solidity
function setArbitrageModule(address arbAddress) external onlyOwner;
```

**Example:**
```javascript
// Only owner can call this
await sentinelVault.setArbitrageModule(arbAddress);
```

#### 2. Check Cross-Chain Opportunities

```solidity
function checkForCrossChainOpportunities() external;
```

**Logic:**
1. Queries `arb.bestChain()` to find optimal chain
2. If best chain is not "Arc", executes cross-chain move
3. Moves 25% of vault balance (for demo purposes)
4. Emits `CrossChainDecision` event

**Example:**
```javascript
await sentinelVault.checkForCrossChainOpportunities();
```

### New Events

```solidity
event CrossChainDecision(
    string selectedChain,
    uint256 price,
    uint256 timestamp,
    string reason
);
```

**Listen for events:**
```javascript
sentinelVault.on("CrossChainDecision", (chain, price, timestamp, reason) => {
    console.log(`Cross-chain decision: ${chain}`);
    console.log(`Price: $${ethers.formatUnits(price, 18)}`);
    console.log(`Reason: ${reason}`);
});
```

---

## 📊 Frontend Integration

### Setup

```javascript
import { ethers } from 'ethers';
import CrossChainArbitrageABI from './abi/CrossChainArbitrage.json';
import SentinelVaultABI from './abi/SentinelVault.json';

const ARB_ADDRESS = "0x..."; // Deployed CrossChainArbitrage address
const SENTINEL_VAULT = "0x..."; // SentinelVault address

const arb = new ethers.Contract(ARB_ADDRESS, CrossChainArbitrageABI, signer);
const sentinelVault = new ethers.Contract(SENTINEL_VAULT, SentinelVaultABI, signer);
```

### Simulate Multi-Chain Data

```javascript
// Simulate price differences
async function simulatePriceDifferences() {
    // Set Arc price (current chain)
    await arb.setChainPrice("Arc", ethers.parseUnits("1.000", 18));
    
    // Set Ethereum price (slightly lower)
    await arb.setChainPrice("Ethereum", ethers.parseUnits("0.999", 18));
    
    // Set Arbitrum price (higher)
    await arb.setChainPrice("Arbitrum", ethers.parseUnits("1.001", 18));
}

// Simulate yield differences
async function simulateYieldDifferences() {
    await arb.setChainYield("Arc", ethers.parseUnits("0.05", 18));      // 5%
    await arb.setChainYield("Ethereum", ethers.parseUnits("0.04", 18)); // 4%
    await arb.setChainYield("Arbitrum", ethers.parseUnits("0.07", 18)); // 7%
}

// Simulate risk scores
async function simulateRiskScores() {
    await arb.setChainRisk("Arc", 50);        // Medium risk
    await arb.setChainRisk("Ethereum", 40);   // Lower risk
    await arb.setChainRisk("Arbitrum", 60);   // Higher risk
}
```

### Check Arbitrage Opportunities

```javascript
async function checkArbitrage() {
    const bridgeFee = ethers.parseUnits("0.001", 18); // 0.1%
    
    const [profitable, profit] = await arb.detectArbitrage(
        "Arc",
        "Ethereum",
        bridgeFee
    );
    
    if (profitable) {
        console.log(`✅ Arbitrage opportunity!`);
        console.log(`Profit: $${ethers.formatUnits(profit, 18)}`);
    }
}
```

### Get Best Chain

```javascript
async function getBestChain() {
    const bestChain = await arb.bestChain();
    const score = await arb.getChainScore(bestChain);
    
    console.log(`Best chain: ${bestChain}`);
    console.log(`Score: ${ethers.formatUnits(score, 18)}`);
    
    return bestChain;
}
```

### Trigger Cross-Chain Check

```javascript
async function triggerCrossChainCheck() {
    // Check for opportunities and execute if found
    const tx = await sentinelVault.checkForCrossChainOpportunities();
    await tx.wait();
    
    console.log("Cross-chain check completed!");
}
```

### Complete Example

```javascript
async function crossChainArbitrageDemo() {
    // 1. Set up chain data
    await simulatePriceDifferences();
    await simulateYieldDifferences();
    await simulateRiskScores();
    
    // 2. Check for arbitrage
    await checkArbitrage();
    
    // 3. Get best chain
    const bestChain = await getBestChain();
    
    // 4. Trigger cross-chain check
    await triggerCrossChainCheck();
    
    // 5. Listen for events
    sentinelVault.on("CrossChainDecision", (chain, price, timestamp, reason) => {
        updateUI(chain, price, reason);
    });
}
```

---

## 🎯 Use Cases

### 1. Price Arbitrage

When USDC price differs between chains:
- Buy on cheaper chain
- Sell on expensive chain
- Profit after bridge fees

### 2. Yield Optimization

When yield rates differ:
- Move funds to higher-yield chain
- Maximize returns

### 3. Risk Management

When risk scores differ:
- Move to lower-risk chain
- Protect capital

### 4. Combined Optimization

Best chain selector considers all factors:
- Yield (40% weight)
- Risk (30% weight)
- Price stability (30% weight)

---

## ⚠️ Important Notes

### Simulation Only

- **No real bridging** - All cross-chain moves are simulated
- **No actual USDC movement** - Only events are emitted
- **Manual data input** - Prices/yields/risks are set by frontend
- **Demo-driven** - Designed for hackathon presentation

### Gas Considerations

- Setting chain data requires gas
- `checkForCrossChainOpportunities()` requires gas
- Events are emitted for frontend tracking

### Security

- Only owner can set arbitrage module
- No funds are actually moved
- All operations are viewable on-chain

---

## 📝 Deployment

### Deploy CrossChainArbitrage

```bash
forge script script/DeployCrossChainArbitrage.s.sol \
  --rpc-url https://rpc.testnet.arc.network \
  --broadcast
```

### Connect to SentinelVault

```javascript
// After deploying both contracts
await sentinelVault.setArbitrageModule(arbAddress);
```

---

## 🔍 Events Reference

### CrossChainArbitrage Events

```solidity
event ChainPriceUpdated(string indexed chain, uint256 price, uint256 timestamp);
event ChainYieldUpdated(string indexed chain, uint256 yield, uint256 timestamp);
event ChainRiskUpdated(string indexed chain, uint256 riskScore, uint256 timestamp);
event CrossChainMove(string sourceChain, string destinationChain, uint256 amount, uint256 timestamp);
event ArbitrageDetected(string chainA, string chainB, int256 profit, uint256 timestamp);
```

### SentinelVault Events

```solidity
event CrossChainDecision(
    string selectedChain,
    uint256 price,
    uint256 timestamp,
    string reason
);
```

---

## 🚀 Quick Start

1. **Deploy CrossChainArbitrage**
2. **Deploy SentinelVault** (or use existing)
3. **Connect them**: `setArbitrageModule(arbAddress)`
4. **Set chain data** from frontend
5. **Call `checkForCrossChainOpportunities()`**
6. **Listen for events** and update UI

---

## 📊 Example Scoring

**Chain A:**
- Yield: 5% (0.05e18)
- Risk: 50
- Price: $1.00 (1e18)
- Score: ~0.05e18

**Chain B:**
- Yield: 7% (0.07e18)
- Risk: 40
- Price: $1.00 (1e18)
- Score: ~0.07e18

**Result:** Chain B wins (higher yield, lower risk)

---

## 🎉 Summary

The cross-chain arbitrage module provides:
- ✅ Multi-chain price tracking
- ✅ Yield comparison
- ✅ Risk scoring
- ✅ Arbitrage detection
- ✅ Simulated CCTP movement
- ✅ Integration with SentinelVault
- ✅ Clean events for frontend

**Perfect for hackathon demos!** 🚀

