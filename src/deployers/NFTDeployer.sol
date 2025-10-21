// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MemeSoulNFT} from "../MemeSoulNFT.sol";

/**
 * @title NFTDeployer
 * @notice Deploys MemeSoulNFT contracts and mints soul NFTs
 * @dev Extracted from MemeForgeFactory to reduce contract size
 */
contract NFTDeployer {
    /**
     * @notice Deploy a new MemeSoulNFT and mint the soul NFT
     * @param to Address to mint NFT to
     * @param memeToken Address of the associated MemeToken
     * @param name Token name
     * @param symbol Token symbol
     * @param theme Token theme
     * @param logoURI Token logo URI
     * @param creator Address of the creator
     * @return nftContract Address of deployed MemeSoulNFT
     */
    function deployAndMintNFT(
        address to,
        address memeToken,
        string memory name,
        string memory symbol,
        string memory theme,
        string memory logoURI,
        address creator
    ) external returns (address nftContract) {
        // Deploy MemeSoulNFT
        MemeSoulNFT nft = new MemeSoulNFT();
        nftContract = address(nft);

        // Create metadata
        MemeSoulNFT.MemecoinMetadata memory metadata = MemeSoulNFT.MemecoinMetadata({
            name: name,
            symbol: symbol,
            theme: theme,
            logoURI: logoURI,
            createdAt: block.timestamp,
            creator: creator
        });

        // Mint Soul NFT
        nft.mintSoulNFT(to, memeToken, metadata, logoURI);

        // Transfer ownership to creator
        nft.transferOwnership(creator);

        return nftContract;
    }
}
