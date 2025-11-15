# Frontend Update: Use Contract's bridgeUSDC() Instead of Direct CCTP Calls

## 🎯 What Changed

The backend contract now handles CCTP bridging internally. **Stop calling CCTP directly from the frontend** and use the contract's `bridgeUSDC()` function instead.

---

## ❌ OLD WAY (Remove This)

```javascript
// ❌ DON'T DO THIS ANYMORE - Remove direct CCTP calls
import { TokenMessenger } from '@circle-fin/cctp-sdk';

const tokenMessenger = new TokenMessenger(tokenMessengerAddress, signer);

// Direct CCTP call - REMOVE THIS
await tokenMessenger.depositForBurn(
  amount,
  destinationDomain,
  mintRecipient,
  usdcAddress
);
```

**Why this fails:**
- Frontend is calling CCTP directly
- Contract doesn't know about the bridge
- State doesn't update
- Events don't fire

---

## ✅ NEW WAY (Use This)

```javascript
// ✅ DO THIS - Use the contract's bridgeUSDC() function
import { ethers } from 'ethers';
import CrossChainArbitrageABI from './abi/CrossChainArbitrage.json';
import IERC20ABI from './abi/IERC20.json';

// Contract addresses
const CROSS_CHAIN_ARB = "0xfe9d856E1f3BA56C462DF56B27b8863f1ff700B9"; // Your deployed address
const USDC_ADDRESS = "0x3600000000000000000000000000000000000000";

// Connect to contracts
const crossChainArb = new ethers.Contract(
  CROSS_CHAIN_ARB,
  CrossChainArbitrageABI,
  signer
);

const usdc = new ethers.Contract(
  USDC_ADDRESS,
  IERC20ABI,
  signer
);

// Bridge USDC function
async function bridgeUSDC(toChain, amountInDollars, recipientAddress) {
  try {
    const amount = ethers.parseUnits(amountInDollars.toString(), 6); // USDC has 6 decimals
    const userAddress = await signer.getAddress();
    
    // Step 1: Check and approve USDC to CrossChainArbitrage contract
    const allowance = await usdc.allowance(userAddress, CROSS_CHAIN_ARB);
    
    if (allowance < amount) {
      console.log("Approving USDC to CrossChainArbitrage contract...");
      const approveTx = await usdc.approve(CROSS_CHAIN_ARB, amount);
      await approveTx.wait();
      console.log("✅ USDC approved!");
    }
    
    // Step 2: Call bridgeUSDC on the contract
    console.log(`Bridging ${amountInDollars} USDC to ${toChain}...`);
    const bridgeTx = await crossChainArb.bridgeUSDC(
      toChain,           // "Ethereum", "Arbitrum", "Base", "Optimism"
      amount,            // Amount in wei (6 decimals)
      recipientAddress   // Address to receive USDC on destination chain
    );
    
    const receipt = await bridgeTx.wait();
    console.log("✅ Bridge successful! Transaction:", receipt.hash);
    
    return receipt;
  } catch (error) {
    console.error("❌ Bridge failed:", error);
    throw error;
  }
}
```

---

## 📝 Complete Example

### React Component Example

```javascript
import { useState } from 'react';
import { ethers } from 'ethers';

function BridgeComponent({ signer, crossChainArb, usdc }) {
  const [toChain, setToChain] = useState("Ethereum");
  const [amount, setAmount] = useState("");
  const [recipient, setRecipient] = useState("");
  const [isBridging, setIsBridging] = useState(false);

  const handleBridge = async () => {
    if (!amount || !recipient) {
      alert("Please enter amount and recipient address");
      return;
    }

    setIsBridging(true);
    try {
      const userAddress = await signer.getAddress();
      const amountWei = ethers.parseUnits(amount, 6); // USDC has 6 decimals
      
      // Step 1: Approve USDC
      const allowance = await usdc.allowance(userAddress, crossChainArb.target);
      if (allowance < amountWei) {
        const approveTx = await usdc.approve(crossChainArb.target, amountWei);
        await approveTx.wait();
        console.log("Approval confirmed");
      }
      
      // Step 2: Bridge
      const bridgeTx = await crossChainArb.bridgeUSDC(toChain, amountWei, recipient);
      const receipt = await bridgeTx.wait();
      
      alert(`Bridge successful! TX: ${receipt.hash}`);
    } catch (error) {
      console.error("Bridge error:", error);
      alert(`Bridge failed: ${error.message}`);
    } finally {
      setIsBridging(false);
    }
  };

  return (
    <div className="bridge-form">
      <h3>Bridge USDC</h3>
      
      <select value={toChain} onChange={(e) => setToChain(e.target.value)}>
        <option value="Ethereum">Ethereum</option>
        <option value="Arbitrum">Arbitrum</option>
        <option value="Base">Base</option>
        <option value="Optimism">Optimism</option>
      </select>
      
      <input
        type="number"
        placeholder="Amount (USDC)"
        value={amount}
        onChange={(e) => setAmount(e.target.value)}
      />
      
      <input
        type="text"
        placeholder="Recipient Address"
        value={recipient}
        onChange={(e) => setRecipient(e.target.value)}
      />
      
      <button onClick={handleBridge} disabled={isBridging}>
        {isBridging ? "Bridging..." : "Bridge USDC"}
      </button>
    </div>
  );
}
```

