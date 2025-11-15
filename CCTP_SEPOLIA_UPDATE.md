# CCTP Update: Ethereum Sepolia Testnet

## ✅ Changes Applied

### Backend Contract Updates (`src/CrossChainArbitrage.sol`)

1. **Chain Name Updated:**
   - Changed: `"Ethereum"` → `"Ethereum Sepolia"`
   - Updated in: `supportedChains` array

2. **Domain ID Updated:**
   - Changed: `chainDomains["Ethereum"] = 0` → `chainDomains["Ethereum Sepolia"] = 11155111`
   - Removed special handling for domain 0 (Ethereum mainnet)

3. **Default Values Updated:**
   - `chainPrices["Ethereum Sepolia"] = 1e18`
   - `chainYields["Ethereum Sepolia"] = 0.05e18`
   - `chainRiskScores["Ethereum Sepolia"] = 50`

4. **Domain Validation:**
   - Removed special case for Ethereum domain 0
   - Now requires all domains to be non-zero

### Frontend Updates

1. **`procti/hooks/useCCTP.ts`:**
   - Updated `isCCTPAvailable()` to check for "Ethereum Sepolia"
   - Removed domain 0 validation logic
   - Updated error messages to reference Ethereum Sepolia (11155111)

2. **`procti/components/SimulatedBridge.tsx`:**
   - Updated dropdown to show only testnet chains
   - Removed mainnet chains from CCTP supported list
   - Updated error messages

3. **`procti/components/ArbitrageDetector.tsx`:**
   - Default chain B changed to "Ethereum Sepolia"
   - Updated available chains list

4. **`procti/components/ChainDataManager.tsx`:**
   - Updated available chains list

5. **`src/SentinelVault.sol`:**
   - Updated `getUnifiedVaultBalance()` fallback to use "Ethereum Sepolia"

## 📋 CCTP Contract Addresses

### Arc Testnet (Source Chain)
- **USDC:** `0x3600000000000000000000000000000000000000`
- **TokenMessenger:** `0x8FE6B999Dc680CcFDD5Bf7EB0974218be2542DAA`
- **Domain:** 26

### Ethereum Sepolia (Destination Chain)
- **Domain:** 11155111
- **Note:** TokenMessenger and USDC addresses on Sepolia are handled by Circle's CCTP infrastructure

## 🎯 What This Fixes

1. **Removes Mainnet References:** No more attempts to bridge to Ethereum mainnet (domain 0)
2. **Uses Testnet Domain:** Now uses Ethereum Sepolia domain 11155111
3. **Proper Testnet-to-Testnet:** Arc testnet → Ethereum Sepolia testnet bridging
4. **Better Error Messages:** All errors now reference Sepolia instead of mainnet

## ⚠️ Important Notes

- **Arc Testnet Addresses Stay the Same:** The TokenMessenger and USDC addresses on Arc testnet remain unchanged
- **Contract Needs Redeployment:** The backend contract changes require redeployment to take effect
- **Frontend Works Immediately:** Frontend changes work with the current deployed contract, but will work better after contract redeployment

## 🚀 Next Steps

1. **Redeploy Contract:** Deploy the updated `CrossChainArbitrage.sol` with Ethereum Sepolia domain
2. **Test Bridging:** Try bridging from Arc testnet to Ethereum Sepolia
3. **Verify Domain:** Ensure the contract's `chainDomains["Ethereum Sepolia"]` returns 11155111

## 📚 References

- Ethereum Sepolia Domain: 11155111
- Arc Testnet Domain: 26
- Circle CCTP Docs: https://developers.circle.com/stablecoins/docs/cctp-contracts

