# Frontend Integration Prompt - Enhanced Cross-Chain Features

## 🎯 Your Mission

Integrate the **Enhanced Cross-Chain Arbitrage** module into the ArcSentinel frontend. This adds intelligent cross-chain switching that respects user risk profiles, active chain tracking, and simulated cross-chain USDC movements.

---

## 🆕 What's New

### Latest Features (Just Added!)

1. **Active Chain Tracking**
   - Track which chain is currently active
   - Display current active chain in UI
   - Show chain switching history

2. **Smart Chain Switching**
   - `switchToBestChain()` - Automatically switch to optimal chain
   - Respects user risk profiles (Conservative/Balanced/Aggressive)
   - Automatically moves to SafePool if best chain price is risky

3. **Simulated Cross-Chain Bridging**
   - `simulateBridge()` - Simulate USDC movement between chains
   - Visualize cross-chain moves in real-time
   - No real bridging (demo-safe)

4. **Enhanced Events**
   - `CrossChainDecision` - Chain switching decisions with reasons
   - `CrossChainMove` - Simulated bridge movements (fromChain → toChain)

5. **Risk Profile Integration**
   - Cross-chain decisions respect user's risk tolerance
   - Automatically switches to SafePool when needed
   - Prevents risky chain switches

---

## 📍 Contract Addresses

### Network: Arc Testnet
- **Chain ID:** 5042002
- **RPC URL:** `https://rpc.testnet.arc.network`
- **Block Explorer:** https://testnet.arcscan.app

### Contracts

| Contract | Address | Purpose |
|----------|---------|---------|
| **SentinelVault** | `0xDf9053726a2217326bFEadc0c3480c5De7107B8f` | **Main contract - use this!** |
| **CrossChainArbitrage** | `0xfe9d856E1f3BA56C462DF56B27b8863f1ff700B9` | **Cross-chain features** |
| SafePool | `0xb90892b0143eb804037D582FE7678C636D47f0a5` | Internal |
| YieldPool | `0xC6D145006Cd18C7b22D584737A8909DdF3b839D5` | Internal |
| OracleFeed | `0xd8A5E7ACa9A2B61d223Ea993749B5F6576aa503f` | Read price |
| USDC | `0x3600000000000000000000000000000000000000` | Token |

---

## 🔌 Setup

### Install Dependencies

```bash
npm install ethers
# or
yarn add ethers
```

### Import ABIs

```javascript
import SentinelVaultABI from './abi/SentinelVault.json';
import CrossChainArbitrageABI from './abi/CrossChainArbitrage.json';
import IERC20ABI from './abi/IERC20.json';
```

### Connect Contracts

