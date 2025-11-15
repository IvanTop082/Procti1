# Contract Addresses

## ⚠️ FILL THIS IN AFTER DEPLOYMENT

After deploying the contracts, fill in the addresses below and share this file with your friend.

---

## Network Information

**Network Name:** Arc Testnet
**Chain ID:** 5042002
**RPC URL:** https://rpc.testnet.arc.network
**Block Explorer:** https://testnet.arcscan.app

---

## Contract Addresses

### Main Contract (Frontend should use this)
**SentinelVault:** `0xDf9053726a2217326bFEadc0c3480c5De7107B8f` ← **Most important for frontend**
**Note:** Updated with mode history logging + risk profiles + approval fix + auto-rebalance + enhanced rebalance events + cross-chain arbitrage

### Cross-Chain Arbitrage Module
**CrossChainArbitrage:** `0x7A612459095bBe3F579068CDE982aa91C57919A6` ← **For cross-chain features**
**Note:** Updated with real CCTP integration, bridgeUSDC() function, activeChain tracking, switchToBestChain(), and simulateBridge() functions - monitors 5 chains for arbitrage opportunities

### Supporting Contracts
**SafePool:** `0xb90892b0143eb804037D582FE7678C636D47f0a5`
**YieldPool:** `0xC6D145006Cd18C7b22D584737A8909DdF3b839D5`
**OracleFeed:** `0xd8A5E7ACa9A2B61d223Ea993749B5F6576aa503f`

### Token Address
**USDC:** `0x3600000000000000000000000000000000000000`

---

## For Frontend Integration

Your friend needs:

1. **Contract Addresses** (above)
2. **Network/Chain ID** (above)
3. **RPC URL** (above)
4. **ABI Files** (from `/abi` folder in this repo)

### Example Frontend Setup

```javascript
// Network configuration
const networkConfig = {
  chainId: 11155111, // Sepolia example
  rpcUrl: "https://sepolia.infura.io/v3/YOUR_KEY",
  contracts: {
    sentinelVault: "0x...", // Fill in after deployment
    oracleFeed: "0x...",     // Fill in after deployment
    usdc: "0x..."            // Fill in after deployment
  }
};

// Connect to contracts
import SentinelVaultABI from './abi/SentinelVault.json';
import OracleFeedABI from './abi/OracleFeed.json';

const sentinelVault = new ethers.Contract(
  networkConfig.contracts.sentinelVault,
  SentinelVaultABI,
  signer
);
```

---

## Block Explorer Links

View your deployed contracts on Arc Testnet Explorer:
- **SentinelVault:** https://testnet.arcscan.app/address/0xDf9053726a2217326bFEadc0c3480c5De7107B8f
- **CrossChainArbitrage:** https://testnet.arcscan.app/address/0x7A612459095bBe3F579068CDE982aa91C57919A6
- **SafePool:** https://testnet.arcscan.app/address/0xb90892b0143eb804037D582FE7678C636D47f0a5
- **YieldPool:** https://testnet.arcscan.app/address/0xC6D145006Cd18C7b22D584737A8909DdF3b839D5
- **OracleFeed:** https://testnet.arcscan.app/address/0xd8A5E7ACa9A2B61d223Ea993749B5F6576aa503f
- **USDC:** https://testnet.arcscan.app/address/0x3600000000000000000000000000000000000000

---

## Notes

- Keep your private key **SECRET** - never share it!
- Only share the contract addresses and network info
- Testnet deployments are free but use test tokens
- Mainnet deployments cost real money (ETH for gas)

