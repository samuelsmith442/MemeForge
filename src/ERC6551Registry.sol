// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/IERC6551Registry.sol";

/**
 * @title ERC6551Registry
 * @dev Registry for creating and computing token-bound account addresses
 * @notice Implements the ERC-6551 standard for NFT-owned smart contract accounts
 */
contract ERC6551Registry is IERC6551Registry {
    /**
     * @notice Creates a token-bound account for an NFT
     * @dev Uses CREATE2 for deterministic address generation
     * @param implementation Address of the account implementation
     * @param salt Salt for address generation
     * @param chainId Chain ID where the NFT exists
     * @param tokenContract Address of the NFT contract
     * @param tokenId ID of the NFT
     * @return The address of the created or existing account
     */
    function createAccount(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external returns (address) {
        assembly {
            // Memory Layout:
            // ----
            // 0x00   0xff                     (1 byte)
            // 0x01   registry (address)       (20 bytes)
            // 0x15   salt (bytes32)           (32 bytes)
            // 0x35   Bytecode Hash (bytes32)  (32 bytes)
            // ----
            // 0x55   ERC-1167 Constructor + Header (20 bytes)
            // 0x69   implementation (address)      (20 bytes)
            // 0x7D   ERC-1167 Footer              (15 bytes)
            // 0x8C   salt (uint256)               (32 bytes)
            // 0xAC   chainId (uint256)            (32 bytes)
            // 0xCC   tokenContract (address)      (32 bytes)
            // 0xEC   tokenId (uint256)            (32 bytes)

            // Copy bytecode + constant data to memory
            calldatacopy(0x8c, 0x24, 0x80) // salt, chainId, tokenContract, tokenId
            mstore(0x6c, 0x5af43d82803e903d91602b57fd5bf3) // ERC-1167 footer
            mstore(0x5d, implementation) // implementation
            mstore(0x49, 0x3d60ad80600a3d3981f3363d3d373d3d3d363d73) // ERC-1167 constructor + header

            // Copy create2 computation data to memory
            mstore(0x35, keccak256(0x55, 0xb7)) // keccak256(bytecode)
            mstore(0x15, salt) // salt
            mstore(0x01, shl(96, address())) // registry address
            mstore8(0x00, 0xff) // 0xFF

            // Compute account address
            let computed := keccak256(0x00, 0x55)

            // If the account has not yet been deployed
            if iszero(extcodesize(computed)) {
                // Deploy account contract
                let deployed := create2(0, 0x55, 0xb7, salt)

                // Revert if the deployment fails
                if iszero(deployed) {
                    mstore(0x00, 0x20188a59) // `AccountCreationFailed()`
                    revert(0x1c, 0x04)
                }

                // Store account address in memory before salt and chainId
                mstore(0x6c, deployed)

                // Emit the ERC6551AccountCreated event
                log4(
                    0x6c,
                    0x60,
                    // `ERC6551AccountCreated(address,address,bytes32,uint256,address,uint256)`
                    0x79f19b3655ee38b1ce526556b7731a20c8f218fbda4a3990b6cc4172fdf88722,
                    implementation,
                    tokenContract,
                    tokenId
                )

                // Return the account address
                // aderyn-fp-next-line(yul-return) - Intentional assembly return per ERC-6551 spec
                return(0x6c, 0x20)
            }

            // Otherwise, return the computed account address
            mstore(0x00, shr(96, shl(96, computed)))
            // aderyn-fp-next-line(yul-return) - Intentional assembly return per ERC-6551 spec
            return(0x00, 0x20)
        }
    }

    /**
     * @notice Computes the address of a token-bound account
     * @dev Does not deploy the account
     * @param implementation Address of the account implementation
     * @param salt Salt for address generation
     * @param chainId Chain ID where the NFT exists
     * @param tokenContract Address of the NFT contract
     * @param tokenId ID of the NFT
     * @return The computed address of the token-bound account
     */
    function account(address implementation, bytes32 salt, uint256 chainId, address tokenContract, uint256 tokenId)
        external
        view
        returns (address)
    {
        assembly {
            // Copy bytecode + constant data to memory
            calldatacopy(0x8c, 0x24, 0x80) // salt, chainId, tokenContract, tokenId
            mstore(0x6c, 0x5af43d82803e903d91602b57fd5bf3) // ERC-1167 footer
            mstore(0x5d, implementation) // implementation
            mstore(0x49, 0x3d60ad80600a3d3981f3363d3d373d3d3d363d73) // ERC-1167 constructor + header

            // Copy create2 computation data to memory
            mstore(0x35, keccak256(0x55, 0xb7)) // keccak256(bytecode)
            mstore(0x15, salt) // salt
            mstore(0x01, shl(96, address())) // registry address
            mstore8(0x00, 0xff) // 0xFF

            // Store computed account address in memory
            mstore(0x00, shr(96, shl(96, keccak256(0x00, 0x55))))

            // Return computed account address
            // aderyn-fp-next-line(yul-return) - Intentional assembly return per ERC-6551 spec
            return(0x00, 0x20)
        }
    }
}
