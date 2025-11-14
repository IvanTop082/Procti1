# Deploy to Arc Testnet

## Arc Testnet Information

- **Network Name:** Arc Testnet
- **RPC URL:** `https://rpc.testnet.arc.network`
- **Block Explorer:** https://testnet.arcscan.app
- **Native Token:** USDC (used for gas fees)
- **Faucet:** https://faucet.circle.com

---

## Prerequisites

1. **Get Test USDC from Faucet:**
   - Visit: https://faucet.circle.com
   - Get test USDC for gas fees
   - Arc uses USDC as native gas token (not ETH!)

2. **Have a Wallet Ready:**
   - MetaMask or any EVM-compatible wallet
   - Private key for deployment

---

## Deployment Steps

### Step 1: Deploy Mock USDC (if needed)

If you don't have a USDC address on Arc testnet, deploy a mock USDC first:

```powershell
# Set Foundry path
$env:PATH += ";$env:USERPROFILE\.foundry\bin"

# Set your private key (keep this secret!)
$env:PRIVATE_KEY="your_private_key_here"

# Deploy Mock USDC
forge script script/DeployMockUSDC.s.sol:DeployMockUSDC `
  --rpc-url https://rpc.testnet.arc.network `
  --broadcast
```

**Copy the MockUSDC address** from the output.

### Step 2: Deploy Procti Contracts

```powershell
# Set environment variables
$env:PATH += ";$env:USERPROFILE\.foundry\bin"
$env:PRIVATE_KEY="your_private_key_here"
$env:USDC_ADDRESS="0x..."  # MockUSDC address from Step 1, or real USDC address

# Deploy all contracts
forge script script/Deploy.s.sol:Deploy `
  --rpc-url https://rpc.testnet.arc.network `
  --broadcast
```

### Step 3: Save Contract Addresses

After deployment, you'll see output like:
```
SafePool deployed at: 0x1234...
YieldPool deployed at: 0x5678...
OracleFeed deployed at: 0x9abc...
SentinelVault deployed at: 0xdef0...
```

**Fill these in `CONTRACT_ADDRESSES.md`**

---

## Verify Deployment

1. Visit https://testnet.arcscan.app
2. Search for your contract addresses
3. Verify they're deployed correctly

---

## Share with Frontend Developer

Send your friend:
1. **Contract Addresses** (from `CONTRACT_ADDRESSES.md`)
2. **Network Info:**
   - Network: Arc Testnet
   - RPC URL: `https://rpc.testnet.arc.network`
   - Chain ID: (check block explorer or network docs)
3. **ABI Files** (from `/abi` folder)
4. **`FRONTEND_INTEGRATION.md`** (integration guide)

---

## Important Notes

⚠️ **Arc uses USDC for gas fees** (not ETH!)
- Make sure you have test USDC from the faucet
- Gas fees are paid in USDC

⚠️ **Keep your private key secret!**
- Never share your private key
- Only share contract addresses

✅ **Testnet is free to use**
- No real money needed
- Perfect for hackathon demos

---

## Troubleshooting

**Error: Insufficient funds**
- Get more test USDC from faucet: https://faucet.circle.com

**Error: Network connection**
- Check RPC URL is correct: `https://rpc.testnet.arc.network`
- Try again, network might be busy

**Contracts not showing on explorer**
- Wait a few minutes for indexing
- Check transaction hash on explorer

