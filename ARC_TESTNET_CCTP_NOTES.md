# Arc Testnet CCTP Integration Notes

## ✅ Verification Results

**TokenMessenger Contract:**
- Address: `0x8FE6B999Dc680CcFDD5Bf7EB0974218be2542DAA`
- Status: ✅ **EXISTS** (code size: 2175 bytes)
- Can interact with USDC: ✅ **YES**

**USDC Contract:**
- Address: `0x3600000000000000000000000000000000000000`
- Status: ✅ **EXISTS** (code size: 1798 bytes)

## ⚠️ Known Limitations

### Domain Support
Arc testnet uses domain **26**. However, bridging **from** Arc testnet **to** other chains may have limitations:

1. **Mainnet Chains (Ethereum, Base, Arbitrum, Optimism)**
   - Domain 0 (Ethereum) may not be fully supported from Arc testnet
   - Mainnet domains (42161, 8453, 10) may not work from testnet
   - **Recommendation:** Use testnet-to-testnet bridging instead

2. **Testnet Chains**
   - Ethereum Sepolia (domain varies)
   - Base Sepolia (domain varies)
   - Arbitrum Sepolia (domain varies)
   - Optimism Sepolia (domain varies)
   - **These should work better for testnet-to-testnet transfers**

## 🔧 Troubleshooting

### If `bridgeUSDC()` Reverts

**Most Common Causes:**
1. **Unsupported Domain:** Arc testnet TokenMessenger may not support all destination domains
2. **Mainnet vs Testnet Mismatch:** Trying to bridge from testnet to mainnet may fail
3. **USDC Address Recognition:** TokenMessenger may not recognize the USDC address format

**Solutions:**
1. Try bridging to a testnet chain instead of mainnet
2. Verify the destination domain is correct for testnet
3. Check if Circle's CCTP fully supports Arc testnet → other testnets

## 📝 Recommendations

1. **For Testing:** Use testnet-to-testnet bridging (Arc → Sepolia testnets)
2. **For Production:** Verify CCTP support for Arc mainnet (when available)
3. **Error Handling:** Frontend now provides better error messages for TokenMessenger failures

## 🔗 Resources

- Arc Testnet Explorer: https://testnet.arcscan.app
- Circle CCTP Docs: https://developers.circle.com/stablecoin/docs
- TokenMessenger Address: `0x8FE6B999Dc680CcFDD5Bf7EB0974218be2542DAA`

