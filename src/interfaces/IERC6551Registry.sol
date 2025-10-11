// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IERC6551Registry
 * @dev Interface for the ERC-6551 Registry contract
 * @notice The registry creates and computes addresses for token-bound accounts
 */
interface IERC6551Registry {
    /**
     * @dev Emitted when a new token-bound account is created
     */
    event ERC6551AccountCreated(
        address account,
        address indexed implementation,
        bytes32 salt,
        uint256 chainId,
        address indexed tokenContract,
        uint256 indexed tokenId
    );

    /**
     * @dev Reverted when account creation fails
     */
    error AccountCreationFailed();

    /**
     * @notice Creates a token-bound account for an NFT
     * @dev If account already exists, returns existing address without calling create2
     * @param implementation Address of the account implementation contract
     * @param salt Salt for deterministic address generation
     * @param chainId Chain ID where the NFT exists
     * @param tokenContract Address of the NFT contract
     * @param tokenId ID of the NFT
     * @return account Address of the token-bound account
     */
    function createAccount(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external returns (address account);

    /**
     * @notice Computes the address of a token-bound account
     * @dev Does not deploy the account
     * @param implementation Address of the account implementation contract
     * @param salt Salt for deterministic address generation
     * @param chainId Chain ID where the NFT exists
     * @param tokenContract Address of the NFT contract
     * @param tokenId ID of the NFT
     * @return account Computed address of the token-bound account
     */
    function account(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external view returns (address account);
}
