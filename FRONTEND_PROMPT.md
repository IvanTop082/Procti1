# Frontend Integration Prompt - Cross-Chain Arbitrage

## 🎯 Your Mission

Integrate the **Cross-Chain Arbitrage** module into the ArcSentinel frontend. This adds multi-chain monitoring, arbitrage detection, and automated cross-chain fund movement capabilities.

---

## 📋 What You're Building

### New Features to Add

1. **Multi-Chain Dashboard**
   - Display prices, yields, and risk scores for 5 chains
   - Show real-time chain comparison
   - Highlight best chain

2. **Arbitrage Detection UI**
   - Show arbitrage opportunities between chains
   - Display potential profits
   - Alert when opportunities are detected

3. **Cross-Chain Controls**
   - Button to check for cross-chain opportunities
   - Display cross-chain decisions
   - Show simulated cross-chain moves

4. **Chain Data Management**
   - Input fields to set prices/yields/risks for each chain
   - Update chain data in real-time
   - Visualize chain scores

---

## 🔌 Contract Integration

### Contract Addresses

```javascript
const SENTINEL_VAULT = "0xDf9053726a2217326bFEadc0c3480c5De7107B8f";
const CROSS_CHAIN_ARB = "0x387a8Ed9B0BeC289CA53a4F58F9c25A4366Fd245";
```

### Import ABIs

```javascript
import SentinelVaultABI from './abi/SentinelVault.json';
import CrossChainArbitrageABI from './abi/CrossChainArbitrage.json';
```

### Connect Contracts

```javascript
const sentinelVault = new ethers.Contract(
  SENTINEL_VAULT,
  SentinelVaultABI,
  signer
);

const crossChainArb = new ethers.Contract(
  CROSS_CHAIN_ARB,
  CrossChainArbitrageABI,
  signer
);
```

---

## 🎨 UI Components to Build

### 1. Multi-Chain Dashboard Component

**Display:**
- Chain name
- Current price (USDC)
- Yield (APR %)
- Risk score (0-100)
- Chain score (calculated)
- Best chain indicator

**Example Layout:**
```
┌─────────────────────────────────────┐
│  Multi-Chain Dashboard              │
├─────────────────────────────────────┤
│  Arc          [BEST]                │
│  Price: $1.000  Yield: 5%  Risk: 50│
│  Score: 0.052                        │
├─────────────────────────────────────┤
│  Ethereum                            │
│  Price: $0.999  Yield: 4%  Risk: 40 │
│  Score: 0.048                        │
├─────────────────────────────────────┤
│  Arbitrum                            │
│  Price: $1.001  Yield: 7%  Risk: 60 │
│  Score: 0.055                        │
└─────────────────────────────────────┘
```

**Code:**
```javascript
async function MultiChainDashboard() {
  const chains = await crossChainArb.getSupportedChains();
  const chainData = [];
  
  for (const chain of chains) {
    const [price, yield_, risk, score] = await Promise.all([
      crossChainArb.chainPrices(chain),
      crossChainArb.chainYields(chain),
      crossChainArb.chainRiskScores(chain),
      crossChainArb.getChainScore(chain)
    ]);
    
    chainData.push({
      name: chain,
      price: Number(price) / 1e18,
      yield: Number(yield_) / 1e18 * 100, // Convert to percentage
      risk: Number(risk),
      score: Number(score) / 1e18
    });
  }
  
  const bestChain = await crossChainArb.bestChain();
  
  return (
    <div className="dashboard">
      {chainData.map(chain => (
        <ChainCard
          key={chain.name}
          chain={chain}
          isBest={chain.name === bestChain}
        />
      ))}
    </div>
  );
}
```

---

### 2. Arbitrage Detection Component

**Display:**
- Chain A vs Chain B comparison
- Price difference
- Bridge fee
- Potential profit
- "Detect Arbitrage" button

