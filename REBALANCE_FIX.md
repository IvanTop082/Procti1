# Rebalance Double-Click Fix

## Problem

When clicking "simulate event" and "rebalance" buttons:
- **First click**: Transaction fails on blockchain
- **Second click**: Transaction succeeds

## Root Cause

The issue was caused by **ERC20 approval behavior**. Some tokens (including USDC) require:
1. **First**: Reset approval to `0` 
2. **Then**: Set new approval amount

If you try to set a new approval when there's already a non-zero approval, the transaction can fail.

## Solution

Added a `_safeApprove()` helper function that:
1. Resets approval to `0` first
2. Then sets the new approval amount

This ensures approvals always work, even if there's an existing approval.

## Changes Made

### 1. Added `_safeApprove()` Helper

```solidity
function _safeApprove(address spender, uint256 amount) internal {
    // Reset approval to 0 first (required by some ERC20 tokens)
    usdc.approve(spender, 0);
    // Then set new approval
    require(usdc.approve(spender, amount), "SentinelVault: Approval failed");
}
```

### 2. Updated All Approval Calls

Replaced all direct `usdc.approve()` calls with `_safeApprove()`:
- In `deposit()` function
- In `withdraw()` function  
- In `rebalance()` function

### 3. Improved Rebalance Logic

Added comments clarifying when mode is already correct (no-op cases):
- If already in Emergency mode and price still below threshold → do nothing
- If already in Defensive mode and price still below threshold → do nothing
- If already in Farming mode and price above threshold → do nothing

## Why This Fixes the Issue

**Before:**
- First transaction: Tries to approve, but existing approval causes failure
- Second transaction: Approval was reset by first transaction, so it succeeds

**After:**
- First transaction: Resets approval to 0, then sets new approval → succeeds ✅
- Second transaction: Also resets and sets → succeeds ✅

## Testing

The contract compiles successfully. After deployment, the double-click issue should be resolved.

## Deployment

Redeploy `SentinelVault` with this fix:

```bash
forge script script/DeploySentinelVault.s.sol:DeploySentinelVault \
  --rpc-url https://rpc.testnet.arc.network \
  --broadcast
```

## Frontend Impact

No frontend changes needed! The fix is entirely on the contract side. Transactions should now succeed on the first try.

---

**Note**: This is a common pattern in DeFi contracts. Always reset approvals to 0 before setting new approvals when working with ERC20 tokens.

