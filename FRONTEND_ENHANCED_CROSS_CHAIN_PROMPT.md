# Frontend Implementation Prompt: Enhanced Cross-Chain Features Section

## 🎯 Your Mission

Implement the **"Enhanced Cross-Chain Features"** section of the Procti dashboard. This section displays active chain status, smart cross-chain checks, simulated bridging, movement history, and decision logs in a clean, organized grid layout.

---

## 📋 What Already Exists

The following components and hooks are **already built** and working:

### Components (Already Created)
- ✅ `ActiveChainDisplay.tsx` - Shows current and best chain
- ✅ `SmartCrossChainChecker.tsx` - Button to check cross-chain opportunities
- ✅ `SimulatedBridge.tsx` - Form for simulating cross-chain transfers
- ✅ `CrossChainMoveVisualizer.tsx` - Displays movement history
- ✅ `CrossChainDecisionLog.tsx` - Displays decision history

### Hooks (Already Created)
- ✅ `useCrossChainArb.ts` - Hook for interacting with CrossChainArbitrage contract
- ✅ `useSimulateBridge.ts` - Hook for simulating bridges
- ✅ `useVault.ts` - Hook for vault operations

### Contracts (Already Deployed)
- ✅ `CrossChainArbitrage` at `0x7A612459095bBe3F579068CDE982aa91C57919A6`
- ✅ `SentinelVault` at `0xDf9053726a2217326bFEadc0c3480c5De7107B8f`

---

## 🐛 Issues to Fix

### 1. Event Parameter Mismatch in CrossChainMoveVisualizer

**Problem:** The contract emits `fromChain` and `toChain`, but the component is looking for `sourceChain` and `destChain`.

**Location:** `procti/components/CrossChainMoveVisualizer.tsx`

**Fix:** Update the event ABI and decoding logic:

```typescript
// Current (WRONG):
const CROSS_CHAIN_MOVE_EVENT_ABI = {
  type: "event",
  name: "CrossChainMove",
  inputs: [
    { name: "sourceChain", type: "string", indexed: false },  // ❌ Wrong
    { name: "destChain", type: "string", indexed: false },     // ❌ Wrong
    // ...
  ],
} as const;

// Should be (CORRECT):
const CROSS_CHAIN_MOVE_EVENT_ABI = {
  type: "event",
  name: "CrossChainMove",
  inputs: [
    { name: "fromChain", type: "string", indexed: false },     // ✅ Correct
    { name: "toChain", type: "string", indexed: false },       // ✅ Correct
    { name: "amount", type: "uint256", indexed: false },
    { name: "timestamp", type: "uint256", indexed: false },
  ],
} as const;

// Also update the decoding:
return {
  from: (decoded.args as any).fromChain || "",    // ✅ Changed from sourceChain
  to: (decoded.args as any).toChain || "",        // ✅ Changed from destChain
  // ...
};
```

---

## 🎨 Expected UI Layout

Based on the design, the section should be organized as follows:

```
┌─────────────────────────────────────────────────────────────┐
│ Enhanced Cross-Chain Features                               │
├──────────────────────┬──────────────────────────────────────┤
│ Active Chain         │ Smart Cross-Chain Check              │
│                      │                                      │
│ Current: Ethereum    │ [Check Cross-Chain Opportunities]   │
│ Best Chain: Ethereum │                                      │
│                      │                                      │
│ ✓ Optimal Chain      │                                      │
│   Selected           │                                      │
├──────────────────────┴──────────────────────────────────────┤
│ Cross-Chain Bridge (Simulated)                              │
│                                                              │
│ From Chain: [Ethereum ▼]                                    │
│ To Chain: [Select destination... ▼]                         │
│ Amount: [100]                                               │
│ Bridge Fee: [0.1]                                           │
│                                                              │
│ [Simulate Bridge USDC from Ethereum to ...]                 │
├──────────────────────┬──────────────────────────────────────┤
│ Cross-Chain Movements│ Cross-Chain Decisions                │
│                      │                                      │
│ No movements yet     │ No decisions yet                     │
│                      │                                      │
└──────────────────────┴──────────────────────────────────────┘
```