**Code:**
```javascript
async function ArbitrageDetector() {
  const [chainA, setChainA] = useState("Arc");
  const [chainB, setChainB] = useState("Ethereum");
  const [bridgeFee, setBridgeFee] = useState("0.001"); // 0.1%
  const [result, setResult] = useState(null);
  
  const detectArbitrage = async () => {
    const fee = ethers.parseUnits(bridgeFee, 18);
    const [profitable, profit] = await crossChainArb.detectArbitrage(
      chainA,
      chainB,
      fee
    );
    
    setResult({
      profitable,
      profit: Number(profit) / 1e18,
      chainA,
      chainB
    });
  };
  
  return (
    <div>
      <select value={chainA} onChange={e => setChainA(e.target.value)}>
        <option>Arc</option>
        <option>Ethereum</option>
        <option>Arbitrum</option>
        <option>Base</option>
        <option>Optimism</option>
      </select>
      
      <span> vs </span>
      
      <select value={chainB} onChange={e => setChainB(e.target.value)}>
        <option>Arc</option>
        <option>Ethereum</option>
        <option>Arbitrum</option>
        <option>Base</option>
        <option>Optimism</option>
      </select>
      
      <input
        type="number"
        value={bridgeFee}
        onChange={e => setBridgeFee(e.target.value)}
        placeholder="Bridge fee (0.001 = 0.1%)"
      />
      
      <button onClick={detectArbitrage}>Detect Arbitrage</button>
      
      {result && (
        <div className={result.profitable ? "profit" : "no-profit"}>
          {result.profitable ? (
            <p>✅ Arbitrage Opportunity!</p>
          ) : (
            <p>❌ No profitable arbitrage</p>
          )}
          <p>Potential Profit: ${result.profit.toFixed(6)}</p>
        </div>
      )}
    </div>
  );
}
```

---

### 3. Chain Data Manager Component

**Display:**
- Input fields for each chain
- Price, Yield, Risk inputs
- "Update" buttons
- Current values display

**Code:**
```javascript
function ChainDataManager() {
  const [selectedChain, setSelectedChain] = useState("Arc");
  const [price, setPrice] = useState("1.000");
  const [yield_, setYield] = useState("5"); // 5%
  const [risk, setRisk] = useState("50");
  
  const updatePrice = async () => {
    const priceWei = ethers.parseUnits(price, 18);
    const tx = await crossChainArb.setChainPrice(selectedChain, priceWei);
    await tx.wait();
    alert(`Price updated for ${selectedChain}`);
  };
  
  const updateYield = async () => {
    const yieldWei = ethers.parseUnits((Number(yield_) / 100).toString(), 18);
    const tx = await crossChainArb.setChainYield(selectedChain, yieldWei);
    await tx.wait();
    alert(`Yield updated for ${selectedChain}`);
  };
  
  const updateRisk = async () => {
    const tx = await crossChainArb.setChainRisk(selectedChain, Number(risk));
    await tx.wait();
    alert(`Risk updated for ${selectedChain}`);
  };
  
  return (
    <div>
      <select value={selectedChain} onChange={e => setSelectedChain(e.target.value)}>
        <option>Arc</option>
        <option>Ethereum</option>
        <option>Arbitrum</option>
        <option>Base</option>
        <option>Optimism</option>
      </select>
      
      <div>
        <label>Price (USD):</label>
        <input
          type="number"
          step="0.001"
          value={price}
          onChange={e => setPrice(e.target.value)}
        />
        <button onClick={updatePrice}>Update Price</button>
      </div>
      
      <div>
        <label>Yield (APR %):</label>
        <input
          type="number"
          step="0.1"
          value={yield_}
          onChange={e => setYield(e.target.value)}
        />
        <button onClick={updateYield}>Update Yield</button>
      </div>
      
      <div>
        <label>Risk Score (0-100):</label>
        <input
          type="number"
          min="0"
          max="100"
          value={risk}
          onChange={e => setRisk(e.target.value)}
        />
        <button onClick={updateRisk}>Update Risk</button>
      </div>
    </div>
  );
}
```

---

### 4. Cross-Chain Opportunity Checker

**Display:**
- "Check Cross-Chain Opportunities" button
- Current best chain
- Decision log
- Cross-chain move notifications