```javascript
import { ethers } from 'ethers';

// Connect wallet
const provider = new ethers.BrowserProvider(window.ethereum);
const signer = await provider.getSigner();

// Contract addresses
const SENTINEL_VAULT = "0xDf9053726a2217326bFEadc0c3480c5De7107B8f";
const CROSS_CHAIN_ARB = "0xfe9d856E1f3BA56C462DF56B27b8863f1ff700B9";

// Connect to contracts
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

### 1. Active Chain Display Component

**Purpose:** Show the currently active chain and allow manual switching

```javascript
function ActiveChainDisplay({ crossChainArb, sentinelVault }) {
  const [activeChain, setActiveChain] = useState(null);
  const [bestChain, setBestChain] = useState(null);
  const [isSwitching, setIsSwitching] = useState(false);

  useEffect(() => {
    loadActiveChain();
    loadBestChain();
    
    // Listen for chain switching events
    crossChainArb.on("CrossChainDecision", (newChain, timestamp, reason) => {
      setActiveChain(newChain);
      loadBestChain();
    });
    
    return () => {
      crossChainArb.removeAllListeners("CrossChainDecision");
    };
  }, []);

  const loadActiveChain = async () => {
    const chain = await crossChainArb.activeChain();
    setActiveChain(chain);
  };

  const loadBestChain = async () => {
    const chain = await crossChainArb.bestChain();
    setBestChain(chain);
  };

  const switchToBestChain = async () => {
    setIsSwitching(true);
    try {
      const tx = await sentinelVault.triggerBestChainSwitch();
      await tx.wait();
      await loadActiveChain();
      alert(`Switched to best chain: ${bestChain}`);
    } catch (error) {
      console.error("Error switching chain:", error);
      alert("Failed to switch chain");
    } finally {
      setIsSwitching(false);
    }
  };

  return (
    <div className="active-chain-card">
      <h3>Active Chain</h3>
      <div className="chain-display">
        <div className="current-chain">
          <span className="label">Current:</span>
          <span className="chain-name">{activeChain || "Loading..."}</span>
        </div>
        <div className="best-chain">
          <span className="label">Best Chain:</span>
          <span className="chain-name">{bestChain || "Loading..."}</span>
        </div>
      </div>
      
      {activeChain !== bestChain && (
        <button 
          onClick={switchToBestChain} 
          disabled={isSwitching}
          className="switch-button"
        >
          {isSwitching ? "Switching..." : `Switch to ${bestChain}`}
        </button>
      )}
      
      {activeChain === bestChain && (
        <div className="status-badge optimal">
          ✓ Optimal Chain Selected
        </div>
      )}
    </div>
  );
}
```

### 2. Cross-Chain Decision Log Component

**Purpose:** Display all cross-chain decisions with reasons

```javascript
function CrossChainDecisionLog({ sentinelVault }) {
  const [decisions, setDecisions] = useState([]);

  useEffect(() => {
    // Listen for cross-chain decisions
    const handler = (selectedChain, price, timestamp, reason) => {
      setDecisions(prev => [{
        chain: selectedChain,
        price: Number(price) / 1e18,
        timestamp: new Date(Number(timestamp) * 1000),
        reason: reason,
        id: Date.now()
      }, ...prev]);
    };

    sentinelVault.on("CrossChainDecision", handler);
    
    return () => {
      sentinelVault.removeAllListeners("CrossChainDecision");
    };
  }, []);

  const getReasonColor = (reason) => {
    if (reason.includes("too risky")) return "red";
    if (reason.includes("Defensive")) return "orange";
    if (reason.includes("optimal")) return "green";
    return "blue";
  };

  return (
    <div className="decision-log">
      <h3>Cross-Chain Decisions</h3>
      <div className="decisions-list">
        {decisions.length === 0 ? (
          <p className="empty-state">No decisions yet</p>
        ) : (
          decisions.map(decision => (
            <div 
              key={decision.id} 
              className={`decision-item ${getReasonColor(decision.reason)}`}
            >
              <div className="decision-header">
                <span className="chain-name">{decision.chain}</span>
                <span className="timestamp">
                  {decision.timestamp.toLocaleTimeString()}
                </span>
              </div>
              <div className="decision-details">
                <p className="reason">{decision.reason}</p>
                <p className="price">
                  Price: ${decision.price.toFixed(6)}
                </p>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
```

### 3. Cross-Chain Move Visualizer Component

**Purpose:** Show simulated cross-chain USDC movements

```javascript
function CrossChainMoveVisualizer({ crossChainArb }) {
  const [moves, setMoves] = useState([]);

  useEffect(() => {
    // Listen for cross-chain moves
    const handler = (fromChain, toChain, amount, timestamp) => {
      setMoves(prev => [{
        from: fromChain,
        to: toChain,
        amount: ethers.formatUnits(amount, 6), // USDC has 6 decimals
        timestamp: new Date(Number(timestamp) * 1000),
        id: Date.now()
      }, ...prev]);
    };

    crossChainArb.on("CrossChainMove", handler);
    
    return () => {
      crossChainArb.removeAllListeners("CrossChainMove");
    };
  }, []);

  return (
    <div className="move-visualizer">
      <h3>Cross-Chain Movements</h3>
      <div className="moves-list">
        {moves.length === 0 ? (
          <p className="empty-state">No movements yet</p>
        ) : (
          moves.map(move => (
            <div key={move.id} className="move-item">
              <div className="move-arrow">
                <span className="from-chain">{move.from}</span>
                <span className="arrow">→</span>
                <span className="to-chain">{move.to}</span>
              </div>
              <div className="move-details">
                <span className="amount">{move.amount} USDC</span>
                <span className="timestamp">
                  {move.timestamp.toLocaleTimeString()}
                </span>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
```

### 4. Smart Cross-Chain Opportunity Checker

**Purpose:** Check for opportunities with risk profile integration

```javascript
function SmartCrossChainChecker({ sentinelVault, crossChainArb }) {
  const [isChecking, setIsChecking] = useState(false);
  const [lastDecision, setLastDecision] = useState(null);

  useEffect(() => {
    // Listen for decisions
    const handler = (selectedChain, price, timestamp, reason) => {
      setLastDecision({
        chain: selectedChain,
        price: Number(price) / 1e18,
        reason: reason,
        timestamp: new Date(Number(timestamp) * 1000)
      });
    };

    sentinelVault.on("CrossChainDecision", handler);
    
    return () => {
      sentinelVault.removeAllListeners("CrossChainDecision");
    };
  }, []);

  const checkOpportunities = async () => {
    setIsChecking(true);
    try {
      const tx = await sentinelVault.checkForCrossChainOpportunities();
      await tx.wait();
      alert("Cross-chain check completed! Check the decision log.");
    } catch (error) {
      console.error("Error checking opportunities:", error);
      alert("Failed to check opportunities: " + error.message);
    } finally {
      setIsChecking(false);
    }
  };

  return (
    <div className="opportunity-checker">
      <h3>Smart Cross-Chain Check</h3>
      <p className="description">
        Checks for cross-chain opportunities while respecting your risk profile.
        Automatically switches to SafePool if best chain price is too risky.
      </p>
      
      <button 
        onClick={checkOpportunities} 
        disabled={isChecking}
        className="check-button"
      >
        {isChecking ? "Checking..." : "Check Cross-Chain Opportunities"}
      </button>

      {lastDecision && (
        <div className="last-decision">
          <h4>Last Decision:</h4>
          <p><strong>Chain:</strong> {lastDecision.chain}</p>
          <p><strong>Price:</strong> ${lastDecision.price.toFixed(6)}</p>
          <p><strong>Reason:</strong> {lastDecision.reason}</p>
        </div>
      )}
    </div>
  );
}
```

### 5. Simulated Bridge Component

**Purpose:** Manually simulate cross-chain USDC movements

```javascript
function SimulatedBridge({ crossChainArb }) {
  const [toChain, setToChain] = useState("");
  const [amount, setAmount] = useState("");
  const [isBridging, setIsBridging] = useState(false);
  const [activeChain, setActiveChain] = useState(null);
  const [supportedChains, setSupportedChains] = useState([]);

  useEffect(() => {
    loadActiveChain();
    loadSupportedChains();
    
    // Listen for chain switches
    crossChainArb.on("CrossChainMove", () => {
      loadActiveChain();
    });
    
    return () => {
      crossChainArb.removeAllListeners("CrossChainMove");
    };
  }, []);

  const loadActiveChain = async () => {
    const chain = await crossChainArb.activeChain();
    setActiveChain(chain);
  };

  const loadSupportedChains = async () => {
    const chains = await crossChainArb.getSupportedChains();
    setSupportedChains(chains);
  };

  const simulateBridge = async () => {
    if (!toChain || !amount) {
      alert("Please select a chain and enter an amount");
      return;
    }

    setIsBridging(true);
    try {
      const amountWei = ethers.parseUnits(amount, 6); // USDC has 6 decimals
      const tx = await crossChainArb.simulateBridge(toChain, amountWei);
      await tx.wait();
      alert(`Simulated bridge: ${amount} USDC to ${toChain}`);
      setAmount("");
    } catch (error) {
      console.error("Error bridging:", error);
      alert("Failed to simulate bridge: " + error.message);
    } finally {
      setIsBridging(false);
    }
  };

  return (
    <div className="simulated-bridge">
      <h3>Simulate Cross-Chain Bridge</h3>
      <p className="description">
        Simulate moving USDC to another chain (demo only - no real bridging)
      </p>
      
      <div className="bridge-form">
        <div className="form-group">
          <label>From Chain (Current):</label>
          <input 
            type="text" 
            value={activeChain || ""} 
            disabled 
            className="current-chain"
          />
        </div>
        
        <div className="form-group">
          <label>To Chain:</label>
          <select 
            value={toChain} 
            onChange={(e) => setToChain(e.target.value)}
            disabled={isBridging}
          >
            <option value="">Select chain...</option>
            {supportedChains
              .filter(chain => chain !== activeChain)
              .map(chain => (
                <option key={chain} value={chain}>
                  {chain}
                </option>
              ))}
          </select>
        </div>
        
        <div className="form-group">
          <label>Amount (USDC):</label>
          <input
            type="number"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="100"
            disabled={isBridging}
          />
        </div>
        
        <button 
          onClick={simulateBridge} 
          disabled={isBridging || !toChain || !amount}
          className="bridge-button"
        >
          {isBridging ? "Bridging..." : "Simulate Bridge"}
        </button>
      </div>
    </div>
  );
}
```

### 6. Complete Dashboard Integration

```javascript
import { useState, useEffect } from 'react';
import { ethers } from 'ethers';

function CrossChainDashboard() {
  const [sentinelVault, setSentinelVault] = useState(null);
  const [crossChainArb, setCrossChainArb] = useState(null);
  const [isConnected, setIsConnected] = useState(false);

  useEffect(() => {
    connectContracts();
  }, []);

  const connectContracts = async () => {
    if (window.ethereum) {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      
      const vault = new ethers.Contract(
        "0xDf9053726a2217326bFEadc0c3480c5De7107B8f",
        SentinelVaultABI,
        signer
      );
      
      const arb = new ethers.Contract(
        "0xfe9d856E1f3BA56C462DF56B27b8863f1ff700B9",
        CrossChainArbitrageABI,
        signer
      );
      
      setSentinelVault(vault);
      setCrossChainArb(arb);
      setIsConnected(true);
    }
  };

  if (!isConnected) {
    return <div>Connecting to contracts...</div>;
  }

  return (
    <div className="cross-chain-dashboard">
      <h1>Cross-Chain Arbitrage Dashboard</h1>
      
      <div className="dashboard-grid">
        {/* Active Chain Display */}
        <ActiveChainDisplay 
          crossChainArb={crossChainArb}
          sentinelVault={sentinelVault}
        />
        
        {/* Smart Opportunity Checker */}
        <SmartCrossChainChecker 
          sentinelVault={sentinelVault}
          crossChainArb={crossChainArb}
        />
        
        {/* Simulated Bridge */}
        <SimulatedBridge crossChainArb={crossChainArb} />
        
        {/* Decision Log */}
        <CrossChainDecisionLog sentinelVault={sentinelVault} />
        
        {/* Move Visualizer */}
        <CrossChainMoveVisualizer crossChainArb={crossChainArb} />
      </div>
    </div>
  );
}
```

---

## 📡 Event Listening Guide

### CrossChainDecision Event

**Emitted by:** `SentinelVault`

**Parameters:**
- `selectedChain` (string) - The chain selected
- `price` (uint256) - Price at time of decision (18 decimals)
- `timestamp` (uint256) - Block timestamp
- `reason` (string) - Reason for the decision

**Example Reasons:**
- "Switching active chain to best chain"
- "Best chain price too risky for user profile - staying on current chain"
- "Switching to best chain (Defensive mode due to price risk)"
- "Cross-chain arbitrage opportunity detected - switching to best chain"
- "Arc is the optimal chain"

**Code:**
```javascript
sentinelVault.on("CrossChainDecision", (selectedChain, price, timestamp, reason) => {
  console.log("Decision:", {
    chain: selectedChain,
    price: Number(price) / 1e18,
    timestamp: new Date(Number(timestamp) * 1000),
    reason: reason
  });
});
```

### CrossChainMove Event

**Emitted by:** `CrossChainArbitrage`

**Parameters:**
- `fromChain` (string) - Source chain
- `toChain` (string) - Destination chain
- `amount` (uint256) - Amount moved (USDC, 6 decimals)
- `timestamp` (uint256) - Block timestamp

**Code:**
```javascript
crossChainArb.on("CrossChainMove", (fromChain, toChain, amount, timestamp) => {
  console.log("Cross-chain move:", {
    from: fromChain,
    to: toChain,
    amount: ethers.formatUnits(amount, 6),
    timestamp: new Date(Number(timestamp) * 1000)
  });
});
```

### CrossChainDecision Event (from Arbitrage Module)

**Emitted by:** `CrossChainArbitrage` (when `switchToBestChain()` is called)

**Parameters:**
- `newChain` (string) - The new active chain
- `timestamp` (uint256) - Block timestamp
- `reason` (string) - Always "Switching active chain to best chain"

**Code:**
```javascript
crossChainArb.on("CrossChainDecision", (newChain, timestamp, reason) => {
  console.log("Chain switched:", newChain);
  // Update active chain display
});
```

---

## 🔑 Key Functions Reference

### SentinelVault Functions

#### `checkForCrossChainOpportunities()`
- **Purpose:** Check for cross-chain opportunities with risk profile integration
- **Returns:** Transaction receipt
- **Behavior:**
  - Checks best chain price against user's risk thresholds
  - Automatically switches to SafePool if price is risky
  - Switches to best chain if price is acceptable
  - Emits `CrossChainDecision` event

```javascript
const tx = await sentinelVault.checkForCrossChainOpportunities();
await tx.wait();
```

#### `triggerBestChainSwitch()`
- **Purpose:** Manually trigger switch to best chain
- **Returns:** Transaction receipt
- **Behavior:**
  - Calls `switchToBestChain()` on arbitrage module
  - Updates `activeChain`
  - Emits `CrossChainDecision` event

```javascript
const tx = await sentinelVault.triggerBestChainSwitch();
await tx.wait();
```

### CrossChainArbitrage Functions

#### `activeChain()`
- **Purpose:** Get current active chain
- **Returns:** `string` - Current active chain name
- **View function** (no gas)

```javascript
const activeChain = await crossChainArb.activeChain();
console.log("Active chain:", activeChain);
```

#### `bestChain()`
- **Purpose:** Get best chain based on scoring
- **Returns:** `string` - Best chain name
- **View function** (no gas)

```javascript
const bestChain = await crossChainArb.bestChain();
console.log("Best chain:", bestChain);
```

#### `switchToBestChain()`
- **Purpose:** Switch active chain to best chain
- **Returns:** Transaction receipt
- **Gas cost:** ~50k gas
- **Behavior:**
  - Updates `activeChain` to best chain
  - Emits `CrossChainDecision` event

```javascript
const tx = await crossChainArb.switchToBestChain();
await tx.wait();
```

#### `simulateBridge(string toChain, uint256 amount)`
- **Purpose:** Simulate cross-chain USDC movement
- **Parameters:**
  - `toChain` - Target chain name (must be supported)
  - `amount` - Amount in USDC (6 decimals)
- **Returns:** Transaction receipt
- **Gas cost:** ~60k gas
- **Behavior:**
  - Updates `activeChain` to `toChain`
  - Emits `CrossChainMove` event
  - **No real bridging** (demo only)

```javascript
const amount = ethers.parseUnits("100", 6); // 100 USDC
const tx = await crossChainArb.simulateBridge("Ethereum", amount);
await tx.wait();
```

---

## 🎨 UI/UX Recommendations

### Color Coding

- **Active Chain:** Blue highlight
- **Best Chain:** Green highlight
- **Risky Decision:** Red alert
- **Defensive Mode:** Orange indicator
- **Safe Decision:** Green indicator
- **Optimal Chain:** Green badge

### Real-Time Updates

1. **Poll active chain** every 5-10 seconds
2. **Poll best chain** every 10-30 seconds
3. **Listen to events** for instant updates
4. **Show notifications** for chain switches

### User Flow

1. **Initial Load:**
   - Show active chain
   - Show best chain
   - Display decision log (empty)

2. **User Checks Opportunities:**
   - Click "Check Cross-Chain Opportunities"
   - Show loading state
   - Display decision in log
   - Update active chain if switched

3. **User Simulates Bridge:**
   - Select target chain
   - Enter amount
   - Click "Simulate Bridge"
   - Show movement in visualizer
   - Update active chain

4. **Automatic Updates:**
   - Listen for events
   - Update UI automatically
   - Show notifications

---

## 📊 Data Format Reference

### Decimals

- **Prices:** 18 decimals (1e18 = $1.00)
  ```javascript
  const price = await crossChainArb.chainPrices("Ethereum");
  const priceFormatted = Number(price) / 1e18; // 0.999
  ```

- **Yields:** 18 decimals (0.05e18 = 5%)
  ```javascript
  const yield = await crossChainArb.chainYields("Arbitrum");
  const yieldPercent = Number(yield) / 1e18 * 100; // 5%
  ```

- **Risks:** No decimals (0-100 integer)
  ```javascript
  const risk = await crossChainArb.chainRiskScores("Base");
  const riskNumber = Number(risk); // 30
  ```

- **USDC Amounts:** 6 decimals (1e6 = 1 USDC)
  ```javascript
  const amount = ethers.parseUnits("100", 6); // 100 USDC
  const formatted = ethers.formatUnits(amount, 6); // "100.0"
  ```

### Chain Names

Supported chains (case-sensitive):
- `"Arc"`
- `"Ethereum"`
- `"Arbitrum"`
- `"Base"`
- `"Optimism"`

---

## 🚀 Quick Start Checklist

- [ ] Import ABIs (SentinelVault, CrossChainArbitrage)
- [ ] Connect to contracts
- [ ] Build Active Chain Display component
- [ ] Build Cross-Chain Decision Log component
- [ ] Build Cross-Chain Move Visualizer component
- [ ] Build Smart Cross-Chain Checker component
- [ ] Build Simulated Bridge component
- [ ] Set up event listeners
- [ ] Add real-time polling
- [ ] Style with color coding
- [ ] Test with simulated data
- [ ] Add error handling
- [ ] Add loading states

---

## 💡 Demo Flow

1. **Initial State:**
   - Active chain: "Arc"
   - Best chain: "Ethereum" (example)
   - Show "Switch to Ethereum" button

2. **User Clicks "Check Opportunities":**
   - Function checks best chain price
   - If price is safe: switches to Ethereum, moves to YieldPool
   - If price is risky: stays on Arc, moves to SafePool
   - Event emitted with decision

3. **User Simulates Bridge:**
   - Selects "Arbitrum" as target
   - Enters 100 USDC
   - Clicks "Simulate Bridge"
   - Event emitted: CrossChainMove(Arc → Arbitrum, 100 USDC)
   - Active chain updates to "Arbitrum"

4. **Automatic Updates:**
   - Events trigger UI updates
   - Decision log shows all decisions
   - Move visualizer shows all movements

---

## ⚠️ Important Notes

### Simulation Only
- **No real bridging** - All moves are simulated
- **No actual USDC movement** - Only events emitted
- **Demo-safe** - Perfect for hackathon presentation

### Risk Profile Integration
- Cross-chain decisions **automatically respect** user's risk profile
- Conservative users: Won't switch to risky chains
- Aggressive users: More willing to switch
- **Always protects users** by moving to SafePool when needed

### Gas Costs
- `checkForCrossChainOpportunities()`: ~150k gas
- `switchToBestChain()`: ~50k gas
- `simulateBridge()`: ~60k gas
- View functions: Free (no gas)

### Error Handling
Always wrap contract calls in try-catch:
```javascript
try {
  const tx = await sentinelVault.checkForCrossChainOpportunities();
  await tx.wait();
} catch (error) {
  console.error("Error:", error);
  // Show user-friendly error message
}
```

---

## 🎯 Key Features Summary

✅ **Active Chain Tracking** - Know which chain is active  
✅ **Smart Switching** - Respects risk profiles  
✅ **Simulated Bridging** - Visualize cross-chain moves  
✅ **Event-Driven** - Real-time updates via events  
✅ **Risk-Aware** - Automatically protects users  
✅ **Demo-Safe** - No real funds moved  

---

## 📝 Example Integration

```javascript
// Complete example
import { ethers } from 'ethers';
import { useState, useEffect } from 'react';

function useCrossChain(signer) {
  const [activeChain, setActiveChain] = useState(null);
  const [bestChain, setBestChain] = useState(null);
  const [decisions, setDecisions] = useState([]);
  const [moves, setMoves] = useState([]);

  useEffect(() => {
    if (!signer) return;

    const vault = new ethers.Contract(
      "0xDf9053726a2217326bFEadc0c3480c5De7107B8f",
      SentinelVaultABI,
      signer
    );

    const arb = new ethers.Contract(
      "0xfe9d856E1f3BA56C462DF56B27b8863f1ff700B9",
      CrossChainArbitrageABI,
      signer
    );

    // Load initial data
    const loadData = async () => {
      setActiveChain(await arb.activeChain());
      setBestChain(await arb.bestChain());
    };
    loadData();

    // Listen for decisions
    vault.on("CrossChainDecision", (chain, price, timestamp, reason) => {
      setDecisions(prev => [{
        chain, price: Number(price) / 1e18,
        timestamp: new Date(Number(timestamp) * 1000),
        reason
      }, ...prev]);
    });

    // Listen for moves
    arb.on("CrossChainMove", (from, to, amount, timestamp) => {
      setMoves(prev => [{
        from, to,
        amount: ethers.formatUnits(amount, 6),
        timestamp: new Date(Number(timestamp) * 1000)
      }, ...prev]);
      setActiveChain(to); // Update active chain
    });

    return () => {
      vault.removeAllListeners();
      arb.removeAllListeners();
    };
  }, [signer]);

  return { activeChain, bestChain, decisions, moves };
}
```

---

**Ready to build? Start with the Active Chain Display component and work your way through the checklist!** 🚀

