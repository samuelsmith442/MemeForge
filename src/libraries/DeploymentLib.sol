// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MemeToken} from "../MemeToken.sol";
import {MemeSoulNFT} from "../MemeSoulNFT.sol";
import {MemeGovernor} from "../MemeGovernor.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";

/**
 * @title DeploymentLib
 * @notice Contract for deploying governance components
 * @dev Extracted to reduce MemeForgeFactory contract size
 * Changed from library to contract to avoid size limit issues
 */
contract DeploymentLib {
    /**
     * @notice Deploy governance contracts for a memecoin
     * @param token Address of the MemeToken
     * @param votingDelay Voting delay period
     * @param votingPeriod Voting period duration
     * @param proposalThreshold Minimum tokens required to create proposal
     * @param quorumPercentage Percentage of votes required for quorum
     * @param timelockDelay Timelock delay period
     * @param creator Address of the memecoin creator
     * @return governor Address of deployed MemeGovernor
     * @return timelock Address of deployed TimelockController
     */
    function deployGovernance(
        address token,
        uint48 votingDelay,
        uint32 votingPeriod,
        uint256 proposalThreshold,
        uint256 quorumPercentage,
        uint256 timelockDelay,
        address creator
    ) external returns (address governor, address timelock) {
        // Deploy TimelockController (factory is temporary admin)
        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);
        proposers[0] = address(0); // Will be set to governor
        executors[0] = address(0); // Anyone can execute

        // In library context with delegatecall, address(this) is the factory
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
        TimelockController(payable(timelock)).grantRole(adminRole, creator);

        // Renounce deployer's admin role for decentralization
        TimelockController(payable(timelock)).renounceRole(adminRole, address(this));

        // Note: Token ownership and governance setup handled by factory
        return (governor, timelock);
    }
}
