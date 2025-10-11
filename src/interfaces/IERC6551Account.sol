// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IERC6551Account
 * @dev Interface for ERC-6551 token-bound accounts
 * @notice Defines the core functionality for accounts owned by NFTs
 */
interface IERC6551Account {
    /**
     * @notice Allows the account to receive Ether
     * @dev Accounts MUST implement a receive function
     */
    receive() external payable;

    /**
     * @notice Returns the token that owns this account
     * @dev The return value MUST be constant - it MUST NOT change over time
     * @return chainId The chain ID of the chain the token exists on
     * @return tokenContract The contract address of the token
     * @return tokenId The ID of the token
     */
    function token() external view returns (uint256 chainId, address tokenContract, uint256 tokenId);

    /**
     * @notice Returns a value that changes each time the account state changes
     * @dev Used to track account state modifications
     * @return The current account state
     */
    function state() external view returns (uint256);

    /**
     * @notice Checks if a given signer is authorized to act on behalf of the account
     * @dev MUST return 0x523e3260 if the signer is valid
     * @param signer The address to check signing authorization for
     * @param context Additional data used to determine if the signer is valid
     * @return magicValue Magic value indicating whether the signer is valid
     */
    function isValidSigner(address signer, bytes calldata context) external view returns (bytes4 magicValue);
}

/**
 * @title IERC6551Executable
 * @dev Interface for executing operations on behalf of a token-bound account
 * @notice Allows valid signers to perform arbitrary operations
 */
interface IERC6551Executable {
    /**
     * @notice Executes a low-level operation if the caller is a valid signer
     * @dev Reverts and bubbles up error if operation fails
     * @param to The target address of the operation
     * @param value The Ether value to be sent to the target
     * @param data The encoded operation calldata
     * @param operation The type of operation (0=CALL, 1=DELEGATECALL, 2=CREATE, 3=CREATE2)
     * @return The result of the operation
     */
    function execute(address to, uint256 value, bytes calldata data, uint8 operation)
        external
        payable
        returns (bytes memory);
}
