# Bridge Transaction Troubleshooting Guide

## 🔍 Common Issues and Fixes

### Issue: "Bridge transaction was reverted"

This error occurs when the `bridgeUSDC()` call fails. Here are the most common causes and fixes:

---

## ✅ Fix 1: USDC Approval Required

**Problem:** User hasn't approved USDC to CrossChainArbitrage contract before calling `bridgeUSDC()`.

**Solution:** The frontend MUST approve USDC to the contract first:

```javascript
// Step 1: Approve USDC to CrossChainArbitrage contract
const userAddress = await signer.getAddress();
const crossChainArbAddress = "0x7A612459095bBe3F579068CDE982aa91C57919A6";

// Check current allowance
const allowance = await usdc.allowance(userAddress, crossChainArbAddress);

if (allowance < amount) {
  console.log("Approving USDC to CrossChainArbitrage...");
  const approveTx = await usdc.approve(crossChainArbAddress, amount);
  await approveTx.wait(); // ⚠️ CRITICAL: Wait for confirmation!
  console.log("✅ Approval confirmed");
}

// Step 2: Now bridge
const bridgeTx = await crossChainArb.bridgeUSDC(toChain, amount, recipient);
await bridgeTx.wait();
```

**⚠️ Important:** 
- Approval must complete BEFORE calling bridgeUSDC()
- Wait for approval transaction to confirm
- Approval must be to CrossChainArbitrage contract, not TokenMessenger

---

## ✅ Fix 2: Check Transaction on Block Explorer

The error message says "Please check the transaction on the block explorer". Here's how to debug:

1. **Get the transaction hash** from the error or receipt
2. **Visit:** https://testnet.arcscan.app/tx/<transaction_hash>
3. **Check the revert reason** - it will show the exact error

Common revert reasons:
- `"CrossChainArbitrage: USDC transfer failed"` → User hasn't approved
- `"CrossChainArbitrage: USDC approval failed"` → Contract can't approve TokenMessenger
- `"CrossChainArbitrage: Invalid destination domain"` → Chain name incorrect
- `"CrossChainArbitrage: Unsupported chain"` → Chain name not in supported list

---

## ✅ Fix 3: Verify Chain Names

**Problem:** Chain name doesn't match exactly.

**Solution:** Use exact chain names (case-sensitive):

```javascript
// ✅ Correct
await crossChainArb.bridgeUSDC("Ethereum", amount, recipient);
await crossChainArb.bridgeUSDC("Arbitrum", amount, recipient);
await crossChainArb.bridgeUSDC("Base", amount, recipient);
await crossChainArb.bridgeUSDC("Optimism", amount, recipient);

// ❌ Wrong
await crossChainArb.bridgeUSDC("ethereum", amount, recipient); // lowercase
await crossChainArb.bridgeUSDC("ETH", amount, recipient); // abbreviation
```

---

## ✅ Fix 4: Check Recipient Address

**Problem:** Recipient address is invalid or zero address.

**Solution:** Ensure recipient is a valid address on the destination chain:

```javascript
// ✅ Correct
const recipient = "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb"; // Valid address

// ❌ Wrong
const recipient = "0x0000000000000000000000000000000000000000"; // Zero address
const recipient = ""; // Empty
```

---

## ✅ Fix 5: Verify USDC Balance

**Problem:** User doesn't have enough USDC (including gas fees).

**Solution:** Check balance before bridging:

```javascript
const userAddress = await signer.getAddress();
const balance = await usdc.balanceOf(userAddress);
const amount = ethers.parseUnits("100", 6); // 100 USDC

if (balance < amount) {
  throw new Error(`Insufficient balance. Have: ${ethers.formatUnits(balance, 6)}, Need: ${ethers.formatUnits(amount, 6)}`);
}

// Also need extra for gas (Arc uses USDC for gas!)
const gasBuffer = ethers.parseUnits("1", 6); // 1 USDC buffer
if (balance < amount + gasBuffer) {
  console.warn("Low balance - may not have enough for gas");
}
```

