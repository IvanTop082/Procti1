# Procti Protocol - Quick Start Guide

## 🚀 Quick Setup

1. **Install Foundry** (if not already installed):
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Build the project**:
   ```bash
   forge build
   ```

3. **Copy ABIs to /abi folder**:
   ```powershell
   # Windows
   .\scripts\copy-abis.ps1
   
   # Linux/Mac
   ./scripts/copy-abis.sh
   ```

4. **Deploy locally** (using Anvil):
   ```bash
   # Terminal 1: Start Anvil
   anvil
   
   # Terminal 2: Deploy
   export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
   export USDC_ADDRESS=0x... # Use a mock USDC or real address
   forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast
   ```

## 📋 Contract Addresses (After Deployment)

After deployment, you'll get:
- `SafePool`: [address]
- `YieldPool`: [address]
- `OracleFeed`: [address]
- `SentinelVault`: [address] ← **Main contract for frontend**

## 🔗 Frontend Integration

Import ABIs from `/abi` folder:

```javascript
import SentinelVaultABI from './abi/SentinelVault.json';
import OracleFeedABI from './abi/OracleFeed.json';
```

## 🎯 Key Functions for Frontend

### SentinelVault
- `deposit(amount)` - Deposit USDC
- `withdraw(amount)` - Withdraw USDC
- `getMode()` - Get current mode (0=Farming, 1=Defensive, 2=Emergency)
- `rebalance()` - Trigger rebalancing based on oracle price
- `simulateRisk(newPrice)` - Check if price would trigger mode change

### OracleFeed (for demo)
- `setPrice(price)` - Set USDC price (use `ethers.parseUnits("0.998", 18)` for $0.998)
- `getPrice()` - Get current price

## 🧪 Demo Flow

1. User deposits USDC → Funds go to YieldPool (Farming mode)
2. Set oracle price to < $0.999 → Call `rebalance()` → Switches to Defensive mode
3. Funds automatically move from YieldPool to SafePool
4. Set oracle price back to >= $0.999 → Call `rebalance()` → Switches back to Farming mode

## 📝 Notes

- All contracts use USDC (IERC20 interface)
- Price threshold: 0.999e18 = $0.999
- YieldPool simulates 5% APY
- Emergency mode (2) holds funds directly in vault

