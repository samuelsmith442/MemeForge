// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";

/**
 * @title HelperConfig
 * @dev Manages network-specific configuration for MemeForge deployments
 * @notice Handles Anvil (local), Sepolia (testnet), and Mainnet configurations
 */
contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address registry; // ERC6551Registry address (if pre-deployed)
        address implementation; // TokenBoundAccount implementation (if pre-deployed)
        uint256 deployerKey;
    }

    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    constructor() {
        if (block.chainid == 11_155_111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory sepoliaNetworkConfig) {
        sepoliaNetworkConfig = NetworkConfig({
            registry: address(0), // Deploy new registry on Sepolia
            implementation: address(0), // Deploy new implementation on Sepolia
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getMainnetEthConfig() public view returns (NetworkConfig memory mainnetNetworkConfig) {
        mainnetNetworkConfig = NetworkConfig({
            registry: address(0), // Deploy new registry on Mainnet
            implementation: address(0), // Deploy new implementation on Mainnet
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    function getOrCreateAnvilEthConfig() public view returns (NetworkConfig memory anvilNetworkConfig) {
        // Check to see if we set an active network config
        if (activeNetworkConfig.deployerKey != 0) {
            return activeNetworkConfig;
        }

        // For local Anvil, we'll deploy fresh contracts
        anvilNetworkConfig = NetworkConfig({
            registry: address(0), // Deploy new registry locally
            implementation: address(0), // Deploy new implementation locally
            deployerKey: DEFAULT_ANVIL_PRIVATE_KEY
        });
    }
}
