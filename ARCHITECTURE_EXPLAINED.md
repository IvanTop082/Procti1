# 🏗️ Procti Protocol Architecture - Simple Explanation

## Why 3 Different Addresses?

Your protocol has **4 smart contracts** (each has its own address). Here's why:

### 1. **SentinelVault** (Main Contract) - `0x6D6F4f209AE8E03DCfC4719a5b8bA50B2fe45FDa`
   - **This is the ONLY contract your friend's frontend should interact with!**
   - Users deposit/withdraw through this contract
   - It automatically manages funds between the other pools

### 2. **YieldPool** - `0xA2d5245AC4f3e622d025d82c03211A794e61709C`
   - Holds funds when in "Farming Mode" (normal operation)
   - Generates yield (simulated 5% APY)
   - **Users don't interact with this directly**

### 3. **SafePool** - `0x00fa22EefFBb6c61F9e6286d470F2F694Fb1EFA4`
   - Holds funds when in "Defensive Mode" (when price drops)
   - Safe storage, no yield
   - **Users don't interact with this directly**

### 4. **OracleFeed** - `0x32108F6ad1d9F8f805a4E72b3C9829425FCfFb73`
   - Provides USDC price information
   - Used to trigger mode switches
   - **Frontend can read from this, but users don't deposit here**

### 5. **MockUSDC** (Token) - `0x615Fe162774b71c6fA55deC75a25F83561948a64`
   - The USDC token itself
   - Users need to approve this before depositing

---

## 🔄 How It Works (Simple Flow)

```
User Wallet
    ↓
    [1. Approve USDC to SentinelVault]
    ↓
    [2. Call SentinelVault.deposit(amount)]
    ↓
SentinelVault (Main Contract)
    ↓
    [Checks current mode]
    ↓
    ├─→ If Farming Mode → Sends to YieldPool
    └─→ If Defensive Mode → Sends to SafePool
```

**Users ONLY interact with SentinelVault!** The other contracts are internal.

---

## ❌ Why Transactions Are Failing

Looking at your explorer, I see failed `deposit` and `withdraw` calls. Here's why:

### Problem 1: Approval Amount or Format
The user needs to approve USDC **BEFORE** calling deposit. Common issues:

1. **Wrong decimal places**: USDC uses **6 decimals** (not 18!)
   - ✅ Correct: `ethers.parseUnits("100", 6)` = 100 USDC
   - ❌ Wrong: `ethers.parseUnits("100", 18)` = way too much

2. **Approval too low**: Must approve at least the deposit amount
   - If depositing 10 USDC, must approve at least 10 USDC

3. **Approval to wrong address**: Must approve to **SentinelVault**, not YieldPool or SafePool

### Problem 2: Insufficient Balance
- User must have USDC in their wallet
- Must have enough USDC for gas fees (Arc uses USDC for gas!)

### Problem 3: Transaction Order
The correct order is:
1. ✅ Approve USDC to SentinelVault
2. ✅ Wait for approval transaction to confirm
3. ✅ Then call deposit

---

## ✅ Correct Frontend Flow

### Step 1: Connect Wallet
```javascript
const provider = new ethers.BrowserProvider(window.ethereum);
const signer = await provider.getSigner();
```

### Step 2: Connect to Contracts
```javascript
// ONLY connect to SentinelVault (main contract)
const sentinelVault = new ethers.Contract(
  "0x6D6F4f209AE8E03DCfC4719a5b8bA50B2fe45FDa", // SentinelVault
  SentinelVaultABI,
  signer
);

// Also need USDC contract for approvals
const usdc = new ethers.Contract(
  "0x615Fe162774b71c6fA55deC75a25F83561948a64", // MockUSDC
  IERC20ABI,
  signer
);
```

### Step 3: Deposit (CORRECT WAY)
```javascript
async function deposit(amountInDollars) {
  // IMPORTANT: USDC uses 6 decimals!
  const amount = ethers.parseUnits(amountInDollars.toString(), 6);
  
  // Step 1: Approve USDC to SentinelVault
  console.log("Approving USDC...");
  const approveTx = await usdc.approve(
    "0x6D6F4f209AE8E03DCfC4719a5b8bA50B2fe45FDa", // SentinelVault address
    amount
  );
  await approveTx.wait(); // Wait for confirmation!
  
  // Step 2: Deposit (after approval confirms)
  console.log("Depositing...");
  const depositTx = await sentinelVault.deposit(amount);
  await depositTx.wait();
  
  console.log("Deposit successful!");
}
```

### Step 4: Withdraw
```javascript
async function withdraw(amountInDollars) {
  const amount = ethers.parseUnits(amountInDollars.toString(), 6);
  
  const tx = await sentinelVault.withdraw(amount);
  await tx.wait();
  
  console.log("Withdrawal successful!");
}
```

---

## 🎯 Key Points for Your Friend

1. **ONLY use SentinelVault address** (`0x6D6F4f209AE8E03DCfC4719a5b8bA50B2fe45FDa`)
   - Don't interact with YieldPool, SafePool directly
   - SentinelVault handles everything

2. **USDC uses 6 decimals** (not 18!)
   - Always use: `ethers.parseUnits(amount, 6)`
   - Always use: `ethers.formatUnits(balance, 6)` to display

3. **Two-step process for deposits:**
   - First: Approve USDC to SentinelVault
   - Second: Call deposit (after approval confirms)

4. **Check user balance:**
   ```javascript
   const userAddress = await signer.getAddress();
   const balance = await sentinelVault.userDeposits(userAddress);
   const balanceInDollars = ethers.formatUnits(balance, 6);
   ```

5. **Check current mode:**
   ```javascript
   const mode = await sentinelVault.getMode();
   // 0 = Farming, 1 = Defensive, 2 = Emergency
   ```

---

## 🔍 Debugging Failed Transactions

If transactions fail, check:

1. **User has USDC?**
   ```javascript
   const usdcBalance = await usdc.balanceOf(userAddress);
   ```

2. **Approval exists?**
   ```javascript
   const allowance = await usdc.allowance(
     userAddress,
     "0x6D6F4f209AE8E03DCfC4719a5b8bA50B2fe45FDa" // SentinelVault
   );
   ```

3. **Enough for gas?** (Arc uses USDC for gas!)

4. **Correct decimals?** (6 for USDC, not 18!)

---

## 📝 Summary

- **4 contracts** = SentinelVault (main) + YieldPool + SafePool + OracleFeed
- **Frontend ONLY uses SentinelVault address**
- **USDC uses 6 decimals** (critical!)
- **Two steps**: Approve → Deposit
- **Other contracts are internal** - users don't interact with them

Your friend should focus on **SentinelVault** only. Everything else is handled automatically!

