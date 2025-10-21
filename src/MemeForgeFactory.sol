// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MemeToken} from "./MemeToken.sol";
import {MemeSoulNFT} from "./MemeSoulNFT.sol";
import {MemeGovernor} from "./MemeGovernor.sol";
import {ERC6551Registry} from "./ERC6551Registry.sol";
import {TokenBoundAccount} from "./TokenBoundAccount.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title MemeForgeFactory
 * @notice Factory contract for one-click memecoin deployment
 * @dev Deploys complete memecoin ecosystem: Token, NFT, Governance, TBA
 */
contract MemeForgeFactory is Ownable, ReentrancyGuard {
    ///////////////////
    // State Variables
    ///////////////////

    ERC6551Registry public immutable registry;
    TokenBoundAccount public immutable implementation;
    address public immutable stakingVault;

    // Governance parameters
    uint48 public votingDelay = 1 days;
    uint32 public votingPeriod = 1 weeks;
    uint256 public proposalThreshold = 1000e18;
    uint256 public quorumPercentage = 4;
    uint256 public timelockDelay = 2 days;

    // Deployment fee (optional)
    uint256 public deploymentFee;

    // Registry of deployed memecoins
    address[] public allMemecoins;
    mapping(address => DeploymentInfo) public deployments;
    mapping(address => address[]) public creatorMemecoins;

    ///////////////////
    // Type Declarations
    ///////////////////

    struct DeploymentInfo {
        address token;
        address soulNFT;
        address governor;
        address timelock;
        address creator;
        uint256 deployedAt;
        bool exists;
    }

    struct DeploymentParams {
        string name;
        string symbol;
        uint256 initialSupply;
        uint256 rewardRate;
        string theme;
        string logoURI;
        bool enableGovernance;
    }

    ///////////////////
    // Events
    ///////////////////

    event MemecoinDeployed(
        address indexed token,
        address indexed soulNFT,
        address indexed creator,
        address governor,
        address timelock,
        string name,
        string symbol
    );

    event GovernanceParametersUpdated(
        uint48 votingDelay, uint32 votingPeriod, uint256 proposalThreshold, uint256 quorumPercentage
    );

    event DeploymentFeeUpdated(uint256 oldFee, uint256 newFee);

    ///////////////////
    // Errors
    ///////////////////

    error MemeForgeFactory__InsufficientFee();
    error MemeForgeFactory__InvalidParameters();
    error MemeForgeFactory__DeploymentNotFound();
    error MemeForgeFactory__TransferFailed();

    ///////////////////
    // Functions
    ///////////////////

    /**
     * @notice Constructor
     * @param _registry Address of ERC6551Registry
     * @param _implementation Address of TokenBoundAccount implementation
     * @param _stakingVault Address of StakingVault
     */
    constructor(address _registry, address _implementation, address _stakingVault) Ownable(msg.sender) {
        registry = ERC6551Registry(_registry);
        implementation = TokenBoundAccount(payable(_implementation));
        stakingVault = _stakingVault;
    }

    /**
     * @notice Deploy a complete memecoin ecosystem
     * @param params Deployment parameters
     * @return token Address of deployed MemeToken
     * @return soulNFT Address of deployed MemeSoulNFT
     * @return governor Address of deployed MemeGovernor (if enabled)
     * @return timelock Address of deployed TimelockController (if enabled)
     */
    function deployMemecoin(DeploymentParams calldata params)
        external
        payable
        nonReentrant
        returns (address token, address soulNFT, address governor, address timelock)
    {
        // Validate parameters
        if (bytes(params.name).length == 0 || bytes(params.symbol).length == 0) {
            revert MemeForgeFactory__InvalidParameters();
        }
        if (params.initialSupply == 0) revert MemeForgeFactory__InvalidParameters();

        // Check deployment fee
        if (msg.value < deploymentFee) revert MemeForgeFactory__InsufficientFee();

        // Deploy MemeToken (factory receives initial supply)
        MemeToken memeToken = new MemeToken(
            params.name, params.symbol, params.initialSupply, params.rewardRate, params.theme, params.logoURI
        );
        token = address(memeToken);

        // Deploy MemeSoulNFT (factory becomes owner)
        MemeSoulNFT nft = new MemeSoulNFT();
        soulNFT = address(nft);

        // CEI Pattern: Update state BEFORE any external calls
        // Store deployment info in registry FIRST
        DeploymentInfo memory info = DeploymentInfo({
            token: token,
            soulNFT: soulNFT,
            governor: address(0), // Will be updated if governance enabled
            timelock: address(0), // Will be updated if governance enabled
            creator: msg.sender,
            deployedAt: block.timestamp,
            exists: true
        });

        deployments[token] = info;
        allMemecoins.push(token);
        creatorMemecoins[msg.sender].push(token);

        // EFFECTS complete - now safe to make external calls

        // Set staking vault (external call to owned contract)
        memeToken.setStakingVault(stakingVault);

        // Deploy governance if enabled
        if (params.enableGovernance) {
            (governor, timelock) = _deployGovernance(token);
            // Update deployment info with governance addresses
            // aderyn-fp-next-line(reentrancy-state-change) - Updating existing registry entry after governance deployment
            deployments[token].governor = governor;
            deployments[token].timelock = timelock;
        }

        // EFFECTS complete - now safe to make external calls to msg.sender

        // Create metadata for Soul NFT
        MemeSoulNFT.MemecoinMetadata memory metadata = MemeSoulNFT.MemecoinMetadata({
            name: params.name,
            symbol: params.symbol,
            theme: params.theme,
            logoURI: params.logoURI,
            createdAt: block.timestamp,
            creator: msg.sender
        });

        // External calls to msg.sender (potential reentrancy - protected by nonReentrant)
        nft.mintSoulNFT(msg.sender, token, metadata, params.logoURI);
        nft.transferOwnership(msg.sender);

        // Transfer tokens and ownership
        memeToken.transfer(msg.sender, params.initialSupply);

        // Transfer token ownership after token transfer
        if (!params.enableGovernance) {
            memeToken.transferOwnership(msg.sender);
        }

        emit MemecoinDeployed(token, soulNFT, msg.sender, governor, timelock, params.name, params.symbol);

        return (token, soulNFT, governor, timelock);
    }

    /**
     * @notice Deploy governance contracts for a memecoin
     * @param token Address of the MemeToken
     * @return governor Address of deployed MemeGovernor
     * @return timelock Address of deployed TimelockController
     */
    function _deployGovernance(address token) internal returns (address governor, address timelock) {
        // Deploy TimelockController (factory is temporary admin)
        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);
        proposers[0] = address(0); // Will be set to governor
        executors[0] = address(0); // Anyone can execute

        timelock = address(new TimelockController(timelockDelay, proposers, executors, address(this)));

        // Deploy Governor
        governor = address(
            new MemeGovernor(
                IVotes(token),
                TimelockController(payable(timelock)),
                votingDelay,
                votingPeriod,
                proposalThreshold,
                quorumPercentage
            )
        );

        // Grant roles
        bytes32 proposerRole = TimelockController(payable(timelock)).PROPOSER_ROLE();
        bytes32 executorRole = TimelockController(payable(timelock)).EXECUTOR_ROLE();
        bytes32 adminRole = TimelockController(payable(timelock)).DEFAULT_ADMIN_ROLE();

        TimelockController(payable(timelock)).grantRole(proposerRole, governor);
        TimelockController(payable(timelock)).grantRole(executorRole, address(0));

        // Grant admin role to creator for future governance management
        TimelockController(payable(timelock)).grantRole(adminRole, msg.sender);

        // Renounce factory's admin role for decentralization
        TimelockController(payable(timelock)).renounceRole(adminRole, address(this));

        // Set governance address on token before transferring ownership
        MemeToken(token).setGovernance(governor);

        // Transfer token ownership to timelock
        MemeToken(token).transferOwnership(timelock);

        return (governor, timelock);
    }

    ///////////////////
    // View Functions
    ///////////////////

    /**
     * @notice Get deployment info for a memecoin
     * @param token Address of the MemeToken
     * @return info Deployment information
     */
    function getDeploymentInfo(address token) external view returns (DeploymentInfo memory info) {
        info = deployments[token];
        if (!info.exists) revert MemeForgeFactory__DeploymentNotFound();
        return info;
    }

    /**
     * @notice Get all memecoins deployed by a creator
     * @param creator Address of the creator
     * @return Array of memecoin addresses
     */
    function getCreatorMemecoins(address creator) external view returns (address[] memory) {
        return creatorMemecoins[creator];
    }

    /**
     * @notice Get total number of deployed memecoins
     * @return Total count
     */
    function getTotalMemecoins() external view returns (uint256) {
        return allMemecoins.length;
    }

    /**
     * @notice Get memecoin at index
     * @param index Index in the array
     * @return Address of memecoin
     */
    function getMemecoinAtIndex(uint256 index) external view returns (address) {
        return allMemecoins[index];
    }

    /**
     * @notice Get all deployed memecoins
     * @return Array of all memecoin addresses
     */
    function getAllMemecoins() external view returns (address[] memory) {
        return allMemecoins;
    }

    ///////////////////
    // Admin Functions
    ///////////////////

    /**
     * @notice Update governance parameters
     * @param _votingDelay New voting delay
     * @param _votingPeriod New voting period
     * @param _proposalThreshold New proposal threshold
     * @param _quorumPercentage New quorum percentage
     */
    function updateGovernanceParameters(
        uint48 _votingDelay,
        uint32 _votingPeriod,
        uint256 _proposalThreshold,
        uint256 _quorumPercentage
    ) external onlyOwner {
        votingDelay = _votingDelay;
        votingPeriod = _votingPeriod;
        proposalThreshold = _proposalThreshold;
        quorumPercentage = _quorumPercentage;

        emit GovernanceParametersUpdated(_votingDelay, _votingPeriod, _proposalThreshold, _quorumPercentage);
    }

    /**
     * @notice Update deployment fee
     * @param _newFee New deployment fee
     */
    function updateDeploymentFee(uint256 _newFee) external onlyOwner {
        uint256 oldFee = deploymentFee;
        deploymentFee = _newFee;

        emit DeploymentFeeUpdated(oldFee, _newFee);
    }

    /**
     * @notice Withdraw collected fees
     * @param to Address to send fees to
     */
    function withdrawFees(address payable to) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success,) = to.call{value: balance}("");
        if (!success) revert MemeForgeFactory__TransferFailed();
    }

    /**
     * @notice Receive function to accept ETH
     */
    receive() external payable {}
}
