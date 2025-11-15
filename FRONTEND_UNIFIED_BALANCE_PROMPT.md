# Frontend Integration Prompt - Unified Balance Feature

## 🎯 Your Mission

Add a **"Unified Balance"** feature to the ArcSentinel dashboard that displays the total vault balance across all chains as a single, prominent number at the top of the dashboard - similar to Circle's "Unified USDC Balance" design.

---

## 🆕 What's New

### Unified Balance Feature

The `getUnifiedVaultBalance()` function returns the sum of all vault balances across all supported chains (Arc, Ethereum, Arbitrum, Base, Optimism) as a single number.

**Key Benefits:**
- ✅ Single number showing total balance across all chains
- ✅ View function (free to call, no gas)
- ✅ Real-time updates
- ✅ Clean, Circle-inspired design

---

## 📍 Contract Address

**SentinelVault:** `0xDf9053726a2217326bFEadc0c3480c5De7107B8f`

**Function:**
```solidity
function getUnifiedVaultBalance() external view returns (uint256)
```

**Returns:** Total balance across all chains (USDC, 6 decimals)

---

## 🎨 Design Inspiration: Circle's Unified Balance

Circle's design features:
- **Large, prominent number** at the top
- **Clean typography** with clear hierarchy
- **"Unified USDC Balance" label**
- **Real-time updates**
- **Minimal, elegant styling**

---

## 🔌 Setup

### Import ABI

```javascript
import SentinelVaultABI from './abi/SentinelVault.json';
```

### Connect Contract

```javascript
import { ethers } from 'ethers';

const SENTINEL_VAULT = "0xDf9053726a2217326bFEadc0c3480c5De7107B8f";

const provider = new ethers.BrowserProvider(window.ethereum);
const signer = await provider.getSigner();

const sentinelVault = new ethers.Contract(
  SENTINEL_VAULT,
  SentinelVaultABI,
  signer
);
```

---

## 🎨 UI Component: Unified Balance Display

### Component Structure

```javascript
import { useState, useEffect } from 'react';
import { ethers } from 'ethers';

function UnifiedBalanceDisplay({ sentinelVault, userAddress }) {
  const [unifiedBalance, setUnifiedBalance] = useState(null);
  const [walletBalance, setWalletBalance] = useState(null);
  const [totalBalance, setTotalBalance] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [activeChain, setActiveChain] = useState(null);

  useEffect(() => {
    if (sentinelVault && userAddress) {
      loadUnifiedBalance();
      loadWalletBalance();
      
      // Poll for updates every 5 seconds
      const interval = setInterval(() => {
        loadUnifiedBalance();
        loadWalletBalance();
      }, 5000);

      return () => clearInterval(interval);
    }
  }, [sentinelVault, userAddress]);

  const loadUnifiedBalance = async () => {
    try {
      const balance = await sentinelVault.getUnifiedVaultBalance();
      const formatted = ethers.formatUnits(balance, 6); // USDC has 6 decimals
      setUnifiedBalance(formatted);
    } catch (error) {
      console.error("Error loading unified balance:", error);
    }
  };

  const loadWalletBalance = async () => {
    try {
      // Get USDC contract (you'll need the USDC address)
      const USDC_ADDRESS = "0x3600000000000000000000000000000000000000";
      const usdc = new ethers.Contract(
        USDC_ADDRESS,
        IERC20ABI,
        signer
      );
      const balance = await usdc.balanceOf(userAddress);
      const formatted = ethers.formatUnits(balance, 6);
      setWalletBalance(formatted);
      
      // Calculate total (vault + wallet on active chain)
      if (unifiedBalance !== null) {
        const total = parseFloat(unifiedBalance) + parseFloat(formatted);
        setTotalBalance(total.toFixed(2));
      }
    } catch (error) {
      console.error("Error loading wallet balance:", error);
    } finally {
      setIsLoading(false);
    }
  };

  if (isLoading) {
    return (
      <div className="unified-balance-loading">
        <div className="loading-spinner"></div>
        <p>Loading balance...</p>
      </div>
    );
  }

  return (
    <div className="unified-balance-container">
      {/* Main Unified Balance Display */}
      <div className="unified-balance-card">
        <div className="balance-header">
          <h2 className="balance-label">Unified USDC Balance</h2>
          <span className="balance-subtitle">Across all chains</span>
        </div>
        
        <div className="balance-amount">
          <span className="balance-value">
            {totalBalance !== null 
              ? `$${parseFloat(totalBalance).toLocaleString('en-US', { 
                  minimumFractionDigits: 2, 
                  maximumFractionDigits: 2 
                })}`
              : unifiedBalance !== null
              ? `$${parseFloat(unifiedBalance).toLocaleString('en-US', { 
                  minimumFractionDigits: 2, 
                  maximumFractionDigits: 2 
                })}`
              : '$0.00'
            }
          </span>
        </div>

        {/* Breakdown */}
        <div className="balance-breakdown">
          <div className="breakdown-item">
            <span className="breakdown-label">Vault Balance</span>
            <span className="breakdown-value">
              ${unifiedBalance !== null 
                ? parseFloat(unifiedBalance).toLocaleString('en-US', { 
                    minimumFractionDigits: 2, 
                    maximumFractionDigits: 2 
                  })
                : '0.00'
              }
            </span>
          </div>
          
          {walletBalance !== null && (
            <div className="breakdown-item">
              <span className="breakdown-label">Wallet Balance ({activeChain || 'Arc'})</span>
              <span className="breakdown-value">
                ${parseFloat(walletBalance).toLocaleString('en-US', { 
                  minimumFractionDigits: 2, 
                  maximumFractionDigits: 2 
                })}
              </span>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
```

