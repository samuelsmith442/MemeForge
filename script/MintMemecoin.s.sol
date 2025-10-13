// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MemeSoulNFT} from "../src/MemeSoulNFT.sol";
import {MemeToken} from "../src/MemeToken.sol";
import {ERC6551Registry} from "../src/ERC6551Registry.sol";
import {TokenBoundAccount} from "../src/TokenBoundAccount.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

/**
 * @title MintMemecoin
 * @dev Script to mint a Soul NFT and create a token-bound account for a memecoin
 * @notice Set CONTRACT_ADDRESSES environment variables or update the default addresses below
 */
contract MintMemecoin is Script {
    // Default contract addresses - update these after deployment
    address public DEFAULT_SOUL_NFT_ADDRESS = address(0);
    address public DEFAULT_MEME_TOKEN_ADDRESS = address(0);
    address public DEFAULT_REGISTRY_ADDRESS = address(0);
    address public DEFAULT_IMPLEMENTATION_ADDRESS = address(0);

    function run() external {
        // Try to get contract addresses from environment variables, otherwise use defaults
        address soulNFTAddress = getEnvAddressOrDefault("SOUL_NFT_ADDRESS", DEFAULT_SOUL_NFT_ADDRESS);
        address memeTokenAddress = getEnvAddressOrDefault("MEME_TOKEN_ADDRESS", DEFAULT_MEME_TOKEN_ADDRESS);
        address registryAddress = getEnvAddressOrDefault("REGISTRY_ADDRESS", DEFAULT_REGISTRY_ADDRESS);
        address implementationAddress =
            getEnvAddressOrDefault("IMPLEMENTATION_ADDRESS", DEFAULT_IMPLEMENTATION_ADDRESS);

        require(soulNFTAddress != address(0), "Soul NFT address not set");
        require(memeTokenAddress != address(0), "MemeToken address not set");
        require(registryAddress != address(0), "Registry address not set");
        require(implementationAddress != address(0), "Implementation address not set");

        // Get network configuration
        HelperConfig helperConfig = new HelperConfig();
        (,, uint256 deployerKey) = helperConfig.activeNetworkConfig();

        // Mint the Soul NFT and create TBA
        mintMemecoinSoulNFT(
            soulNFTAddress, memeTokenAddress, registryAddress, implementationAddress, deployerKey
        );
    }

    function mintMemecoinSoulNFT(
        address soulNFTAddress,
        address memeTokenAddress,
        address registryAddress,
        address implementationAddress,
        uint256 deployerKey
    ) public {
        address recipient = vm.addr(deployerKey);
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerKey);

        // Get the deployed contracts
        MemeSoulNFT soulNFT = MemeSoulNFT(soulNFTAddress);
        MemeToken memeToken = MemeToken(memeTokenAddress);

        // Create metadata for the Soul NFT
        MemeSoulNFT.MemecoinMetadata memory metadata = MemeSoulNFT.MemecoinMetadata({
            name: memeToken.name(),
            symbol: memeToken.symbol(),
            theme: memeToken.theme(),
            logoURI: memeToken.logoURI(),
            createdAt: 0, // Will be set by contract
            creator: address(0) // Will be set by contract
        });

        // Mint the Soul NFT
        uint256 tokenId = soulNFT.mintSoulNFT(
            recipient, memeTokenAddress, metadata, "ipfs://QmSoulNFTMetadata"
        );

        console.log("Soul NFT minted with token ID:", tokenId);

        // Create a token-bound account for this Soul NFT
        ERC6551Registry registry = ERC6551Registry(registryAddress);
        address tbaAddress = registry.createAccount(
            implementationAddress, bytes32(0), block.chainid, soulNFTAddress, tokenId
        );

        console.log("Token-Bound Account created at:", tbaAddress);

        // Link the TBA to the Soul NFT
        soulNFT.linkTokenBoundAccount(tokenId, tbaAddress);

        // Stop broadcasting transactions
        vm.stopBroadcast();

        // Log summary
        console.log("\n=== Memecoin Soul NFT Minting Summary ===");
        console.log("Soul NFT Token ID:", tokenId);
        console.log("Owner:", recipient);
        console.log("Linked Memecoin:", memeTokenAddress);
        console.log("Token-Bound Account:", tbaAddress);
        console.log("=========================================\n");
    }

    // Helper function to get address from environment or use default
    function getEnvAddressOrDefault(string memory envVar, address defaultAddress)
        internal
        view
        returns (address)
    {
        try vm.envAddress(envVar) returns (address envAddress) {
            return envAddress;
        } catch {
            return defaultAddress;
        }
    }
}
