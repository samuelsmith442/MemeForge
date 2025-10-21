// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MemeToken} from "../MemeToken.sol";

/**
 * @title TokenDeployer
 * @notice Deploys MemeToken contracts
 * @dev Extracted from MemeForgeFactory to reduce contract size
 */
contract TokenDeployer {
    /**
     * @notice Deploy a new MemeToken
     * @param name Token name
     * @param symbol Token symbol
     * @param initialSupply Initial token supply
     * @param rewardRate Staking reward rate
     * @param theme Token theme
     * @param logoURI Token logo URI
     * @return token Address of deployed MemeToken
     */
    function deployToken(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint256 rewardRate,
        string memory theme,
        string memory logoURI
    ) external returns (address token) {
        MemeToken memeToken = new MemeToken(name, symbol, initialSupply, rewardRate, theme, logoURI);
        token = address(memeToken);

        // Transfer initial supply to caller (factory)
        memeToken.transfer(msg.sender, initialSupply);

        // Transfer ownership to caller (factory)
        memeToken.transferOwnership(msg.sender);

        return token;
    }
}
