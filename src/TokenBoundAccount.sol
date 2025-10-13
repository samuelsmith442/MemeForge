// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IERC6551Account.sol";

// Errors
error TokenBoundAccount__InvalidSigner();
error TokenBoundAccount__InvalidOperation();
error TokenBoundAccount__ExecutionFailed();

/**
 * @title TokenBoundAccount
 * @dev Implementation of ERC-6551 token-bound account
 * @notice A smart contract wallet owned by an NFT
 */
contract TokenBoundAccount is IERC165, IERC1271, IERC6551Account, IERC6551Executable, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Chain ID where this account was deployed
    uint256 private immutable _deploymentChainId;

    /// @notice Current state of the account (increments on each state change)
    uint256 public state;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        _deploymentChainId = block.chainid;
    }

    /*//////////////////////////////////////////////////////////////
                            RECEIVE FUNCTION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows the account to receive Ether
     */
    receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Executes a low-level operation if caller is authorized
     * @dev Only supports CALL operations (operation = 0)
     * @param to Target address
     * @param value Ether value to send
     * @param data Calldata to execute
     * @param operation Operation type (0=CALL, 1=DELEGATECALL, 2=CREATE, 3=CREATE2)
     * @return result Result of the operation
     */
    function execute(address to, uint256 value, bytes calldata data, uint8 operation)
        external
        payable
        virtual
        nonReentrant
        returns (bytes memory result)
    {
        if (!_isValidSigner(msg.sender)) revert TokenBoundAccount__InvalidSigner();
        if (operation != 0) revert TokenBoundAccount__InvalidOperation();

        // Increment state to track changes
        ++state;

        // Execute the call
        bool success;
        (success, result) = to.call{value: value}(data);

        if (!success) {
            // Bubble up the revert reason
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /**
     * @notice Checks if a signer is valid
     * @param signer Address to check
     * @param context Additional context (unused)
     * @return magicValue Magic value if signer is valid, 0 otherwise
     */
    function isValidSigner(address signer, bytes calldata context)
        external
        view
        virtual
        returns (bytes4 magicValue)
    {
        if (_isValidSigner(signer)) {
            return IERC6551Account.isValidSigner.selector;
        }
        return bytes4(0);
    }

    /**
     * @notice Validates a signature (ERC-1271)
     * @param hash Hash of the data to validate
     * @param signature Signature to validate
     * @return magicValue Magic value if signature is valid
     */
    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        virtual
        returns (bytes4 magicValue)
    {
        bool isValid = SignatureChecker.isValidSignatureNow(owner(), hash, signature);

        if (isValid) {
            return IERC1271.isValidSignature.selector;
        }

        return bytes4(0);
    }

    /**
     * @notice Checks if this contract supports an interface
     * @param interfaceId Interface ID to check
     * @return True if interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external pure virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC6551Account).interfaceId
            || interfaceId == type(IERC6551Executable).interfaceId;
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the token that owns this account
     * @dev Reads from contract bytecode (immutable data)
     * @return chainId Chain ID where the token exists
     * @return tokenContract Address of the token contract
     * @return tokenId ID of the token
     */
    function token() public view virtual returns (uint256 chainId, address tokenContract, uint256 tokenId) {
        bytes memory footer = new bytes(0x60);

        assembly {
            // The footer contains: salt (32) + chainId (32) + tokenContract (32) + tokenId (32)
            // Located at the end of the bytecode starting at position 0x4d
            extcodecopy(address(), add(footer, 0x20), 0x4d, 0x60)
        }

        return abi.decode(footer, (uint256, address, uint256));
    }

    /**
     * @notice Returns the owner of this account
     * @dev Owner is the holder of the NFT
     * @return Address of the NFT owner
     */
    function owner() public view virtual returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = token();

        // If on different chain, no owner
        if (chainId != _deploymentChainId) return address(0);

        return IERC721(tokenContract).ownerOf(tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Internal function to check if signer is valid
     * @param signer Address to check
     * @return True if signer is the NFT owner
     */
    function _isValidSigner(address signer) internal view virtual returns (bool) {
        return signer == owner();
    }
}