**Code:**
```javascript
function CrossChainOpportunityChecker() {
  const [bestChain, setBestChain] = useState(null);
  const [decisions, setDecisions] = useState([]);
  
  useEffect(() => {
    // Listen for cross-chain decisions
    sentinelVault.on("CrossChainDecision", (chain, price, timestamp, reason) => {
      setDecisions(prev => [{
        chain,
        price: Number(price) / 1e18,
        timestamp: new Date(Number(timestamp) * 1000),
        reason
      }, ...prev]);
    });
    
    // Get initial best chain
    loadBestChain();
    
    return () => {
      sentinelVault.removeAllListeners("CrossChainDecision");
    };
  }, []);
  
  const loadBestChain = async () => {
    const chain = await crossChainArb.bestChain();
    setBestChain(chain);
  };
  
  const checkOpportunities = async () => {
    try {
      const tx = await sentinelVault.checkForCrossChainOpportunities();
      await tx.wait();
      await loadBestChain(); // Refresh best chain
      alert("Cross-chain check completed!");
    } catch (error) {
      console.error("Error checking opportunities:", error);
    }
  };
  
  return (
    <div>
      <div>
        <h3>Best Chain: {bestChain || "Loading..."}</h3>
        <button onClick={checkOpportunities}>
          Check Cross-Chain Opportunities
        </button>
      </div>
      
      <div className="decision-log">
        <h4>Cross-Chain Decisions</h4>
        {decisions.map((decision, idx) => (
          <div key={idx} className="decision-item">
            <p><strong>{decision.chain}</strong> - {decision.reason}</p>
            <p>Price: ${decision.price.toFixed(6)}</p>
            <p>Time: {decision.timestamp.toLocaleString()}</p>
          </div>
        ))}
      </div>
    </div>
  );
}
```

---

### 5. Complete Integration Example

```javascript
import { ethers } from 'ethers';
import { useState, useEffect } from 'react';
import SentinelVaultABI from './abi/SentinelVault.json';
import CrossChainArbitrageABI from './abi/CrossChainArbitrage.json';

const SENTINEL_VAULT = "0xDf9053726a2217326bFEadc0c3480c5De7107B8f";
const CROSS_CHAIN_ARB = "0x387a8Ed9B0BeC289CA53a4F58F9c25A4366Fd245";

function CrossChainDashboard() {
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [sentinelVault, setSentinelVault] = useState(null);
  const [crossChainArb, setCrossChainArb] = useState(null);
  const [chains, setChains] = useState([]);
  const [bestChain, setBestChain] = useState(null);
  
  useEffect(() => {
    initContracts();
  }, []);
  
  const initContracts = async () => {
    if (window.ethereum) {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      
      const sentinelVault = new ethers.Contract(
        SENTINEL_VAULT,
        SentinelVaultABI,
        signer
      );
      
      const crossChainArb = new ethers.Contract(
        CROSS_CHAIN_ARB,
        CrossChainArbitrageABI,
        signer
      );
      
      setProvider(provider);
      setSigner(signer);
      setSentinelVault(sentinelVault);
      setCrossChainArb(crossChainArb);
      
      // Load initial data
      const chains = await crossChainArb.getSupportedChains();
      setChains(chains);
      
      const best = await crossChainArb.bestChain();
      setBestChain(best);
      
      // Listen for events
      setupEventListeners(sentinelVault, crossChainArb);
    }
  };
  
  const setupEventListeners = (sentinelVault, crossChainArb) => {
    // Listen for cross-chain decisions
    sentinelVault.on("CrossChainDecision", (chain, price, timestamp, reason) => {
      console.log("Cross-chain decision:", { chain, price, reason });
      // Update UI
    });
    
    // Listen for chain data updates
    crossChainArb.on("ChainPriceUpdated", (chain, price, timestamp) => {
      console.log("Price updated:", chain, price);
      // Refresh chain data
    });
    
    crossChainArb.on("CrossChainMove", (source, dest, amount, timestamp) => {
      console.log("Cross-chain move:", { source, dest, amount });
      // Show notification
    });
  };
  
  return (
    <div className="cross-chain-dashboard">
      <h1>Cross-Chain Arbitrage Dashboard</h1>
      
      {/* Multi-Chain Dashboard */}
      <MultiChainDashboard
        chains={chains}
        crossChainArb={crossChainArb}
        bestChain={bestChain}
      />
      
      {/* Arbitrage Detector */}
      <ArbitrageDetector crossChainArb={crossChainArb} />
      
      {/* Chain Data Manager */}
      <ChainDataManager crossChainArb={crossChainArb} />
      
      {/* Opportunity Checker */}
      <CrossChainOpportunityChecker
        sentinelVault={sentinelVault}
        crossChainArb={crossChainArb}
      />
    </div>
  );
}
```

