// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/MemeToken.sol";
import "../src/MemeGovernor.sol";
import "../src/StakingVault.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";

contract GovernanceTest is Test {
    MemeToken public token;
    MemeGovernor public governor;
    TimelockController public timelock;
    StakingVault public stakingVault;

    address public owner = address(1);
    address public voter1 = address(2);
    address public voter2 = address(3);
    address public voter3 = address(4);

    // Governance parameters
    uint48 public constant VOTING_DELAY = 1 days;
    uint32 public constant VOTING_PERIOD = 1 weeks;
    uint256 public constant PROPOSAL_THRESHOLD = 1000e18; // 1,000 tokens
    uint256 public constant QUORUM_PERCENTAGE = 4; // 4%
    uint256 public constant TIMELOCK_DELAY = 2 days;

    // Token supply
    uint256 public constant INITIAL_SUPPLY = 1_000_000e18; // 1M tokens

    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 voteStart,
        uint256 voteEnd,
        string description
    );

    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 weight, string reason);

    function setUp() public {
        vm.startPrank(owner);

        // Deploy token
        token = new MemeToken("TestMeme", "TMEME", INITIAL_SUPPLY, 1e15, "Test Theme", "ipfs://test");

        // Setup timelock
        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);
        proposers[0] = address(0); // Will be set to governor after deployment
        executors[0] = address(0); // Anyone can execute

        timelock = new TimelockController(TIMELOCK_DELAY, proposers, executors, owner);

        // Deploy governor
        governor = new MemeGovernor(
            IVotes(address(token)), timelock, VOTING_DELAY, VOTING_PERIOD, PROPOSAL_THRESHOLD, QUORUM_PERCENTAGE
        );

        // Grant roles to governor
        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE();

        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0)); // Anyone can execute
        timelock.revokeRole(adminRole, owner); // Renounce admin for full decentralization

        // Distribute tokens BEFORE transferring ownership
        token.transfer(voter1, 100_000e18); // 10% - enough for proposals
        token.transfer(voter2, 50_000e18); // 5% - enough for quorum
        token.transfer(voter3, 20_000e18); // 2%

        // Transfer token ownership to timelock for governance control
        token.transferOwnership(address(timelock));

        vm.stopPrank();

        // Delegate voting power
        vm.prank(owner);
        token.delegate(owner);

        vm.prank(voter1);
        token.delegate(voter1);

        vm.prank(voter2);
        token.delegate(voter2);

        vm.prank(voter3);
        token.delegate(voter3);

        // Move forward 1 block so delegation takes effect
        vm.roll(block.number + 1);
    }

    /*//////////////////////////////////////////////////////////////
                        DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Deployment() public view {
        assertEq(governor.name(), "MemeGovernor");
        assertEq(address(governor.token()), address(token));
        assertEq(governor.votingDelay(), VOTING_DELAY);
        assertEq(governor.votingPeriod(), VOTING_PERIOD);
        assertEq(governor.proposalThreshold(), PROPOSAL_THRESHOLD);
    }

    function test_TimelockRoles() public view {
        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();

        assertTrue(timelock.hasRole(proposerRole, address(governor)));
        assertTrue(timelock.hasRole(executorRole, address(0)));
    }

    function test_VotingPower() public view {
        assertEq(token.getVotes(owner), 830_000e18); // Remaining after transfers
        assertEq(token.getVotes(voter1), 100_000e18);
        assertEq(token.getVotes(voter2), 50_000e18);
        assertEq(token.getVotes(voter3), 20_000e18);
    }

    /*//////////////////////////////////////////////////////////////
                        PROPOSAL CREATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_CreateProposal() public {
        // Create proposal to change reward rate
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(token);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature("setRewardRate(uint256)", 2e15);

        string memory description = "Proposal #1: Increase reward rate to 0.002";

        vm.prank(voter1);
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        assertTrue(proposalId > 0);
        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Pending));
    }

    function test_RevertWhen_ProposalThresholdNotMet() public {
        // Create a new voter with insufficient tokens
        address poorVoter = address(5);

        vm.prank(owner);
        token.transfer(poorVoter, 500e18); // Only 500 tokens, needs 1000

        vm.prank(poorVoter);
        token.delegate(poorVoter);

        vm.roll(block.number + 1);

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(token);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature("setRewardRate(uint256)", 2e15);

        vm.prank(poorVoter);
        vm.expectRevert();
        governor.propose(targets, values, calldatas, "Test proposal");
    }

    function test_MultipleProposals() public {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(token);
        values[0] = 0;

        vm.startPrank(voter1);

        calldatas[0] = abi.encodeWithSignature("setRewardRate(uint256)", 2e15);
        uint256 proposalId1 = governor.propose(targets, values, calldatas, "Proposal #1");

        calldatas[0] = abi.encodeWithSignature("setRewardRate(uint256)", 3e15);
        uint256 proposalId2 = governor.propose(targets, values, calldatas, "Proposal #2");

        vm.stopPrank();

        assertTrue(proposalId1 != proposalId2);
    }

    /*//////////////////////////////////////////////////////////////
                        VOTING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_VoteFor() public {
        uint256 proposalId = _createProposal();

        // Move past voting delay
        vm.roll(block.number + VOTING_DELAY + 1);

        vm.prank(voter1);
        governor.castVote(proposalId, 1); // 1 = For

        (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) = governor.proposalVotes(proposalId);

        assertEq(forVotes, 100_000e18);
        assertEq(againstVotes, 0);
        assertEq(abstainVotes, 0);
    }

    function test_VoteAgainst() public {
        uint256 proposalId = _createProposal();

        vm.roll(block.number + VOTING_DELAY + 1);

        vm.prank(voter1);
        governor.castVote(proposalId, 0); // 0 = Against

        (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) = governor.proposalVotes(proposalId);

        assertEq(againstVotes, 100_000e18);
        assertEq(forVotes, 0);
        assertEq(abstainVotes, 0);
    }

    function test_VoteAbstain() public {
        uint256 proposalId = _createProposal();

        vm.roll(block.number + VOTING_DELAY + 1);

        vm.prank(voter1);
        governor.castVote(proposalId, 2); // 2 = Abstain

        (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) = governor.proposalVotes(proposalId);

        assertEq(abstainVotes, 100_000e18);
        assertEq(forVotes, 0);
        assertEq(againstVotes, 0);
    }

    function test_MultipleVoters() public {
        uint256 proposalId = _createProposal();

        vm.roll(block.number + VOTING_DELAY + 1);

        vm.prank(voter1);
        governor.castVote(proposalId, 1); // For

        vm.prank(voter2);
        governor.castVote(proposalId, 1); // For

        vm.prank(voter3);
        governor.castVote(proposalId, 0); // Against

        (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) = governor.proposalVotes(proposalId);

        assertEq(forVotes, 150_000e18); // voter1 + voter2
        assertEq(againstVotes, 20_000e18); // voter3
        assertEq(abstainVotes, 0);
    }

    function test_RevertWhen_VoteTwice() public {
        uint256 proposalId = _createProposal();

        vm.roll(block.number + VOTING_DELAY + 1);

        vm.startPrank(voter1);
        governor.castVote(proposalId, 1);

        vm.expectRevert();
        governor.castVote(proposalId, 1);
        vm.stopPrank();
    }

    function test_RevertWhen_VoteBeforeDelay() public {
        uint256 proposalId = _createProposal();

        // Don't move forward - still in delay period
        vm.prank(voter1);
        vm.expectRevert();
        governor.castVote(proposalId, 1);
    }

    function test_RevertWhen_VoteAfterPeriod() public {
        uint256 proposalId = _createProposal();

        // Move past voting period
        vm.roll(block.number + VOTING_DELAY + VOTING_PERIOD + 1);

        vm.prank(voter1);
        vm.expectRevert();
        governor.castVote(proposalId, 1);
    }

    /*//////////////////////////////////////////////////////////////
                        QUORUM TESTS
    //////////////////////////////////////////////////////////////*/

    function test_QuorumReached() public {
        uint256 proposalId = _createProposal();

        vm.roll(block.number + VOTING_DELAY + 1);

        // Need 4% of 1M = 40k tokens
        vm.prank(voter2); // Has 50k tokens
        governor.castVote(proposalId, 1);

        // Move to end of voting period
        vm.roll(block.number + VOTING_PERIOD);

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Succeeded));
    }

    function test_QuorumNotReached() public {
        uint256 proposalId = _createProposal();

        vm.roll(block.number + VOTING_DELAY + 1);

        // Only 20k tokens voted (need 40k for quorum)
        vm.prank(voter3);
        governor.castVote(proposalId, 1);

        vm.roll(block.number + VOTING_PERIOD);

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Defeated));
    }

    /*//////////////////////////////////////////////////////////////
                        EXECUTION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_QueueAndExecuteProposal() public {
        uint256 proposalId = _createAndPassProposal();

        // Queue the proposal
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(token);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature("setRewardRate(uint256)", 2e15);

        string memory description = "Proposal #1: Increase reward rate to 0.002";

        governor.queue(targets, values, calldatas, keccak256(bytes(description)));

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Queued));

        // Wait for timelock delay
        vm.warp(block.timestamp + TIMELOCK_DELAY + 1);

        // Execute
        governor.execute(targets, values, calldatas, keccak256(bytes(description)));

        assertEq(uint8(governor.state(proposalId)), uint8(IGovernor.ProposalState.Executed));
        assertEq(token.rewardRate(), 2e15);
    }

    function test_RevertWhen_ExecuteBeforeTimelock() public {
        _createAndPassProposal();

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(token);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature("setRewardRate(uint256)", 2e15);

        string memory description = "Proposal #1: Increase reward rate to 0.002";

        governor.queue(targets, values, calldatas, keccak256(bytes(description)));

        // Try to execute immediately (before timelock delay)
        vm.expectRevert();
        governor.execute(targets, values, calldatas, keccak256(bytes(description)));
    }

    function test_RevertWhen_ExecuteFailedProposal() public {
        uint256 proposalId = _createProposal();

        vm.roll(block.number + VOTING_DELAY + 1);

        // Vote against
        vm.prank(voter1);
        governor.castVote(proposalId, 0);

        vm.roll(block.number + VOTING_PERIOD);

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(token);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature("setRewardRate(uint256)", 2e15);

        string memory description = "Proposal #1: Increase reward rate to 0.002";

        vm.expectRevert();
        governor.queue(targets, values, calldatas, keccak256(bytes(description)));
    }

    /*//////////////////////////////////////////////////////////////
                        HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _createProposal() internal returns (uint256) {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        targets[0] = address(token);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSignature("setRewardRate(uint256)", 2e15);

        string memory description = "Proposal #1: Increase reward rate to 0.002";

        vm.prank(voter1);
        return governor.propose(targets, values, calldatas, description);
    }

    function _createAndPassProposal() internal returns (uint256) {
        uint256 proposalId = _createProposal();

        // Move past voting delay
        vm.roll(block.number + VOTING_DELAY + 1);

        // Vote with enough tokens to reach quorum and pass
        vm.prank(voter1);
        governor.castVote(proposalId, 1);

        vm.prank(voter2);
        governor.castVote(proposalId, 1);

        // Move to end of voting period
        vm.roll(block.number + VOTING_PERIOD);

        return proposalId;
    }
}
