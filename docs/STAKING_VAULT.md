# StakingVault Documentation

## Overview

The **StakingVault** is a dedicated contract that handles staking logic for all MemeTokens in the MemeForge ecosystem. It integrates with Chainlink VRF to provide random reward multipliers, making staking more engaging and fun.

## Key Features

### 1. **Multi-Token Support**
- Single vault handles staking for multiple tokens
- Each token can have its own reward rate
- Tokens can be enabled/disabled independently

### 2. **Chainlink VRF Integration**
- Random reward multipliers (1x to 5x)
- Provably fair randomness
- Makes claiming rewards exciting

### 3. **Flexible Reward System**
- Time-based rewards (per second)
- Configurable reward rates per token
- Rewards are minted, not transferred (infinite supply)

### 4. **Security**
- ReentrancyGuard protection
- Owner-only admin functions
- SafeERC20 for token transfers

## Architecture

```
User
  ↓
  ├─→ stake(token, amount)
  │     └─→ Token transferred to vault
  │     └─→ Stake info updated
  │
  ├─→ unstake(token, amount)
  │     └─→ Rewards updated
  │     └─→ Token transferred back
  │
  └─→ claimRewards(token)
        └─→ Request randomness from VRF
        └─→ VRF returns random number
        └─→ Apply multiplier (1x-5x)
        └─→ Mint rewards to user
```

## Contract Structure

### State Variables

```solidity
// VRF Configuration
IVRFCoordinatorV2 public immutable vrfCoordinator;
uint64 public subscriptionId;
bytes32 public keyHash;
uint32 public callbackGasLimit;

// Multiplier Constants
uint256 public constant MIN_MULTIPLIER = 100;  // 1x
uint256 public constant MAX_MULTIPLIER = 500;  // 5x
uint256 public constant MULTIPLIER_PRECISION = 100;

// Token Configuration
mapping(address => TokenConfig) public tokenConfigs;

// User Stakes
mapping(address => mapping(address => StakeInfo)) public stakes;

// VRF Requests
mapping(uint256 => RandomnessRequest) public randomnessRequests;
```

### Key Functions

#### **User Functions**

**`stake(address token, uint256 amount)`**
- Stakes tokens to earn rewards
- Requires token approval first
- Updates reward calculations before staking

**`unstake(address token, uint256 amount)`**
- Unstakes tokens
- Automatically updates rewards
- Returns tokens to user

**`claimRewards(address token)`**
- Claims pending rewards with random multiplier
- Requests randomness from Chainlink VRF
- Rewards minted after VRF callback

#### **Admin Functions**

**`configureToken(address token, uint256 rewardRate, bool isActive)`**
- Configures a token for staking
- Sets reward rate (per second per token)
- Enables/disables staking

**`updateVRFConfig(uint64 _subscriptionId, bytes32 _keyHash, uint32 _callbackGasLimit)`**
- Updates Chainlink VRF configuration
- Only owner can call

#### **View Functions**

**`calculateRewards(address user, address token)`**
- Returns pending rewards for a user
- Includes time-based calculation

**`getStakeInfo(address user, address token)`**
- Returns stake amount, start time, and pending rewards

**`getTokenConfig(address token)`**
- Returns reward rate, total staked, and active status

## Integration Guide

### For MemeToken Contracts

1. **Add mint function** (if not already present):
```solidity
function mint(address to, uint256 amount) external {
    require(msg.sender == stakingVault || msg.sender == owner());
    _mint(to, amount);
}
```

2. **Set vault address**:
```solidity
token.setStakingVault(address(vault));
```

3. **Configure in vault**:
```solidity
vault.configureToken(address(token), rewardRate, true);
```

### For Users

1. **Approve tokens**:
```solidity
token.approve(address(vault), amount);
```

2. **Stake**:
```solidity
vault.stake(address(token), amount);
```

3. **Claim rewards** (with random multiplier):
```solidity
vault.claimRewards(address(token));
// Wait for VRF callback
// Rewards automatically minted with multiplier
```

4. **Unstake**:
```solidity
vault.unstake(address(token), amount);
```

## Chainlink VRF Setup

### Local Testing (Mock VRF)

For development, use `MockVRFCoordinatorV2`:

