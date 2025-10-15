// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/StakingVault.sol";
import "../src/MemeToken.sol";
import "../src/mocks/MockVRFCoordinatorV2.sol";

contract StakingVaultTest is Test {
    StakingVault public vault;
    MockVRFCoordinatorV2 public mockVRF;
    MemeToken public token1;
    MemeToken public token2;

    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);

    uint256 constant INITIAL_SUPPLY = 1_000_000 * 1e18;
    uint256 constant REWARD_RATE = 1e15; // 0.001 tokens per second per token staked
    bytes32 constant KEY_HASH = bytes32(uint256(1));
    uint64 constant SUBSCRIPTION_ID = 1;
    uint32 constant CALLBACK_GAS_LIMIT = 500_000;

    function setUp() public {
        vm.startPrank(owner);

        // Deploy mock VRF coordinator
        mockVRF = new MockVRFCoordinatorV2();

        // Deploy staking vault
        vault = new StakingVault(address(mockVRF), SUBSCRIPTION_ID, KEY_HASH, CALLBACK_GAS_LIMIT);

        // Deploy test tokens
        token1 = new MemeToken("TestToken1", "TT1", INITIAL_SUPPLY, REWARD_RATE, "Test theme 1", "ipfs://logo1");

        token2 = new MemeToken("TestToken2", "TT2", INITIAL_SUPPLY, REWARD_RATE, "Test theme 2", "ipfs://logo2");

        // Configure tokens in vault
        vault.configureToken(address(token1), REWARD_RATE, true);
        vault.configureToken(address(token2), REWARD_RATE, true);

        // Set vault address on tokens so they can mint rewards
        token1.setStakingVault(address(vault));
        token2.setStakingVault(address(vault));

        // Transfer tokens to users
        token1.transfer(user1, 100_000 * 1e18);
        token1.transfer(user2, 100_000 * 1e18);
        token2.transfer(user1, 100_000 * 1e18);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                            DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Deployment() public {
        assertEq(address(vault.vrfCoordinator()), address(mockVRF));
        assertEq(vault.subscriptionId(), SUBSCRIPTION_ID);
        assertEq(vault.keyHash(), KEY_HASH);
        assertEq(vault.callbackGasLimit(), CALLBACK_GAS_LIMIT);
        assertEq(vault.owner(), owner);
    }

    function test_TokenConfiguration() public {
        (uint256 rewardRate, uint256 totalStaked, bool isActive) = vault.getTokenConfig(address(token1));
        assertEq(rewardRate, REWARD_RATE);
        assertEq(totalStaked, 0);
        assertTrue(isActive);
    }

    /*//////////////////////////////////////////////////////////////
                            STAKING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Stake() public {
        uint256 stakeAmount = 1000 * 1e18;

        vm.startPrank(user1);
        token1.approve(address(vault), stakeAmount);
        vault.stake(address(token1), stakeAmount);
        vm.stopPrank();

        (uint256 amount, uint256 startTime, uint256 pendingRewards) = vault.getStakeInfo(user1, address(token1));
        assertEq(amount, stakeAmount);
        assertEq(startTime, block.timestamp);
        assertEq(pendingRewards, 0);

        (, uint256 totalStaked,) = vault.getTokenConfig(address(token1));
        assertEq(totalStaked, stakeAmount);
    }

    function test_StakeMultipleUsers() public {
        uint256 stakeAmount1 = 1000 * 1e18;
        uint256 stakeAmount2 = 2000 * 1e18;

        // User1 stakes
        vm.startPrank(user1);
        token1.approve(address(vault), stakeAmount1);
        vault.stake(address(token1), stakeAmount1);
        vm.stopPrank();

        // User2 stakes
        vm.startPrank(user2);
        token1.approve(address(vault), stakeAmount2);
        vault.stake(address(token1), stakeAmount2);
        vm.stopPrank();

        (uint256 amount1,,) = vault.getStakeInfo(user1, address(token1));
        (uint256 amount2,,) = vault.getStakeInfo(user2, address(token1));

        assertEq(amount1, stakeAmount1);
        assertEq(amount2, stakeAmount2);

        (, uint256 totalStaked,) = vault.getTokenConfig(address(token1));
        assertEq(totalStaked, stakeAmount1 + stakeAmount2);
    }

    function test_StakeMultipleTokens() public {
        uint256 stakeAmount = 1000 * 1e18;

        vm.startPrank(user1);

        // Stake token1
        token1.approve(address(vault), stakeAmount);
        vault.stake(address(token1), stakeAmount);

        // Stake token2
        token2.approve(address(vault), stakeAmount);
        vault.stake(address(token2), stakeAmount);

        vm.stopPrank();

        (uint256 amount1,,) = vault.getStakeInfo(user1, address(token1));
        (uint256 amount2,,) = vault.getStakeInfo(user1, address(token2));

        assertEq(amount1, stakeAmount);
        assertEq(amount2, stakeAmount);
    }

    function test_RevertWhen_StakeZeroAmount() public {
        vm.startPrank(user1);
        vm.expectRevert(StakingVault.StakingVault__InvalidAmount.selector);
        vault.stake(address(token1), 0);
        vm.stopPrank();
    }

    function test_RevertWhen_StakeInactiveToken() public {
        vm.prank(owner);
        vault.configureToken(address(token1), REWARD_RATE, false);

        vm.startPrank(user1);
        token1.approve(address(vault), 1000 * 1e18);
        vm.expectRevert(StakingVault.StakingVault__StakingNotActive.selector);
        vault.stake(address(token1), 1000 * 1e18);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                            UNSTAKING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Unstake() public {
        uint256 stakeAmount = 1000 * 1e18;
        uint256 unstakeAmount = 500 * 1e18;

        vm.startPrank(user1);
        token1.approve(address(vault), stakeAmount);
        vault.stake(address(token1), stakeAmount);

        uint256 balanceBefore = token1.balanceOf(user1);
        vault.unstake(address(token1), unstakeAmount);
        uint256 balanceAfter = token1.balanceOf(user1);

        vm.stopPrank();

        assertEq(balanceAfter - balanceBefore, unstakeAmount);

        (uint256 amount,,) = vault.getStakeInfo(user1, address(token1));
        assertEq(amount, stakeAmount - unstakeAmount);
    }

    function test_UnstakeAll() public {
        uint256 stakeAmount = 1000 * 1e18;

        vm.startPrank(user1);
        token1.approve(address(vault), stakeAmount);
        vault.stake(address(token1), stakeAmount);

        vault.unstake(address(token1), stakeAmount);
        vm.stopPrank();

        (uint256 amount,,) = vault.getStakeInfo(user1, address(token1));
        assertEq(amount, 0);
    }

    function test_RevertWhen_UnstakeZeroAmount() public {
        vm.startPrank(user1);
        vm.expectRevert(StakingVault.StakingVault__InvalidAmount.selector);
        vault.unstake(address(token1), 0);
        vm.stopPrank();
    }

    function test_RevertWhen_UnstakeMoreThanStaked() public {
        uint256 stakeAmount = 1000 * 1e18;

        vm.startPrank(user1);
        token1.approve(address(vault), stakeAmount);
        vault.stake(address(token1), stakeAmount);

        vm.expectRevert(StakingVault.StakingVault__InsufficientStake.selector);
        vault.unstake(address(token1), stakeAmount + 1);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                            REWARD TESTS
    //////////////////////////////////////////////////////////////*/

    function test_CalculateRewards() public {
        uint256 stakeAmount = 1000 * 1e18;

        vm.startPrank(user1);
        token1.approve(address(vault), stakeAmount);
        vault.stake(address(token1), stakeAmount);
        vm.stopPrank();

        // Fast forward 1 day
        vm.warp(block.timestamp + 1 days);

        uint256 expectedRewards = (stakeAmount * REWARD_RATE * 1 days) / 1e18;
        uint256 actualRewards = vault.calculateRewards(user1, address(token1));

        assertEq(actualRewards, expectedRewards);
    }

    function test_ClaimRewardsWithRandomMultiplier() public {
        uint256 stakeAmount = 1000 * 1e18;

        vm.startPrank(user1);
        token1.approve(address(vault), stakeAmount);
        vault.stake(address(token1), stakeAmount);
        vm.stopPrank();

        // Fast forward 1 day
        vm.warp(block.timestamp + 1 days);

        uint256 balanceBefore = token1.balanceOf(user1);

        // Request rewards
        vm.prank(user1);
        vault.claimRewards(address(token1));

        // Fulfill the VRF request (requestId = 1 for first request)
        mockVRF.fulfillRequest(1);

        uint256 balanceAfter = token1.balanceOf(user1);
        uint256 rewardReceived = balanceAfter - balanceBefore;

        // Reward should be between 1x and 5x the base reward
        uint256 baseReward = (stakeAmount * REWARD_RATE * 1 days) / 1e18;
        uint256 minReward = baseReward; // 1x multiplier
        uint256 maxReward = (baseReward * 5); // 5x multiplier

        assertGe(rewardReceived, minReward);
        assertLe(rewardReceived, maxReward);
    }

    function test_RevertWhen_ClaimWithNoRewards() public {
        vm.startPrank(user1);
        token1.approve(address(vault), 1000 * 1e18);
        vault.stake(address(token1), 1000 * 1e18);

        // Try to claim immediately (no time passed)
        vm.expectRevert(StakingVault.StakingVault__NoRewardsToClaim.selector);
        vault.claimRewards(address(token1));
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ConfigureToken() public {
        address newToken = address(0x123);
        uint256 newRewardRate = 2e15;

        vm.prank(owner);
        vault.configureToken(newToken, newRewardRate, true);

        (uint256 rewardRate,, bool isActive) = vault.getTokenConfig(newToken);
        assertEq(rewardRate, newRewardRate);
        assertTrue(isActive);
    }

    function test_UpdateVRFConfig() public {
        uint64 newSubId = 2;
        bytes32 newKeyHash = bytes32(uint256(2));
        uint32 newGasLimit = 600_000;

        vm.prank(owner);
        vault.updateVRFConfig(newSubId, newKeyHash, newGasLimit);

        assertEq(vault.subscriptionId(), newSubId);
        assertEq(vault.keyHash(), newKeyHash);
        assertEq(vault.callbackGasLimit(), newGasLimit);
    }

    function test_RevertWhen_NonOwnerConfiguresToken() public {
        vm.prank(user1);
        vm.expectRevert();
        vault.configureToken(address(token1), REWARD_RATE, true);
    }

    /*//////////////////////////////////////////////////////////////
                        INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_FullStakingCycle() public {
        uint256 stakeAmount = 1000 * 1e18;

        // Stake
        vm.startPrank(user1);
        token1.approve(address(vault), stakeAmount);
        vault.stake(address(token1), stakeAmount);
        vm.stopPrank();

        // Wait and accumulate rewards
        vm.warp(block.timestamp + 7 days);

        // Claim rewards
        uint256 balanceBefore = token1.balanceOf(user1);
        vm.prank(user1);
        vault.claimRewards(address(token1));

        // Fulfill VRF request
        mockVRF.fulfillRequest(1);

        uint256 balanceAfter = token1.balanceOf(user1);

        assertTrue(balanceAfter > balanceBefore);

        // Unstake
        vm.prank(user1);
        vault.unstake(address(token1), stakeAmount);

        (uint256 finalStake,,) = vault.getStakeInfo(user1, address(token1));
        assertEq(finalStake, 0);
    }

    function test_MultipleUsersCompetingForRewards() public {
        uint256 stake1 = 1000 * 1e18;
        uint256 stake2 = 2000 * 1e18;

        // Both users stake
        vm.startPrank(user1);
        token1.approve(address(vault), stake1);
        vault.stake(address(token1), stake1);
        vm.stopPrank();

        vm.startPrank(user2);
        token1.approve(address(vault), stake2);
        vault.stake(address(token1), stake2);
        vm.stopPrank();

        // Fast forward
        vm.warp(block.timestamp + 1 days);

        // Both claim rewards
        uint256 balance1Before = token1.balanceOf(user1);
        vm.prank(user1);
        vault.claimRewards(address(token1));
        mockVRF.fulfillRequest(1); // Fulfill user1's request
        uint256 rewards1 = token1.balanceOf(user1) - balance1Before;

        uint256 balance2Before = token1.balanceOf(user2);
        vm.prank(user2);
        vault.claimRewards(address(token1));
        mockVRF.fulfillRequest(2); // Fulfill user2's request
        uint256 rewards2 = token1.balanceOf(user2) - balance2Before;

        // User2 should have approximately 2x rewards (before multiplier)
        // We can't test exact amounts due to random multipliers
        assertTrue(rewards1 > 0);
        assertTrue(rewards2 > 0);
    }
}
