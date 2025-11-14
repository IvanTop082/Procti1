# Frontend Integration Guide

This guide is for your friend who's building the frontend.

---

## What You Need

1. **Contract Addresses** - From `CONTRACT_ADDRESSES.md` (after deployment)
2. **Network Information** - Chain ID and RPC URL
3. **ABI Files** - From `/abi` folder in this repository

---

## Quick Setup

### 1. Get the ABIs

Copy these files from the `/abi` folder:
- `SentinelVault.json`
- `OracleFeed.json`
- `IERC20.json` (for USDC)

### 2. Get Contract Addresses

Ask for the `CONTRACT_ADDRESSES.md` file after deployment.

### 3. Connect to Contracts

```javascript
import { ethers } from 'ethers';
import SentinelVaultABI from './abi/SentinelVault.json';
import OracleFeedABI from './abi/OracleFeed.json';
import IERC20ABI from './abi/IERC20.json';

// Network configuration (from CONTRACT_ADDRESSES.md)
const CONFIG = {
  chainId: 11155111, // Example: Sepolia
  rpcUrl: "https://sepolia.infura.io/v3/YOUR_KEY",
  contracts: {
    sentinelVault: "0x...", // From CONTRACT_ADDRESSES.md
    oracleFeed: "0x...",     // From CONTRACT_ADDRESSES.md
    usdc: "0x..."           // From CONTRACT_ADDRESSES.md
  }
};

// Connect to provider
const provider = new ethers.JsonRpcProvider(CONFIG.rpcUrl);
// Or use MetaMask: const provider = new ethers.BrowserProvider(window.ethereum);

// Get signer (for transactions)
const signer = await provider.getSigner();

// Connect to contracts
const sentinelVault = new ethers.Contract(
  CONFIG.contracts.sentinelVault,
  SentinelVaultABI,
  signer
);

const oracleFeed = new ethers.Contract(
  CONFIG.contracts.oracleFeed,
  OracleFeedABI,
  signer
);

const usdc = new ethers.Contract(
  CONFIG.contracts.usdc,
  IERC20ABI,
  signer
);
```

---

## Key Functions

### Check Current Mode
```javascript
const mode = await sentinelVault.getMode();
// Returns: 0 = Farming, 1 = Defensive, 2 = Emergency
```

### Get User Balance
```javascript
const userAddress = await signer.getAddress();
const balance = await sentinelVault.userDeposits(userAddress);
// Returns balance in USDC (6 decimals)
```

### Deposit USDC
```javascript
const amount = ethers.parseUnits("100", 6); // 100 USDC (6 decimals)

// 1. Approve USDC spending
await usdc.approve(CONFIG.contracts.sentinelVault, amount);

// 2. Deposit
const tx = await sentinelVault.deposit(amount);
await tx.wait();
```

### Withdraw USDC
```javascript
const amount = ethers.parseUnits("50", 6); // 50 USDC

const tx = await sentinelVault.withdraw(amount);
await tx.wait();
```

### Get Oracle Price
```javascript
const price = await oracleFeed.getPrice();
// Returns price scaled by 1e18 (e.g., 1e18 = $1.00)
const priceInDollars = Number(price) / 1e18;
```

### Set Oracle Price (for demo)
```javascript
const newPrice = ethers.parseUnits("0.998", 18); // $0.998
const tx = await oracleFeed.setPrice(newPrice);
await tx.wait();
```

### Simulate Risk
```javascript
const testPrice = ethers.parseUnits("0.998", 18);
const wouldTrigger = await sentinelVault.simulateRisk(testPrice);
// Returns true if price < $0.999
```

### Rebalance (Switch Modes)
```javascript
const tx = await sentinelVault.rebalance();
await tx.wait();
// Automatically switches modes based on current oracle price
```

---

## Events to Listen To

```javascript
// Listen for deposits
sentinelVault.on("Deposited", (user, amount, event) => {
  console.log(`User ${user} deposited ${amount}`);
});

// Listen for withdrawals
sentinelVault.on("Withdrawn", (user, amount, event) => {
  console.log(`User ${user} withdrew ${amount}`);
});

// Listen for mode changes
sentinelVault.on("ModeChanged", (oldMode, newMode, event) => {
  console.log(`Mode changed from ${oldMode} to ${newMode}`);
});

// Listen for rebalances
sentinelVault.on("Rebalanced", (mode, amount, event) => {
  console.log(`Rebalanced to mode ${mode} with ${amount}`);
});
```

---

## UI Flow Example

```javascript
// 1. Check if user is connected
const accounts = await window.ethereum.request({ method: 'eth_accounts' });
if (accounts.length === 0) {
  // Prompt to connect wallet
  await window.ethereum.request({ method: 'eth_requestAccounts' });
}

// 2. Get current state
const [mode, userBalance, oraclePrice] = await Promise.all([
  sentinelVault.getMode(),
  sentinelVault.userDeposits(await signer.getAddress()),
  oracleFeed.getPrice()
]);

// 3. Display in UI
const modeNames = ["Farming", "Defensive", "Emergency"];
console.log(`Current Mode: ${modeNames[mode]}`);
console.log(`Your Balance: ${ethers.formatUnits(userBalance, 6)} USDC`);
console.log(`USDC Price: $${Number(oraclePrice) / 1e18}`);

// 4. Handle user actions
async function handleDeposit(amount) {
  const amountWei = ethers.parseUnits(amount.toString(), 6);
  await usdc.approve(CONFIG.contracts.sentinelVault, amountWei);
  await sentinelVault.deposit(amountWei);
}

async function handleRebalance() {
  await sentinelVault.rebalance();
  // Refresh UI to show new mode
}
```

---

## Important Notes

1. **USDC uses 6 decimals** (not 18 like ETH)
   - Use `ethers.parseUnits("100", 6)` for 100 USDC
   - Use `ethers.formatUnits(balance, 6)` to display

2. **Oracle price uses 18 decimals**
   - Use `ethers.parseUnits("1.00", 18)` for $1.00
   - Use `Number(price) / 1e18` to convert to dollars

3. **Always check approvals** before deposits
   - Users must approve USDC spending first

4. **Handle errors gracefully**
   - Insufficient balance
   - Network errors
   - Transaction rejections

5. **Test on testnet first** before mainnet!

---

## Need Help?

- Check `CONTRACT_ADDRESSES.md` for addresses
- Check `/abi` folder for contract ABIs
- All contracts are verified and tested ✅

