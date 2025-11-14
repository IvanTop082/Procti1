# Procti Protocol - Arc Testnet Deployment Commands
# Run these commands in PowerShell

# ============================================
# STEP 1: Set your private key
# ============================================
# ⚠️ SECURITY: Replace with your actual private key
# Never share your private key!
$env:PRIVATE_KEY="0xYourPrivateKeyHere"

# Add Foundry to PATH
$env:PATH += ";$env:USERPROFILE\.foundry\bin"

# ============================================
# STEP 2: Deploy Mock USDC
# ============================================
Write-Host "`n=== Deploying Mock USDC ===" -ForegroundColor Cyan
forge script script/DeployMockUSDC.s.sol:DeployMockUSDC `
  --rpc-url https://rpc.testnet.arc.network `
  --broadcast

# ============================================
# STEP 3: Set USDC address and deploy main contracts
# ============================================
# After MockUSDC deploys, copy its address from the output above
# Then set it here:
$env:USDC_ADDRESS="0x..."  # ← Paste MockUSDC address here

Write-Host "`n=== Deploying Procti Protocol Contracts ===" -ForegroundColor Cyan
forge script script/Deploy.s.sol:Deploy `
  --rpc-url https://rpc.testnet.arc.network `
  --broadcast

Write-Host "`n=== Deployment Complete! ===" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Copy all contract addresses from the output above" -ForegroundColor White
Write-Host "2. Fill them in CONTRACT_ADDRESSES.md" -ForegroundColor White
Write-Host "3. Share with your friend!" -ForegroundColor White
Write-Host "`nBlock Explorer: https://testnet.arcscan.app" -ForegroundColor Cyan

