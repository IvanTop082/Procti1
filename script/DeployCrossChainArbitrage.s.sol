// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {CrossChainArbitrage} from "../src/CrossChainArbitrage.sol";

/**
 * @title DeployCrossChainArbitrage
 * @dev Deployment script for CrossChainArbitrage contract (simulation mode)
 */
contract DeployCrossChainArbitrage is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying CrossChainArbitrage (simulation mode)...");

        CrossChainArbitrage arb = new CrossChainArbitrage();
        console.log("CrossChainArbitrage deployed at:", address(arb));

        console.log("\n=== Deployment Summary ===");
        console.log("CrossChainArbitrage:", address(arb));
        console.log("Mode: Simulation (no real bridging)");
        console.log("===========================");

        vm.stopBroadcast();
    }
}

