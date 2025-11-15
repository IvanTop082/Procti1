# Real CCTP Integration Guide

## ✅ What's Changed

The `CrossChainArbitrage` contract now supports **real CCTP bridging** in addition to simulated bridging.

### New Features

1. **Real CCTP Integration**
   - Uses Circle's TokenMessengerV2 contract
   - Actually bridges USDC across chains
   - Returns burn message nonce

2. **New Function: `bridgeUSDC()`**
   - Bridges real USDC using CCTP
   - Requires USDC approval first
   - Updates active chain state

3. **Updated Constructor**
   - Now requires USDC and TokenMessenger addresses
   - Sets up real CCTP integration

4. **Backward Compatibility**
   - `simulateBridge()` still works (demo mode)
   - `executeCrossChainMove()` still works (uses simulation)

---

## 📍 Contract Addresses (Arc Testnet)

### CCTP Contracts
- **TokenMessengerV2:** `0x8FE6B999Dc680CcFDD5Bf7EB0974218be2542DAA`
- **USDC:** `0x3600000000000000000000000000000000000000`

### Domain IDs
- **Arc:** 26
- **Ethereum:** 0
- **Arbitrum:** 42161
- **Base:** 8453
- **Optimism:** 10

---

## 🚀 Deployment

### Deploy Updated Contract

```powershell
$env:PATH += ";$env:USERPROFILE\.foundry\bin"
$env:PRIVATE_KEY="your_private_key"
$env:USDC_ADDRESS="0x3600000000000000000000000000000000000000"
$env:TOKEN_MESSENGER_ADDRESS="0x8FE6B999Dc680CcFDD5Bf7EB0974218be2542DAA"

forge script script/DeployCrossChainArbitrage.s.sol:DeployCrossChainArbitrage `
  --rpc-url https://rpc.testnet.arc.network `
  --broadcast
```

---

## 💻 Frontend Integration

### Option 1: Use Real CCTP Bridging (Recommended)

```javascript
import { ethers } from 'ethers';
import CrossChainArbitrageABI from './abi/CrossChainArbitrage.json';

const CROSS_CHAIN_ARB = "0xfe9d856E1f3BA56C462DF56B27b8863f1ff700B9"; // Your deployed address
const USDC_ADDRESS = "0x3600000000000000000000000000000000000000";

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

// Bridge USDC to another chain
async function bridgeUSDC(toChain, amountInDollars, recipientAddress) {
  try {
    const amount = ethers.parseUnits(amountInDollars.toString(), 6); // USDC has 6 decimals
    
    // Step 1: Approve USDC to CrossChainArbitrage contract
    const userAddress = await signer.getAddress();
    const allowance = await usdc.allowance(userAddress, CROSS_CHAIN_ARB);
    
    if (allowance < amount) {
      console.log("Approving USDC...");
      const approveTx = await usdc.approve(CROSS_CHAIN_ARB, amount);
      await approveTx.wait();
      console.log("Approval confirmed!");
    }
    
    // Step 2: Call bridgeUSDC
    console.log(`Bridging ${amountInDollars} USDC to ${toChain}...`);
    const bridgeTx = await crossChainArb.bridgeUSDC(
      toChain,           // e.g., "Ethereum"
      amount,            // Amount in wei (6 decimals)
      recipientAddress   // Address to receive on destination chain
    );
    
    const receipt = await bridgeTx.wait();
    console.log("Bridge successful! Transaction:", receipt.hash);
    
    // Get the nonce from the transaction
    const nonce = await crossChainArb.bridgeUSDC.staticCall(
      toChain,
      amount,
      recipientAddress
    );
    
    return { txHash: receipt.hash, nonce };
  } catch (error) {
    console.error("Bridge failed:", error);
    throw error;
  }
}

