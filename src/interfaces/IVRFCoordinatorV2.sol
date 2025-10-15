// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IVRFCoordinatorV2
 * @notice Interface for Chainlink VRF V2 Coordinator
 */
interface IVRFCoordinatorV2 {
    /**
     * @notice Request random words from VRF
     * @param keyHash The gas lane key hash
     * @param subId The subscription ID
     * @param minimumRequestConfirmations Minimum confirmations
     * @param callbackGasLimit Gas limit for callback
     * @param numWords Number of random words to request
     * @return requestId The request ID
     */
    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId);
}
