# Procti Protocol

A smart contract protocol for automated risk management and yield optimization with USDC deposits.

## Overview

Procti Protocol consists of four main contracts:

- **SentinelVault**: Main vault that manages user deposits and automatically rebalances between yield generation and safe storage based on oracle price
- **YieldPool**: Simulated yield vault that generates returns on USDC deposits
- **SafePool**: Secure vault that holds USDC deposits without yield (used in defensive mode)
- **OracleFeed**: Price feed contract for monitoring USDC price stability

## Contracts

### SentinelVault.sol
Main contract that users interact with. Features:
- `deposit(uint256 amount)`: Deposit USDC into the vault
- `withdraw(uint256 amount)`: Withdraw USDC from the vault
- `getMode()`: Get current mode (0 = Farming, 1 = Defensive, 2 = Emergency)
- `simulateRisk(uint256 newPrice)`: Simulate what would happen with a new price
- `rebalance()`: Automatically rebalance based on oracle price

**Modes:**
- **Farming Mode (0)**: Funds are in YieldPool generating yield
- **Defensive Mode (1)**: Funds are in SafePool (triggered when price < $0.999)
- **Emergency Mode (2)**: Funds held directly in vault

### YieldPool.sol
Simulated yield vault with:
- `deposit(uint256 amount)`: Deposit USDC
- `withdrawAll()`: Withdraw all USDC (returns principal)

### SafePool.sol
Secure storage vault with:
- `deposit(uint256 amount)`: Deposit USDC
- `withdrawAll()`: Withdraw all USDC

### OracleFeed.sol
Price feed with:
- `setPrice(uint256 price)`: Set USDC price (for demo, scaled by 1e18)
- `getPrice()`: Get current price

## Setup

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed

### Installation

```bash
# Install dependencies (forge-std is already included)
forge install
```

### Build

```bash
forge build
```

After building, copy ABIs to the `/abi` folder:

**Windows (PowerShell):**
```powershell
.\scripts\copy-abis.ps1
```

**Linux/Mac:**
```bash
chmod +x scripts/copy-abis.sh
./scripts/copy-abis.sh
```

ABIs will be available in the `/abi` folder for frontend integration.

## Deployment

### Local Testing

1. Start a local Anvil node:
```bash
anvil
```

2. Deploy contracts:
```bash
# Set environment variables
export PRIVATE_KEY=<your_private_key>
export USDC_ADDRESS=<usdc_token_address>

# Deploy
forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast
```

### Testnet/Mainnet

```bash
forge script script/Deploy.s.sol:Deploy \
  --rpc-url <your_rpc_url> \
  --private-key <your_private_key> \
  --broadcast \
  --verify
```

## Usage

### For Frontend Developers

All contract ABIs are available in the `/abi` folder after running the copy script:
- `SentinelVault.json`
- `YieldPool.json`
- `SafePool.json`
- `OracleFeed.json`
- `IERC20.json`

### Example Integration

```javascript
// Example using ethers.js
import SentinelVaultABI from './abi/SentinelVault.json';
import OracleFeedABI from './abi/OracleFeed.json';

const sentinelVault = new ethers.Contract(sentinelVaultAddress, SentinelVaultABI, signer);
const oracleFeed = new ethers.Contract(oracleFeedAddress, OracleFeedABI, signer);

// Deposit USDC
await usdc.approve(sentinelVaultAddress, amount);
await sentinelVault.deposit(amount);

// Check current mode
const mode = await sentinelVault.getMode(); // 0 = Farming, 1 = Defensive, 2 = Emergency

// Simulate risk
const wouldTrigger = await sentinelVault.simulateRisk(ethers.parseUnits("0.998", 18));

// Rebalance (automatically switches modes based on price)
await sentinelVault.rebalance();

// Set oracle price (for demo)
await oracleFeed.setPrice(ethers.parseUnits("0.998", 18)); // Triggers Defensive mode
```

## Testing

```bash
forge test
```

## Project Structure

```
/contracts (src/)
    SentinelVault.sol
    YieldPool.sol
    SafePool.sol
    OracleFeed.sol
    IERC20.sol

/scripts
    Deploy.s.sol

/abi (generated after build + copy script)
    SentinelVault.json
    YieldPool.json
    SafePool.json
    OracleFeed.json
    IERC20.json
```

## Hackathon Notes

- All contracts are well-commented for easy presentation
- Simple, clean architecture for quick integration
- OracleFeed allows manual price setting for demo purposes
- YieldPool uses a simple multiplier to simulate yield (5% APY)
- SentinelVault automatically rebalances when price drops below $0.999

## License

MIT
# proctitest