---

## 🎯 Key Functions to Implement

### 1. Get All Chain Data

```javascript
async function getAllChainData(crossChainArb) {
  const chains = await crossChainArb.getSupportedChains();
  const data = [];
  
  for (const chain of chains) {
    const [price, yield_, risk, score] = await Promise.all([
      crossChainArb.chainPrices(chain),
      crossChainArb.chainYields(chain),
      crossChainArb.chainRiskScores(chain),
      crossChainArb.getChainScore(chain)
    ]);
    
    data.push({
      name: chain,
      price: Number(price) / 1e18,
      yield: Number(yield_) / 1e18 * 100,
      risk: Number(risk),
      score: Number(score) / 1e18
    });
  }
  
  return data;
}
```

### 2. Simulate Chain Data (for Demo)

```javascript
async function simulateChainData(crossChainArb) {
  // Simulate price differences
  await crossChainArb.setChainPrice("Arc", ethers.parseUnits("1.000", 18));
  await crossChainArb.setChainPrice("Ethereum", ethers.parseUnits("0.999", 18));
  await crossChainArb.setChainPrice("Arbitrum", ethers.parseUnits("1.001", 18));
  await crossChainArb.setChainPrice("Base", ethers.parseUnits("0.998", 18));
  await crossChainArb.setChainPrice("Optimism", ethers.parseUnits("1.000", 18));
  
  // Simulate yield differences
  await crossChainArb.setChainYield("Arc", ethers.parseUnits("0.05", 18));      // 5%
  await crossChainArb.setChainYield("Ethereum", ethers.parseUnits("0.04", 18)); // 4%
  await crossChainArb.setChainYield("Arbitrum", ethers.parseUnits("0.07", 18));  // 7%
  await crossChainArb.setChainYield("Base", ethers.parseUnits("0.06", 18));     // 6%
  await crossChainArb.setChainYield("Optimism", ethers.parseUnits("0.05", 18));  // 5%
  
  // Simulate risk scores
  await crossChainArb.setChainRisk("Arc", 50);
  await crossChainArb.setChainRisk("Ethereum", 40);
  await crossChainArb.setChainRisk("Arbitrum", 60);
  await crossChainArb.setChainRisk("Base", 45);
  await crossChainArb.setChainRisk("Optimism", 55);
}
```

### 3. Check Arbitrage Between Chains

```javascript
async function checkArbitrage(crossChainArb, chainA, chainB, bridgeFeePercent = 0.1) {
  const bridgeFee = ethers.parseUnits((bridgeFeePercent / 100).toString(), 18);
  const [profitable, profit] = await crossChainArb.detectArbitrage(
    chainA,
    chainB,
    bridgeFee
  );
  
  return {
    profitable,
    profit: Number(profit) / 1e18,
    chainA,
    chainB,
    bridgeFee: bridgeFeePercent
  };
}
```

### 4. Get Best Chain

```javascript
async function getBestChain(crossChainArb) {
  const bestChain = await crossChainArb.bestChain();
  const score = await crossChainArb.getChainScore(bestChain);
  
  return {
    chain: bestChain,
    score: Number(score) / 1e18
  };
}
```

### 5. Trigger Cross-Chain Check

