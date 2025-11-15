# Frontend Bridge Fix - Critical Update

## 🚨 The Problem

The bridge transaction fails because **USDC must be approved to the CrossChainArbitrage contract BEFORE calling `bridgeUSDC()`**.

---

## ✅ The Solution

### Complete Bridge Flow (FIXED)

```javascript
import { ethers } from 'ethers';

const CROSS_CHAIN_ARB = "0x7A612459095bBe3F579068CDE982aa91C57919A6";
const USDC_ADDRESS = "0x3600000000000000000000000000000000000000";

async function bridgeUSDC(toChain, amountInDollars, recipientAddress) {
  try {
    const amount = ethers.parseUnits(amountInDollars.toString(), 6); // USDC has 6 decimals
    const userAddress = await signer.getAddress();
    
    // ⚠️ CRITICAL STEP 1: Approve USDC to CrossChainArbitrage contract
    const allowance = await usdc.allowance(userAddress, CROSS_CHAIN_ARB);
    
    if (allowance < amount) {
      console.log("Step 1: Approving USDC to CrossChainArbitrage contract...");
      const approveTx = await usdc.approve(CROSS_CHAIN_ARB, amount);
      
      // ⚠️ CRITICAL: Wait for approval to confirm!
      const approveReceipt = await approveTx.wait();
      
      if (approveReceipt.status !== 1) {
        throw new Error("Approval transaction failed");
      }
      
      console.log("✅ Step 1 Complete: USDC approved");
    } else {
      console.log("✅ Step 1: USDC already approved");
    }
    
    // Step 2: Verify inputs
    if (!ethers.isAddress(recipientAddress)) {
      throw new Error("Invalid recipient address");
    }
    
    // Step 3: Call bridgeUSDC
    console.log(`Step 2: Bridging ${amountInDollars} USDC to ${toChain}...`);
    const bridgeTx = await crossChainArb.bridgeUSDC(
      toChain,           // "Ethereum", "Arbitrum", "Base", "Optimism"
      amount,            // Amount in wei (6 decimals)
      recipientAddress   // Address to receive on destination chain
    );
    
    // Wait for bridge transaction
    const bridgeReceipt = await bridgeTx.wait();
    
    if (bridgeReceipt.status !== 1) {
      // Transaction reverted - get more details
      throw new Error("Bridge transaction was reverted. Check block explorer for details.");
    }
    
    console.log("✅ Step 2 Complete: Bridge successful!");
    console.log("Transaction hash:", bridgeReceipt.hash);
    
    return bridgeReceipt;
    
  } catch (error) {
    console.error("Bridge error:", error);
    
    // Provide helpful error messages
    if (error.reason) {
      throw new Error(`Bridge failed: ${error.reason}`);
    }
    
    if (error.message?.includes("transfer failed")) {
      throw new Error("USDC approval required. Please approve USDC to CrossChainArbitrage contract first.");
    }
    
    throw error;
  }
}
```

---

## 🔧 Update Your useCCTP Hook

Here's the corrected hook:

```typescript
// hooks/useCCTP.ts

export const useCCTP = () => {
  const bridgeUSDC = async (
    toChain: string,
    amount: string,
    recipient: string
  ) => {
    try {
      const amountWei = ethers.parseUnits(amount, 6);
      const userAddress = await signer.getAddress();
      const crossChainArbAddress = "0x7A612459095bBe3F579068CDE982aa91C57919A6";
      
      // ⚠️ CRITICAL: Approve first
      const allowance = await usdc.allowance(userAddress, crossChainArbAddress);
      
      if (allowance < amountWei) {
        setTransferStatus("Approving USDC...");
        const approveTx = await usdc.approve(crossChainArbAddress, amountWei);
        const approveReceipt = await approveTx.wait();
        
        if (approveReceipt.status !== 1) {
          throw new Error("Approval failed");
        }
      }
      
      setTransferStatus("Bridging USDC...");
      
      // Now bridge
      const bridgeTx = await crossChainArb.bridgeUSDC(toChain, amountWei, recipient);
      const receipt = await bridgeTx.wait();
      
      if (receipt.status === 0) {
        throw new Error("Bridge transaction was reverted. Please check the transaction on the block explorer.");
      }
      
      setTransferStatus("✅ Bridge successful!");
      return receipt;
      
    } catch (error) {
      console.error("Bridge error:", error);
      setTransferStatus("❌ Bridge failed");
      throw error;
    }
  };
  
  return { bridgeUSDC };
};
```

