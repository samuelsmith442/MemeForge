// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/ERC6551Registry.sol";
import "../src/TokenBoundAccount.sol";
import "../src/MemeSoulNFT.sol";
import "../src/MemeToken.sol";

contract ERC6551Test is Test {
    ERC6551Registry public registry;
    TokenBoundAccount public implementation;
    MemeSoulNFT public soulNFT;
    MemeToken public memeToken;

    address public owner = address(1);
    address public creator = address(2);
    address public user1 = address(3);

    uint256 constant CHAIN_ID = 31337; // Anvil default chain ID

    function setUp() public {
        vm.startPrank(owner);

        // Deploy registry and implementation
        registry = new ERC6551Registry();
        implementation = new TokenBoundAccount();

        // Deploy Soul NFT
        soulNFT = new MemeSoulNFT();

        // Deploy a memecoin
        memeToken = new MemeToken(
            "MeowFi",
            "MEOW",
            1_000_000 * 1e18,
            1e18,
            "A memecoin for cat lovers",
            "ipfs://QmTest123"
        );

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                            REGISTRY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_RegistryDeployment() public view {
        // Registry should be deployed
        assertTrue(address(registry) != address(0));
    }

    function test_ComputeAccountAddress() public view {
        address computed = registry.account(
            address(implementation),
            bytes32(0),
            CHAIN_ID,
            address(soulNFT),
            0
        );

        // Should return a valid address
        assertTrue(computed != address(0));
    }

    function test_CreateAccount() public {
        vm.prank(owner);
        address account = registry.createAccount(
            address(implementation),
            bytes32(0),
            CHAIN_ID,
            address(soulNFT),
            0
        );

        // Account should be created
        assertTrue(account != address(0));
        
        // Account should have code
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        assertGt(size, 0);
    }

    function test_CreateAccountIdempotent() public {
        vm.startPrank(owner);
        
        address account1 = registry.createAccount(
            address(implementation),
            bytes32(0),
            CHAIN_ID,
            address(soulNFT),
            0
        );

        address account2 = registry.createAccount(
            address(implementation),
            bytes32(0),
            CHAIN_ID,
            address(soulNFT),
            0
        );

        vm.stopPrank();

        // Should return same address
        assertEq(account1, account2);
    }

    function test_CreateAccountDifferentTokens() public {
        vm.startPrank(owner);
        
        address account1 = registry.createAccount(
            address(implementation),
            bytes32(0),
            CHAIN_ID,
            address(soulNFT),
            0
        );

        address account2 = registry.createAccount(
            address(implementation),
            bytes32(0),
            CHAIN_ID,
            address(soulNFT),
            1
        );

        vm.stopPrank();

        // Should return different addresses
        assertTrue(account1 != account2);
    }

    /*//////////////////////////////////////////////////////////////
                        TOKEN BOUND ACCOUNT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_AccountReceiveEther() public {
        // Create account
        vm.prank(owner);
        address account = registry.createAccount(
            address(implementation),
            bytes32(0),
            CHAIN_ID,
            address(soulNFT),
            0
        );

        // Send Ether to account
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        (bool success,) = account.call{value: 0.5 ether}("");

        assertTrue(success);
        assertEq(address(account).balance, 0.5 ether);
    }

    function test_AccountToken() public {
        // Mint NFT first
        MemeSoulNFT.MemecoinMetadata memory metadata = MemeSoulNFT.MemecoinMetadata({
            name: "MeowFi",
            symbol: "MEOW",
            theme: "Cat lovers",
            logoURI: "ipfs://QmTest123",
            createdAt: 0,
            creator: address(0)
        });

        vm.prank(owner);
        soulNFT.mintSoulNFT(creator, address(memeToken), metadata, "ipfs://QmNFT");

        // Create account for token ID 0
        vm.prank(owner);
        address account = registry.createAccount(
            address(implementation),
            bytes32(0),
            CHAIN_ID,
            address(soulNFT),
            0
        );

        // Check token info
        TokenBoundAccount tba = TokenBoundAccount(payable(account));
        (uint256 chainId, address tokenContract, uint256 tokenId) = tba.token();

        assertEq(chainId, CHAIN_ID);
        assertEq(tokenContract, address(soulNFT));
        assertEq(tokenId, 0);
    }

    function test_AccountOwner() public {
        // Mint NFT to creator
        MemeSoulNFT.MemecoinMetadata memory metadata = MemeSoulNFT.MemecoinMetadata({
            name: "MeowFi",
            symbol: "MEOW",
            theme: "Cat lovers",
            logoURI: "ipfs://QmTest123",
            createdAt: 0,
            creator: address(0)
        });

        vm.prank(owner);
        soulNFT.mintSoulNFT(creator, address(memeToken), metadata, "ipfs://QmNFT");

        // Create account
        vm.prank(owner);
        address account = registry.createAccount(
            address(implementation),
            bytes32(0),
            CHAIN_ID,
            address(soulNFT),
            0
        );

        // Check owner
        TokenBoundAccount tba = TokenBoundAccount(payable(account));
        assertEq(tba.owner(), creator);
    }

    function test_AccountExecute() public {
        // Mint NFT to creator
        MemeSoulNFT.MemecoinMetadata memory metadata = MemeSoulNFT.MemecoinMetadata({
            name: "MeowFi",
            symbol: "MEOW",
            theme: "Cat lovers",
            logoURI: "ipfs://QmTest123",
            createdAt: 0,
            creator: address(0)
        });

        vm.prank(owner);
        soulNFT.mintSoulNFT(creator, address(memeToken), metadata, "ipfs://QmNFT");

        // Create account
        vm.prank(owner);
        address account = registry.createAccount(
            address(implementation),
            bytes32(0),
            CHAIN_ID,
            address(soulNFT),
            0
        );

        // Fund the account
        vm.deal(account, 1 ether);

        // Execute a transfer from the account
        TokenBoundAccount tba = TokenBoundAccount(payable(account));
        
        vm.prank(creator); // NFT owner
        tba.execute(user1, 0.5 ether, "", 0);

        assertEq(user1.balance, 0.5 ether);
        assertEq(address(account).balance, 0.5 ether);
    }

    function test_RevertWhen_NonOwnerExecutes() public {
        // Mint NFT to creator
        MemeSoulNFT.MemecoinMetadata memory metadata = MemeSoulNFT.MemecoinMetadata({
            name: "MeowFi",
            symbol: "MEOW",
            theme: "Cat lovers",
            logoURI: "ipfs://QmTest123",
            createdAt: 0,
            creator: address(0)
        });

        vm.prank(owner);
        soulNFT.mintSoulNFT(creator, address(memeToken), metadata, "ipfs://QmNFT");

        // Create account
        vm.prank(owner);
        address account = registry.createAccount(
            address(implementation),
            bytes32(0),
            CHAIN_ID,
            address(soulNFT),
            0
        );

        // Try to execute as non-owner
        TokenBoundAccount tba = TokenBoundAccount(payable(account));
        
        vm.prank(user1); // Not the NFT owner
        vm.expectRevert(TokenBoundAccount__InvalidSigner.selector);
        tba.execute(user1, 0, "", 0);
    }

    function test_AccountState() public {
        // Mint NFT
        MemeSoulNFT.MemecoinMetadata memory metadata = MemeSoulNFT.MemecoinMetadata({
            name: "MeowFi",
            symbol: "MEOW",
            theme: "Cat lovers",
            logoURI: "ipfs://QmTest123",
            createdAt: 0,
            creator: address(0)
        });

        vm.prank(owner);
        soulNFT.mintSoulNFT(creator, address(memeToken), metadata, "ipfs://QmNFT");

        // Create account
        vm.prank(owner);
        address account = registry.createAccount(
            address(implementation),
            bytes32(0),
            CHAIN_ID,
            address(soulNFT),
            0
        );

        TokenBoundAccount tba = TokenBoundAccount(payable(account));
        
        uint256 initialState = tba.state();
        assertEq(initialState, 0);

        // Execute something to change state
        vm.deal(account, 1 ether);
        vm.prank(creator);
        tba.execute(user1, 0.1 ether, "", 0);

        uint256 newState = tba.state();
        assertEq(newState, 1);
    }

    function test_AccountIsValidSigner() public {
        // Mint NFT to creator
        MemeSoulNFT.MemecoinMetadata memory metadata = MemeSoulNFT.MemecoinMetadata({
            name: "MeowFi",
            symbol: "MEOW",
            theme: "Cat lovers",
            logoURI: "ipfs://QmTest123",
            createdAt: 0,
            creator: address(0)
        });

        vm.prank(owner);
        soulNFT.mintSoulNFT(creator, address(memeToken), metadata, "ipfs://QmNFT");

        // Create account
        vm.prank(owner);
        address account = registry.createAccount(
            address(implementation),
            bytes32(0),
            CHAIN_ID,
            address(soulNFT),
            0
        );

        TokenBoundAccount tba = TokenBoundAccount(payable(account));
        
        // Check if creator is valid signer
        bytes4 result = tba.isValidSigner(creator, "");
        assertEq(result, IERC6551Account.isValidSigner.selector);

        // Check if user1 is NOT valid signer
        bytes4 result2 = tba.isValidSigner(user1, "");
        assertEq(result2, bytes4(0));
    }

    function test_AccountSupportsInterface() public {
        vm.prank(owner);
        address account = registry.createAccount(
            address(implementation),
            bytes32(0),
            CHAIN_ID,
            address(soulNFT),
            0
        );

        TokenBoundAccount tba = TokenBoundAccount(payable(account));
        
        // Should support ERC165
        assertTrue(tba.supportsInterface(type(IERC165).interfaceId));
        
        // Should support IERC6551Account
        assertTrue(tba.supportsInterface(type(IERC6551Account).interfaceId));
        
        // Should support IERC6551Executable
        assertTrue(tba.supportsInterface(type(IERC6551Executable).interfaceId));
    }

    /*//////////////////////////////////////////////////////////////
                        INTEGRATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_IntegrationWithMemeSoulNFT() public {
        // Mint Soul NFT
        MemeSoulNFT.MemecoinMetadata memory metadata = MemeSoulNFT.MemecoinMetadata({
            name: "MeowFi",
            symbol: "MEOW",
            theme: "Cat lovers",
            logoURI: "ipfs://QmTest123",
            createdAt: 0,
            creator: address(0)
        });

        vm.prank(owner);
        uint256 tokenId = soulNFT.mintSoulNFT(creator, address(memeToken), metadata, "ipfs://QmNFT");

        // Create TBA for this NFT
        vm.prank(owner);
        address account = registry.createAccount(
            address(implementation),
            bytes32(0),
            CHAIN_ID,
            address(soulNFT),
            tokenId
        );

        // Link TBA to Soul NFT
        vm.prank(owner);
        soulNFT.linkTokenBoundAccount(tokenId, account);

        // Verify linkage
        assertEq(soulNFT.getTokenBoundAccount(tokenId), account);

        // Verify TBA knows its token
        TokenBoundAccount tba = TokenBoundAccount(payable(account));
        (uint256 chainId, address tokenContract, uint256 tid) = tba.token();
        
        assertEq(chainId, CHAIN_ID);
        assertEq(tokenContract, address(soulNFT));
        assertEq(tid, tokenId);
        assertEq(tba.owner(), creator);
    }

    function test_TBACanHoldTokens() public {
        // Setup: Mint NFT and create TBA
        MemeSoulNFT.MemecoinMetadata memory metadata = MemeSoulNFT.MemecoinMetadata({
            name: "MeowFi",
            symbol: "MEOW",
            theme: "Cat lovers",
            logoURI: "ipfs://QmTest123",
            createdAt: 0,
            creator: address(0)
        });

        vm.prank(owner);
        uint256 tokenId = soulNFT.mintSoulNFT(creator, address(memeToken), metadata, "ipfs://QmNFT");

        vm.prank(owner);
        address account = registry.createAccount(
            address(implementation),
            bytes32(0),
            CHAIN_ID,
            address(soulNFT),
            tokenId
        );

        // Transfer some memecoins to the TBA
        vm.prank(owner);
        memeToken.transfer(account, 1000 * 1e18);

        // Verify TBA holds the tokens
        assertEq(memeToken.balanceOf(account), 1000 * 1e18);
    }

    function test_TBAOwnerCanTransferTokens() public {
        // Setup
        MemeSoulNFT.MemecoinMetadata memory metadata = MemeSoulNFT.MemecoinMetadata({
            name: "MeowFi",
            symbol: "MEOW",
            theme: "Cat lovers",
            logoURI: "ipfs://QmTest123",
            createdAt: 0,
            creator: address(0)
        });

        vm.prank(owner);
        uint256 tokenId = soulNFT.mintSoulNFT(creator, address(memeToken), metadata, "ipfs://QmNFT");

        vm.prank(owner);
        address account = registry.createAccount(
            address(implementation),
            bytes32(0),
            CHAIN_ID,
            address(soulNFT),
            tokenId
        );

        // Transfer tokens to TBA
        vm.prank(owner);
        memeToken.transfer(account, 1000 * 1e18);

        // NFT owner transfers tokens from TBA
        TokenBoundAccount tba = TokenBoundAccount(payable(account));
        bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", user1, 500 * 1e18);
        
        vm.prank(creator);
        tba.execute(address(memeToken), 0, data, 0);

        // Verify transfer
        assertEq(memeToken.balanceOf(user1), 500 * 1e18);
        assertEq(memeToken.balanceOf(account), 500 * 1e18);
    }
}
