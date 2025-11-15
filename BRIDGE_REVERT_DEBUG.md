# Bridge Transaction Revert - Debugging Guide

## The Problem

When calling `bridgeUSDC()`, the transaction reverts with a generic error (`0x` revert reason).

## Common Causes

### 1. **Insufficient USDC Allowance** ⚠️ MOST COMMON

**Symptom:** Transaction reverts at `transferFrom` step

**Solution:**
- User must approve USDC to `CrossChainArbitrage` contract **BEFORE** calling `bridgeUSDC()`
- Check current allowance:
  ```javascript
  const allowance = await usdc.allowance(userAddress, crossChainArbAddress);
  console.log("Current allowance:", allowance.toString());
  ```
- If allowance is less than amount, approve:
  ```javascript
  await usdc.approve(crossChainArbAddress, amount);
  await approveTx.wait(); // Wait for confirmation!
  ```

### 2. **Insufficient USDC Balance**

**Symptom:** User doesn't have enough USDC

**Check:**
```javascript
const balance = await usdc.balanceOf(userAddress);
if (balance < amount) {
  throw new Error("Insufficient balance");
}
```

### 3. **TokenMessenger Contract Issue**

**Symptom:** Transaction reverts at `depositForBurn` call

**Possible causes:**
- TokenMessenger address is wrong
- TokenMessenger doesn't have permission to burn USDC
- Destination domain is invalid

**Check TokenMessenger:**
```javascript
// Verify TokenMessenger address
const tokenMessenger = await crossChainArb.tokenMessenger();
console.log("TokenMessenger:", tokenMessenger);

// Should be: 0x8FE6B999Dc680CcFDD5Bf7EB0974218be2542DAA (Arc Testnet)
```

### 4. **Invalid Destination Domain**

**Symptom:** Domain validation fails

**Check domains:**
```javascript
// Check domain for each chain
const arcDomain = await crossChainArb.chainDomains("Arc"); // Should be 26
const ethDomain = await crossChainArb.chainDomains("Ethereum"); // Should be 0
const arbDomain = await crossChainArb.chainDomains("Arbitrum"); // Should be 42161
```

### 5. **USDC Approval Reset Issue**

**Symptom:** Transaction reverts at approval step

**Fix:** The contract now handles this better (doesn't require reset to succeed)

## Debugging Steps

### Step 1: Check User Balance
```javascript
const balance = await usdc.balanceOf(userAddress);
console.log("User balance:", ethers.formatUnits(balance, 6), "USDC");
```

### Step 2: Check Allowance
```javascript
const allowance = await usdc.allowance(userAddress, crossChainArbAddress);
console.log("Allowance:", ethers.formatUnits(allowance, 6), "USDC");
console.log("Required:", ethers.formatUnits(amount, 6), "USDC");
console.log("Sufficient?", allowance >= amount);
```

### Step 3: Verify Contract Configuration
```javascript
// Check USDC address
const usdcAddress = await crossChainArb.usdc();
console.log("USDC address:", usdcAddress);

// Check TokenMessenger
const tokenMessenger = await crossChainArb.tokenMessenger();
console.log("TokenMessenger:", tokenMessenger);

// Check supported chains
const chains = await crossChainArb.getSupportedChains();
console.log("Supported chains:", chains);
```

### Step 4: Test with Small Amount
Try bridging a very small amount (e.g., 0.01 USDC) to see if the issue is amount-related.

### Step 5: Check Transaction Details
Look at the failed transaction on the block explorer:
- Which function call failed?
- What was the revert reason?
- What was the gas used?

## Frontend Fix

Make sure the frontend:

1. **Checks allowance BEFORE bridging:**
```javascript
const allowance = await checkAllowance(amountWei);
if (!allowance) {
  await approveUSDC(amountWei);
  // Wait for approval to confirm!
}
```

2. **Waits for approval confirmation:**
```javascript
const approveTx = await usdc.approve(crossChainArbAddress, amount);
const receipt = await approveTx.wait(); // CRITICAL: Wait for confirmation!
if (receipt.status !== 1) {
  throw new Error("Approval failed");
}
```

3. **Verifies balance:**
```javascript
const balance = await usdc.balanceOf(userAddress);
if (balance < amount) {
  throw new Error("Insufficient balance");
}
```

## Contract Addresses (Arc Testnet)

- **CrossChainArbitrage:** `0x7A612459095bBe3F579068CDE982aa91C57919A6`
- **USDC:** `0x3600000000000000000000000000000000000000`
- **TokenMessenger:** `0x8FE6B999Dc680CcFDD5Bf7EB0974218be2542DAA`

## Next Steps

1. Check browser console for detailed error messages
2. Verify allowance is sufficient
3. Try with a very small amount first
4. Check the transaction on block explorer for exact revert reason
5. Verify TokenMessenger address is correct

