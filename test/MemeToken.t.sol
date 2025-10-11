// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MemeToken.sol";
import "../src/MemeSoulNFT.sol";

contract MemeTokenTest is Test {
    MemeToken public memeToken;
    MemeSoulNFT public soulNFT;

    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);

    uint256 constant INITIAL_SUPPLY = 1_000_000 * 1e18;
    uint256 constant REWARD_RATE = 1e18; // 1 token per second per token staked

    function setUp() public {
        vm.startPrank(owner);

        // Deploy MemeToken
        memeToken = new MemeToken(
            "MeowFi",
            "MEOW",
            INITIAL_SUPPLY,
            REWARD_RATE,
            "A memecoin for cat lovers who love DeFi",
            "ipfs://QmTest123"
        );

        // Deploy Soul NFT
        soulNFT = new MemeSoulNFT();

        // Link contracts
        memeToken.setSoulNFT(address(soulNFT));

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                            DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Deployment() public view {
        assertEq(memeToken.name(), "MeowFi");
        assertEq(memeToken.symbol(), "MEOW");
        assertEq(memeToken.totalSupply(), INITIAL_SUPPLY);
        assertEq(memeToken.balanceOf(owner), INITIAL_SUPPLY);
        assertEq(memeToken.rewardRate(), REWARD_RATE);
        assertEq(memeToken.theme(), "A memecoin for cat lovers who love DeFi");
        assertEq(memeToken.logoURI(), "ipfs://QmTest123");
    }

    function test_InitialOwnership() public view {
        assertEq(memeToken.owner(), owner);
        assertEq(soulNFT.owner(), owner);
    }

    /*//////////////////////////////////////////////////////////////
                            TRANSFER TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Transfer() public {
        vm.prank(owner);
        memeToken.transfer(user1, 1000 * 1e18);

        assertEq(memeToken.balanceOf(user1), 1000 * 1e18);
        assertEq(memeToken.balanceOf(owner), INITIAL_SUPPLY - 1000 * 1e18);
    }

    function test_TransferFrom() public {
        vm.prank(owner);
        memeToken.approve(user1, 1000 * 1e18);

        vm.prank(user1);
        memeToken.transferFrom(owner, user2, 1000 * 1e18);

        assertEq(memeToken.balanceOf(user2), 1000 * 1e18);
    }

    /*//////////////////////////////////////////////////////////////
                            STAKING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Stake() public {
        // Transfer tokens to user1
        vm.prank(owner);
        memeToken.transfer(user1, 10000 * 1e18);

        // User1 stakes tokens
        vm.startPrank(user1);
        uint256 stakeAmount = 5000 * 1e18;
        memeToken.stake(stakeAmount);
        vm.stopPrank();

        assertEq(memeToken.stakedBalance(user1), stakeAmount);
        assertEq(memeToken.totalStaked(), stakeAmount);
        assertEq(memeToken.balanceOf(address(memeToken)), stakeAmount);
    }

    function test_StakeMultipleUsers() public {
        // Transfer tokens to users
        vm.startPrank(owner);
        memeToken.transfer(user1, 10000 * 1e18);
        memeToken.transfer(user2, 10000 * 1e18);
        vm.stopPrank();

        // User1 stakes
        vm.prank(user1);
        memeToken.stake(5000 * 1e18);

        // User2 stakes
        vm.prank(user2);
        memeToken.stake(3000 * 1e18);

        assertEq(memeToken.totalStaked(), 8000 * 1e18);
        assertEq(memeToken.stakedBalance(user1), 5000 * 1e18);
        assertEq(memeToken.stakedBalance(user2), 3000 * 1e18);
    }

    function test_RevertWhen_StakeInsufficientBalance() public {
        vm.prank(user1);
        vm.expectRevert(MemeToken.InsufficientBalance.selector);
        memeToken.stake(1000 * 1e18); // user1 has no tokens
    }

    function test_RevertWhen_StakeZeroAmount() public {
        vm.prank(owner);
        vm.expectRevert(MemeToken.InvalidAmount.selector);
        memeToken.stake(0);
    }

    /*//////////////////////////////////////////////////////////////
                            UNSTAKING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Unstake() public {
        // Setup: Transfer and stake
        vm.prank(owner);
        memeToken.transfer(user1, 10000 * 1e18);

        vm.prank(user1);
        memeToken.stake(5000 * 1e18);

        // Wait some time
        vm.warp(block.timestamp + 100);

        // Unstake
        vm.prank(user1);
        memeToken.unstake(2000 * 1e18);

        assertEq(memeToken.stakedBalance(user1), 3000 * 1e18);
        assertEq(memeToken.totalStaked(), 3000 * 1e18);
    }

    function test_RevertWhen_UnstakeMoreThanStaked() public {
        vm.prank(owner);
        memeToken.transfer(user1, 10000 * 1e18);

        vm.prank(user1);
        memeToken.stake(5000 * 1e18);

        vm.prank(user1);
        vm.expectRevert(MemeToken.InsufficientStakedBalance.selector);
        memeToken.unstake(6000 * 1e18); // More than staked
    }

    /*//////////////////////////////////////////////////////////////
                            REWARDS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_CalculateRewards() public {
        // Setup: Transfer and stake
        vm.prank(owner);
        memeToken.transfer(user1, 10000 * 1e18);

        vm.prank(user1);
        memeToken.stake(5000 * 1e18);

        // Wait 100 seconds
        vm.warp(block.timestamp + 100);

        // Calculate rewards
        uint256 rewards = memeToken.calculateRewards(user1);

        // Expected: 5000 tokens * 1 token/sec * 100 sec / 1e18 = 500,000 tokens
        assertGt(rewards, 0);
    }

    function test_ClaimRewards() public {
        // Setup: Transfer and stake
        vm.prank(owner);
        memeToken.transfer(user1, 10000 * 1e18);

        vm.prank(user1);
        memeToken.stake(5000 * 1e18);

        // Wait some time
        vm.warp(block.timestamp + 100);

        uint256 balanceBefore = memeToken.balanceOf(user1);

        // Claim rewards
        vm.prank(user1);
        memeToken.claimRewards();

        uint256 balanceAfter = memeToken.balanceOf(user1);

        assertGt(balanceAfter, balanceBefore);
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SetRewardRate() public {
        vm.prank(owner);
        memeToken.setRewardRate(2e18);

        assertEq(memeToken.rewardRate(), 2e18);
    }

    function test_SetStakingActive() public {
        vm.prank(owner);
        memeToken.setStakingActive(false);

        assertEq(memeToken.stakingActive(), false);
    }

    function test_RevertWhen_NonOwnerSetRewardRate() public {
        vm.prank(user1);
        vm.expectRevert();
        memeToken.setRewardRate(2e18);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GetStakingInfo() public {
        vm.prank(owner);
        memeToken.transfer(user1, 10000 * 1e18);

        vm.prank(user1);
        memeToken.stake(5000 * 1e18);

        (uint256 staked, uint256 rewards, uint256 lastStake) = memeToken.getStakingInfo(user1);

        assertEq(staked, 5000 * 1e18);
        assertEq(lastStake, block.timestamp);
    }

    function test_GetMetadata() public view {
        (string memory name, string memory symbol, string memory theme, string memory logo, uint256 supply) =
            memeToken.getMetadata();

        assertEq(name, "MeowFi");
        assertEq(symbol, "MEOW");
        assertEq(theme, "A memecoin for cat lovers who love DeFi");
        assertEq(logo, "ipfs://QmTest123");
        assertEq(supply, INITIAL_SUPPLY);
    }

    /*//////////////////////////////////////////////////////////////
                            BURN TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Burn() public {
        uint256 burnAmount = 1000 * 1e18;
        uint256 initialSupply = memeToken.totalSupply();

        vm.prank(owner);
        memeToken.burn(burnAmount);

        assertEq(memeToken.totalSupply(), initialSupply - burnAmount);
        assertEq(memeToken.balanceOf(owner), INITIAL_SUPPLY - burnAmount);
    }
}
