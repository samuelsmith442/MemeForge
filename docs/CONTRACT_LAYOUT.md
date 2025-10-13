# Contract Layout Standards

This document describes the standardized contract layout used throughout the MemeForge project.

## Layout Order

All contracts in this project follow this standardized order:

### 1. **Version Pragma**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
```

### 2. **Imports**
```solidity
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
```

### 3. **Errors**
Custom error declarations outside the contract (for better gas efficiency and to avoid naming conflicts):
```solidity
error ContractName__ErrorDescription();
error ContractName__AnotherError();
```

**Naming Convention:** `ContractName__ErrorDescription`
- Prefix with contract name to avoid conflicts
- Use double underscore separator
- Descriptive error name in PascalCase

### 4. **Contract Documentation & Definition**
```solidity
/**
 * @title ContractName
 * @dev Brief description
 * @notice User-facing description
 */
contract ContractName is Parent1, Parent2 {
```

### 5. **Type Declarations**
```solidity
struct MyStruct {
    uint256 value;
    address owner;
}

enum Status { Active, Inactive }
```

### 6. **State Variables**
```solidity
uint256 public counter;
mapping(address => uint256) private balances;
```

### 7. **Events**
```solidity
event Transfer(address indexed from, address indexed to, uint256 amount);
```

### 8. **Modifiers**
```solidity
modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;
}
```

### 9. **Functions**
Ordered by visibility and purpose:

#### 9.1 Constructor
```solidity
constructor() {
    // initialization
}
```

#### 9.2 Receive Function
```solidity
receive() external payable {}
```

#### 9.3 Fallback Function
```solidity
fallback() external payable {}
```

#### 9.4 External Functions
```solidity
function externalFunction() external {}
```

#### 9.5 Public Functions
```solidity
function publicFunction() public {}
```

#### 9.6 Internal Functions
```solidity
function _internalFunction() internal {}
```

#### 9.7 Private Functions
```solidity
function _privateFunction() private {}
```

---

## Examples from MemeForge

### MemeToken.sol
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Errors
error MemeToken__InsufficientBalance();
error MemeToken__InvalidAddress();

/**
 * @title MemeToken
 * @dev AI-generated memecoin with built-in utility mechanisms
 */
contract MemeToken is ERC20, Ownable {
    // State variables
    uint256 public rewardRate;
    
    // Events
    event Staked(address indexed user, uint256 amount);
    
    // Constructor
    constructor() ERC20("MemeToken", "MEME") {}
    
    // External functions
    function stake(uint256 amount) external {}
    
    // Internal functions
    function _calculateRewards() internal view returns (uint256) {}
}
```

### MemeSoulNFT.sol
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Errors
error MemeSoulNFT__InvalidAddress();
error MemeSoulNFT__TokenAlreadyLinked();

/**
 * @title MemeSoulNFT
 * @dev NFT representing the "soul" or identity of a memecoin
 */
contract MemeSoulNFT is ERC721, Ownable {
    // Type declarations
    struct MemecoinMetadata {
        string name;
        string symbol;
    }
    
    // State variables
    uint256 private _tokenIdCounter;
    
    // Events
    event SoulNFTMinted(uint256 indexed tokenId);
    
    // Constructor
    constructor() ERC721("MemeForge Soul", "MEMSOUL") {}
    
    // External functions
    function mintSoulNFT() external {}
}
```

### TokenBoundAccount.sol
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Errors
error TokenBoundAccount__InvalidSigner();
error TokenBoundAccount__InvalidOperation();

/**
 * @title TokenBoundAccount
 * @dev Implementation of ERC-6551 token-bound account
 */
contract TokenBoundAccount is ReentrancyGuard {
    // State variables
    uint256 private immutable _deploymentChainId;
    
    // Constructor
    constructor() {}
    
    // Receive function
    receive() external payable {}
    
    // External functions
    function execute() external payable {}
    
    // Public functions
    function token() public view returns (uint256, address, uint256) {}
    
    // Internal functions
    function _isValidSigner() internal view returns (bool) {}
}
```

---

## Benefits

1. **Consistency**: All contracts follow the same structure
2. **Readability**: Easy to navigate and understand
3. **Maintainability**: Predictable location for each element
4. **Gas Efficiency**: Errors declared outside contract save gas
5. **Conflict Avoidance**: Namespaced errors prevent collisions
6. **Best Practices**: Follows Solidity style guide recommendations

---

## Error Naming Convention

### Pattern
```
ContractName__ErrorDescription
```

### Examples
- `MemeToken__InsufficientBalance`
- `MemeSoulNFT__TokenAlreadyLinked`
- `TokenBoundAccount__InvalidSigner`

### Why?
- Prevents naming conflicts across contracts
- Makes errors easily traceable to their source
- Improves debugging experience
- Follows modern Solidity best practices

---

## Verification

All contracts in the MemeForge project have been reorganized to follow this layout:
- ✅ MemeToken.sol
- ✅ MemeSoulNFT.sol
- ✅ TokenBoundAccount.sol
- ✅ ERC6551Registry.sol

All 50 tests pass after reorganization.

---

**Last Updated:** October 13, 2025