---

## 🎨 CSS Styling (Circle-Inspired)

```css
.unified-balance-container {
  width: 100%;
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem 1rem;
}

.unified-balance-card {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 16px;
  padding: 3rem 2rem;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
  color: white;
  text-align: center;
}

.balance-header {
  margin-bottom: 1.5rem;
}

.balance-label {
  font-size: 1.25rem;
  font-weight: 500;
  margin: 0;
  opacity: 0.9;
  letter-spacing: 0.5px;
}

.balance-subtitle {
  font-size: 0.875rem;
  opacity: 0.8;
  display: block;
  margin-top: 0.5rem;
}

.balance-amount {
  margin: 2rem 0;
}

.balance-value {
  font-size: 4rem;
  font-weight: 700;
  line-height: 1;
  letter-spacing: -2px;
  display: block;
}

.balance-breakdown {
  display: flex;
  justify-content: center;
  gap: 3rem;
  margin-top: 2rem;
  padding-top: 2rem;
  border-top: 1px solid rgba(255, 255, 255, 0.2);
}

.breakdown-item {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.breakdown-label {
  font-size: 0.875rem;
  opacity: 0.8;
  text-transform: uppercase;
  letter-spacing: 1px;
}

.breakdown-value {
  font-size: 1.5rem;
  font-weight: 600;
}

/* Loading State */
.unified-balance-loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 4rem 2rem;
  gap: 1rem;
}

.loading-spinner {
  width: 40px;
  height: 40px;
  border: 4px solid rgba(102, 126, 234, 0.2);
  border-top-color: #667eea;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* Responsive Design */
@media (max-width: 768px) {
  .balance-value {
    font-size: 2.5rem;
  }
  
  .balance-breakdown {
    flex-direction: column;
    gap: 1.5rem;
  }
  
  .unified-balance-card {
    padding: 2rem 1.5rem;
  }
}
```

---

## 🔄 Real-Time Updates

### Option 1: Polling (Recommended)

```javascript
useEffect(() => {
  if (sentinelVault) {
    // Load immediately
    loadUnifiedBalance();
    
    // Poll every 5 seconds
    const interval = setInterval(() => {
      loadUnifiedBalance();
    }, 5000);
    
    return () => clearInterval(interval);
  }
}, [sentinelVault]);
```

### Option 2: Event Listeners

```javascript
useEffect(() => {
  if (!sentinelVault) return;

  // Listen for deposit/withdraw events
  const depositHandler = () => {
    loadUnifiedBalance();
  };
  
  const withdrawHandler = () => {
    loadUnifiedBalance();
  };

  sentinelVault.on("Deposited", depositHandler);
  sentinelVault.on("Withdrawn", withdrawHandler);
  
  // Listen for cross-chain moves
  const crossChainHandler = () => {
    loadUnifiedBalance();
  };
  
  // If you have access to crossChainArb contract
  if (crossChainArb) {
    crossChainArb.on("CrossChainMove", crossChainHandler);
  }

  return () => {
    sentinelVault.removeAllListeners("Deposited");
    sentinelVault.removeAllListeners("Withdrawn");
    if (crossChainArb) {
      crossChainArb.removeAllListeners("CrossChainMove");
    }
  };
}, [sentinelVault, crossChainArb]);
```

