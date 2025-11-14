# PowerShell script to copy ABIs to /abi folder
# Run this after: forge build

Write-Host "Copying ABIs to /abi folder..."

# Create abi directory if it doesn't exist
if (-not (Test-Path "abi")) {
    New-Item -ItemType Directory -Path "abi" | Out-Null
}

# Copy ABIs from out/ directory
$contracts = @("SentinelVault", "YieldPool", "SafePool", "OracleFeed", "IERC20")

foreach ($contract in $contracts) {
    $sourcePath = "out\$contract.sol\$contract.json"
    $destPath = "abi\$contract.json"
    
    if (Test-Path $sourcePath) {
        Copy-Item $sourcePath $destPath -Force
        Write-Host "Copied: $contract.json"
    } else {
        Write-Warning "ABI not found for $contract at $sourcePath"
    }
}

Write-Host "`nABI copy complete! Check the /abi folder."

