// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {MockUSDC} from "../src/MockUSDC.sol";

/**
 * @title DeployMockUSDC
 * @dev Deploy a mock USDC token for testing purposes
 * @notice Use this if you don't have a real USDC address on testnet
 */
contract DeployMockUSDC is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("Deploying Mock USDC...");
        
        // Deploy with initial supply of 1,000,000 USDC (6 decimals)
        uint256 initialSupply = 1_000_000 * 1e6;
        MockUSDC mockUSDC = new MockUSDC(initialSupply);
        
        console.log("MockUSDC deployed at:", address(mockUSDC));
        console.log("Initial supply:", initialSupply / 1e6, "USDC");
        console.log("Deployer balance:", mockUSDC.balanceOf(msg.sender) / 1e6, "USDC");
        
        vm.stopBroadcast();
    }
}

