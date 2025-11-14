# PowerShell script to deploy Procti contracts to Arc Testnet
# Run this script to deploy all contracts

Write-Host "=== Procti Protocol - Arc Testnet Deployment ===" -ForegroundColor Cyan
Write-Host ""

# Check if Foundry is available
$forgePath = "$env:USERPROFILE\.foundry\bin\forge.exe"
if (-not (Test-Path $forgePath)) {
    Write-Host "Error: Foundry not found at $forgePath" -ForegroundColor Red
    Write-Host "Please install Foundry first: https://book.getfoundry.sh/getting-started/installation" -ForegroundColor Yellow
    exit 1
}

# Add Foundry to PATH
$env:PATH += ";$env:USERPROFILE\.foundry\bin"

# Check for required environment variables
if (-not $env:PRIVATE_KEY) {
    Write-Host "Error: PRIVATE_KEY environment variable not set" -ForegroundColor Red
    Write-Host "Set it with: `$env:PRIVATE_KEY='your_private_key_here'" -ForegroundColor Yellow
    exit 1
}

Write-Host "Step 1: Deploying Mock USDC (if needed)..." -ForegroundColor Yellow
Write-Host "Note: Arc testnet uses USDC for gas fees. Make sure you have test USDC!" -ForegroundColor Yellow
Write-Host "Faucet: https://faucet.circle.com" -ForegroundColor Yellow
Write-Host ""

# Deploy Mock USDC
Write-Host "Deploying MockUSDC..." -ForegroundColor Green
$mockUSDCOutput = forge script script/DeployMockUSDC.s.sol:DeployMockUSDC --rpc-url https://rpc.testnet.arc.network --broadcast 2>&1

# Extract MockUSDC address from output
$mockUSDCAddress = ""
if ($mockUSDCOutput -match "MockUSDC deployed at:\s*(0x[a-fA-F0-9]{40})") {
    $mockUSDCAddress = $matches[1]
    Write-Host "MockUSDC deployed at: $mockUSDCAddress" -ForegroundColor Green
} else {
    Write-Host "Warning: Could not extract MockUSDC address from output" -ForegroundColor Yellow
    Write-Host "Please check the output above and set USDC_ADDRESS manually" -ForegroundColor Yellow
    Write-Host ""
    $mockUSDCAddress = Read-Host "Enter MockUSDC address (or press Enter to skip)"
}

if (-not $mockUSDCAddress) {
    Write-Host "Error: USDC address is required" -ForegroundColor Red
    exit 1
}

$env:USDC_ADDRESS = $mockUSDCAddress

Write-Host ""
Write-Host "Step 2: Deploying Procti Protocol Contracts..." -ForegroundColor Yellow
Write-Host ""

# Deploy main contracts
Write-Host "Deploying contracts..." -ForegroundColor Green
forge script script/Deploy.s.sol:Deploy --rpc-url https://rpc.testnet.arc.network --broadcast

Write-Host ""
Write-Host "=== Deployment Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Copy the contract addresses from the output above" -ForegroundColor White
Write-Host "2. Fill them in CONTRACT_ADDRESSES.md" -ForegroundColor White
Write-Host "3. Share CONTRACT_ADDRESSES.md and /abi folder with your friend" -ForegroundColor White
Write-Host ""
Write-Host "Block Explorer: https://testnet.arcscan.app" -ForegroundColor Cyan

