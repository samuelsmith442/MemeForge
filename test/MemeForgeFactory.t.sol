// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/MemeForgeFactory.sol";
import "../src/MemeToken.sol";
import "../src/MemeSoulNFT.sol";
import "../src/MemeGovernor.sol";
import "../src/ERC6551Registry.sol";
import "../src/TokenBoundAccount.sol";
import "../src/StakingVault.sol";
import "../src/mocks/MockVRFCoordinatorV2.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";

contract MemeForgeFactoryTest is Test {
    MemeForgeFactory public factory;
    ERC6551Registry public registry;
    TokenBoundAccount public implementation;
    StakingVault public stakingVault;
    MockVRFCoordinatorV2 public mockVRF;

    address public owner = address(1);
    address public creator1 = address(2);
    address public creator2 = address(3);

    event MemecoinDeployed(
        address indexed token,
        address indexed soulNFT,
        address indexed creator,
        address governor,
        address timelock,
        string name,
        string symbol
    );

    function setUp() public {
        vm.startPrank(owner);

        // Deploy infrastructure
        registry = new ERC6551Registry();
        implementation = new TokenBoundAccount();
        mockVRF = new MockVRFCoordinatorV2();
        stakingVault = new StakingVault(address(mockVRF), 1, bytes32(uint256(1)), 500_000);

        // Deploy factory
        factory = new MemeForgeFactory(address(registry), address(implementation), address(stakingVault));

        vm.stopPrank();

        // Fund creators
        vm.deal(creator1, 100 ether);
        vm.deal(creator2, 100 ether);
    }

    /*//////////////////////////////////////////////////////////////
                        DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_FactoryDeployment() public view {
        assertEq(address(factory.registry()), address(registry));
        assertEq(address(factory.implementation()), address(implementation));
        assertEq(factory.stakingVault(), address(stakingVault));
        assertEq(factory.owner(), owner);
    }

    function test_DeployMemecoinWithoutGovernance() public {
        MemeForgeFactory.DeploymentParams memory params = MemeForgeFactory.DeploymentParams({
            name: "TestMeme",
            symbol: "TMEME",
            initialSupply: 1_000_000e18,
            rewardRate: 1e15,
            theme: "Test Theme",
            logoURI: "ipfs://test",
            enableGovernance: false
        });

        vm.prank(creator1);
        (address token, address soulNFT, address governor, address timelock) = factory.deployMemecoin(params);

        // Verify deployments
        assertTrue(token != address(0));
        assertTrue(soulNFT != address(0));
        assertEq(governor, address(0)); // No governance
        assertEq(timelock, address(0)); // No timelock

        // Verify token
        MemeToken memeToken = MemeToken(token);
        assertEq(memeToken.name(), "TestMeme");
        assertEq(memeToken.symbol(), "TMEME");
        assertEq(memeToken.totalSupply(), 1_000_000e18);
        assertEq(memeToken.balanceOf(creator1), 1_000_000e18);

        // Verify Soul NFT
        MemeSoulNFT nft = MemeSoulNFT(soulNFT);
        assertEq(nft.owner(), creator1); // NFT contract owner
        assertEq(nft.ownerOf(0), creator1); // Token owner (first token is ID 0)
    }

    function test_DeployMemecoinWithGovernance() public {
        MemeForgeFactory.DeploymentParams memory params = MemeForgeFactory.DeploymentParams({
            name: "GovMeme",
            symbol: "GMEME",
            initialSupply: 1_000_000e18,
            rewardRate: 1e15,
            theme: "Governance Theme",
            logoURI: "ipfs://gov",
            enableGovernance: true
        });

        vm.prank(creator1);
        (address token, address soulNFT, address governor, address timelock) = factory.deployMemecoin(params);

        // Verify all deployments
        assertTrue(token != address(0));
        assertTrue(soulNFT != address(0));
        assertTrue(governor != address(0));
        assertTrue(timelock != address(0));

        // Verify governance setup
        MemeGovernor gov = MemeGovernor(payable(governor));
        assertEq(address(gov.token()), token);
        assertEq(gov.votingDelay(), 1 days);
        assertEq(gov.votingPeriod(), 1 weeks);

        // Verify token ownership transferred to timelock
        MemeToken memeToken = MemeToken(token);
        assertEq(memeToken.owner(), timelock);
    }

    function test_DeployMultipleMemecoins() public {
        MemeForgeFactory.DeploymentParams memory params1 = MemeForgeFactory.DeploymentParams({
            name: "Meme1",
            symbol: "M1",
            initialSupply: 1_000_000e18,
            rewardRate: 1e15,
            theme: "Theme1",
            logoURI: "ipfs://1",
            enableGovernance: false
        });

        MemeForgeFactory.DeploymentParams memory params2 = MemeForgeFactory.DeploymentParams({
            name: "Meme2",
            symbol: "M2",
            initialSupply: 2_000_000e18,
            rewardRate: 2e15,
            theme: "Theme2",
            logoURI: "ipfs://2",
            enableGovernance: true
        });

        vm.prank(creator1);
        (address token1,,,) = factory.deployMemecoin(params1);

        vm.prank(creator2);
        (address token2,,,) = factory.deployMemecoin(params2);

        // Verify both are tracked
        assertEq(factory.getTotalMemecoins(), 2);
        assertEq(factory.getMemecoinAtIndex(0), token1);
        assertEq(factory.getMemecoinAtIndex(1), token2);
    }

    function test_EmitMemecoinDeployedEvent() public {
        MemeForgeFactory.DeploymentParams memory params = MemeForgeFactory.DeploymentParams({
            name: "EventMeme",
            symbol: "EMEME",
            initialSupply: 1_000_000e18,
            rewardRate: 1e15,
            theme: "Event Theme",
            logoURI: "ipfs://event",
            enableGovernance: false
        });

        vm.expectEmit(false, false, true, true);
        emit MemecoinDeployed(address(0), address(0), creator1, address(0), address(0), "EventMeme", "EMEME");

        vm.prank(creator1);
        factory.deployMemecoin(params);
    }

    /*//////////////////////////////////////////////////////////////
                        VALIDATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RevertWhen_EmptyName() public {
        MemeForgeFactory.DeploymentParams memory params = MemeForgeFactory.DeploymentParams({
            name: "",
            symbol: "TMEME",
            initialSupply: 1_000_000e18,
            rewardRate: 1e15,
            theme: "Test",
            logoURI: "ipfs://test",
            enableGovernance: false
        });

        vm.prank(creator1);
        vm.expectRevert(MemeForgeFactory.MemeForgeFactory__InvalidParameters.selector);
        factory.deployMemecoin(params);
    }

    function test_RevertWhen_EmptySymbol() public {
        MemeForgeFactory.DeploymentParams memory params = MemeForgeFactory.DeploymentParams({
            name: "TestMeme",
            symbol: "",
            initialSupply: 1_000_000e18,
            rewardRate: 1e15,
            theme: "Test",
            logoURI: "ipfs://test",
            enableGovernance: false
        });

        vm.prank(creator1);
        vm.expectRevert(MemeForgeFactory.MemeForgeFactory__InvalidParameters.selector);
        factory.deployMemecoin(params);
    }

    function test_RevertWhen_ZeroSupply() public {
        MemeForgeFactory.DeploymentParams memory params = MemeForgeFactory.DeploymentParams({
            name: "TestMeme",
            symbol: "TMEME",
            initialSupply: 0,
            rewardRate: 1e15,
            theme: "Test",
            logoURI: "ipfs://test",
            enableGovernance: false
        });

        vm.prank(creator1);
        vm.expectRevert(MemeForgeFactory.MemeForgeFactory__InvalidParameters.selector);
        factory.deployMemecoin(params);
    }

    function test_RevertWhen_InsufficientFee() public {
        vm.prank(owner);
        factory.updateDeploymentFee(1 ether);

        MemeForgeFactory.DeploymentParams memory params = MemeForgeFactory.DeploymentParams({
            name: "TestMeme",
            symbol: "TMEME",
            initialSupply: 1_000_000e18,
            rewardRate: 1e15,
            theme: "Test",
            logoURI: "ipfs://test",
            enableGovernance: false
        });

        vm.prank(creator1);
        vm.expectRevert(MemeForgeFactory.MemeForgeFactory__InsufficientFee.selector);
        factory.deployMemecoin{value: 0.5 ether}(params);
    }

    /*//////////////////////////////////////////////////////////////
                        REGISTRY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GetDeploymentInfo() public {
        MemeForgeFactory.DeploymentParams memory params = MemeForgeFactory.DeploymentParams({
            name: "TestMeme",
            symbol: "TMEME",
            initialSupply: 1_000_000e18,
            rewardRate: 1e15,
            theme: "Test",
            logoURI: "ipfs://test",
            enableGovernance: true
        });

        vm.prank(creator1);
        (address token, address soulNFT, address governor, address timelock) = factory.deployMemecoin(params);

        MemeForgeFactory.DeploymentInfo memory info = factory.getDeploymentInfo(token);

        assertEq(info.token, token);
        assertEq(info.soulNFT, soulNFT);
        assertEq(info.governor, governor);
        assertEq(info.timelock, timelock);
        assertEq(info.creator, creator1);
        assertTrue(info.exists);
    }

    function test_GetCreatorMemecoins() public {
        MemeForgeFactory.DeploymentParams memory params = MemeForgeFactory.DeploymentParams({
            name: "TestMeme",
            symbol: "TMEME",
            initialSupply: 1_000_000e18,
            rewardRate: 1e15,
            theme: "Test",
            logoURI: "ipfs://test",
            enableGovernance: false
        });

        vm.startPrank(creator1);
        (address token1,,,) = factory.deployMemecoin(params);
        params.name = "TestMeme2";
        params.symbol = "TMEME2";
        (address token2,,,) = factory.deployMemecoin(params);
        vm.stopPrank();

        address[] memory memecoins = factory.getCreatorMemecoins(creator1);
        assertEq(memecoins.length, 2);
        assertEq(memecoins[0], token1);
        assertEq(memecoins[1], token2);
    }

    function test_GetAllMemecoins() public {
        MemeForgeFactory.DeploymentParams memory params = MemeForgeFactory.DeploymentParams({
            name: "TestMeme",
            symbol: "TMEME",
            initialSupply: 1_000_000e18,
            rewardRate: 1e15,
            theme: "Test",
            logoURI: "ipfs://test",
            enableGovernance: false
        });

        vm.prank(creator1);
        (address token1,,,) = factory.deployMemecoin(params);

        vm.prank(creator2);
        params.name = "TestMeme2";
        params.symbol = "TMEME2";
        (address token2,,,) = factory.deployMemecoin(params);

        address[] memory allMemecoins = factory.getAllMemecoins();
        assertEq(allMemecoins.length, 2);
        assertEq(allMemecoins[0], token1);
        assertEq(allMemecoins[1], token2);
    }

    /*//////////////////////////////////////////////////////////////
                        ADMIN TESTS
    //////////////////////////////////////////////////////////////*/

    function test_UpdateGovernanceParameters() public {
        vm.prank(owner);
        factory.updateGovernanceParameters(2 days, 2 weeks, 2000e18, 5);

        assertEq(factory.votingDelay(), 2 days);
        assertEq(factory.votingPeriod(), 2 weeks);
        assertEq(factory.proposalThreshold(), 2000e18);
        assertEq(factory.quorumPercentage(), 5);
    }

    function test_UpdateDeploymentFee() public {
        vm.prank(owner);
        factory.updateDeploymentFee(1 ether);

        assertEq(factory.deploymentFee(), 1 ether);
    }

    function test_WithdrawFees() public {
        // Set fee and deploy
        vm.prank(owner);
        factory.updateDeploymentFee(1 ether);

        MemeForgeFactory.DeploymentParams memory params = MemeForgeFactory.DeploymentParams({
            name: "TestMeme",
            symbol: "TMEME",
            initialSupply: 1_000_000e18,
            rewardRate: 1e15,
            theme: "Test",
            logoURI: "ipfs://test",
            enableGovernance: false
        });

        vm.prank(creator1);
        factory.deployMemecoin{value: 1 ether}(params);

        // Withdraw fees
        address payable recipient = payable(address(999));
        uint256 balanceBefore = recipient.balance;

        vm.prank(owner);
        factory.withdrawFees(recipient);

        assertEq(recipient.balance, balanceBefore + 1 ether);
    }

    function test_RevertWhen_NonOwnerUpdatesParameters() public {
        vm.prank(creator1);
        vm.expectRevert();
        factory.updateGovernanceParameters(2 days, 2 weeks, 2000e18, 5);
    }

    function test_RevertWhen_NonOwnerUpdatesFee() public {
        vm.prank(creator1);
        vm.expectRevert();
        factory.updateDeploymentFee(1 ether);
    }

    function test_RevertWhen_NonOwnerWithdrawsFees() public {
        vm.prank(creator1);
        vm.expectRevert();
        factory.withdrawFees(payable(address(999)));
    }
}
