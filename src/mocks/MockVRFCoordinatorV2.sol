// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../interfaces/IVRFCoordinatorV2.sol";

/**
 * @title MockVRFCoordinatorV2
 * @notice Mock VRF Coordinator for testing ONLY
 * @dev Provides instant randomness without actual Chainlink VRF
 *
 * ⚠️ WARNING: DO NOT USE IN PRODUCTION ⚠️
 * This contract uses weak randomness (block.timestamp, block.prevrandao)
 * which is predictable and manipulable by miners/validators.
 *
 * FOR TESTING PURPOSES ONLY!
 * Use real Chainlink VRF in production for cryptographically secure randomness.
 */
contract MockVRFCoordinatorV2 is IVRFCoordinatorV2 {
    ///////////////////
    // State Variables
    ///////////////////
    uint256 private requestCounter;
    mapping(uint256 => address) public requestToConsumer;
    mapping(uint256 => uint256[]) public requestToRandomWords;

    ///////////////////
    // Events
    ///////////////////
    event RandomWordsRequested(uint256 indexed requestId, address indexed consumer, uint32 numWords);

    ///////////////////
    // External Functions
    ///////////////////

    /**
     * @notice Mock request for random words
     * @dev Immediately fulfills the request with pseudo-random values
     */
    function requestRandomWords(
        bytes32, // keyHash
        uint64, // subId
        uint16, // minimumRequestConfirmations
        uint32 callbackGasLimit,
        uint32 numWords
    ) external override returns (uint256 requestId) {
        requestId = ++requestCounter;
        requestToConsumer[requestId] = msg.sender;

        emit RandomWordsRequested(requestId, msg.sender, numWords);

        // Generate pseudo-random words
        uint256[] memory randomWords = new uint256[](numWords);
        for (uint32 i = 0; i < numWords; i++) {
            // ⚠️ WEAK RANDOMNESS - TESTING ONLY ⚠️
            // This uses predictable block data and is NOT cryptographically secure.
            // Miners/validators can manipulate these values.
            // Use real Chainlink VRF in production!
            // aderyn-fp-next-line(weak-randomness) - Mock contract for testing only
            randomWords[i] =
                uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, requestId, i)));
        }

        // Store the random words for later fulfillment
        requestToRandomWords[requestId] = randomWords;

        return requestId;
    }

    /**
     * @notice Fulfill a pending request
     * @param requestId The request ID to fulfill
     */
    function fulfillRequest(uint256 requestId) external {
        address consumer = requestToConsumer[requestId];
        require(consumer != address(0), "MockVRF: Request not found");

        uint256[] memory randomWords = requestToRandomWords[requestId];

        (bool success,) =
            consumer.call(abi.encodeWithSignature("fulfillRandomWords(uint256,uint256[])", requestId, randomWords));

        require(success, "MockVRF: Callback failed");
    }

    /**
     * @notice Manually fulfill a request (for testing specific scenarios)
     * @param requestId The request ID to fulfill
     * @param randomWords Array of random words to provide
     */
    function fulfillRandomWordsManual(uint256 requestId, uint256[] memory randomWords) external {
        address consumer = requestToConsumer[requestId];
        require(consumer != address(0), "MockVRF: Request not found");

        (bool success,) =
            consumer.call(abi.encodeWithSignature("fulfillRandomWords(uint256,uint256[])", requestId, randomWords));

        require(success, "MockVRF: Manual callback failed");
    }
}