---

## 📝 Implementation Steps

### Step 1: Fix the Event Parameter Mismatch

1. Open `procti/components/CrossChainMoveVisualizer.tsx`
2. Update the `CROSS_CHAIN_MOVE_EVENT_ABI` to use `fromChain` and `toChain` instead of `sourceChain` and `destChain`
3. Update the decoding logic to match
4. Test that movements appear correctly after a bridge

### Step 2: Verify Component Integration

The components are already imported in `procti/app/page.tsx`:

```typescript
// Line 129-143 in page.tsx
<div className="border-t border-gray-200 pt-12">
  <h2 className="text-2xl font-medium text-gray-900 mb-6">Enhanced Cross-Chain Features</h2>
  <div className="space-y-6">
    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
      <ActiveChainDisplay />
      <SmartCrossChainChecker />
    </div>
    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
      <SimulatedBridge />
      <CrossChainMoveVisualizer />
    </div>
    <CrossChainDecisionLog />
  </div>
</div>
```

**Verify:**
- All components are rendering
- Grid layout is correct (2 columns on desktop, 1 column on mobile)
- Components are properly spaced

### Step 3: Test the Full Flow

1. **Test Active Chain Display:**
   - Connect wallet
   - Verify "Current" and "Best Chain" are displayed
   - If they match, verify "✓ Optimal Chain Selected" appears

2. **Test Smart Cross-Chain Check:**
   - Click "Check Cross-Chain Opportunities" button
   - Wait for transaction to complete
   - Verify a decision appears in the "Cross-Chain Decisions" log

3. **Test Simulated Bridge:**
   - Select a "From Chain" (e.g., Ethereum)
   - Select a "To Chain" (e.g., Arbitrum)
   - Enter an amount (e.g., 1.0)
   - Click "Simulate Bridge"
   - Approve transaction in wallet
   - Verify a movement appears in "Cross-Chain Movements"

4. **Test Event Listening:**
   - After bridging, verify the movement appears in real-time
   - After checking opportunities, verify the decision appears in real-time
   - Verify timestamps are displayed correctly

---

## 🔧 Technical Details

### Contract Events

#### CrossChainMove Event
**Emitted by:** `CrossChainArbitrage.simulateBridge()`

```solidity
event CrossChainMove(
    string fromChain,
    string toChain,
    uint256 amount,
    uint256 timestamp
);
```

**How to Listen:**
```typescript
// Using viem's getLogs (already implemented in CrossChainMoveVisualizer)
const logs = await publicClient.getLogs({
  address: contractsConfig.crossChainArb.address,
  event: CROSS_CHAIN_MOVE_EVENT_ABI,
  fromBlock: currentBlock - 1000n,
  toBlock: "latest",
});
```

#### CrossChainDecision Event
**Emitted by:** `SentinelVault.checkForCrossChainOpportunities()` or `CrossChainArbitrage.switchToBestChain()`

```solidity
event CrossChainDecision(
    string selectedChain,
    uint256 price,
    uint256 timestamp,
    string reason
);
```

**How to Listen:**
```typescript
// Using viem's getLogs (already implemented in CrossChainDecisionLog)
const logs = await publicClient.getLogs({
  address: contractsConfig.vault.address,  // Note: from SentinelVault, not CrossChainArbitrage
  event: CROSS_CHAIN_DECISION_EVENT_ABI,
  fromBlock: currentBlock - 1000n,
  toBlock: "latest",
});
```

### Supported Chains

The following chains are supported:
- `"Arc"`
- `"Ethereum"`
- `"Arbitrum"`
- `"Base"`
- `"Optimism"`

**Important:** Do NOT use "Ethereum Sepolia" or any testnet-specific names. Only use the 5 chains listed above.

### Contract Functions

#### `simulateBridge(string toChain, uint256 amount)`
- Simulates moving USDC from the active chain to `toChain`
- Updates `activeChain` to `toChain`
- Emits `CrossChainMove` event
- **No real bridging** - this is simulation only

