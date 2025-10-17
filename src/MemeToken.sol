// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/**
 * @title MemeToken
 * @dev AI-generated memecoin with built-in utility mechanisms
 * @notice This contract represents a memecoin with staking and governance capabilities
 * @dev Includes ERC20Votes for on-chain governance and delegation
 */
contract MemeToken is ERC20, ERC20Burnable, ERC20Votes, Ownable, ReentrancyGuard {
    ///////////////////
    // Errors
    ///////////////////
    error MemeToken__InsufficientBalance();
    error MemeToken__InsufficientStakedBalance();
    error MemeToken__StakingNotActive();
    error MemeToken__InvalidAddress();
    error MemeToken__InvalidAmount();
    error MemeToken__NoRewardsToClaim();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Address of the linked Soul NFT (ERC-721)
    address public soulNFT;

    /// @notice Address of the staking vault contract
    address public stakingVault;

    /// @notice Address of the governance contract
    address public governance;

    /// @notice Reward rate per block for staking (in wei)
    uint256 public rewardRate;

    /// @notice Total amount of tokens currently staked
    uint256 public totalStaked;

    /// @notice Mapping of user addresses to their staked balance
    mapping(address => uint256) public stakedBalance;

    /// @notice Mapping of user addresses to their last stake timestamp
    mapping(address => uint256) public lastStakeTime;

    /// @notice Mapping of user addresses to their accumulated rewards
    mapping(address => uint256) public pendingRewards;

    /// @notice Theme/description of this memecoin
    string public theme;

    /// @notice URI for the memecoin logo
    string public logoURI;

    /// @notice Whether staking is currently active
    bool public stakingActive;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 oldRate, uint256 newRate);
    event StakingVaultSet(address indexed vault);
    event GovernanceSet(address indexed governance);
    event SoulNFTSet(address indexed nft);
    event StakingStatusChanged(bool active);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Initializes the memecoin with AI-generated parameters
     * @param _name Token name (e.g., "MeowFi")
     * @param _symbol Token symbol (e.g., "MEOW")
     * @param _initialSupply Initial token supply (with decimals)
     * @param _rewardRate Staking reward rate per block
     * @param _theme AI-generated theme/description
     * @param _logoURI URI for the token logo
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        uint256 _rewardRate,
        string memory _theme,
        string memory _logoURI
    ) ERC20(_name, _symbol) Ownable(msg.sender) EIP712(_name, "1") {
        _mint(msg.sender, _initialSupply);
        rewardRate = _rewardRate;
        theme = _theme;
        logoURI = _logoURI;
        stakingActive = true;
        
        // Self-delegate voting power to enable governance participation
        _delegate(msg.sender, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                            STAKING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Stake tokens to earn rewards
     * @param amount Amount of tokens to stake
     */
    function stake(uint256 amount) external nonReentrant {
        if (!stakingActive) revert MemeToken__StakingNotActive();
        if (amount == 0) revert MemeToken__InvalidAmount();
        if (balanceOf(msg.sender) < amount) revert MemeToken__InsufficientBalance();

        // Update pending rewards before changing stake
        _updateRewards(msg.sender);

        // Transfer tokens to this contract
        _transfer(msg.sender, address(this), amount);

        // Update staking state
        stakedBalance[msg.sender] += amount;
        totalStaked += amount;
        lastStakeTime[msg.sender] = block.timestamp;

        emit Staked(msg.sender, amount);
    }

    /**
     * @notice Unstake tokens and claim rewards
     * @param amount Amount of tokens to unstake
     */
    function unstake(uint256 amount) external nonReentrant {
        if (amount == 0) revert MemeToken__InvalidAmount();
        if (stakedBalance[msg.sender] < amount) revert MemeToken__InsufficientStakedBalance();

        // Update and claim pending rewards
        _updateRewards(msg.sender);
        _claimRewards(msg.sender);

        // Update staking state
        stakedBalance[msg.sender] -= amount;
        totalStaked -= amount;

        // Transfer tokens back to user
        _transfer(address(this), msg.sender, amount);

        emit Unstaked(msg.sender, amount);
    }

    /**
     * @notice Claim accumulated staking rewards
     */
    function claimRewards() external nonReentrant {
        _updateRewards(msg.sender);
        _claimRewards(msg.sender);
    }

    /**
     * @notice Calculate pending rewards for a user
     * @param user Address of the user
     * @return Pending reward amount
     */
    function calculateRewards(address user) public view returns (uint256) {
        if (stakedBalance[user] == 0) {
            return pendingRewards[user];
        }

        uint256 stakingDuration = block.timestamp - lastStakeTime[user];
        uint256 newRewards = (stakedBalance[user] * rewardRate * stakingDuration) / 1e18;

        return pendingRewards[user] + newRewards;
    }

    /**
     * @dev Internal function to update user rewards
     * @param user Address of the user
     */
    function _updateRewards(address user) internal {
        if (stakedBalance[user] > 0) {
            uint256 rewards = calculateRewards(user);
            pendingRewards[user] = rewards;
            lastStakeTime[user] = block.timestamp;
        }
    }

    /**
     * @dev Internal function to claim rewards
     * @param user Address of the user
     */
    function _claimRewards(address user) internal {
        uint256 rewards = pendingRewards[user];
        if (rewards == 0) revert MemeToken__NoRewardsToClaim();

        pendingRewards[user] = 0;

        // Mint reward tokens
        _mint(user, rewards);

        emit RewardsClaimed(user, rewards);
    }

    /*//////////////////////////////////////////////////////////////
                          GOVERNANCE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Vote on a governance proposal
     * @dev This is a placeholder - full implementation in MemeGovernance.sol
     * @param proposalId ID of the proposal
     * @param support Whether to support the proposal
     */
    function vote(uint256 proposalId, bool support) external {
        if (governance == address(0)) revert MemeToken__InvalidAddress();

        // Voting power is based on token balance
        uint256 votingPower = balanceOf(msg.sender);
        if (votingPower == 0) revert MemeToken__InsufficientBalance();

        // Call governance contract (will be implemented in Phase 2)
        // IGovernance(governance).castVote(proposalId, msg.sender, support, votingPower);
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Set the staking vault address
     * @param _stakingVault Address of the staking vault
     */
    function setStakingVault(address _stakingVault) external onlyOwner {
        if (_stakingVault == address(0)) revert MemeToken__InvalidAddress();
        stakingVault = _stakingVault;
        emit StakingVaultSet(_stakingVault);
    }

    /**
     * @notice Mint tokens (only callable by staking vault for rewards)
     * @param to Address to mint to
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) external {
        if (msg.sender != stakingVault && msg.sender != owner()) revert MemeToken__InvalidAddress();
        _mint(to, amount);
    }

    /**
     * @notice Set the governance contract address
     * @param _governance Address of the governance contract
     */
    function setGovernance(address _governance) external onlyOwner {
        if (_governance == address(0)) revert MemeToken__InvalidAddress();
        governance = _governance;
        emit GovernanceSet(_governance);
    }

    /**
     * @notice Set the Soul NFT address
     * @param _soulNFT Address of the Soul NFT
     */
    function setSoulNFT(address _soulNFT) external onlyOwner {
        if (_soulNFT == address(0)) revert MemeToken__InvalidAddress();
        soulNFT = _soulNFT;
        emit SoulNFTSet(_soulNFT);
    }

    /**
     * @notice Update the reward rate
     * @param _newRate New reward rate per block
     */
    function setRewardRate(uint256 _newRate) external onlyOwner {
        uint256 oldRate = rewardRate;
        rewardRate = _newRate;
        emit RewardRateUpdated(oldRate, _newRate);
    }

    /**
     * @notice Toggle staking on/off
     * @param _active Whether staking should be active
     */
    function setStakingActive(bool _active) external onlyOwner {
        stakingActive = _active;
        emit StakingStatusChanged(_active);
    }

    /**
     * @notice Update the logo URI
     * @param _newLogoURI New logo URI
     */
    function setLogoURI(string memory _newLogoURI) external onlyOwner {
        logoURI = _newLogoURI;
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get staking information for a user
     * @param user Address of the user
     * @return staked Amount staked
     * @return rewards Pending rewards
     * @return lastStake Last stake timestamp
     */
    function getStakingInfo(address user) external view returns (uint256 staked, uint256 rewards, uint256 lastStake) {
        return (stakedBalance[user], calculateRewards(user), lastStakeTime[user]);
    }

    /**
     * @notice Get memecoin metadata
     * @return tokenName Token name
     * @return tokenSymbol Token symbol
     * @return themeStr Theme description
     * @return logo Logo URI
     * @return supply Total supply
     */
    function getMetadata()
        external
        view
        returns (
            string memory tokenName,
            string memory tokenSymbol,
            string memory themeStr,
            string memory logo,
            uint256 supply
        )
    {
        return (name(), symbol(), theme, logoURI, totalSupply());
    }

    /*//////////////////////////////////////////////////////////////
                        GOVERNANCE OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Override required by ERC20Votes to update voting checkpoints
     * @notice This function is called on every token transfer
     */
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes)
    {
        super._update(from, to, value);
    }
}