```solidity
MockVRFCoordinatorV2 mockVRF = new MockVRFCoordinatorV2();
StakingVault vault = new StakingVault(
    address(mockVRF),
    1, // subscription ID
    bytes32(uint256(1)), // key hash
    500_000 // callback gas limit
);
```

In tests, manually fulfill requests:
```solidity
vault.claimRewards(token);
mockVRF.fulfillRequest(1); // Fulfill the request
```

### Testnet Deployment (Real VRF)

1. **Create VRF Subscription**:
   - Go to https://vrf.chain.link/
   - Connect wallet
   - Create subscription
   - Fund with test LINK from https://faucets.chain.link/

2. **Deploy with real VRF**:
```solidity
address vrfCoordinator = 0x...; // Sepolia VRF Coordinator
bytes32 keyHash = 0x...; // Gas lane key hash
uint64 subId = 123; // Your subscription ID

StakingVault vault = new StakingVault(
    vrfCoordinator,
    subId,
    keyHash,
    500_000
);
```

3. **Add vault as consumer**:
   - In VRF UI, add vault address to subscription

### Mainnet Deployment

Same as testnet, but:
- Use mainnet VRF Coordinator
- Fund subscription with real LINK
- Costs ~0.25 LINK per request

## Reward Calculation

### Base Reward Formula

```
baseReward = (stakedAmount * rewardRate * stakingDuration) / 1e18
```

Where:
- `stakedAmount`: Amount of tokens staked
- `rewardRate`: Tokens per second per token staked (e.g., 1e15 = 0.001)
- `stakingDuration`: Time since last claim (in seconds)

### Example

```
Staked: 1000 tokens
Rate: 1e15 (0.001 tokens/second/token)
Duration: 86400 seconds (1 day)

baseReward = (1000e18 * 1e15 * 86400) / 1e18
           = 86,400 tokens
```

### With Random Multiplier

```
finalReward = baseReward * multiplier / 100
```

Where multiplier is random between 100 (1x) and 500 (5x):
- Min: 86,400 tokens (1x)
- Max: 432,000 tokens (5x)

## Gas Optimization

- Uses `SafeERC20` for safe transfers
- Minimal storage reads/writes
- Efficient reward calculation
- ReentrancyGuard only where needed

## Security Considerations

1. **Reentrancy Protection**: All state-changing functions protected
2. **Access Control**: Admin functions restricted to owner
3. **VRF Validation**: Only VRF coordinator can fulfill requests
4. **Safe Math**: Uses Solidity 0.8+ built-in overflow protection
5. **Token Approval**: Users must approve before staking

## Testing

Run comprehensive test suite:
```bash
forge test --match-path test/StakingVault.t.sol -vv
```

Tests cover:
- ✅ Staking/unstaking
- ✅ Reward calculations
- ✅ VRF integration
- ✅ Multi-token support
- ✅ Multi-user scenarios
- ✅ Edge cases and reverts

## Events

```solidity
event TokenConfigured(address indexed token, uint256 rewardRate, bool isActive);
event Staked(address indexed user, address indexed token, uint256 amount);
event Unstaked(address indexed user, address indexed token, uint256 amount);
event RewardsClaimed(address indexed user, address indexed token, uint256 amount, uint256 multiplier);
event RandomnessRequested(uint256 indexed requestId, address indexed user, address indexed token);
event VRFConfigUpdated(uint64 subscriptionId, bytes32 keyHash, uint32 callbackGasLimit);
```

## Error Handling

```solidity
error StakingVault__InvalidAmount();
error StakingVault__InsufficientStake();
error StakingVault__NoRewardsToClaim();
error StakingVault__InvalidToken();
error StakingVault__StakingNotActive();
error StakingVault__InvalidMultiplier();
error StakingVault__RequestNotFound();
```

## Future Enhancements

Potential improvements for future versions:
- [ ] Multiple reward tokens
- [ ] Lock periods with bonus multipliers
- [ ] Tiered reward rates based on stake amount
- [ ] Emergency pause functionality
- [ ] Reward token swapping
- [ ] NFT boost multipliers

## License

MIT License

---

**Built for ETHOnline 2025 🚀**