#### `switchToBestChain()`
- Switches the active chain to the best chain (as computed by `bestChain()`)
- Emits `CrossChainDecision` event from `CrossChainArbitrage`

#### `checkForCrossChainOpportunities()`
- Called on `SentinelVault` (not `CrossChainArbitrage`)
- Checks for opportunities while respecting risk profile
- May emit `CrossChainDecision` event from `SentinelVault`

---

## 🎨 Styling Guidelines

All components should follow the existing design system:

- **Card Background:** `bg-white`
- **Border:** `border border-gray-200`
- **Border Radius:** `rounded-sm`
- **Padding:** `p-5`
- **Heading:** `text-lg font-medium text-gray-900 mb-4`
- **Button Primary:** `bg-blue-600 text-white rounded-sm hover:bg-blue-700`
- **Button Disabled:** `disabled:bg-gray-400 disabled:cursor-not-allowed`
- **Text Secondary:** `text-sm text-gray-500`
- **Grid Layout:** `grid grid-cols-1 md:grid-cols-2 gap-6`

---

## ✅ Checklist

- [ ] Fix `CrossChainMoveVisualizer.tsx` event parameter names
- [ ] Verify all 5 components render correctly
- [ ] Test Active Chain display shows current and best chain
- [ ] Test Smart Cross-Chain Check button works
- [ ] Test Simulated Bridge form works end-to-end
- [ ] Test Cross-Chain Movements log displays movements
- [ ] Test Cross-Chain Decisions log displays decisions
- [ ] Verify grid layout is responsive (2 columns desktop, 1 column mobile)
- [ ] Verify event listeners update UI in real-time
- [ ] Test with different chain combinations
- [ ] Verify error handling (e.g., insufficient balance, invalid chain)

---

## 🐛 Common Issues & Solutions

### Issue: Movements not appearing after bridge
**Solution:** Check that `CrossChainMoveVisualizer.tsx` uses `fromChain` and `toChain` (not `sourceChain`/`destChain`)

### Issue: Decisions not appearing after check
**Solution:** Verify you're listening to events from `SentinelVault` (not `CrossChainArbitrage`) for `CrossChainDecision`

### Issue: "No movements yet" always showing
**Solution:** 
1. Check that `publicClient` and `currentBlock` are available
2. Verify the contract address is correct
3. Check browser console for errors
4. Verify you've actually performed a bridge transaction

### Issue: RPC rate limiting (429 errors)
**Solution:** The components already have retry logic with exponential backoff. If you see 429 errors, the RPC is rate-limited. Wait a few minutes and try again.

---

## 📚 Reference Files

- **Contract ABI:** `procti/abi/CrossChainArbitrage.json`
- **Contract Config:** `procti/config/contracts.ts`
- **Main Page:** `procti/app/page.tsx`
- **Components:**
  - `procti/components/ActiveChainDisplay.tsx`
  - `procti/components/SmartCrossChainChecker.tsx`
  - `procti/components/SimulatedBridge.tsx`
  - `procti/components/CrossChainMoveVisualizer.tsx`
  - `procti/components/CrossChainDecisionLog.tsx`
- **Hooks:**
  - `procti/hooks/useCrossChainArb.ts`
  - `procti/hooks/useSimulateBridge.ts`

---

## 🚀 Quick Start

1. **Fix the event parameter mismatch:**
   ```bash
   # Open and edit:
   procti/components/CrossChainMoveVisualizer.tsx
   ```

2. **Test locally:**
   ```bash
   npm run dev
   ```

3. **Verify the section appears:**
   - Navigate to the "Enhanced Cross-Chain Features" section
   - All 5 components should be visible

4. **Test the flow:**
   - Connect wallet
   - Click "Check Cross-Chain Opportunities"
   - Perform a simulated bridge
   - Verify movements and decisions appear

---

## 💡 Tips

- Use the browser console (F12) to debug event listening
- Check the block explorer for transaction confirmations: https://testnet.arcscan.app
- The components already handle loading states and error states
- Event listeners poll every 60 seconds by default (to avoid rate limiting)

---

**Good luck! The components are already built, you just need to fix the event parameter mismatch and verify everything works together.** 🎉


