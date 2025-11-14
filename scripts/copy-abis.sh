#!/bin/bash
# Bash script to copy ABIs to /abi folder
# Run this after: forge build

echo "Copying ABIs to /abi folder..."

# Create abi directory if it doesn't exist
mkdir -p abi

# Copy ABIs from out/ directory
contracts=("SentinelVault" "YieldPool" "SafePool" "OracleFeed" "IERC20")

for contract in "${contracts[@]}"; do
    source_path="out/${contract}.sol/${contract}.json"
    dest_path="abi/${contract}.json"
    
    if [ -f "$source_path" ]; then
        cp "$source_path" "$dest_path"
        echo "Copied: ${contract}.json"
    else
        echo "Warning: ABI not found for $contract at $source_path"
    fi
done

echo ""
echo "ABI copy complete! Check the /abi folder."

