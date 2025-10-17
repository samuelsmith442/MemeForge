// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MemeToken} from "../src/MemeToken.sol";
import {MemeSoulNFT} from "../src/MemeSoulNFT.sol";
import {ERC6551Registry} from "../src/ERC6551Registry.sol";
import {TokenBoundAccount} from "../src/TokenBoundAccount.sol";
import {StakingVault} from "../src/StakingVault.sol";
import {MockVRFCoordinatorV2} from "../src/mocks/MockVRFCoordinatorV2.sol";
import {MemeGovernor} from "../src/MemeGovernor.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

/**
 * @title DeployMemeForge
 * @dev Deployment script for the complete MemeForge ecosystem
 * @notice Deploys all core contracts: Registry, TBA Implementation, Soul NFT, and example Memecoin
 */
contract DeployMemeForge is Script {
    // Governance parameters
    uint48 public constant VOTING_DELAY = 1 days;
    uint32 public constant VOTING_PERIOD = 1 weeks;
    uint256 public constant PROPOSAL_THRESHOLD = 1000e18; // 1,000 tokens
    uint256 public constant QUORUM_PERCENTAGE = 4; // 4%
    uint256 public constant TIMELOCK_DELAY = 2 days;

    function run()
        external
        returns (
            ERC6551Registry registry,
            TokenBoundAccount implementation,
            MemeSoulNFT soulNFT,
            StakingVault stakingVault,
            MockVRFCoordinatorV2 mockVRF,
            MemeToken exampleToken,
            TimelockController timelock,
            MemeGovernor governor,
            HelperConfig helperConfig
        )
    {
        // Get network configuration
        helperConfig = new HelperConfig();
        (address existingRegistry, address existingImplementation, uint256 deployerKey) =
            helperConfig.activeNetworkConfig();

        // Start broadcasting transactions with the appropriate private key
        vm.startBroadcast(deployerKey);

        // Deploy ERC6551Registry if not already deployed
        if (existingRegistry == address(0)) {
            registry = new ERC6551Registry();
            console.log("ERC6551Registry deployed at:", address(registry));
        } else {
            registry = ERC6551Registry(existingRegistry);
            console.log("Using existing ERC6551Registry at:", address(registry));
        }

        // Deploy TokenBoundAccount implementation if not already deployed
        if (existingImplementation == address(0)) {
            implementation = new TokenBoundAccount();
            console.log("TokenBoundAccount implementation deployed at:", address(implementation));
        } else {
            implementation = TokenBoundAccount(payable(existingImplementation));
            console.log("Using existing TokenBoundAccount implementation at:", address(implementation));
        }

        // Deploy MemeSoulNFT
        soulNFT = new MemeSoulNFT();
        console.log("MemeSoulNFT deployed at:", address(soulNFT));
        console.log("MemeSoulNFT Owner:", soulNFT.owner());

        // Deploy Mock VRF Coordinator (for local testing)
        mockVRF = new MockVRFCoordinatorV2();
        console.log("MockVRFCoordinatorV2 deployed at:", address(mockVRF));

        // Deploy StakingVault with Mock VRF
        stakingVault = new StakingVault(
            address(mockVRF), // VRF Coordinator
            1, // Subscription ID
            bytes32(uint256(1)), // Key Hash
            500_000 // Callback Gas Limit
        );
        console.log("StakingVault deployed at:", address(stakingVault));
        console.log("StakingVault Owner:", stakingVault.owner());

        // Deploy an example MemeToken
        exampleToken = new MemeToken(
            "MeowFi", // name
            "MEOW", // symbol
            1_000_000 * 1e18, // initial supply (1 million tokens)
            1e15, // reward rate (0.001 tokens per second per token staked)
            "A memecoin for cat lovers", // theme
            "ipfs://QmExampleLogoURI" // logoURI
        );
        console.log("Example MemeToken deployed at:", address(exampleToken));
        console.log("MemeToken Owner:", exampleToken.owner());
        console.log("MemeToken Total Supply:", exampleToken.totalSupply());

        // Configure the example token in the staking vault
        stakingVault.configureToken(address(exampleToken), 1e15, true);
        console.log("Example MemeToken configured in StakingVault");

        // Set the staking vault on the example token
        exampleToken.setStakingVault(address(stakingVault));
        console.log("StakingVault set on Example MemeToken");

        // Deploy Governance System
        console.log("\n=== Deploying Governance System ===");

        // Deploy TimelockController
        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);
        proposers[0] = address(0); // Will be set to governor after deployment
        executors[0] = address(0); // Anyone can execute

        timelock = new TimelockController(TIMELOCK_DELAY, proposers, executors, vm.addr(deployerKey));
        console.log("TimelockController deployed at:", address(timelock));
        console.log("Timelock Delay:", TIMELOCK_DELAY);

        // Deploy Governor
        governor = new MemeGovernor(
            IVotes(address(exampleToken)), timelock, VOTING_DELAY, VOTING_PERIOD, PROPOSAL_THRESHOLD, QUORUM_PERCENTAGE
        );
        console.log("MemeGovernor deployed at:", address(governor));
        console.log("Voting Delay:", VOTING_DELAY);
        console.log("Voting Period:", VOTING_PERIOD);
        console.log("Proposal Threshold:", PROPOSAL_THRESHOLD);
        console.log("Quorum Percentage:", QUORUM_PERCENTAGE);

        // Grant roles to governor
        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE();

        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0));
        console.log("Governor granted PROPOSER_ROLE on Timelock");
        console.log("Anyone granted EXECUTOR_ROLE on Timelock");

        // Transfer token ownership to timelock for governance control
        exampleToken.transferOwnership(address(timelock));
        console.log("Example MemeToken ownership transferred to Timelock");

        // Renounce admin role for full decentralization (optional - commented out for safety)
        // timelock.revokeRole(adminRole, vm.addr(deployerKey));
        // console.log("Admin role revoked from deployer (fully decentralized)");

        console.log("=== Governance System Deployed ===\n");

        // Stop broadcasting transactions
        vm.stopBroadcast();

        // Log deployment summary
        console.log("\n=== MemeForge Deployment Summary ===");
        console.log("Network Chain ID:", block.chainid);
        console.log("Deployer:", vm.addr(deployerKey));
        console.log("\n--- Core Infrastructure ---");
        console.log("ERC6551Registry:", address(registry));
        console.log("TokenBoundAccount Implementation:", address(implementation));
        console.log("MemeSoulNFT:", address(soulNFT));
        console.log("\n--- Staking & Rewards ---");
        console.log("MockVRFCoordinatorV2:", address(mockVRF));
        console.log("StakingVault:", address(stakingVault));
        console.log("\n--- Governance ---");
        console.log("TimelockController:", address(timelock));
        console.log("MemeGovernor:", address(governor));
        console.log("\n--- Example Token ---");
        console.log("Example MemeToken:", address(exampleToken));
        console.log("Token Owner:", exampleToken.owner(), "(Timelock for governance)");
        console.log("=====================================\n");

        return (registry, implementation, soulNFT, stakingVault, mockVRF, exampleToken, timelock, governor, helperConfig);
    }
}
