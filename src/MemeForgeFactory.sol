// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MemeToken} from "./MemeToken.sol";
import {ERC6551Registry} from "./ERC6551Registry.sol";
import {TokenBoundAccount} from "./TokenBoundAccount.sol";
import {TokenDeployer} from "./deployers/TokenDeployer.sol";
import {NFTDeployer} from "./deployers/NFTDeployer.sol";
import {DeploymentLib} from "./libraries/DeploymentLib.sol";
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

    // Deployer contracts
    TokenDeployer public immutable tokenDeployer;
    NFTDeployer public immutable nftDeployer;

    // Governance parameters
    uint48 public votingDelay = 1 days;
    uint32 public votingPeriod = 1 weeks;
    uint256 public proposalThreshold = 1000e18;
    uint256 public quorumPercentage = 4;
    uint256 public timelockDelay = 2 days;

    // Deployment fee (optional)
    uint256 public deploymentFee;

    // Use shorter error messages to save bytecode
    error InvalidParams();
    error InsufficientFee();

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

    error Unauthorized();
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

        // Deploy deployer contracts
        tokenDeployer = new TokenDeployer();
        nftDeployer = new NFTDeployer();
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
            revert InvalidParams();
        }
        if (params.initialSupply == 0) revert InvalidParams();

        // Check deployment fee
        if (msg.value < deploymentFee) revert InsufficientFee();

        // Deploy MemeToken via TokenDeployer
        token = tokenDeployer.deployToken(
            params.name, params.symbol, params.initialSupply, params.rewardRate, params.theme, params.logoURI
        );
        MemeToken memeToken = MemeToken(token);

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
            (governor, timelock) = DeploymentLib.deployGovernance(
                token, votingDelay, votingPeriod, proposalThreshold, quorumPercentage, timelockDelay, msg.sender
            );
            // Update deployment info with governance addresses
            // aderyn-fp-next-line(reentrancy-state-change) - Updating existing registry entry after governance deployment
            deployments[token].governor = governor;
            deployments[token].timelock = timelock;
        }

        // EFFECTS complete - now safe to make external calls to msg.sender

        // Deploy and mint NFT via NFTDeployer
        soulNFT = nftDeployer.deployAndMintNFT(
            msg.sender, token, params.name, params.symbol, params.theme, params.logoURI, msg.sender
        );

        // Update soulNFT in deployment info
        deployments[token].soulNFT = soulNFT;

        // Transfer tokens and ownership
        memeToken.transfer(msg.sender, params.initialSupply);

        // Transfer token ownership after token transfer
        if (!params.enableGovernance) {
            memeToken.transferOwnership(msg.sender);
        }

        emit MemecoinDeployed(token, soulNFT, msg.sender, governor, timelock, params.name, params.symbol);

        return (token, soulNFT, governor, timelock);
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