```javascript
async function triggerCrossChainCheck(sentinelVault) {
  const tx = await sentinelVault.checkForCrossChainOpportunities();
  await tx.wait();
  return tx.hash;
}
```

---

## 📊 Event Listening

### Listen for Cross-Chain Decisions

```javascript
sentinelVault.on("CrossChainDecision", (chain, price, timestamp, reason) => {
  console.log("Cross-chain decision made!");
  console.log("Chain:", chain);
  console.log("Price:", ethers.formatUnits(price, 18));
  console.log("Reason:", reason);
  
  // Update UI
  showNotification(`Cross-chain decision: ${chain} - ${reason}`);
});
```

### Listen for Chain Data Updates

```javascript
crossChainArb.on("ChainPriceUpdated", (chain, price, timestamp) => {
  console.log(`Price updated for ${chain}: $${ethers.formatUnits(price, 18)}`);
  // Refresh chain data in UI
});

crossChainArb.on("ChainYieldUpdated", (chain, yield_, timestamp) => {
  console.log(`Yield updated for ${chain}: ${ethers.formatUnits(yield_, 18) * 100}%`);
  // Refresh chain data in UI
});

crossChainArb.on("ChainRiskUpdated", (chain, riskScore, timestamp) => {
  console.log(`Risk updated for ${chain}: ${riskScore}`);
  // Refresh chain data in UI
});
```

### Listen for Cross-Chain Moves

```javascript
crossChainArb.on("CrossChainMove", (sourceChain, destChain, amount, timestamp) => {
  console.log(`Cross-chain move: ${amount} USDC from ${sourceChain} to ${destChain}`);
  // Show notification
  showNotification(`Moving ${ethers.formatUnits(amount, 6)} USDC to ${destChain}`);
});
```

---

## 🎨 UI/UX Recommendations

### Color Coding

- **Best Chain**: Green highlight
- **Profitable Arbitrage**: Green alert
- **No Arbitrage**: Gray/neutral
- **High Risk**: Red indicator
- **Low Risk**: Green indicator

### Real-Time Updates

- Poll chain data every 10-30 seconds
- Update best chain automatically
- Show live arbitrage opportunities
- Display decision log in real-time

### User Actions

1. **Set Chain Data** → Update prices/yields/risks
2. **Detect Arbitrage** → Check between two chains
3. **Check Opportunities** → Trigger cross-chain check
4. **View Dashboard** → See all chain data

---

## 🚀 Quick Start Checklist

- [ ] Import ABIs (SentinelVault, CrossChainArbitrage)
- [ ] Connect to contracts
- [ ] Build Multi-Chain Dashboard component
- [ ] Build Arbitrage Detector component
- [ ] Build Chain Data Manager component
- [ ] Build Cross-Chain Opportunity Checker
- [ ] Set up event listeners
- [ ] Add real-time updates
- [ ] Style with color coding
- [ ] Test with simulated data

---

## 💡 Demo Flow

1. **Initial Load**: Show all chains with default data
2. **User Sets Data**: Update prices/yields/risks for demo
3. **Show Best Chain**: Highlight optimal chain
4. **Detect Arbitrage**: Show opportunities
5. **Check Opportunities**: Trigger cross-chain check
6. **Show Decision**: Display cross-chain decision event
7. **Update UI**: Refresh with new data

---

## 📝 Important Notes

### Decimals
- **Prices**: 18 decimals (1e18 = $1.00)
- **Yields**: 18 decimals (0.05e18 = 5%)
- **Risks**: No decimals (0-100 integer)
- **USDC amounts**: 6 decimals (1e6 = 1 USDC)

### Gas Costs
- Setting chain data: ~50k gas per update
- Checking opportunities: ~100k gas
- Events are cheap

### Error Handling
- Check if contracts are connected
- Handle transaction failures gracefully
- Show user-friendly error messages

---

## 🎉 You're Ready!

Build a beautiful, functional cross-chain arbitrage dashboard that:
- Shows multi-chain data
- Detects arbitrage opportunities
- Triggers cross-chain checks
- Displays decisions in real-time

**Make it look professional and demo-ready!** 🚀

