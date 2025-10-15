// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IVRFCoordinatorV2.sol";
import "./interfaces/IMintable.sol";

/**
 * @title StakingVault
 * @dev Dedicated staking vault with Chainlink VRF for random reward multipliers
 * @notice Handles staking for multiple MemeTokens with randomized rewards
 */
contract StakingVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    ///////////////////
    // Errors
    ///////////////////
    error StakingVault__InvalidAmount();
    error StakingVault__InsufficientStake();
    error StakingVault__NoRewardsToClaim();
    error StakingVault__InvalidToken();
    error StakingVault__StakingNotActive();
    error StakingVault__InvalidMultiplier();
    error StakingVault__RequestNotFound();

    ///////////////////
    // Type Declarations
    ///////////////////
    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        uint256 lastClaimTime;
        uint256 pendingRewards;
    }

    struct TokenConfig {
        uint256 rewardRate; // Rewards per second per token staked (in wei)
        uint256 totalStaked;
        bool isActive;
    }

    struct RandomnessRequest {
        address user;
        address token;
        uint256 rewardAmount;
    }

    ///////////////////
    // State Variables
    ///////////////////

    /// @notice Chainlink VRF Coordinator
    IVRFCoordinatorV2 public immutable vrfCoordinator;

    /// @notice VRF subscription ID
    uint64 public subscriptionId;

    /// @notice VRF key hash
    bytes32 public keyHash;

    /// @notice VRF callback gas limit
    uint32 public callbackGasLimit;

    /// @notice VRF request confirmations
    uint16 public requestConfirmations;

    /// @notice VRF number of random words
    uint32 public numWords;

    /// @notice Minimum multiplier (100 = 1x)
    uint256 public constant MIN_MULTIPLIER = 100;

    /// @notice Maximum multiplier (500 = 5x)
    uint256 public constant MAX_MULTIPLIER = 500;

    /// @notice Multiplier precision
    uint256 public constant MULTIPLIER_PRECISION = 100;

    /// @notice Mapping of token address to configuration
    mapping(address => TokenConfig) public tokenConfigs;

    /// @notice Mapping of user => token => stake info
    mapping(address => mapping(address => StakeInfo)) public stakes;

    /// @notice Mapping of VRF request ID to randomness request
    mapping(uint256 => RandomnessRequest) public randomnessRequests;

    ///////////////////
    // Events
    ///////////////////
    event TokenConfigured(address indexed token, uint256 rewardRate, bool isActive);
    event Staked(address indexed user, address indexed token, uint256 amount);
    event Unstaked(address indexed user, address indexed token, uint256 amount);
    event RewardsClaimed(address indexed user, address indexed token, uint256 amount, uint256 multiplier);
    event RandomnessRequested(uint256 indexed requestId, address indexed user, address indexed token);
    event VRFConfigUpdated(uint64 subscriptionId, bytes32 keyHash, uint32 callbackGasLimit);

    ///////////////////
    // Constructor
    ///////////////////
    constructor(address _vrfCoordinator, uint64 _subscriptionId, bytes32 _keyHash, uint32 _callbackGasLimit)
        Ownable(msg.sender)
    {
        vrfCoordinator = IVRFCoordinatorV2(_vrfCoordinator);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = 3;
        numWords = 1;
    }

    ///////////////////
    // External Functions
    ///////////////////

    /**
     * @notice Stake tokens to earn rewards
     * @param token Address of the token to stake
     * @param amount Amount to stake
     */
    function stake(address token, uint256 amount) external nonReentrant {
        if (amount == 0) revert StakingVault__InvalidAmount();
        if (!tokenConfigs[token].isActive) revert StakingVault__StakingNotActive();

        // Update rewards before changing stake
        _updateRewards(msg.sender, token);

        // Transfer tokens to vault
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // Update stake info
        stakes[msg.sender][token].amount += amount;
        stakes[msg.sender][token].startTime = block.timestamp;
        stakes[msg.sender][token].lastClaimTime = block.timestamp;

        tokenConfigs[token].totalStaked += amount;

        emit Staked(msg.sender, token, amount);
    }

    /**
     * @notice Unstake tokens
     * @param token Address of the token to unstake
     * @param amount Amount to unstake
     */
    function unstake(address token, uint256 amount) external nonReentrant {
        if (amount == 0) revert StakingVault__InvalidAmount();
        if (stakes[msg.sender][token].amount < amount) revert StakingVault__InsufficientStake();

        // Update rewards before unstaking
        _updateRewards(msg.sender, token);

        // Update stake info
        stakes[msg.sender][token].amount -= amount;
        tokenConfigs[token].totalStaked -= amount;

        // Transfer tokens back to user
        IERC20(token).safeTransfer(msg.sender, amount);

        emit Unstaked(msg.sender, token, amount);
    }

    /**
     * @notice Claim rewards with random multiplier from Chainlink VRF
     * @param token Address of the token to claim rewards for
     */
    function claimRewards(address token) external nonReentrant {
        _updateRewards(msg.sender, token);

        uint256 rewards = stakes[msg.sender][token].pendingRewards;
        if (rewards == 0) revert StakingVault__NoRewardsToClaim();

        // Request random multiplier from Chainlink VRF
        uint256 requestId =
            vrfCoordinator.requestRandomWords(keyHash, subscriptionId, requestConfirmations, callbackGasLimit, numWords);

        // Store request info
        randomnessRequests[requestId] = RandomnessRequest({user: msg.sender, token: token, rewardAmount: rewards});

        // Clear pending rewards (will be minted after VRF callback)
        stakes[msg.sender][token].pendingRewards = 0;

        emit RandomnessRequested(requestId, msg.sender, token);
    }

    /**
     * @notice Callback function for Chainlink VRF
     * @param requestId The ID of the VRF request
     * @param randomWords Array of random values from VRF
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external nonReentrant {
        // Only VRF coordinator can call this
        require(msg.sender == address(vrfCoordinator), "Only VRF coordinator");

        RandomnessRequest memory request = randomnessRequests[requestId];
        if (request.user == address(0)) revert StakingVault__RequestNotFound();

        // Calculate random multiplier (1x to 5x)
        uint256 multiplier = MIN_MULTIPLIER + (randomWords[0] % (MAX_MULTIPLIER - MIN_MULTIPLIER + 1));

        // Calculate final reward with multiplier
        uint256 finalReward = (request.rewardAmount * multiplier) / MULTIPLIER_PRECISION;

        // Mint rewards to user
        IMintable(request.token).mint(request.user, finalReward);

        emit RewardsClaimed(request.user, request.token, finalReward, multiplier);

        // Clean up request
        delete randomnessRequests[requestId];
    }

    ///////////////////
    // Public Functions
    ///////////////////

    /**
     * @notice Calculate pending rewards for a user
     * @param user Address of the user
     * @param token Address of the token
     * @return Pending rewards amount
     */
    function calculateRewards(address user, address token) public view returns (uint256) {
        StakeInfo memory stakeInfo = stakes[user][token];
        if (stakeInfo.amount == 0) {
            return stakeInfo.pendingRewards;
        }

        uint256 stakingDuration = block.timestamp - stakeInfo.lastClaimTime;
        uint256 rewardRate = tokenConfigs[token].rewardRate;
        uint256 newRewards = (stakeInfo.amount * rewardRate * stakingDuration) / 1e18;

        return stakeInfo.pendingRewards + newRewards;
    }

    ///////////////////
    // Internal Functions
    ///////////////////

    /**
     * @dev Update pending rewards for a user
     * @param user Address of the user
     * @param token Address of the token
     */
    function _updateRewards(address user, address token) internal {
        if (stakes[user][token].amount > 0) {
            uint256 rewards = calculateRewards(user, token);
            stakes[user][token].pendingRewards = rewards;
            stakes[user][token].lastClaimTime = block.timestamp;
        }
    }

    ///////////////////
    // Admin Functions
    ///////////////////

    /**
     * @notice Configure a token for staking
     * @param token Address of the token
     * @param rewardRate Reward rate per second per token
     * @param isActive Whether staking is active for this token
     */
    function configureToken(address token, uint256 rewardRate, bool isActive) external onlyOwner {
        if (token == address(0)) revert StakingVault__InvalidToken();

        tokenConfigs[token] = TokenConfig({
            rewardRate: rewardRate,
            totalStaked: tokenConfigs[token].totalStaked, // Preserve existing stakes
            isActive: isActive
        });

        emit TokenConfigured(token, rewardRate, isActive);
    }

    /**
     * @notice Update VRF configuration
     * @param _subscriptionId New subscription ID
     * @param _keyHash New key hash
     * @param _callbackGasLimit New callback gas limit
     */
    function updateVRFConfig(uint64 _subscriptionId, bytes32 _keyHash, uint32 _callbackGasLimit) external onlyOwner {
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;

        emit VRFConfigUpdated(_subscriptionId, _keyHash, _callbackGasLimit);
    }

    ///////////////////
    // View Functions
    ///////////////////

    /**
     * @notice Get stake information for a user
     * @param user Address of the user
     * @param token Address of the token
     * @return amount Staked amount
     * @return startTime Stake start time
     * @return pendingRewards Pending rewards
     */
    function getStakeInfo(address user, address token)
        external
        view
        returns (uint256 amount, uint256 startTime, uint256 pendingRewards)
    {
        StakeInfo memory stakeInfo = stakes[user][token];
        return (stakeInfo.amount, stakeInfo.startTime, calculateRewards(user, token));
    }

    /**
     * @notice Get token configuration
     * @param token Address of the token
     * @return rewardRate Reward rate
     * @return totalStaked Total staked amount
     * @return isActive Whether staking is active
     */
    function getTokenConfig(address token)
        external
        view
        returns (uint256 rewardRate, uint256 totalStaked, bool isActive)
    {
        TokenConfig memory config = tokenConfigs[token];
        return (config.rewardRate, config.totalStaked, config.isActive);
    }
}