// Example usage
await bridgeUSDC("Ethereum", 100, "0x..."); // Bridge 100 USDC to Ethereum
```

### Option 2: Use Simulated Bridging (Demo Mode)

```javascript
// For demo/testing without real bridging
const amount = ethers.parseUnits("100", 6);
await crossChainArb.simulateBridge("Ethereum", amount);
```

---

## 🔑 Key Functions

### `bridgeUSDC(string toChain, uint256 amount, address recipient)`

**Purpose:** Bridge real USDC using CCTP

**Parameters:**
- `toChain` - Target chain name ("Ethereum", "Arbitrum", "Base", "Optimism")
- `amount` - Amount in USDC (6 decimals)
- `recipient` - Address to receive USDC on destination chain

**Returns:** `uint64 nonce` - Burn message nonce

**Requirements:**
- User must approve USDC to CrossChainArbitrage contract first
- User must have sufficient USDC balance
- Chain must be supported

**Example:**
```javascript
const amount = ethers.parseUnits("100", 6); // 100 USDC
const recipient = "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb"; // Destination address
const tx = await crossChainArb.bridgeUSDC("Ethereum", amount, recipient);
```

### `simulateBridge(string toChain, uint256 amount)`

**Purpose:** Simulate bridging (demo only, no real bridging)

**Parameters:**
- `toChain` - Target chain name
- `amount` - Amount (for display only)

**Note:** This doesn't actually bridge - just updates state and emits events.

---

## ⚠️ Important Notes

### USDC Approval Flow

**CRITICAL:** Users must approve USDC before bridging:

```javascript
// 1. Check current allowance
const allowance = await usdc.allowance(userAddress, crossChainArbAddress);

// 2. Approve if needed
if (allowance < amount) {
  await usdc.approve(crossChainArbAddress, amount);
  await approveTx.wait(); // Wait for confirmation!
}

// 3. Then bridge
await crossChainArb.bridgeUSDC(toChain, amount, recipient);
```

### Decimals

- **USDC uses 6 decimals** (not 18!)
- Always use `ethers.parseUnits(amount, 6)` for USDC
- Always use `ethers.formatUnits(amount, 6)` to display

### Recipient Address

- Must be a valid address on the destination chain
- Will be converted to bytes32 format internally
- Should be the address that will receive the USDC

### Gas Costs

- Real CCTP bridging costs gas (paid in USDC on Arc)
- Approval transaction: ~45k gas
- Bridge transaction: ~150k+ gas
- Make sure user has enough USDC for gas!

---

## 🔄 Migration from Frontend CCTP Calls

### Before (Frontend calling CCTP directly):

```javascript
// ❌ Old way - calling CCTP directly from frontend
await tokenMessenger.depositForBurn(
  amount,
  destinationDomain,
  mintRecipient,
  usdcAddress
);
```

### After (Using our contract):

```javascript
// ✅ New way - using our contract
// 1. Approve USDC to CrossChainArbitrage
await usdc.approve(crossChainArbAddress, amount);

// 2. Call bridgeUSDC
await crossChainArb.bridgeUSDC("Ethereum", amount, recipientAddress);
```

**Benefits:**
- ✅ Centralized logic in contract
- ✅ Automatic state updates (activeChain)
- ✅ Event emissions for frontend
- ✅ Easier to track and manage

---

## 📊 Event Listening

Listen for cross-chain moves:

```javascript
crossChainArb.on("CrossChainMove", (fromChain, toChain, amount, timestamp) => {
  console.log(`Bridged ${ethers.formatUnits(amount, 6)} USDC from ${fromChain} to ${toChain}`);
  // Update UI
});
```

---

## 🐛 Troubleshooting

### Error: "USDC transfer failed"
- **Cause:** User hasn't approved USDC to contract
- **Fix:** Call `usdc.approve(crossChainArbAddress, amount)` first

### Error: "Invalid destination domain"
- **Cause:** Chain name not supported or domain not set
- **Fix:** Use one of: "Arc", "Ethereum", "Arbitrum", "Base", "Optimism"

### Error: "Insufficient balance"
- **Cause:** User doesn't have enough USDC
- **Fix:** Check user balance and ensure they have USDC + gas fees

### Transaction Fails with Empty Revert
- **Cause:** CCTP contract might not be properly configured
- **Fix:** Verify TokenMessenger address is correct for your network

---

## ✅ Summary

1. **Deploy** updated CrossChainArbitrage with USDC and TokenMessenger addresses
2. **Approve** USDC to the contract before bridging
3. **Call** `bridgeUSDC()` with chain name, amount, and recipient
4. **Listen** to `CrossChainMove` events for updates
5. **Use** `simulateBridge()` for demos without real bridging

The contract now supports both real CCTP bridging and simulated bridging, giving you flexibility for demos and production! 🚀

