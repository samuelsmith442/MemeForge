// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/MemeSoulNFT.sol";
import "../src/MemeToken.sol";

contract MemeSoulNFTTest is Test {
    MemeSoulNFT public soulNFT;
    MemeToken public memeToken;

    address public owner = address(1);
    address public creator = address(2);
    address public user1 = address(3);

    function setUp() public {
        vm.startPrank(owner);

        // Deploy contracts
        soulNFT = new MemeSoulNFT();
        memeToken = new MemeToken(
            "MeowFi",
            "MEOW",
            1_000_000 * 1e18,
            1e18,
            "A memecoin for cat lovers who love DeFi",
            "ipfs://QmTest123"
        );

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                            DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Deployment() public view {
        assertEq(soulNFT.name(), "MemeForge Soul");
        assertEq(soulNFT.symbol(), "MEMSOUL");
        assertEq(soulNFT.owner(), owner);
        assertEq(soulNFT.totalMinted(), 0);
    }

    /*//////////////////////////////////////////////////////////////
                            MINTING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_MintSoulNFT() public {
        MemeSoulNFT.MemecoinMetadata memory metadata = MemeSoulNFT.MemecoinMetadata({
            name: "MeowFi",
            symbol: "MEOW",
            theme: "A memecoin for cat lovers who love DeFi",
            logoURI: "ipfs://QmTest123",
            createdAt: 0,
            creator: address(0)
        });

        vm.prank(owner);
        uint256 tokenId = soulNFT.mintSoulNFT(
            creator,
            address(memeToken),
            metadata,
            "ipfs://QmNFTMetadata"
        );

        assertEq(tokenId, 0);
        assertEq(soulNFT.ownerOf(tokenId), creator);
        assertEq(soulNFT.totalMinted(), 1);
        assertEq(soulNFT.getLinkedMemeToken(tokenId), address(memeToken));
    }

    function test_MintMultipleSoulNFTs() public {
        // Deploy second memecoin
        vm.prank(owner);
        MemeToken memeToken2 = new MemeToken(
            "DogeFi",
            "DOGE",
            1_000_000 * 1e18,
            1e18,
            "A memecoin for dog lovers",
            "ipfs://QmTest456"
        );

        MemeSoulNFT.MemecoinMetadata memory metadata1 = MemeSoulNFT.MemecoinMetadata({
            name: "MeowFi",
            symbol: "MEOW",
            theme: "Cat lovers",
            logoURI: "ipfs://QmTest123",
            createdAt: 0,
            creator: address(0)
        });

        MemeSoulNFT.MemecoinMetadata memory metadata2 = MemeSoulNFT.MemecoinMetadata({
            name: "DogeFi",
            symbol: "DOGE",
            theme: "Dog lovers",
            logoURI: "ipfs://QmTest456",
            createdAt: 0,
            creator: address(0)
        });

        vm.startPrank(owner);
        uint256 tokenId1 = soulNFT.mintSoulNFT(creator, address(memeToken), metadata1, "ipfs://QmNFT1");
        uint256 tokenId2 = soulNFT.mintSoulNFT(user1, address(memeToken2), metadata2, "ipfs://QmNFT2");
        vm.stopPrank();

        assertEq(tokenId1, 0);
        assertEq(tokenId2, 1);
        assertEq(soulNFT.totalMinted(), 2);
        assertEq(soulNFT.ownerOf(tokenId1), creator);
        assertEq(soulNFT.ownerOf(tokenId2), user1);
    }

    function test_RevertWhen_MintToZeroAddress() public {
        MemeSoulNFT.MemecoinMetadata memory metadata = MemeSoulNFT.MemecoinMetadata({
            name: "MeowFi",
            symbol: "MEOW",
            theme: "Cat lovers",
            logoURI: "ipfs://QmTest123",
            createdAt: 0,
            creator: address(0)
        });

        vm.prank(owner);
        vm.expectRevert(MemeSoulNFT.MemeSoulNFT__InvalidAddress.selector);
        soulNFT.mintSoulNFT(address(0), address(memeToken), metadata, "ipfs://QmNFT");
    }

    function test_RevertWhen_MintWithZeroMemeToken() public {
        MemeSoulNFT.MemecoinMetadata memory metadata = MemeSoulNFT.MemecoinMetadata({
            name: "MeowFi",
            symbol: "MEOW",
            theme: "Cat lovers",
            logoURI: "ipfs://QmTest123",
            createdAt: 0,
            creator: address(0)
        });

        vm.prank(owner);
        vm.expectRevert(MemeSoulNFT.MemeSoulNFT__InvalidAddress.selector);
        soulNFT.mintSoulNFT(creator, address(0), metadata, "ipfs://QmNFT");
    }

    function test_RevertWhen_MintDuplicateMemeToken() public {
        MemeSoulNFT.MemecoinMetadata memory metadata = MemeSoulNFT.MemecoinMetadata({
            name: "MeowFi",
            symbol: "MEOW",
            theme: "Cat lovers",
            logoURI: "ipfs://QmTest123",
            createdAt: 0,
            creator: address(0)
        });

        vm.startPrank(owner);
        soulNFT.mintSoulNFT(creator, address(memeToken), metadata, "ipfs://QmNFT");

        vm.expectRevert(MemeSoulNFT.MemeSoulNFT__TokenAlreadyLinked.selector);
        soulNFT.mintSoulNFT(user1, address(memeToken), metadata, "ipfs://QmNFT2");
        vm.stopPrank();
    }

    function test_RevertWhen_NonOwnerMints() public {
        MemeSoulNFT.MemecoinMetadata memory metadata = MemeSoulNFT.MemecoinMetadata({
            name: "MeowFi",
            symbol: "MEOW",
            theme: "Cat lovers",
            logoURI: "ipfs://QmTest123",
            createdAt: 0,
            creator: address(0)
        });

        vm.prank(user1);
        vm.expectRevert();
        soulNFT.mintSoulNFT(creator, address(memeToken), metadata, "ipfs://QmNFT");
    }

    /*//////////////////////////////////////////////////////////////
                        TOKEN-BOUND ACCOUNT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_LinkTokenBoundAccount() public {
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

        address tbaAddress = address(0x1234);

        vm.prank(owner);
        soulNFT.linkTokenBoundAccount(tokenId, tbaAddress);

        assertEq(soulNFT.getTokenBoundAccount(tokenId), tbaAddress);
    }

    function test_RevertWhen_LinkTBAToZeroAddress() public {
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
        vm.expectRevert(MemeSoulNFT.MemeSoulNFT__InvalidAddress.selector);
        soulNFT.linkTokenBoundAccount(tokenId, address(0));
    }

    /*//////////////////////////////////////////////////////////////
                            METADATA TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GetMemecoinMetadata() public {
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

        MemeSoulNFT.MemecoinMetadata memory retrieved = soulNFT.getMemecoinMetadata(tokenId);

        assertEq(retrieved.name, "MeowFi");
        assertEq(retrieved.symbol, "MEOW");
        assertEq(retrieved.theme, "Cat lovers");
        assertEq(retrieved.logoURI, "ipfs://QmTest123");
        assertEq(retrieved.creator, creator);
        assertGt(retrieved.createdAt, 0);
    }

    function test_UpdateTokenURI() public {
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

        vm.prank(creator);
        soulNFT.updateTokenURI(tokenId, "ipfs://QmNewNFT");

        assertEq(soulNFT.tokenURI(tokenId), "ipfs://QmNewNFT");
    }

    function test_UpdateLogoURI() public {
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

        vm.prank(creator);
        soulNFT.updateLogoURI(tokenId, "ipfs://QmNewLogo");

        MemeSoulNFT.MemecoinMetadata memory retrieved = soulNFT.getMemecoinMetadata(tokenId);
        assertEq(retrieved.logoURI, "ipfs://QmNewLogo");
    }

    function test_RevertWhen_UnauthorizedUpdateTokenURI() public {
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

        vm.prank(user1);
        vm.expectRevert(MemeSoulNFT.MemeSoulNFT__UnauthorizedCaller.selector);
        soulNFT.updateTokenURI(tokenId, "ipfs://QmNewNFT");
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GetTokenIdByMemecoin() public {
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

        assertEq(soulNFT.getTokenIdByMemecoin(address(memeToken)), tokenId);
    }

    function test_GetSoulNFTInfo() public {
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

        address tbaAddress = address(0x1234);
        vm.prank(owner);
        soulNFT.linkTokenBoundAccount(tokenId, tbaAddress);

        (address nftOwner, address linkedToken, address tba, MemeSoulNFT.MemecoinMetadata memory meta) =
            soulNFT.getSoulNFTInfo(tokenId);

        assertEq(nftOwner, creator);
        assertEq(linkedToken, address(memeToken));
        assertEq(tba, tbaAddress);
        assertEq(meta.name, "MeowFi");
    }

    /*//////////////////////////////////////////////////////////////
                            TRANSFER TESTS
    //////////////////////////////////////////////////////////////*/

    function test_TransferNFT() public {
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

        vm.prank(creator);
        soulNFT.transferFrom(creator, user1, tokenId);

        assertEq(soulNFT.ownerOf(tokenId), user1);
    }
}