---

## 📊 Complete Integration Example

```javascript
import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import SentinelVaultABI from './abi/SentinelVault.json';
import IERC20ABI from './abi/IERC20.json';

const SENTINEL_VAULT = "0xDf9053726a2217326bFEadc0c3480c5De7107B8f";
const USDC_ADDRESS = "0x3600000000000000000000000000000000000000";

function Dashboard({ provider, signer, userAddress }) {
  const [sentinelVault, setSentinelVault] = useState(null);
  const [unifiedBalance, setUnifiedBalance] = useState(null);
  const [walletBalance, setWalletBalance] = useState(null);

  useEffect(() => {
    if (signer) {
      const vault = new ethers.Contract(
        SENTINEL_VAULT,
        SentinelVaultABI,
        signer
      );
      setSentinelVault(vault);
    }
  }, [signer]);

  useEffect(() => {
    if (sentinelVault && userAddress) {
      loadBalances();
      
      // Poll every 5 seconds
      const interval = setInterval(loadBalances, 5000);
      
      // Listen for events
      sentinelVault.on("Deposited", loadBalances);
      sentinelVault.on("Withdrawn", loadBalances);
      
      return () => {
        clearInterval(interval);
        sentinelVault.removeAllListeners("Deposited");
        sentinelVault.removeAllListeners("Withdrawn");
      };
    }
  }, [sentinelVault, userAddress]);

  const loadBalances = async () => {
    try {
      // Load unified vault balance
      const vaultBalance = await sentinelVault.getUnifiedVaultBalance();
      setUnifiedBalance(ethers.formatUnits(vaultBalance, 6));
      
      // Load wallet balance
      const usdc = new ethers.Contract(USDC_ADDRESS, IERC20ABI, signer);
      const walletBal = await usdc.balanceOf(userAddress);
      setWalletBalance(ethers.formatUnits(walletBal, 6));
    } catch (error) {
      console.error("Error loading balances:", error);
    }
  };

  const totalBalance = unifiedBalance && walletBalance
    ? (parseFloat(unifiedBalance) + parseFloat(walletBalance)).toFixed(2)
    : null;

  return (
    <div className="dashboard">
      {/* Unified Balance at Top */}
      <UnifiedBalanceDisplay
        unifiedBalance={unifiedBalance}
        walletBalance={walletBalance}
        totalBalance={totalBalance}
      />
      
      {/* Rest of dashboard */}
      <div className="dashboard-content">
        {/* Other components */}
      </div>
    </div>
  );
}

function UnifiedBalanceDisplay({ unifiedBalance, walletBalance, totalBalance }) {
  return (
    <div className="unified-balance-container">
      <div className="unified-balance-card">
        <div className="balance-header">
          <h2 className="balance-label">Unified USDC Balance</h2>
          <span className="balance-subtitle">Across all chains</span>
        </div>
        
        <div className="balance-amount">
          <span className="balance-value">
            {totalBalance 
              ? `$${parseFloat(totalBalance).toLocaleString('en-US', { 
                  minimumFractionDigits: 2, 
                  maximumFractionDigits: 2 
                })}`
              : '$0.00'
            }
          </span>
        </div>

        <div className="balance-breakdown">
          <div className="breakdown-item">
            <span className="breakdown-label">Vault Balance</span>
            <span className="breakdown-value">
              ${unifiedBalance 
                ? parseFloat(unifiedBalance).toLocaleString('en-US', { 
                    minimumFractionDigits: 2, 
                    maximumFractionDigits: 2 
                  })
                : '0.00'
              }
            </span>
          </div>
          
          {walletBalance && (
            <div className="breakdown-item">
              <span className="breakdown-label">Wallet Balance</span>
              <span className="breakdown-value">
                ${parseFloat(walletBalance).toLocaleString('en-US', { 
                  minimumFractionDigits: 2, 
                  maximumFractionDigits: 2 
                })}
              </span>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
```

---

## 🎯 Key Features to Implement

### 1. Prominent Display
- ✅ Large, readable number (4rem+ font size)
- ✅ Positioned at the very top of the dashboard
- ✅ Full-width card with gradient background
- ✅ Clear hierarchy (label → value → breakdown)

### 2. Breakdown View
- ✅ Show vault balance separately
- ✅ Show wallet balance on active chain
- ✅ Total = Vault + Wallet (on active chain)