---

## 🔍 Debugging the Current Error

Your error says the transaction was reverted. To debug:

1. **Get the transaction hash** from the error or receipt
2. **Visit block explorer:** https://testnet.arcscan.app/tx/<hash>
3. **Check the revert reason** - it will show the exact error

Common revert reasons:
- `"CrossChainArbitrage: USDC transfer failed"` → **Missing approval!**
- `"CrossChainArbitrage: Invalid destination domain"` → Wrong chain name
- `"CrossChainArbitrage: Unsupported chain"` → Chain not in supported list

---

## 📋 Complete Integration Example

```typescript
// components/SimulatedBridge.tsx (UPDATED)

const handleBridge = async () => {
  try {
    setTransferStatus("Starting bridge...");
    
    // Step 1: Withdraw from vault (if needed)
    if (needsWithdraw) {
      setTransferStatus("Withdrawing from vault...");
      const withdrawTx = await sentinelVault.withdraw(amount);
      await withdrawTx.wait();
      setTransferStatus("✅ Withdrawal complete");
    }
    
    // Step 2: Approve USDC to CrossChainArbitrage
    const userAddress = await signer.getAddress();
    const crossChainArbAddress = "0x7A612459095bBe3F579068CDE982aa91C57919A6";
    const amountWei = ethers.parseUnits(amount, 6);
    
    setTransferStatus("Checking USDC approval...");
    const allowance = await usdc.allowance(userAddress, crossChainArbAddress);
    
    if (allowance < amountWei) {
      setTransferStatus("Approving USDC to CrossChainArbitrage...");
      const approveTx = await usdc.approve(crossChainArbAddress, amountWei);
      const approveReceipt = await approveTx.wait();
      
      if (approveReceipt.status !== 1) {
        throw new Error("Approval transaction failed");
      }
      setTransferStatus("✅ Approval confirmed");
    }
    
    // Step 3: Bridge
    setTransferStatus(`Bridging to ${toChain}...`);
    const bridgeTx = await crossChainArb.bridgeUSDC(
      toChain,
      amountWei,
      recipientAddress
    );
    
    const receipt = await bridgeTx.wait();
    
    if (receipt.status !== 1) {
      throw new Error(`Bridge reverted. Check: https://testnet.arcscan.app/tx/${receipt.hash}`);
    }
    
    setTransferStatus("✅ Bridge successful!");
    
  } catch (error) {
    console.error("Bridge error:", error);
    setTransferStatus(`❌ Error: ${error.message}`);
  }
};
```

---

## ⚠️ Key Points

1. **Approval is REQUIRED** - User must approve USDC to CrossChainArbitrage contract
2. **Wait for approval** - Don't call bridgeUSDC until approval confirms
3. **Check transaction status** - Verify `receipt.status === 1`
4. **Use correct chain names** - "Ethereum", "Arbitrum", "Base", "Optimism" (case-sensitive)
5. **Valid recipient** - Must be a valid address on destination chain

---

## 🐛 If Still Failing

1. Check the transaction hash on block explorer
2. Look for the exact revert reason
3. Verify approval was successful (check allowance)
4. Test with small amount first (1 USDC)
5. Verify contract address is correct: `0x7A612459095bBe3F579068CDE982aa91C57919A6`

---

**The fix is simple: Approve USDC to CrossChainArbitrage contract BEFORE calling bridgeUSDC()!** ✅