---

## 🔑 Key Points

### 1. Approval Target Changed

**Before:** Approve to TokenMessenger  
**Now:** Approve to **CrossChainArbitrage contract**

```javascript
// ✅ Correct
await usdc.approve(crossChainArbAddress, amount);

// ❌ Wrong (don't approve to TokenMessenger anymore)
await usdc.approve(tokenMessengerAddress, amount);
```

### 2. Function Call Changed

**Before:** `tokenMessenger.depositForBurn(...)`  
**Now:** `crossChainArb.bridgeUSDC(toChain, amount, recipient)`

### 3. Parameters Simplified

**Before:** Need domain ID, bytes32 recipient, etc.  
**Now:** Just chain name, amount, and address

```javascript
// ✅ Simple - just use chain name
await crossChainArb.bridgeUSDC("Ethereum", amount, recipientAddress);

// ❌ No need for domain IDs, bytes32 conversion, etc.
```

### 4. Event Listening

Listen to the contract's events:

```javascript
// Listen for cross-chain moves
crossChainArb.on("CrossChainMove", (fromChain, toChain, amount, timestamp) => {
  console.log(`Bridged ${ethers.formatUnits(amount, 6)} USDC from ${fromChain} to ${toChain}`);
  // Update UI
});
```

---

## 🔄 Migration Checklist

- [ ] Remove all direct CCTP `depositForBurn()` calls
- [ ] Remove TokenMessenger imports/instances (optional - can keep for reference)
- [ ] Update USDC approval to approve to `CrossChainArbitrage` contract
- [ ] Replace CCTP calls with `crossChainArb.bridgeUSDC()`
- [ ] Update event listeners to listen to contract events
- [ ] Test with small amounts first
- [ ] Update error handling

---

## 📊 Function Signature

```solidity
function bridgeUSDC(
    string calldata toChain,      // "Ethereum", "Arbitrum", "Base", "Optimism"
    uint256 amount,               // Amount in USDC (6 decimals)
    address recipient             // Address to receive on destination chain
) external returns (uint64 nonce)
```

**Returns:** `uint64 nonce` - The burn message nonce from CCTP

---

## ⚠️ Important Notes

### Decimals
- **USDC uses 6 decimals** (not 18!)
- Always use `ethers.parseUnits(amount, 6)`
- Always use `ethers.formatUnits(amount, 6)` to display

### Approval Flow
1. Check allowance: `await usdc.allowance(userAddress, crossChainArbAddress)`
2. If insufficient, approve: `await usdc.approve(crossChainArbAddress, amount)`
3. Wait for approval: `await approveTx.wait()`
4. Then bridge: `await crossChainArb.bridgeUSDC(...)`

### Supported Chains
- "Arc" (current chain)
- "Ethereum"
- "Arbitrum"
- "Base"
- "Optimism"

### Recipient Address
- Must be a valid address on the destination chain
- Contract converts it to bytes32 internally
- Should be the address that will receive the USDC

---

## 🐛 Common Errors & Fixes

### Error: "USDC transfer failed"
**Cause:** User hasn't approved USDC to CrossChainArbitrage contract  
**Fix:** Call `usdc.approve(crossChainArbAddress, amount)` first

### Error: "Invalid destination domain"
**Cause:** Chain name not supported  
**Fix:** Use exact chain names: "Ethereum", "Arbitrum", "Base", "Optimism"

### Error: "Insufficient balance"
**Cause:** User doesn't have enough USDC  
**Fix:** Check balance and ensure user has USDC + gas fees

### Transaction Fails
**Cause:** CCTP might not be configured or recipient invalid  
**Fix:** Verify recipient address is valid on destination chain

---

## 💡 Benefits of Using Contract Function

✅ **Centralized Logic** - All bridging logic in one place  
✅ **State Management** - Contract automatically updates `activeChain`  
✅ **Event Emissions** - Contract emits `CrossChainMove` events  
✅ **Easier Tracking** - All bridges go through contract  
✅ **Simpler Frontend** - No need to handle CCTP complexity  
✅ **Better UX** - Frontend just calls one function  

---

## 🚀 Quick Start

1. **Remove** direct CCTP calls
2. **Update** approval to approve to `CrossChainArbitrage` contract
3. **Replace** CCTP calls with `bridgeUSDC()`
4. **Test** with small amounts
5. **Listen** to contract events for updates

---

## 📞 Support

If you encounter issues:
1. Check that USDC is approved to the contract
2. Verify chain name is correct (case-sensitive)
3. Ensure recipient address is valid
4. Check user has enough USDC + gas
5. Verify contract is deployed with correct CCTP addresses

---

**That's it! The contract now handles all CCTP complexity for you.** 🎉

