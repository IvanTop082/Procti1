# Deploy to Arc Testnet - Step by Step

## ⚠️ Important: Arc Uses USDC for Gas!

Arc testnet uses **USDC as the native gas token** (not ETH). Make sure you have test USDC first!

---

## Step 1: Get Test USDC

1. Visit: **https://faucet.circle.com**
2. Connect your wallet
3. Request test USDC
4. Wait for it to arrive in your wallet

---

## Step 2: Set Your Private Key

**⚠️ SECURITY WARNING: Never share your private key!**

In PowerShell, set your private key (this is temporary for this session only):

```powershell
$env:PRIVATE_KEY="0xYourPrivateKeyHere"
```

**Or use a .env file** (more secure):
1. Create a `.env` file in the project root
2. Add: `PRIVATE_KEY=0xYourPrivateKeyHere`
3. Never commit this file to git!

---

## Step 3: Deploy Mock USDC

First, we need a USDC token address. Let's deploy a mock USDC:

```powershell
$env:PATH += ";$env:USERPROFILE\.foundry\bin"
$env:PRIVATE_KEY="your_private_key_here"

forge script script/DeployMockUSDC.s.sol:DeployMockUSDC `
  --rpc-url https://rpc.testnet.arc.network `
  --broadcast
```

**Copy the MockUSDC address** from the output (look for "MockUSDC deployed at: 0x...")

---

## Step 4: Deploy Procti Contracts

Now deploy the main contracts:

```powershell
$env:USDC_ADDRESS="0x..."  # Paste MockUSDC address from Step 3

forge script script/Deploy.s.sol:Deploy `
  --rpc-url https://rpc.testnet.arc.network `
  --broadcast
```

---

## Step 5: Save Contract Addresses

After deployment, you'll see:
```
SafePool deployed at: 0x...
YieldPool deployed at: 0x...
OracleFeed deployed at: 0x...
SentinelVault deployed at: 0x...
```

**Fill these in `CONTRACT_ADDRESSES.md`**

---

## Step 6: Verify on Block Explorer

1. Visit: **https://testnet.arcscan.app**
2. Search for your contract addresses
3. Verify they're deployed correctly

---

## Step 7: Share with Your Friend

Send your friend:
1. ✅ `CONTRACT_ADDRESSES.md` (with addresses filled in)
2. ✅ `/abi` folder (all JSON files)
3. ✅ Network info:
   - Network: Arc Testnet
   - RPC URL: `https://rpc.testnet.arc.network`
   - Block Explorer: `https://testnet.arcscan.app`
4. ✅ `FRONTEND_INTEGRATION.md` (integration guide)

---

## Quick Deploy Script

Or use the automated script:

```powershell
.\deploy-arc.ps1
```

This will deploy MockUSDC first, then the main contracts automatically.

---

## Troubleshooting

**"Insufficient funds" error:**
- Get more test USDC from https://faucet.circle.com
- Make sure you have USDC (not ETH) in your wallet

**"Network error":**
- Check your internet connection
- Try again - network might be busy
- Verify RPC URL: `https://rpc.testnet.arc.network`

**"Private key not set":**
- Make sure you set `$env:PRIVATE_KEY` before running commands
- Or use the `.env` file method

---

## Ready to Deploy?

Once you have:
- ✅ Test USDC in your wallet
- ✅ Private key set
- ✅ Ready to deploy

Run the commands above or use `.\deploy-arc.ps1`

