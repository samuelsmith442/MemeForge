// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IMintable
 * @notice Interface for tokens that support minting
 */
interface IMintable {
    function mint(address to, uint256 amount) external;
}