---

## ✅ Fix 6: Complete Frontend Flow

Here's the complete correct flow:

```javascript
async function bridgeUSDCComplete(toChain, amountInDollars, recipientAddress) {
  try {
    const amount = ethers.parseUnits(amountInDollars.toString(), 6);
    const userAddress = await signer.getAddress();
    const crossChainArbAddress = "0x7A612459095bBe3F579068CDE982aa91C57919A6";
    
    // Step 1: Check balance
    const balance = await usdc.balanceOf(userAddress);
    if (balance < amount) {
      throw new Error("Insufficient USDC balance");
    }
    
    // Step 2: Check and approve USDC
    const allowance = await usdc.allowance(userAddress, crossChainArbAddress);
    if (allowance < amount) {
      console.log("Approving USDC...");
      const approveTx = await usdc.approve(crossChainArbAddress, amount);
      const approveReceipt = await approveTx.wait();
      
      if (approveReceipt.status !== 1) {
        throw new Error("Approval transaction failed");
      }
      console.log("✅ Approval confirmed");
    }
    
    // Step 3: Verify recipient is valid
    if (!ethers.isAddress(recipientAddress)) {
      throw new Error("Invalid recipient address");
    }
    
    // Step 4: Verify chain name
    const supportedChains = await crossChainArb.getSupportedChains();
    if (!supportedChains.includes(toChain)) {
      throw new Error(`Unsupported chain: ${toChain}`);
    }
    
    // Step 5: Bridge
    console.log(`Bridging ${amountInDollars} USDC to ${toChain}...`);
    const bridgeTx = await crossChainArb.bridgeUSDC(
      toChain,
      amount,
      recipientAddress
    );
    
    const bridgeReceipt = await bridgeTx.wait();
    
    if (bridgeReceipt.status !== 1) {
      throw new Error("Bridge transaction reverted - check block explorer");
    }
    
    console.log("✅ Bridge successful!", bridgeReceipt.hash);
    return bridgeReceipt;
    
  } catch (error) {
    console.error("Bridge error:", error);
    
    // Check if it's a revert with reason
    if (error.reason) {
      throw new Error(`Bridge failed: ${error.reason}`);
    }
    
    // Check if it's a transaction revert
    if (error.transaction) {
      throw new Error("Bridge transaction was reverted. Please check the transaction on the block explorer.");
    }
    
    throw error;
  }
}
```

---

## 🔍 Debugging Steps

1. **Check the transaction hash** on block explorer
2. **Look for revert reason** in the transaction details
3. **Verify approval** was successful before bridging
4. **Check chain name** matches exactly
5. **Verify recipient** is valid address
6. **Check user balance** is sufficient
7. **Verify contract address** is correct

---

## 📝 Error Messages Reference

| Error Message | Cause | Fix |
|--------------|-------|-----|
| `"USDC transfer failed"` | User hasn't approved USDC to contract | Approve USDC first |
| `"USDC approval failed"` | Contract can't approve TokenMessenger | Check USDC implementation |
| `"Invalid destination domain"` | Chain domain not set correctly | Use correct chain name |
| `"Unsupported chain"` | Chain name not in supported list | Use: "Ethereum", "Arbitrum", "Base", "Optimism" |
| `"Invalid recipient"` | Recipient is zero address | Provide valid address |
| Empty revert (0x) | CCTP call failed | Check CCTP contract addresses |

---

## 🚨 Most Common Issue

**90% of failures are due to missing USDC approval!**

Make sure your frontend:
1. ✅ Checks allowance
2. ✅ Approves USDC to CrossChainArbitrage contract
3. ✅ Waits for approval to confirm
4. ✅ Then calls bridgeUSDC()

---

## 💡 Quick Test

Test with a small amount first:

```javascript
// Test with 1 USDC
await bridgeUSDCComplete("Ethereum", 1, recipientAddress);
```

If this works, the issue might be with larger amounts or specific chains.

