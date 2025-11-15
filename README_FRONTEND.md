# Procti Protocol - Frontend Integration Guide

Complete guide for integrating the Procti Protocol smart contracts into your frontend application.

---

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Contract Addresses](#contract-addresses)
- [Setup](#setup)
- [Connecting to Contracts](#connecting-to-contracts)
- [Core Functions](#core-functions)
- [Risk Profiles](#risk-profiles)
- [Mode History](#mode-history)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)

---

## 🚀 Quick Start

```javascript
import { ethers } from 'ethers';
import SentinelVaultABI from './abi/SentinelVault.json';

// Connect to SentinelVault
const sentinelVault = new ethers.Contract(
  "0xDf9053726a2217326bFEadc0c3480c5De7107B8f",
  SentinelVaultABI,
  signer
);

// Deposit USDC
const amount = ethers.parseUnits("100", 6); // 100 USDC (6 decimals!)
await usdc.approve(sentinelVaultAddress, amount);
await sentinelVault.deposit(amount);
```

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
| **CrossChainArbitrage** | `0x387a8Ed9B0BeC289CA53a4F58F9c25A4366Fd245` | **Cross-chain features** |
| SafePool | `0xb90892b0143eb804037D582FE7678C636D47f0a5` | Internal (don't use directly) |
| YieldPool | `0xC6D145006Cd18C7b22D584737A8909DdF3b839D5` | Internal (don't use directly) |
| OracleFeed | `0xd8A5E7ACa9A2B61d223Ea993749B5F6576aa503f` | Read price (optional) |
| USDC | `0x3600000000000000000000000000000000000000` | Token for approvals |

**⚠️ Important:** Only interact with **SentinelVault** directly. Other contracts are internal.

---

## 🛠️ Setup

### Install Dependencies

```bash
npm install ethers
# or
yarn add ethers
```

### Import ABIs

Copy the ABI files from the `/abi` folder:

```javascript
import SentinelVaultABI from './abi/SentinelVault.json';
import OracleFeedABI from './abi/OracleFeed.json';
import IERC20ABI from './abi/IERC20.json';
```

---

## 🔌 Connecting to Contracts

### 1. Connect Wallet

```javascript
import { ethers } from 'ethers';

// Using MetaMask or browser wallet
const provider = new ethers.BrowserProvider(window.ethereum);
const signer = await provider.getSigner();
const userAddress = await signer.getAddress();
```

### 2. Connect to Contracts

```javascript
// Contract addresses
const SENTINEL_VAULT = "0xDf9053726a2217326bFEadc0c3480c5De7107B8f";
const CROSS_CHAIN_ARB = "0x387a8Ed9B0BeC289CA53a4F58F9c25A4366Fd245";
const ORACLE_FEED = "0xd8A5E7ACa9A2B61d223Ea993749B5F6576aa503f";
const USDC = "0x3600000000000000000000000000000000000000";

// Connect to contracts
const sentinelVault = new ethers.Contract(
  SENTINEL_VAULT,
  SentinelVaultABI,
  signer
);

const oracleFeed = new ethers.Contract(
  ORACLE_FEED,
  OracleFeedABI,
  signer
);

const usdc = new ethers.Contract(
  USDC,
  IERC20ABI,
  signer
);
```

### 3. Add Network to MetaMask (if needed)

```javascript
async function addArcTestnet() {
  await window.ethereum.request({
    method: 'wallet_addEthereumChain',
    params: [{
      chainId: '0x4D0A2', // 5042002 in hex
      chainName: 'Arc Testnet',
      nativeCurrency: {
        name: 'USDC',
        symbol: 'USDC',
        decimals: 6
      },
      rpcUrls: ['https://rpc.testnet.arc.network'],
      blockExplorerUrls: ['https://testnet.arcscan.app']
    }]
  });
}
```

---

## 🎯 Core Functions

### Deposit USDC

```javascript
async function deposit(amountInDollars) {
  try {
    // IMPORTANT: USDC uses 6 decimals, not 18!
    const amount = ethers.parseUnits(amountInDollars.toString(), 6);
    
    // Step 1: Check balance
    const balance = await usdc.balanceOf(userAddress);
    if (balance < amount) {
      throw new Error("Insufficient USDC balance");
    }
    
    // Step 2: Approve USDC to SentinelVault
    const approveTx = await usdc.approve(SENTINEL_VAULT, amount);
    await approveTx.wait(); // Wait for confirmation!
    
    // Step 3: Deposit
    const depositTx = await sentinelVault.deposit(amount);
    await depositTx.wait();
    
    console.log("Deposit successful!");
    return depositTx.hash;
  } catch (error) {
    console.error("Deposit failed:", error);
    throw error;
  }
}

// Usage
await deposit(100); // Deposit 100 USDC
```

### Withdraw USDC

```javascript
async function withdraw(amountInDollars) {
  try {
    const amount = ethers.parseUnits(amountInDollars.toString(), 6);
    
    const withdrawTx = await sentinelVault.withdraw(amount);
    await withdrawTx.wait();
    
    console.log("Withdrawal successful!");
    return withdrawTx.hash;
  } catch (error) {
    console.error("Withdraw failed:", error);
    throw error;
  }
}
```

### Get User Balance

```javascript
async function getUserBalance() {
  const balance = await sentinelVault.userDeposits(userAddress);
  return ethers.formatUnits(balance, 6); // Convert to dollars
}
```

### Get Current Mode

```javascript
async function getCurrentMode() {
  const mode = await sentinelVault.getMode();
  const modes = ["Farming", "Defensive", "Emergency"];
  return {
    value: Number(mode),
    name: modes[Number(mode)]
  };
}
```

### Rebalance

```javascript
async function rebalance() {
  const tx = await sentinelVault.rebalance();
  await tx.wait();
  console.log("Rebalanced!");
}
```

---

## 🎚️ Risk Profiles

Users can customize their risk tolerance with three profiles:

### Set Risk Profile

```javascript
async function setRiskProfile(profile) {
  // 0 = Conservative, 1 = Balanced, 2 = Aggressive
  const tx = await sentinelVault.setRiskProfile(profile);
  await tx.wait();
  console.log(`Risk profile set to: ${profile}`);
}

// Usage
await setRiskProfile(0); // Conservative (safest)
await setRiskProfile(1); // Balanced (default)
await setRiskProfile(2); // Aggressive (higher risk)
```

### Get User Risk Profile

```javascript
async function getUserRiskProfile(address) {
  const profile = await sentinelVault.userRiskProfile(address);
  const profiles = ["Conservative", "Balanced", "Aggressive"];
  return {
    value: Number(profile),
    name: profiles[Number(profile)]
  };
}
```

### Risk Profile Thresholds

| Profile | Defensive Threshold | Emergency Threshold |
|---------|-------------------|-------------------|
| **Conservative** | $0.9992 | $0.996 |
| **Balanced** | $0.999 | $0.995 |
| **Aggressive** | $0.9985 | $0.994 |

**How it works:**
- When a user calls `rebalance()`, it uses **their** risk profile to determine thresholds
- More conservative profiles switch to defensive mode earlier
- More aggressive profiles allow more price movement before switching

---

## 📊 Mode History

Query the complete history of mode changes using events:

### Get All Mode Changes

```javascript
async function getModeHistory() {
  const filter = sentinelVault.filters.ModeChanged();
  const events = await sentinelVault.queryFilter(filter);
  
  return events.map(event => ({
    mode: Number(event.args.newMode),
    modeName: ["Farming", "Defensive", "Emergency"][Number(event.args.newMode)],
    price: ethers.formatUnits(event.args.price, 18), // Convert to dollars
    timestamp: new Date(Number(event.args.timestamp) * 1000),
    reason: event.args.reason,
    blockNumber: event.blockNumber,
    transactionHash: event.transactionHash
  }));
}
```

### Get Mode History from Block Range

```javascript
async function getModeHistoryFromBlock(fromBlock, toBlock) {
  const filter = sentinelVault.filters.ModeChanged();
  const events = await sentinelVault.queryFilter(filter, fromBlock, toBlock);
  
  return events.map(event => ({
    mode: Number(event.args.newMode),
    price: ethers.formatUnits(event.args.price, 18),
    timestamp: new Date(Number(event.args.timestamp) * 1000),
    reason: event.args.reason
  }));
}
```

### Listen for Mode Changes

```javascript
// Listen for new mode changes
sentinelVault.on("ModeChanged", (newMode, price, timestamp, reason, event) => {
  console.log("Mode changed!");
  console.log("New Mode:", ["Farming", "Defensive", "Emergency"][Number(newMode)]);
  console.log("Price:", ethers.formatUnits(price, 18));
  console.log("Reason:", reason);
  
  // Update your UI
  updateModeDisplay(newMode, price, reason);
});
```

---

## 🔍 Oracle Price

### Get Current Price

```javascript
async function getOraclePrice() {
  const price = await oracleFeed.getPrice();
  const priceInDollars = Number(price) / 1e18;
  return priceInDollars;
}
```

### Set Price (for demo/testing)

```javascript
async function setOraclePrice(priceInDollars) {
  const price = ethers.parseUnits(priceInDollars.toString(), 18);
  const tx = await oracleFeed.setPrice(price);
  await tx.wait();
  console.log(`Price set to $${priceInDollars}`);
}

// Usage
await setOraclePrice(0.998); // Set to $0.998 (triggers Defensive mode)
```

### Simulate Risk

```javascript
async function simulateRisk(priceInDollars) {
  const price = ethers.parseUnits(priceInDollars.toString(), 18);
  const wouldTrigger = await sentinelVault.simulateRisk(price);
  return wouldTrigger;
}
```

---

## 📝 Complete Example

```javascript
import { ethers } from 'ethers';
import SentinelVaultABI from './abi/SentinelVault.json';
import OracleFeedABI from './abi/OracleFeed.json';
import IERC20ABI from './abi/IERC20.json';

// Contract addresses
const CONTRACTS = {
  sentinelVault: "0x9Ca88C46cc5A71A1CFC7431e1A18768160f463a9",
  oracleFeed: "0xd8A5E7ACa9A2B61d223Ea993749B5F6576aa503f",
  usdc: "0x3600000000000000000000000000000000000000"
};

// Initialize
const provider = new ethers.BrowserProvider(window.ethereum);
const signer = await provider.getSigner();

const sentinelVault = new ethers.Contract(
  CONTRACTS.sentinelVault,
  SentinelVaultABI,
  signer
);

const oracleFeed = new ethers.Contract(
  CONTRACTS.oracleFeed,
  OracleFeedABI,
  signer
);

const usdc = new ethers.Contract(
  CONTRACTS.usdc,
  IERC20ABI,
  signer
);

// Example: Complete user flow
async function exampleFlow() {
  const userAddress = await signer.getAddress();
  
  // 1. Check current state
  const [balance, mode, profile, price] = await Promise.all([
    sentinelVault.userDeposits(userAddress),
    sentinelVault.getMode(),
    sentinelVault.userRiskProfile(userAddress),
    oracleFeed.getPrice()
  ]);
  
  console.log("Balance:", ethers.formatUnits(balance, 6), "USDC");
  console.log("Mode:", ["Farming", "Defensive", "Emergency"][Number(mode)]);
  console.log("Profile:", ["Conservative", "Balanced", "Aggressive"][Number(profile)]);
  console.log("Price: $", Number(price) / 1e18);
  
  // 2. Set risk profile
  await sentinelVault.setRiskProfile(1); // Balanced
  
  // 3. Deposit
  const depositAmount = ethers.parseUnits("100", 6);
  await usdc.approve(CONTRACTS.sentinelVault, depositAmount);
  await sentinelVault.deposit(depositAmount);
  
  // 4. Get mode history
  const history = await sentinelVault.queryFilter(
    sentinelVault.filters.ModeChanged()
  );
  console.log("Mode changes:", history.length);
  
  // 5. Rebalance (uses user's risk profile)
  await sentinelVault.rebalance();
}
```

---

## ⚠️ Important Notes

### 1. USDC Uses 6 Decimals (Not 18!)

```javascript
// ✅ CORRECT
const amount = ethers.parseUnits("100", 6); // 100 USDC
const display = ethers.formatUnits(balance, 6); // Display balance

// ❌ WRONG
const amount = ethers.parseUnits("100", 18); // This is wrong!
```

### 2. Always Approve Before Depositing

```javascript
// Step 1: Approve
const approveTx = await usdc.approve(sentinelVaultAddress, amount);
await approveTx.wait(); // Wait for confirmation!

// Step 2: Deposit (after approval confirms)
const depositTx = await sentinelVault.deposit(amount);
await depositTx.wait();
```

### 3. Only Use SentinelVault Address

- ✅ **DO**: Interact with SentinelVault directly
- ❌ **DON'T**: Interact with YieldPool or SafePool directly
- ✅ **DO**: Read from OracleFeed for price data

### 4. Arc Testnet Uses USDC for Gas

- Make sure users have test USDC for gas fees
- Get test USDC from: https://faucet.circle.com

---

## 🐛 Troubleshooting

### "Insufficient funds" error
- Check user has USDC balance
- Check user has USDC for gas fees
- Verify amount uses 6 decimals

### "Transfer failed" error
- Make sure USDC is approved to SentinelVault
- Wait for approval transaction to confirm before depositing
- Check approval amount is sufficient

### "Insufficient allowance" error
- Approve USDC to SentinelVault first
- Approve amount must be >= deposit amount

### Transactions failing
- Check network is Arc Testnet (Chain ID: 5042002)
- Verify contract addresses are correct
- Ensure user has test USDC for gas

### Mode not changing
- Check oracle price is set correctly
- Verify user's risk profile thresholds
- Make sure `rebalance()` is called

---

## 📚 Additional Resources

- **Contract Addresses:** See `CONTRACT_ADDRESSES.md`
- **Mode History Guide:** See `MODE_HISTORY_GUIDE.md`
- **Risk Profiles Guide:** See `RISK_PROFILES_GUIDE.md`
- **Block Explorer:** https://testnet.arcscan.app

---

## 🎯 Quick Reference

### Contract Addresses
```javascript
const SENTINEL_VAULT = "0x93A38275a75834385Ad296C6b0248138d3F433B2";
const ORACLE_FEED = "0xd8A5E7ACa9A2B61d223Ea993749B5F6576aa503f";
const USDC = "0x3600000000000000000000000000000000000000";
```

### Network Info
```javascript
const NETWORK = {
  name: "Arc Testnet",
  chainId: 5042002,
  rpcUrl: "https://rpc.testnet.arc.network",
  explorer: "https://testnet.arcscan.app"
};
```

### Common Functions
```javascript
// Deposit
await usdc.approve(SENTINEL_VAULT, amount);
await sentinelVault.deposit(amount);

// Withdraw
await sentinelVault.withdraw(amount);

// Set risk profile
await sentinelVault.setRiskProfile(0); // 0=Conservative, 1=Balanced, 2=Aggressive

// Rebalance
await sentinelVault.rebalance();

// Get mode history
const events = await sentinelVault.queryFilter(sentinelVault.filters.ModeChanged());
```

---

## 💡 Tips

1. **Always wait for transactions** - Use `await tx.wait()` before proceeding
2. **Check approvals** - Verify allowance before attempting deposits
3. **Handle errors gracefully** - Wrap calls in try/catch blocks
4. **Use 6 decimals for USDC** - Always use `parseUnits(amount, 6)`
5. **Query mode history** - Use events for analytics and UI timelines
6. **Set risk profiles** - Let users customize their risk tolerance

---

## 🚀 Ready to Build!

You now have everything you need to integrate Procti Protocol into your frontend. Start with the Quick Start example and build from there!

For questions or issues, check the troubleshooting section or review the contract addresses and ABIs.

**Happy building! 🎉**

