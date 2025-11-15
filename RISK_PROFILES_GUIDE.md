# Risk Profiles Feature Guide

## ✅ Changes Made

The `SentinelVault.sol` contract now supports user-selectable risk profiles that customize the price thresholds for mode switching.

### 1. Risk Profile Enum

Added three risk profile options:
```solidity
enum RiskProfile { Conservative, Balanced, Aggressive }
```

- **Conservative (0)**: Most risk-averse, switches modes at higher price thresholds
- **Balanced (1)**: Default balanced approach
- **Aggressive (2)**: Less risk-averse, allows more price movement before switching

### 2. User Risk Profile Mapping

```solidity
mapping(address => RiskProfile) public userRiskProfile;
```

Each user can have their own risk profile setting.

### 3. Set Risk Profile Function

```solidity
function setRiskProfile(RiskProfile profile) external {
    userRiskProfile[msg.sender] = profile;
}
```

Users can set their profile by calling:
- `setRiskProfile(0)` for Conservative
- `setRiskProfile(1)` for Balanced  
- `setRiskProfile(2)` for Aggressive

### 4. Dynamic Thresholds

The `rebalance()` function now uses dynamic thresholds based on the caller's risk profile:

| Profile | Defensive Threshold | Emergency Threshold |
|---------|-------------------|-------------------|
| **Conservative** | 0.9992 ($0.9992) | 0.996 ($0.996) |
| **Balanced** | 0.999 ($0.999) | 0.995 ($0.995) |
| **Aggressive** | 0.9985 ($0.9985) | 0.994 ($0.994) |

### 5. Enhanced Rebalance Logic

The `rebalance()` function now:
- Reads the caller's risk profile
- Sets thresholds based on profile
- Handles all three modes (Farming, Defensive, Emergency)
- Properly moves funds between pools based on mode transitions

---

## 🔄 How It Works

### Mode Switching Logic

1. **Emergency Mode** (price < emergencyThreshold):
   - Moves funds to SafePool or keeps in vault
   - Most protective mode

2. **Defensive Mode** (emergencyThreshold ≤ price < defensiveThreshold):
   - Moves funds to SafePool
   - Moderate protection

3. **Farming Mode** (price ≥ defensiveThreshold):
   - Moves funds to YieldPool
   - Normal yield generation

### Example Scenarios

**Conservative User:**
- Price drops to $0.9991 → Switches to Defensive (threshold: $0.9992)
- Price drops to $0.9955 → Switches to Emergency (threshold: $0.996)

**Balanced User:**
- Price drops to $0.9989 → Switches to Defensive (threshold: $0.999)
- Price drops to $0.9945 → Switches to Emergency (threshold: $0.995)

**Aggressive User:**
- Price drops to $0.9984 → Switches to Defensive (threshold: $0.9985)
- Price drops to $0.9935 → Switches to Emergency (threshold: $0.994)

---

## 🎯 Frontend Integration

### Set User Risk Profile

```javascript
import { ethers } from 'ethers';
import SentinelVaultABI from './abi/SentinelVault.json';

const sentinelVault = new ethers.Contract(
  "0xBAa73083BA0604BaA69b6D59394d3177624987ca",
  SentinelVaultABI,
  signer
);

// Set risk profile
async function setRiskProfile(profile) {
  // 0 = Conservative, 1 = Balanced, 2 = Aggressive
  const tx = await sentinelVault.setRiskProfile(profile);
  await tx.wait();
  console.log(`Risk profile set to: ${profile}`);
}

// Get user's risk profile
async function getUserRiskProfile(userAddress) {
  const profile = await sentinelVault.userRiskProfile(userAddress);
  const profiles = ["Conservative", "Balanced", "Aggressive"];
  return {
    value: Number(profile),
    name: profiles[Number(profile)]
  };
}

// Usage
await setRiskProfile(0); // Set to Conservative
await setRiskProfile(1); // Set to Balanced
await setRiskProfile(2); // Set to Aggressive

const myProfile = await getUserRiskProfile(await signer.getAddress());
console.log(`My risk profile: ${myProfile.name}`);
```

### UI Example

```javascript
// Risk profile selector component
function RiskProfileSelector() {
  const [profile, setProfile] = useState(1); // Default to Balanced
  
  const handleProfileChange = async (newProfile) => {
    try {
      await setRiskProfile(newProfile);
      setProfile(newProfile);
      alert(`Risk profile updated to: ${getProfileName(newProfile)}`);
    } catch (error) {
      console.error("Failed to set risk profile:", error);
    }
  };
  
  return (
    <div>
      <h3>Select Risk Profile</h3>
      <button onClick={() => handleProfileChange(0)}>
        Conservative (Safest)
      </button>
      <button onClick={() => handleProfileChange(1)}>
        Balanced (Default)
      </button>
      <button onClick={() => handleProfileChange(2)}>
        Aggressive (Higher Risk)
      </button>
    </div>
  );
}
```

---

## 📊 Threshold Comparison

| Price | Conservative | Balanced | Aggressive |
|-------|-------------|----------|------------|
| $1.000 | Farming | Farming | Farming |
| $0.9995 | Defensive | Farming | Farming |
| $0.999 | Defensive | Defensive | Farming |
| $0.9985 | Defensive | Defensive | Defensive |
| $0.996 | Emergency | Defensive | Defensive |
| $0.995 | Emergency | Emergency | Defensive |
| $0.994 | Emergency | Emergency | Emergency |

---

## ⚠️ Important Notes

1. **Default Profile**: If a user hasn't set a profile, it defaults to Conservative (enum value 0)

2. **Per-User Settings**: Each user has their own risk profile - different users can have different profiles

3. **Rebalance Caller**: The `rebalance()` function uses the **caller's** risk profile to determine thresholds. The mode change affects the entire vault (since funds are pooled)

4. **Backward Compatible**: All existing functionality remains intact:
   - `_setMode()` logic unchanged
   - Event emissions unchanged
   - Mode constants unchanged
   - Deposit/withdraw unchanged

5. **No Breaking Changes**: Frontend can continue using the same contract interface, with optional risk profile feature

---

## 🧪 Testing

The contract compiles successfully and maintains all existing functionality while adding the new risk profile feature.

### Test Scenarios

1. **User sets Conservative profile** → Rebalance uses higher thresholds
2. **User sets Aggressive profile** → Rebalance uses lower thresholds  
3. **User doesn't set profile** → Defaults to Conservative
4. **Multiple users with different profiles** → Each can call rebalance with their own thresholds

---

## 📝 Summary

- ✅ Risk profiles added (Conservative, Balanced, Aggressive)
- ✅ Dynamic thresholds based on user profile
- ✅ Enhanced rebalance logic with Emergency mode support
- ✅ Backward compatible with existing functionality
- ✅ Clean, production-ready code
- ✅ No breaking changes to existing mode logic or events

The system now allows users to customize their risk tolerance while maintaining the automatic mode switching functionality!

