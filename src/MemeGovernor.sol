// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";

/**
 * @title MemeGovernor
 * @dev DAO governance contract for MemeForge ecosystem
 * @notice Allows token holders to create and vote on proposals
 * @dev Uses OpenZeppelin Governor with timelock for security
 */
contract MemeGovernor is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl
{
    /**
     * @dev Initializes the governor contract
     * @param _token The ERC20Votes token used for voting
     * @param _timelock The TimelockController for delayed execution
     * @param _votingDelay Delay before voting starts (in blocks)
     * @param _votingPeriod Duration of voting period (in blocks)
     * @param _proposalThreshold Minimum tokens needed to create proposal
     * @param _quorumPercentage Percentage of total supply needed for quorum
     */
    constructor(
        IVotes _token,
        TimelockController _timelock,
        uint48 _votingDelay,
        uint32 _votingPeriod,
        uint256 _proposalThreshold,
        uint256 _quorumPercentage
    )
        Governor("MemeGovernor")
        GovernorSettings(_votingDelay, _votingPeriod, _proposalThreshold)
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(_quorumPercentage)
        GovernorTimelockControl(_timelock)
    {}

    /*//////////////////////////////////////////////////////////////
                        GOVERNANCE PARAMETER GETTERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the voting delay
     * @return Delay in blocks before voting starts
     */
    function votingDelay() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.votingDelay();
    }

    /**
     * @dev Returns the voting period
     * @return Duration in blocks for voting
     */
    function votingPeriod() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.votingPeriod();
    }

    /**
     * @dev Returns the quorum for a specific block number
     * @param blockNumber The block number to check quorum for
     * @return Number of votes required for quorum
     */
    function quorum(uint256 blockNumber)
        public
        view
        override(Governor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    /**
     * @dev Returns the proposal threshold
     * @return Minimum tokens needed to create a proposal
     */
    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.proposalThreshold();
    }

    /*//////////////////////////////////////////////////////////////
                        PROPOSAL STATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the state of a proposal
     * @param proposalId The ID of the proposal
     * @return Current state of the proposal
     */
    function state(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    /**
     * @dev Returns whether a proposal needs to be queued
     * @param proposalId The ID of the proposal
     * @return True if proposal needs queuing
     */
    function proposalNeedsQueuing(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.proposalNeedsQueuing(proposalId);
    }

    /*//////////////////////////////////////////////////////////////
                        PROPOSAL EXECUTION FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Queue operations in the timelock
     * @param proposalId The ID of the proposal
     * @param targets Array of target addresses
     * @param values Array of ETH values to send
     * @param calldatas Array of function call data
     * @param descriptionHash Hash of the proposal description
     * @return Timelock operation ID
     */
    function _queueOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint48) {
        return super._queueOperations(proposalId, targets, values, calldatas, descriptionHash);
    }

    /**
     * @dev Execute operations through the timelock
     * @param proposalId The ID of the proposal
     * @param targets Array of target addresses
     * @param values Array of ETH values to send
     * @param calldatas Array of function call data
     * @param descriptionHash Hash of the proposal description
     */
    function _executeOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._executeOperations(proposalId, targets, values, calldatas, descriptionHash);
    }

    /**
     * @dev Internal cancel function
     * @param targets Array of target addresses
     * @param values Array of ETH values
     * @param calldatas Array of function call data
     * @param descriptionHash Hash of the proposal description
     * @return Proposal ID
     */
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    /**
     * @dev Returns the executor address (timelock)
     * @return Address of the executor
     */
    function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {
        return super._executor();
    }
}
