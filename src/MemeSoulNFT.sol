// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MemeSoulNFT
 * @dev NFT representing the "soul" or identity of a memecoin
 * @notice Each memecoin gets one unique Soul NFT that can own assets via ERC-6551
 */
contract MemeSoulNFT is ERC721, ERC721URIStorage, Ownable {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Counter for token IDs
    uint256 private _tokenIdCounter;

    /// @notice Mapping from token ID to its token-bound account address
    mapping(uint256 => address) public tokenBoundAccount;

    /// @notice Mapping from token ID to the linked memecoin address
    mapping(uint256 => address) public linkedMemeToken;

    /// @notice Mapping from token ID to memecoin metadata
    mapping(uint256 => MemecoinMetadata) public memecoinMetadata;

    /// @notice Mapping from memecoin address to its Soul NFT token ID (tokenId + 1 to handle tokenId 0)
    mapping(address => uint256) private _memecoinToTokenIdPlusOne;

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct MemecoinMetadata {
        string name;
        string symbol;
        string theme;
        string logoURI;
        uint256 createdAt;
        address creator;
    }

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event SoulNFTMinted(uint256 indexed tokenId, address indexed creator, address indexed memeToken);
    event TokenBoundAccountLinked(uint256 indexed tokenId, address indexed tbaAddress);
    event MetadataUpdated(uint256 indexed tokenId);

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidAddress();
    error TokenAlreadyLinked();
    error TokenNotFound();
    error UnauthorizedCaller();

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() ERC721("MemeForge Soul", "MEMSOUL") Ownable(msg.sender) {}

    /*//////////////////////////////////////////////////////////////
                            MINTING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mint a Soul NFT for a new memecoin
     * @param to Address to mint the NFT to (memecoin creator)
     * @param memeToken Address of the linked memecoin
     * @param metadata Metadata for the memecoin
     * @param _tokenURI URI for the NFT metadata
     * @return tokenId The ID of the minted NFT
     */
    function mintSoulNFT(
        address to,
        address memeToken,
        MemecoinMetadata memory metadata,
        string memory _tokenURI
    ) external onlyOwner returns (uint256) {
        if (to == address(0) || memeToken == address(0)) revert InvalidAddress();
        if (_memecoinToTokenIdPlusOne[memeToken] != 0) revert TokenAlreadyLinked();

        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);

        // Link memecoin to this NFT
        linkedMemeToken[tokenId] = memeToken;
        _memecoinToTokenIdPlusOne[memeToken] = tokenId + 1;

        // Store metadata
        metadata.createdAt = block.timestamp;
        metadata.creator = to;
        memecoinMetadata[tokenId] = metadata;

        emit SoulNFTMinted(tokenId, to, memeToken);

        return tokenId;
    }

    /**
     * @notice Link a token-bound account to this Soul NFT
     * @param tokenId ID of the Soul NFT
     * @param tbaAddress Address of the token-bound account
     */
    function linkTokenBoundAccount(uint256 tokenId, address tbaAddress) external onlyOwner {
        if (tbaAddress == address(0)) revert InvalidAddress();
        if (ownerOf(tokenId) == address(0)) revert TokenNotFound();

        tokenBoundAccount[tokenId] = tbaAddress;

        emit TokenBoundAccountLinked(tokenId, tbaAddress);
    }

    /*//////////////////////////////////////////////////////////////
                            UPDATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Update the token URI for a Soul NFT
     * @param tokenId ID of the Soul NFT
     * @param newTokenURI New token URI
     */
    function updateTokenURI(uint256 tokenId, string memory newTokenURI) external {
        if (ownerOf(tokenId) != msg.sender && owner() != msg.sender) {
            revert UnauthorizedCaller();
        }

        _setTokenURI(tokenId, newTokenURI);
        emit MetadataUpdated(tokenId);
    }

    /**
     * @notice Update the logo URI in metadata
     * @param tokenId ID of the Soul NFT
     * @param newLogoURI New logo URI
     */
    function updateLogoURI(uint256 tokenId, string memory newLogoURI) external {
        if (ownerOf(tokenId) != msg.sender && owner() != msg.sender) {
            revert UnauthorizedCaller();
        }

        memecoinMetadata[tokenId].logoURI = newLogoURI;
        emit MetadataUpdated(tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get the token-bound account for a Soul NFT
     * @param tokenId ID of the Soul NFT
     * @return Address of the token-bound account
     */
    function getTokenBoundAccount(uint256 tokenId) external view returns (address) {
        return tokenBoundAccount[tokenId];
    }

    /**
     * @notice Get the linked memecoin for a Soul NFT
     * @param tokenId ID of the Soul NFT
     * @return Address of the linked memecoin
     */
    function getLinkedMemeToken(uint256 tokenId) external view returns (address) {
        return linkedMemeToken[tokenId];
    }

    /**
     * @notice Get metadata for a memecoin
     * @param tokenId ID of the Soul NFT
     * @return Memecoin metadata
     */
    function getMemecoinMetadata(uint256 tokenId) external view returns (MemecoinMetadata memory) {
        return memecoinMetadata[tokenId];
    }

    /**
     * @notice Get the Soul NFT token ID for a memecoin
     * @param memeToken Address of the memecoin
     * @return Token ID of the Soul NFT
     */
    function getTokenIdByMemecoin(address memeToken) external view returns (uint256) {
        uint256 tokenIdPlusOne = _memecoinToTokenIdPlusOne[memeToken];
        if (tokenIdPlusOne == 0) revert TokenNotFound();
        return tokenIdPlusOne - 1;
    }

    /**
     * @notice Get complete information about a Soul NFT
     * @param tokenId ID of the Soul NFT
     * @return owner Owner of the NFT
     * @return memeToken Linked memecoin address
     * @return tba Token-bound account address
     * @return metadata Memecoin metadata
     */
    function getSoulNFTInfo(uint256 tokenId)
        external
        view
        returns (address owner, address memeToken, address tba, MemecoinMetadata memory metadata)
    {
        return (ownerOf(tokenId), linkedMemeToken[tokenId], tokenBoundAccount[tokenId], memecoinMetadata[tokenId]);
    }

    /**
     * @notice Get the total number of Soul NFTs minted
     * @return Total count
     */
    function totalMinted() external view returns (uint256) {
        return _tokenIdCounter;
    }

    /*//////////////////////////////////////////////////////////////
                            OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Override required by Solidity for ERC721URIStorage
     */
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Override required by Solidity for ERC721URIStorage
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
