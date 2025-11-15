# Contract Redeployment Instructions

## Current Status

The verification script shows:
- **Current Contract:** `0x7A612459095bBe3F579068CDE982aa91C57919A6`
- **Ethereum Sepolia Domain:** 0 (needs to be 11155111)
- **Supported Chains:** Still has "Ethereum" instead of "Ethereum Sepolia"

## Deployment Steps

### 1. Ensure You Have Funds

You need Arc testnet ETH for gas fees. The deployment failed with:
```
insufficient funds for gas * price + value: have 0 want 1170251988948814680
```

**Get testnet ETH:**
- Arc testnet faucet (if available)
- Or transfer from another account

### 2. Set Environment Variables

```powershell
$env:PRIVATE_KEY="your_private_key_here"
$env:USDC_ADDRESS="0x3600000000000000000000000000000000000000"
$env:TOKEN_MESSENGER_ADDRESS="0x8FE6B999Dc680CcFDD5Bf7EB0974218be2542DAA"
```

### 3. Deploy the Contract

```powershell
$env:PATH += ";$env:USERPROFILE\.foundry\bin"
forge script script/DeployCrossChainArbitrage.s.sol:DeployCrossChainArbitrage `
  --rpc-url https://rpc.testnet.arc.network `
  --broadcast `
  -vvv
```

### 4. Update Contract Address

After deployment, update `procti/config/contracts.ts`:

```typescript
crossChainArb: {
  address: "0x...NEW_ADDRESS...", // Replace with new deployed address
  abi: CrossChainArbitrageABI.abi,
},
```

### 5. Verify Domain Mapping

Run the verification script:

```powershell
forge script script/VerifyDomainMapping.s.sol:VerifyDomainMapping `
  --rpc-url https://rpc.testnet.arc.network
```

**Expected Output:**
```
Ethereum Sepolia domain: 11155111
[OK] Ethereum Sepolia domain correct (11155111)
[OK] Contract is up to date with Ethereum Sepolia domain
```

### 6. Test Bridging

Once deployed and verified:
1. Open the frontend
2. Connect wallet to Arc testnet
3. Ensure you have USDC approved to the new contract
4. Try bridging to "Ethereum Sepolia"
5. Monitor the transaction

## What Changed

The new contract will have:
- ✅ `chainDomains["Ethereum Sepolia"] = 11155111` (instead of 0)
- ✅ `supportedChains` includes "Ethereum Sepolia" (instead of "Ethereum")
- ✅ No special handling for domain 0

## Verification Commands

**Check domain:**
```powershell
forge script script/VerifyDomainMapping.s.sol:VerifyDomainMapping --rpc-url https://rpc.testnet.arc.network
```

**Test bridge readiness:**
```powershell
forge script script/TestBridgeToSepolia.s.sol:TestBridgeToSepolia --rpc-url https://rpc.testnet.arc.network
```

## After Deployment

1. ✅ Update frontend contract address
2. ✅ Verify domain mapping returns 11155111
3. ✅ Test bridging from Arc to Ethereum Sepolia
4. ✅ Monitor for any errors

