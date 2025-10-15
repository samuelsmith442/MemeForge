// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/StakingVault.sol";
import "../src/MemeToken.sol";
import "../src/mocks/MockVRFCoordinatorV2.sol";

/**
 * @title StakingVaultFuzzTest
 * @dev Fuzz tests for StakingVault to ensure robustness
 */
contract StakingVaultFuzzTest is Test {
    StakingVault public vault;
    MockVRFCoordinatorV2 public mockVRF;
    MemeToken public token;

    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);

    uint256 constant INITIAL_SUPPLY = 1_000_000_000 * 1e18; // 1 billion tokens
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

        // Deploy test token
        token = new MemeToken("FuzzToken", "FUZZ", INITIAL_SUPPLY, REWARD_RATE, "Fuzz test token", "ipfs://fuzz");

        // Configure token in vault
        vault.configureToken(address(token), REWARD_RATE, true);

        // Set vault address on token
        token.setStakingVault(address(vault));

        // Transfer tokens to users
        token.transfer(user1, INITIAL_SUPPLY / 3);
        token.transfer(user2, INITIAL_SUPPLY / 3);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                            STAKING FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Fuzz test: stake any valid amount
    function testFuzz_Stake(uint256 amount) public {
        // Bound amount to reasonable range
        amount = bound(amount, 1, INITIAL_SUPPLY / 3);

        vm.startPrank(user1);
        token.approve(address(vault), amount);
        vault.stake(address(token), amount);
        vm.stopPrank();

        (uint256 staked,,) = vault.getStakeInfo(user1, address(token));
        assertEq(staked, amount);
    }

    /// @dev Fuzz test: stake multiple times with different amounts
    function testFuzz_StakeMultipleTimes(uint256 amount1, uint256 amount2) public {
        amount1 = bound(amount1, 1, INITIAL_SUPPLY / 6);
        amount2 = bound(amount2, 1, INITIAL_SUPPLY / 6);

        vm.startPrank(user1);

        // First stake
        token.approve(address(vault), amount1);
        vault.stake(address(token), amount1);

        // Second stake
        token.approve(address(vault), amount2);
        vault.stake(address(token), amount2);

        vm.stopPrank();

        (uint256 staked,,) = vault.getStakeInfo(user1, address(token));
        assertEq(staked, amount1 + amount2);
    }

    /// @dev Fuzz test: multiple users staking different amounts
    function testFuzz_MultipleUsersStake(uint256 amount1, uint256 amount2) public {
        amount1 = bound(amount1, 1, INITIAL_SUPPLY / 3);
        amount2 = bound(amount2, 1, INITIAL_SUPPLY / 3);

        // User1 stakes
        vm.startPrank(user1);
        token.approve(address(vault), amount1);
        vault.stake(address(token), amount1);
        vm.stopPrank();

        // User2 stakes
        vm.startPrank(user2);
        token.approve(address(vault), amount2);
        vault.stake(address(token), amount2);
        vm.stopPrank();

        (uint256 staked1,,) = vault.getStakeInfo(user1, address(token));
        (uint256 staked2,,) = vault.getStakeInfo(user2, address(token));

        assertEq(staked1, amount1);
        assertEq(staked2, amount2);

        (, uint256 totalStaked,) = vault.getTokenConfig(address(token));
        assertEq(totalStaked, amount1 + amount2);
    }

    /*//////////////////////////////////////////////////////////////
                            UNSTAKING FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Fuzz test: unstake any valid amount
    function testFuzz_Unstake(uint256 stakeAmount, uint256 unstakeAmount) public {
        stakeAmount = bound(stakeAmount, 100, INITIAL_SUPPLY / 3);
        unstakeAmount = bound(unstakeAmount, 1, stakeAmount);

        vm.startPrank(user1);

        // Stake
        token.approve(address(vault), stakeAmount);
        vault.stake(address(token), stakeAmount);

        // Unstake
        vault.unstake(address(token), unstakeAmount);

        vm.stopPrank();

        (uint256 remaining,,) = vault.getStakeInfo(user1, address(token));
        assertEq(remaining, stakeAmount - unstakeAmount);
    }

    /// @dev Fuzz test: stake and unstake multiple times
    function testFuzz_StakeUnstakeCycle(uint256 stake1, uint256 unstake1, uint256 stake2, uint256 unstake2) public {
        stake1 = bound(stake1, 1000, INITIAL_SUPPLY / 6);
        unstake1 = bound(unstake1, 1, stake1);
        stake2 = bound(stake2, 1, INITIAL_SUPPLY / 6);
        unstake2 = bound(unstake2, 1, stake1 - unstake1 + stake2);

        vm.startPrank(user1);

        // First cycle
        token.approve(address(vault), stake1);
        vault.stake(address(token), stake1);
        vault.unstake(address(token), unstake1);

        // Second cycle
        token.approve(address(vault), stake2);
        vault.stake(address(token), stake2);
        vault.unstake(address(token), unstake2);

        vm.stopPrank();

        (uint256 finalStake,,) = vault.getStakeInfo(user1, address(token));
        assertEq(finalStake, stake1 - unstake1 + stake2 - unstake2);
    }

    /*//////////////////////////////////////////////////////////////
                            REWARD FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Fuzz test: rewards calculation with different time periods
    function testFuzz_RewardCalculation(uint256 amount, uint256 timeElapsed) public {
        amount = bound(amount, 1e18, INITIAL_SUPPLY / 3);
        timeElapsed = bound(timeElapsed, 1, 365 days);

        vm.startPrank(user1);
        token.approve(address(vault), amount);
        vault.stake(address(token), amount);
        vm.stopPrank();

        // Fast forward time
        vm.warp(block.timestamp + timeElapsed);

        uint256 expectedRewards = (amount * REWARD_RATE * timeElapsed) / 1e18;
        uint256 actualRewards = vault.calculateRewards(user1, address(token));

        assertEq(actualRewards, expectedRewards);
    }

    /// @dev Fuzz test: rewards with random multipliers
    function testFuzz_RewardsWithMultiplier(uint256 amount, uint256 timeElapsed) public {
        amount = bound(amount, 1e18, INITIAL_SUPPLY / 10);
        timeElapsed = bound(timeElapsed, 1 hours, 30 days);

        vm.startPrank(user1);
        token.approve(address(vault), amount);
        vault.stake(address(token), amount);
        vm.stopPrank();

        // Fast forward time
        vm.warp(block.timestamp + timeElapsed);

        uint256 baseReward = (amount * REWARD_RATE * timeElapsed) / 1e18;
        uint256 balanceBefore = token.balanceOf(user1);

        // Claim rewards
        vm.prank(user1);
        vault.claimRewards(address(token));
        mockVRF.fulfillRequest(1);

        uint256 balanceAfter = token.balanceOf(user1);
        uint256 rewardReceived = balanceAfter - balanceBefore;

        // Verify reward is within multiplier range (1x to 5x)
        assertGe(rewardReceived, baseReward); // At least 1x
        assertLe(rewardReceived, baseReward * 5); // At most 5x
    }

    /// @dev Fuzz test: multiple claims with different time intervals
    function testFuzz_MultipleClaims(uint256 amount, uint256 time1, uint256 time2, uint256 time3) public {
        amount = bound(amount, 1e18, INITIAL_SUPPLY / 10);
        time1 = bound(time1, 1 hours, 7 days);
        time2 = bound(time2, 1 hours, 7 days);
        time3 = bound(time3, 1 hours, 7 days);

        vm.startPrank(user1);
        token.approve(address(vault), amount);
        vault.stake(address(token), amount);
        vm.stopPrank();

        uint256 totalRewards = 0;
        uint256 initialBalance = token.balanceOf(user1);

        // First claim
        vm.warp(block.timestamp + time1);
        vm.prank(user1);
        vault.claimRewards(address(token));
        mockVRF.fulfillRequest(1);
        uint256 balance1 = token.balanceOf(user1);
        totalRewards += (balance1 - initialBalance);

        // Second claim
        vm.warp(block.timestamp + time2);
        vm.prank(user1);
        vault.claimRewards(address(token));
        mockVRF.fulfillRequest(2);
        uint256 balance2 = token.balanceOf(user1);
        totalRewards += (balance2 - balance1);

        // Third claim
        vm.warp(block.timestamp + time3);
        vm.prank(user1);
        vault.claimRewards(address(token));
        mockVRF.fulfillRequest(3);
        uint256 balance3 = token.balanceOf(user1);
        totalRewards += (balance3 - balance2);

        // Verify total rewards are reasonable
        // Each claim gets its own multiplier, so we need to account for that
        uint256 totalTime = time1 + time2 + time3;
        uint256 baseReward = (amount * REWARD_RATE * totalTime) / 1e18;

        // Since each of 3 claims can have 1x-5x multiplier independently,
        // minimum is 3x base (all 1x), maximum is 15x base (all 5x)
        uint256 minExpected = baseReward; // At least 1x on each claim
        uint256 maxExpected = baseReward * 5 * 3; // Up to 5x on each of 3 claims

        assertGe(totalRewards, minExpected);
        assertLe(totalRewards, maxExpected);
    }

    /*//////////////////////////////////////////////////////////////
                        REWARD RATE FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Fuzz test: different reward rates
    function testFuzz_DifferentRewardRates(uint256 rewardRate, uint256 amount) public {
        rewardRate = bound(rewardRate, 1e12, 1e18); // 0.000001 to 1 token per second
        amount = bound(amount, 1e18, INITIAL_SUPPLY / 10);

        // Reconfigure token with new reward rate
        vm.prank(owner);
        vault.configureToken(address(token), rewardRate, true);

        vm.startPrank(user1);
        token.approve(address(vault), amount);
        vault.stake(address(token), amount);
        vm.stopPrank();

        // Wait 1 day
        vm.warp(block.timestamp + 1 days);

        uint256 expectedRewards = (amount * rewardRate * 1 days) / 1e18;
        uint256 actualRewards = vault.calculateRewards(user1, address(token));

        assertEq(actualRewards, expectedRewards);
    }

    /*//////////////////////////////////////////////////////////////
                        EDGE CASE FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Fuzz test: stake immediately after unstaking
    function testFuzz_StakeAfterUnstake(uint256 amount1, uint256 amount2) public {
        amount1 = bound(amount1, 1e18, INITIAL_SUPPLY / 6);
        amount2 = bound(amount2, 1e18, INITIAL_SUPPLY / 6);

        vm.startPrank(user1);

        // Stake
        token.approve(address(vault), amount1);
        vault.stake(address(token), amount1);

        // Unstake all
        vault.unstake(address(token), amount1);

        // Stake again
        token.approve(address(vault), amount2);
        vault.stake(address(token), amount2);

        vm.stopPrank();

        (uint256 staked,,) = vault.getStakeInfo(user1, address(token));
        assertEq(staked, amount2);
    }

    /// @dev Fuzz test: claim with zero rewards should revert
    function testFuzz_ClaimWithZeroRewards(uint256 amount) public {
        amount = bound(amount, 1e18, INITIAL_SUPPLY / 10);

        vm.startPrank(user1);
        token.approve(address(vault), amount);
        vault.stake(address(token), amount);

        // Try to claim immediately (no time passed)
        vm.expectRevert(StakingVault.StakingVault__NoRewardsToClaim.selector);
        vault.claimRewards(address(token));
        vm.stopPrank();
    }

    /// @dev Fuzz test: unstake more than staked should revert
    function testFuzz_UnstakeMoreThanStaked(uint256 stakeAmount, uint256 unstakeAmount) public {
        stakeAmount = bound(stakeAmount, 1e18, INITIAL_SUPPLY / 10);
        unstakeAmount = bound(unstakeAmount, stakeAmount + 1, stakeAmount * 2);

        vm.startPrank(user1);
        token.approve(address(vault), stakeAmount);
        vault.stake(address(token), stakeAmount);

        vm.expectRevert(StakingVault.StakingVault__InsufficientStake.selector);
        vault.unstake(address(token), unstakeAmount);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        ACCOUNTING FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Fuzz test: total staked accounting
    function testFuzz_TotalStakedAccounting(uint256 amount1, uint256 amount2, uint256 amount3) public {
        amount1 = bound(amount1, 1e18, INITIAL_SUPPLY / 10);
        amount2 = bound(amount2, 1e18, INITIAL_SUPPLY / 10);
        amount3 = bound(amount3, 1e18, INITIAL_SUPPLY / 10);

        // User1 stakes
        vm.startPrank(user1);
        token.approve(address(vault), amount1);
        vault.stake(address(token), amount1);
        vm.stopPrank();

        // User2 stakes
        vm.startPrank(user2);
        token.approve(address(vault), amount2);
        vault.stake(address(token), amount2);
        vm.stopPrank();

        // User1 stakes more
        vm.startPrank(user1);
        token.approve(address(vault), amount3);
        vault.stake(address(token), amount3);
        vm.stopPrank();

        (, uint256 totalStaked,) = vault.getTokenConfig(address(token));
        assertEq(totalStaked, amount1 + amount2 + amount3);
    }

    /// @dev Fuzz test: accounting after unstaking
    function testFuzz_AccountingAfterUnstake(uint256 stake1, uint256 stake2, uint256 unstake1) public {
        stake1 = bound(stake1, 1e18, INITIAL_SUPPLY / 6);
        stake2 = bound(stake2, 1e18, INITIAL_SUPPLY / 6);
        unstake1 = bound(unstake1, 1, stake1);

        // Both users stake
        vm.startPrank(user1);
        token.approve(address(vault), stake1);
        vault.stake(address(token), stake1);
        vm.stopPrank();

        vm.startPrank(user2);
        token.approve(address(vault), stake2);
        vault.stake(address(token), stake2);
        vm.stopPrank();

        // User1 unstakes
        vm.prank(user1);
        vault.unstake(address(token), unstake1);

        (, uint256 totalStaked,) = vault.getTokenConfig(address(token));
        assertEq(totalStaked, stake1 - unstake1 + stake2);
    }

    /*//////////////////////////////////////////////////////////////
                        TIME MANIPULATION TESTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Fuzz test: rewards don't overflow with extreme time
    function testFuzz_NoOverflowWithExtremeTime(uint256 amount, uint256 timeElapsed) public {
        amount = bound(amount, 1e18, 1e24); // Up to 1 million tokens
        timeElapsed = bound(timeElapsed, 1, 100 * 365 days); // Up to 100 years

        vm.startPrank(user1);
        token.approve(address(vault), amount);
        vault.stake(address(token), amount);
        vm.stopPrank();

        vm.warp(block.timestamp + timeElapsed);

        // Should not revert due to overflow
        uint256 rewards = vault.calculateRewards(user1, address(token));

        // Verify rewards are reasonable
        uint256 expectedRewards = (amount * REWARD_RATE * timeElapsed) / 1e18;
        assertEq(rewards, expectedRewards);
    }
}
