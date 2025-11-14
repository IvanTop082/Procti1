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
**SentinelVault:** `0x6D6F4f209AE8E03DCfC4719a5b8bA50B2fe45FDa` ← **Most important for frontend**

### Supporting Contracts
**SafePool:** `0x00fa22EefFBb6c61F9e6286d470F2F694Fb1EFA4`
**YieldPool:** `0xA2d5245AC4f3e622d025d82c03211A794e61709C`
**OracleFeed:** `0x32108F6ad1d9F8f805a4E72b3C9829425FCfFb73`

### Token Address
**USDC (MockUSDC):** `0x615Fe162774b71c6fA55deC75a25F83561948a64`

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
- **SentinelVault:** https://testnet.arcscan.app/address/0x6D6F4f209AE8E03DCfC4719a5b8bA50B2fe45FDa
- **SafePool:** https://testnet.arcscan.app/address/0x00fa22EefFBb6c61F9e6286d470F2F694Fb1EFA4
- **YieldPool:** https://testnet.arcscan.app/address/0xA2d5245AC4f3e622d025d82c03211A794e61709C
- **OracleFeed:** https://testnet.arcscan.app/address/0x32108F6ad1d9F8f805a4E72b3C9829425FCfFb73
- **MockUSDC:** https://testnet.arcscan.app/address/0x615Fe162774b71c6fA55deC75a25F83561948a64

---

## Notes

- Keep your private key **SECRET** - never share it!
- Only share the contract addresses and network info
- Testnet deployments are free but use test tokens
- Mainnet deployments cost real money (ETH for gas)

