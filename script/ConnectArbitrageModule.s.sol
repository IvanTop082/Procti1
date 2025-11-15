// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {SentinelVault} from "../src/SentinelVault.sol";
import {CrossChainArbitrage} from "../src/CrossChainArbitrage.sol";

/**
 * @title ConnectArbitrageModule
 * @dev Connect CrossChainArbitrage to SentinelVault
 */
contract ConnectArbitrageModule is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        address sentinelVaultAddress = vm.envAddress("SENTINEL_VAULT_ADDRESS");
        address arbAddress = vm.envAddress("ARB_ADDRESS");

        require(sentinelVaultAddress != address(0), "SENTINEL_VAULT_ADDRESS must be set");
        require(arbAddress != address(0), "ARB_ADDRESS must be set");

        vm.startBroadcast(deployerPrivateKey);

        console.log("Connecting Arbitrage Module...");
        console.log("SentinelVault:", sentinelVaultAddress);
        console.log("CrossChainArbitrage:", arbAddress);

        SentinelVault sentinelVault = SentinelVault(sentinelVaultAddress);
        sentinelVault.setArbitrageModule(arbAddress);

        console.log("Arbitrage module connected successfully!");

        vm.stopBroadcast();
    }
}

