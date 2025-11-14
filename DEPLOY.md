# Quick Deployment Steps

## Current Status: ❌ NOT DEPLOYED

The contracts are ready but need to be deployed to a blockchain.

---

## Fastest Option: Local Anvil (For Testing)

### Step 1: Start Local Blockchain
```powershell
$env:PATH += ";$env:USERPROFILE\.foundry\bin"
anvil
```

**Keep this terminal open!** It will show:
- RPC URL: `http://127.0.0.1:8545`
- Test accounts with private keys

### Step 2: Deploy Mock USDC (if needed)
```powershell
# In a NEW terminal
$env:PATH += ";$env:USERPROFILE\.foundry\bin"
$env:PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"

forge script script/DeployMockUSDC.s.sol:DeployMockUSDC --rpc-url http://127.0.0.1:8545 --broadcast
```

**Copy the MockUSDC address** from the output.

### Step 3: Deploy Procti Contracts
```powershell
$env:USDC_ADDRESS="0x..."  # Paste MockUSDC address from Step 2

forge script script/Deploy.s.sol:Deploy --rpc-url http://127.0.0.1:8545 --broadcast
```

### Step 4: Save Contract Addresses
Copy all addresses from the output and fill in `CONTRACT_ADDRESSES.md`

### Step 5: Share with Friend
Send your friend:
1. `CONTRACT_ADDRESSES.md` (with addresses filled in)
2. `/abi` folder (all JSON files)
3. RPC URL: `http://127.0.0.1:8545` (they need to connect to YOUR Anvil instance)
4. `FRONTEND_INTEGRATION.md` (integration guide)

---

## Testnet Deployment (Recommended for Hackathon)

### For Sepolia Testnet:

1. **Get testnet ETH:**
   - Visit: https://sepoliafaucet.com/
   - Get Sepolia ETH for gas fees

2. **Get testnet USDC or deploy mock:**
   - Option A: Use existing testnet USDC
   - Option B: Deploy MockUSDC first

3. **Deploy:**
```powershell
$env:PATH += ";$env:USERPROFILE\.foundry\bin"
$env:PRIVATE_KEY="your_private_key"
$env:USDC_ADDRESS="0x..."  # Testnet USDC address

# Deploy to Sepolia
forge script script/Deploy.s.sol:Deploy `
  --rpc-url https://sepolia.infura.io/v3/YOUR_INFURA_KEY `
  --broadcast
```

4. **Save addresses** in `CONTRACT_ADDRESSES.md`

5. **Share with friend:**
   - Contract addresses
   - Network: Sepolia (Chain ID: 11155111)
   - RPC URL
   - ABIs from `/abi` folder

---

## What Gets Deployed

1. **SafePool** - Safe storage vault
2. **YieldPool** - Yield generation vault  
3. **OracleFeed** - Price oracle
4. **SentinelVault** - Main contract (frontend uses this)

**Total: 4 contracts**

---

## After Deployment

✅ Fill in `CONTRACT_ADDRESSES.md`  
✅ Share addresses + network info with friend  
✅ Friend can connect from anywhere (if using testnet)  
✅ Contracts are live and accessible!

---

## Need Help?

- See `DEPLOYMENT_GUIDE.md` for detailed instructions
- See `FRONTEND_INTEGRATION.md` for your friend
- All contracts are tested and ready ✅

