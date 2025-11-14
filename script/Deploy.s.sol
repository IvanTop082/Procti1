// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {OracleFeed} from "../src/OracleFeed.sol";
import {SafePool} from "../src/SafePool.sol";
import {YieldPool} from "../src/YieldPool.sol";
import {SentinelVault} from "../src/SentinelVault.sol";

/**
 * @title Deploy
 * @dev Deployment script for Procti protocol contracts
 * @notice Deploys in order: SafePool, YieldPool, OracleFeed, then SentinelVault
 */
contract Deploy is Script {
    function run() external {
        // Get deployer private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Get USDC address from environment (or use a default for local testing)
        address usdcAddress = vm.envOr("USDC_ADDRESS", address(0));
        
        // For local testing, you might want to deploy a mock USDC
        // For this script, we assume USDC address is provided
        require(usdcAddress != address(0), "Deploy: USDC_ADDRESS must be set");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("Deploying Procti Protocol Contracts...");
        console.log("USDC Address:", usdcAddress);
        
        // 1. Deploy SafePool
        console.log("\n1. Deploying SafePool...");
        SafePool safePool = new SafePool(usdcAddress);
        console.log("SafePool deployed at:", address(safePool));
        
        // 2. Deploy YieldPool
        console.log("\n2. Deploying YieldPool...");
        YieldPool yieldPool = new YieldPool(usdcAddress);
        console.log("YieldPool deployed at:", address(yieldPool));
        
        // 3. Deploy OracleFeed
        console.log("\n3. Deploying OracleFeed...");
        OracleFeed oracle = new OracleFeed();
        console.log("OracleFeed deployed at:", address(oracle));
        
        // 4. Deploy SentinelVault (receives all three addresses)
        console.log("\n4. Deploying SentinelVault...");
        SentinelVault sentinelVault = new SentinelVault(
            usdcAddress,
            address(oracle),
            address(safePool),
            address(yieldPool)
        );
        console.log("SentinelVault deployed at:", address(sentinelVault));
        
        console.log("\n=== Deployment Summary ===");
        console.log("SafePool:", address(safePool));
        console.log("YieldPool:", address(yieldPool));
        console.log("OracleFeed:", address(oracle));
        console.log("SentinelVault:", address(sentinelVault));
        console.log("===========================");
        
        vm.stopBroadcast();
    }
}