### 3. Real-Time Updates
- ✅ Poll every 5 seconds
- ✅ Listen to deposit/withdraw events
- ✅ Listen to cross-chain move events
- ✅ Smooth loading states

### 4. Formatting
- ✅ Always show 2 decimal places
- ✅ Use thousand separators (commas)
- ✅ Format as currency ($ prefix)
- ✅ Handle null/loading states gracefully

---

## 📝 Function Reference

### `getUnifiedVaultBalance()`

**Contract:** SentinelVault  
**Type:** View function (no gas cost)  
**Returns:** `uint256` - Total balance in USDC (6 decimals)

**Usage:**
```javascript
const balance = await sentinelVault.getUnifiedVaultBalance();
const formatted = ethers.formatUnits(balance, 6); // Convert to readable format
console.log(`Unified Balance: $${formatted}`);
```

**Decimals:** USDC uses 6 decimals
- `1e6` = 1 USDC
- `1000000` = 1.0 USDC
- Always use `ethers.formatUnits(balance, 6)` to format

---

## 🎨 Design Variations

### Minimal Design
```css
.unified-balance-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  padding: 2rem;
}
```

### Dark Theme
```css
.unified-balance-card {
  background: #1f2937;
  color: white;
  border-radius: 12px;
  padding: 2rem;
}
```

### Gradient Design (Circle-Inspired)
```css
.unified-balance-card {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-radius: 16px;
  padding: 3rem 2rem;
}
```

---

## 🔄 Integration with Existing Components

### Add to Main Dashboard

```javascript
function App() {
  return (
    <div className="app">
      {/* Unified Balance at Top */}
      <UnifiedBalanceDisplay {...props} />
      
      {/* Existing Components */}
      <ActiveChainDisplay {...props} />
      <CrossChainDecisionLog {...props} />
      <SmartCrossChainChecker {...props} />
      {/* ... */}
    </div>
  );
}
```

### Update on Events

```javascript
// In your event listeners
sentinelVault.on("Deposited", () => {
  loadUnifiedBalance();
  // Update other components
});

sentinelVault.on("Withdrawn", () => {
  loadUnifiedBalance();
  // Update other components
});

crossChainArb.on("CrossChainMove", () => {
  loadUnifiedBalance();
  // Update other components
});
```

---

## ⚠️ Important Notes

### Decimals
- **USDC uses 6 decimals**
- Always use `ethers.formatUnits(balance, 6)` to format
- Always use `ethers.parseUnits(amount, 6)` to convert input

### Error Handling
```javascript
try {
  const balance = await sentinelVault.getUnifiedVaultBalance();
  // Handle success
} catch (error) {
  console.error("Error:", error);
  // Show user-friendly error message
  // Fallback to $0.00 or previous value
}
```

### Loading States
- Show spinner while loading
- Display previous value if available
- Handle network errors gracefully

### Performance
- Poll every 5-10 seconds (not too frequent)
- Use event listeners for instant updates
- Cache values to reduce calls

---

## 🚀 Quick Start Checklist

- [ ] Import SentinelVault ABI
- [ ] Connect to SentinelVault contract
- [ ] Create UnifiedBalanceDisplay component
- [ ] Add CSS styling (Circle-inspired)
- [ ] Implement `getUnifiedVaultBalance()` call
- [ ] Add wallet balance loading
- [ ] Implement real-time polling
- [ ] Add event listeners
- [ ] Add loading states
- [ ] Add error handling
- [ ] Format numbers correctly (2 decimals, commas)
- [ ] Position at top of dashboard
- [ ] Test with different balance values
- [ ] Test loading/error states
- [ ] Make responsive for mobile

---

## 💡 Example Values

### Testing
```javascript
// Small balance
unifiedBalance = "123.45" // $123.45

// Large balance
unifiedBalance = "1234567.89" // $1,234,567.89

// Zero balance
unifiedBalance = "0" // $0.00

// Very small balance
unifiedBalance = "0.01" // $0.01
```

### Formatting Examples
```javascript
// Input: "1234567.89"
// Output: "$1,234,567.89"

// Input: "123.45"
// Output: "$123.45"

// Input: "0"
// Output: "$0.00"
```

---

## 🎯 Design Goals

1. **Prominence** - Most visible element on dashboard
2. **Clarity** - Easy to read and understand
3. **Elegance** - Clean, modern design
4. **Real-Time** - Always up-to-date
5. **Responsive** - Works on all screen sizes

---

**Ready to build? Start with the UnifiedBalanceDisplay component and position it at the top of your dashboard!** 🚀

