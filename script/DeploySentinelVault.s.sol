// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {SentinelVault} from "../src/SentinelVault.sol";

/**
 * @title DeploySentinelVault
 * @dev Deploy only SentinelVault with existing pool addresses
 */
contract DeploySentinelVault is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // USDC address
        address usdcAddress = vm.envOr("USDC_ADDRESS", address(0));
        require(usdcAddress != address(0), "DeploySentinelVault: USDC_ADDRESS must be set");
        
        // Existing contract addresses from previous deployment
        address oracleAddress = vm.envOr("ORACLE_ADDRESS", address(0));
        address safePoolAddress = vm.envOr("SAFEPOOL_ADDRESS", address(0));
        address yieldPoolAddress = vm.envOr("YIELDPOOL_ADDRESS", address(0));
        
        // If not provided, use the addresses from the last deployment
        if (oracleAddress == address(0)) {
            oracleAddress = 0xd8A5E7ACa9A2B61d223Ea993749B5F6576aa503f;
        }
        if (safePoolAddress == address(0)) {
            safePoolAddress = 0xb90892b0143eb804037D582FE7678C636D47f0a5;
        }
        if (yieldPoolAddress == address(0)) {
            yieldPoolAddress = 0xC6D145006Cd18C7b22D584737A8909DdF3b839D5;
        }
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("Deploying SentinelVault...");
        console.log("USDC Address:", usdcAddress);
        console.log("Oracle Address:", oracleAddress);
        console.log("SafePool Address:", safePoolAddress);
        console.log("YieldPool Address:", yieldPoolAddress);
        
        SentinelVault sentinelVault = new SentinelVault(
            usdcAddress,
            oracleAddress,
            safePoolAddress,
            yieldPoolAddress
        );
        
        console.log("SentinelVault deployed at:", address(sentinelVault));
        
        vm.stopBroadcast();
    }
}

