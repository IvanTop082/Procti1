# Deployment Guide

## Current Status: ⚠️ NOT DEPLOYED

The contracts are **compiled and tested locally** but **NOT yet deployed to any blockchain**.

To make them accessible from your friend's frontend, you need to deploy them to a blockchain network.

---

## Quick Deployment Options

### Option 1: Local Network (For Testing Only)
**Best for:** Quick testing between you and your friend on the same network

1. **Start Anvil** (local blockchain):
   ```powershell
   $env:PATH += ";$env:USERPROFILE\.foundry\bin"
   anvil
   ```
   This will show you:
   - RPC URL: `http://127.0.0.1:8545`
   - Private keys for testing accounts

2. **Deploy contracts** (in a new terminal):
   ```powershell
   $env:PATH += ";$env:USERPROFILE\.foundry\bin"
   $env:PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"  # First Anvil account
   $env:USDC_ADDRESS="0x..."  # You'll need a mock USDC address
   
   forge script script/Deploy.s.sol:Deploy --rpc-url http://127.0.0.1:8545 --broadcast
   ```

3. **Share the contract addresses** with your friend
4. **Your friend needs to connect to the same Anvil instance** (same RPC URL)

**⚠️ Limitation:** Both computers must be on the same network or use port forwarding.

---

### Option 2: Testnet (Recommended for Hackathon)
**Best for:** Real blockchain deployment that anyone can access

#### Popular Testnets:
- **Sepolia** (Ethereum testnet)
- **Base Sepolia** (Base testnet - lower fees)
- **Arbitrum Sepolia** (Arbitrum testnet)

#### Steps:

1. **Get testnet ETH/USDC:**
   - Get testnet ETH from a faucet (for gas fees)
   - Get testnet USDC or deploy a mock USDC

2. **Get an RPC URL:**
   - Free options: Alchemy, Infura, QuickNode
   - Or use public RPC (slower but free)

3. **Deploy:**
   ```powershell
   $env:PATH += ";$env:USERPROFILE\.foundry\bin"
   $env:PRIVATE_KEY="your_private_key_here"
   $env:USDC_ADDRESS="testnet_usdc_address"
   
   # For Sepolia
   forge script script/Deploy.s.sol:Deploy --rpc-url https://sepolia.infura.io/v3/YOUR_KEY --broadcast --verify
   ```

4. **After deployment, save the addresses** (see `CONTRACT_ADDRESSES.md`)

---

### Option 3: Mainnet (Production)
**⚠️ Only for final production deployment - costs real money!**

---

## What Your Friend Needs

After deployment, share these with your friend:

1. **Contract Addresses** (see `CONTRACT_ADDRESSES.md` template)
2. **Network/Chain ID** (e.g., Sepolia = 11155111)
3. **RPC URL** (so they can connect to the same network)
4. **ABI Files** (from `/abi` folder - already available)

---

## Deployment Checklist

- [ ] Choose deployment network (Local/Testnet/Mainnet)
- [ ] Get RPC URL for the network
- [ ] Get testnet ETH (if using testnet)
- [ ] Get or deploy USDC token
- [ ] Set environment variables (PRIVATE_KEY, USDC_ADDRESS)
- [ ] Run deployment script
- [ ] Save contract addresses
- [ ] Share addresses + network info with friend
- [ ] Verify contracts on block explorer (optional)

---

## Example Deployment Command

```powershell
# Set Foundry path
$env:PATH += ";$env:USERPROFILE\.foundry\bin"

# Set environment variables
$env:PRIVATE_KEY="0xYourPrivateKeyHere"
$env:USDC_ADDRESS="0xYourUSDCAddressHere"

# Deploy to Sepolia testnet
forge script script/Deploy.s.sol:Deploy `
  --rpc-url https://sepolia.infura.io/v3/YOUR_INFURA_KEY `
  --broadcast `
  --verify `
  --etherscan-api-key YOUR_ETHERSCAN_API_KEY
```

After deployment, you'll see output like:
```
SafePool deployed at: 0x1234...
YieldPool deployed at: 0x5678...
OracleFeed deployed at: 0x9abc...
SentinelVault deployed at: 0xdef0...
```

**Save these addresses!** They're what your friend needs to connect.

