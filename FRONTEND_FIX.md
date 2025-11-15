# 🔧 Frontend Fix Guide

## Common Mistakes Causing Failed Transactions

### ❌ Mistake 1: Wrong Decimal Places
```javascript
// WRONG - USDC uses 6 decimals, not 18!
const amount = ethers.parseUnits("10", 18); // This is wrong!

// CORRECT
const amount = ethers.parseUnits("10", 6); // 10 USDC
```

### ❌ Mistake 2: Approving to Wrong Address
```javascript
// WRONG - Don't approve to YieldPool or SafePool
await usdc.approve(yieldPoolAddress, amount);

// CORRECT - Always approve to SentinelVault
await usdc.approve(sentinelVaultAddress, amount);
```

### ❌ Mistake 3: Not Waiting for Approval
```javascript
// WRONG - Don't deposit immediately
await usdc.approve(sentinelVaultAddress, amount);
await sentinelVault.deposit(amount); // Might fail!

// CORRECT - Wait for approval to confirm
const approveTx = await usdc.approve(sentinelVaultAddress, amount);
await approveTx.wait(); // Wait here!
await sentinelVault.deposit(amount);
```

### ❌ Mistake 4: Using Wrong Contract Address
```javascript
// WRONG - Don't use YieldPool or SafePool addresses
const contract = new ethers.Contract(yieldPoolAddress, ABI, signer);

// CORRECT - Always use SentinelVault
const contract = new ethers.Contract(sentinelVaultAddress, ABI, signer);
```

---

## ✅ Complete Working Example

```javascript
import { ethers } from 'ethers';
import SentinelVaultABI from './abi/SentinelVault.json';
import IERC20ABI from './abi/IERC20.json';

// Contract addresses
const SENTINEL_VAULT = "0x6D6F4f209AE8E03DCfC4719a5b8bA50B2fe45FDa";
const USDC = "0x615Fe162774b71c6fA55deC75a25F83561948a64";

// Connect wallet
const provider = new ethers.BrowserProvider(window.ethereum);
const signer = await provider.getSigner();

// Connect to contracts
const sentinelVault = new ethers.Contract(
  SENTINEL_VAULT,
  SentinelVaultABI,
  signer
);

const usdc = new ethers.Contract(
  USDC,
  IERC20ABI,
  signer
);

// Deposit function
async function deposit(amountInDollars) {
  try {
    // Convert to wei (6 decimals for USDC!)
    const amount = ethers.parseUnits(amountInDollars.toString(), 6);
    
    // Check balance
    const userAddress = await signer.getAddress();
    const balance = await usdc.balanceOf(userAddress);
    if (balance < amount) {
      throw new Error("Insufficient USDC balance");
    }
    
    // Step 1: Check existing allowance
    const allowance = await usdc.allowance(userAddress, SENTINEL_VAULT);
    
    // Step 2: Approve if needed
    if (allowance < amount) {
      console.log("Approving USDC...");
      const approveTx = await usdc.approve(SENTINEL_VAULT, amount);
      console.log("Waiting for approval...");
      await approveTx.wait();
      console.log("Approval confirmed!");
    }
    
    // Step 3: Deposit
    console.log("Depositing...");
    const depositTx = await sentinelVault.deposit(amount);
    console.log("Waiting for deposit...");
    await depositTx.wait();
    console.log("Deposit successful!");
    
    return depositTx.hash;
  } catch (error) {
    console.error("Deposit failed:", error);
    throw error;
  }
}

// Withdraw function
async function withdraw(amountInDollars) {
  try {
    const amount = ethers.parseUnits(amountInDollars.toString(), 6);
    
    console.log("Withdrawing...");
    const withdrawTx = await sentinelVault.withdraw(amount);
    await withdrawTx.wait();
    console.log("Withdrawal successful!");
    
    return withdrawTx.hash;
  } catch (error) {
    console.error("Withdraw failed:", error);
    throw error;
  }
}

// Get user balance
async function getUserBalance() {
  const userAddress = await signer.getAddress();
  const balance = await sentinelVault.userDeposits(userAddress);
  return ethers.formatUnits(balance, 6); // Convert back to dollars
}

// Get current mode
async function getMode() {
  const mode = await sentinelVault.getMode();
  const modes = ["Farming", "Defensive", "Emergency"];
  return {
    mode: Number(mode),
    name: modes[Number(mode)]
  };
}

// Usage
await deposit(10); // Deposit 10 USDC
const balance = await getUserBalance(); // Get balance
const mode = await getMode(); // Get current mode
```

---

## 🐛 Debugging Checklist

Before calling deposit, check:

```javascript
// 1. User has USDC?
const usdcBalance = await usdc.balanceOf(userAddress);
console.log("USDC Balance:", ethers.formatUnits(usdcBalance, 6));

// 2. Approval exists?
const allowance = await usdc.allowance(userAddress, SENTINEL_VAULT);
console.log("Allowance:", ethers.formatUnits(allowance, 6));

// 3. User has deposit balance?
const depositBalance = await sentinelVault.userDeposits(userAddress);
console.log("Deposit Balance:", ethers.formatUnits(depositBalance, 6));

// 4. Current mode?
const mode = await sentinelVault.getMode();
console.log("Mode:", mode);
```

---

## 🎯 Quick Reference

| What | Address | Decimals | Purpose |
|------|---------|----------|---------|
| **SentinelVault** | `0x6D6F4f209AE8E03DCfC4719a5b8bA50B2fe45FDa` | - | **Main contract - use this!** |
| USDC (MockUSDC) | `0x615Fe162774b71c6fA55deC75a25F83561948a64` | **6** | Token for approvals |
| YieldPool | `0xA2d5245AC4f3e622d025d82c03211A794e61709C` | - | Internal (don't use) |
| SafePool | `0x00fa22EefFBb6c61F9e6286d470F2F694Fb1EFA4` | - | Internal (don't use) |
| OracleFeed | `0x32108F6ad1d9F8f805a4E72b3C9829425FCfFb73` | 18 | Read price only |

**Remember: Frontend ONLY uses SentinelVault!**

