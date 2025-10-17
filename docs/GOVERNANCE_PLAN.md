# Governance System Implementation Plan
## Days 6-7 (Oct 16-17, 2025)

---

## 🎯 Objectives

Implement a complete DAO governance system for MemeForge that allows token holders to:
1. **Create proposals** for protocol changes
2. **Vote on proposals** with token-weighted voting
3. **Execute proposals** after timelock delay
4. **Manage protocol parameters** through governance

---

## 🏗️ Architecture Overview

### **Components:**

```
MemeToken (ERC20Votes)
    ↓ (voting power)
MemeGovernor (OpenZeppelin Governor)
    ↓ (proposes actions)
TimelockController
    ↓ (executes after delay)
Target Contracts (StakingVault, etc.)
```

### **Governance Flow:**

```
1. Token Holder Creates Proposal
   └─→ MemeGovernor.propose(targets, values, calldatas, description)

2. Voting Period Begins (e.g., 1 week)
   ├─→ Token holders vote: For / Against / Abstain
   └─→ Voting power = token balance at proposal snapshot

3. Proposal Succeeds (quorum + majority reached)
   └─→ Proposal queued in TimelockController

4. Timelock Delay (e.g., 2 days)
   └─→ Security buffer for community review

5. Proposal Executed
   └─→ TimelockController executes the actions
```

---

## 📋 Implementation Steps

### **Step 1: Update MemeToken for Governance** ⏱️ 30 mins

**Goal:** Add voting capabilities to MemeToken

**Changes to `MemeToken.sol`:**
```solidity
// Add imports
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

// Change inheritance
contract MemeToken is ERC20, ERC20Burnable, ERC20Votes, Ownable, ReentrancyGuard {
    
    // Add constructor parameter for initial delegate
    constructor(...) ERC20Permit("MemeToken") {
        // Existing code...
        _delegate(msg.sender, msg.sender); // Self-delegate for voting power
    }
    
    // Override required functions
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes)
    {
        super._update(from, to, value);
    }

    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}
```

**Why ERC20Votes?**
- Provides `getVotes()` for checking voting power
- Implements checkpointing (historical balances)
- Enables delegation (users can delegate voting power)
- Required by OpenZeppelin Governor

---

### **Step 2: Create TimelockController** ⏱️ 15 mins

**Goal:** Add security delay between proposal approval and execution

**File:** `src/TimelockController.sol`

**Option A: Use OpenZeppelin's TimelockController (Recommended)**
```solidity
// Just import and use directly in deployment
import "@openzeppelin/contracts/governance/TimelockController.sol";
```

**Configuration:**
- **Min Delay:** 2 days (172,800 seconds)
- **Proposers:** [MemeGovernor address]
- **Executors:** [address(0)] = anyone can execute after delay
- **Admin:** [address(0)] = no admin (fully decentralized)

**Why Timelock?**
- Security buffer for community to review proposals
- Allows users to exit if they disagree with a proposal
- Standard practice for DAOs (Compound, Uniswap, etc.)

---

### **Step 3: Implement MemeGovernor** ⏱️ 2 hours

**Goal:** Create the main governance contract

**File:** `src/MemeGovernor.sol`

**Structure:**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";

contract MemeGovernor is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl
{
    constructor(
        IVotes _token,
        TimelockController _timelock,
        uint256 _votingDelay,
        uint256 _votingPeriod,
        uint256 _proposalThreshold,
        uint256 _quorumPercentage
    )
        Governor("MemeGovernor")
        GovernorSettings(_votingDelay, _votingPeriod, _proposalThreshold)
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(_quorumPercentage)
        GovernorTimelockControl(_timelock)
    {}

    // Override functions as required by OpenZeppelin
    // ... (see full implementation below)
}
```

**Parameters:**
- **Voting Delay:** 1 day (86,400 seconds) - Time before voting starts
- **Voting Period:** 1 week (604,800 seconds) - How long voting lasts
- **Proposal Threshold:** 1,000 tokens - Min tokens to create proposal
- **Quorum:** 4% - Min participation for proposal to pass

**Extensions Explained:**
1. **GovernorSettings:** Configurable voting delay, period, threshold
2. **GovernorCountingSimple:** For/Against/Abstain voting
3. **GovernorVotes:** Integrates with ERC20Votes token
4. **GovernorVotesQuorumFraction:** Percentage-based quorum
5. **GovernorTimelockControl:** Integrates with timelock

---

### **Step 4: Create Governance Tests** ⏱️ 2 hours

**Goal:** Comprehensive testing of governance workflows

**File:** `test/Governance.t.sol`

**Test Categories:**

#### **A. Proposal Creation Tests**
```solidity
- test_CreateProposal()
- test_RevertWhen_ProposalThresholdNotMet()
- test_ProposalState()
- test_MultipleProposals()
```

#### **B. Voting Tests**
```solidity
- test_VoteFor()
- test_VoteAgainst()
- test_VoteAbstain()
- test_VotingPower()
- test_DelegatedVoting()
- test_RevertWhen_VoteTwice()
- test_RevertWhen_VoteBeforeDelay()
- test_RevertWhen_VoteAfterPeriod()
```

#### **C. Quorum Tests**
```solidity
- test_QuorumReached()
- test_QuorumNotReached()
- test_QuorumCalculation()
```

#### **D. Execution Tests**
```solidity
- test_QueueProposal()
- test_ExecuteProposal()
- test_RevertWhen_ExecuteBeforeTimelock()
- test_RevertWhen_ExecuteFailedProposal()
```

#### **E. Integration Tests**
```solidity
- test_FullGovernanceWorkflow()
- test_UpdateStakingVaultRewardRate()
- test_UpdateGovernanceParameters()
- test_CancelProposal()
```

---

### **Step 5: Example Governance Actions** ⏱️ 30 mins

**Goal:** Create helper contracts for common governance actions

**File:** `src/governance/GovernanceActions.sol`

**Example Actions:**
```solidity
contract GovernanceActions {
    // Action 1: Update StakingVault reward rate
    function updateRewardRate(
        address stakingVault,
        address token,
        uint256 newRate
    ) external {
        StakingVault(stakingVault).configureToken(token, newRate, true);
    }

    // Action 2: Update governance parameters
    function updateVotingPeriod(
        address governor,
        uint256 newPeriod
    ) external {
        MemeGovernor(governor).setVotingPeriod(newPeriod);
    }

    // Action 3: Emergency pause
    function pauseStaking(address stakingVault, address token) external {
        StakingVault(stakingVault).configureToken(token, 0, false);
    }
}
```

---

## 📊 Governance Parameters

### **Recommended Settings:**

| Parameter | Value | Reasoning |
|-----------|-------|-----------|
| **Voting Delay** | 1 day | Time to prepare for vote |
| **Voting Period** | 1 week | Enough time for participation |
| **Proposal Threshold** | 1,000 tokens | Prevents spam, allows participation |
| **Quorum** | 4% | Achievable but meaningful |
| **Timelock Delay** | 2 days | Security buffer |

### **Adjustable Parameters:**

For a new/small community:
- Lower proposal threshold (100 tokens)
- Lower quorum (2%)
- Shorter voting period (3 days)

For a mature/large community:
- Higher proposal threshold (10,000 tokens)
- Higher quorum (10%)
- Longer voting period (2 weeks)

---

## 🔐 Security Considerations

### **1. Timelock Protection**
- ✅ 2-day delay before execution
- ✅ Community can react to malicious proposals
- ✅ Users can exit if they disagree

### **2. Quorum Requirements**
- ✅ Prevents minority attacks
- ✅ Ensures community participation
- ✅ Adjustable via governance

### **3. Proposal Threshold**
- ✅ Prevents spam proposals
- ✅ Requires skin in the game
- ✅ Balances accessibility and security

### **4. Delegation**
- ✅ Users can delegate voting power
- ✅ Enables representative governance
- ✅ Maintains token liquidity

### **5. Snapshot Voting**
- ✅ Prevents vote buying during proposal
- ✅ Uses historical balances
- ✅ Prevents flash loan attacks

---

## 🎨 User Experience Flow

### **Creating a Proposal:**
```
1. User has 1,000+ tokens
2. Calls governor.propose([targets], [values], [calldatas], "description")
3. Proposal enters "Pending" state
4. After 1 day, enters "Active" state
```

### **Voting:**
```
1. Voting period begins (1 week)
2. User calls governor.castVote(proposalId, support)
   - 0 = Against
   - 1 = For
   - 2 = Abstain
3. Voting power = token balance at proposal creation
```

### **Execution:**
```
1. Proposal succeeds (quorum + majority)
2. Anyone calls governor.queue(proposalId)
3. Wait 2 days (timelock)
4. Anyone calls governor.execute(proposalId)
5. Actions execute on target contracts
```

---

## 📝 Example Proposals

### **Proposal 1: Increase Staking Rewards**
```solidity
// Targets
address[] memory targets = new address[](1);
targets[0] = address(stakingVault);

// Values (ETH to send)
uint256[] memory values = new uint256[](1);
values[0] = 0;

// Calldatas
bytes[] memory calldatas = new bytes[](1);
calldatas[0] = abi.encodeWithSignature(
    "configureToken(address,uint256,bool)",
    address(memeToken),
    2e15, // Double the reward rate
    true
);

// Description
string memory description = "Proposal #1: Double staking rewards to 0.002 tokens/second";

// Create proposal
governor.propose(targets, values, calldatas, description);
```

### **Proposal 2: Update Governance Parameters**
```solidity
// Reduce voting period to 3 days
targets[0] = address(governor);
calldatas[0] = abi.encodeWithSignature("setVotingPeriod(uint256)", 3 days);
description = "Proposal #2: Reduce voting period to 3 days for faster governance";
```

---

## 🧪 Testing Strategy

### **Unit Tests:**
- Test each governance function individually
- Verify state transitions
- Check access controls

### **Integration Tests:**
- Full proposal lifecycle
- Multiple proposals simultaneously
- Delegation scenarios

### **Fuzz Tests:**
- Random voting patterns
- Various token distributions
- Edge cases in quorum calculation

### **Scenario Tests:**
- Real-world governance actions
- Emergency situations
- Parameter updates

---

## 📦 Deliverables

### **Contracts:**
1. ✅ `MemeToken.sol` (updated with ERC20Votes)
2. ✅ `MemeGovernor.sol` (main governance contract)
3. ✅ `GovernanceActions.sol` (helper for common actions)
4. ✅ Use OpenZeppelin's `TimelockController`

### **Tests:**
1. ✅ `Governance.t.sol` (30+ tests)
2. ✅ `GovernanceFuzz.t.sol` (10+ fuzz tests)

### **Documentation:**
1. ✅ `docs/GOVERNANCE.md` (user guide)
2. ✅ `docs/GOVERNANCE_PLAN.md` (this file)
3. ✅ Updated `PROGRESS.md`

### **Deployment:**
1. ✅ Updated `DeployMemeForge.s.sol`
2. ✅ Governance setup script

---

## 🚀 Implementation Timeline

### **Day 6 (Oct 16):**
- ⏱️ 09:00-10:00: Update MemeToken with ERC20Votes
- ⏱️ 10:00-12:00: Implement MemeGovernor
- ⏱️ 12:00-13:00: Create GovernanceActions helper
- ⏱️ 13:00-15:00: Write unit tests (proposal creation, voting)
- ⏱️ 15:00-17:00: Write integration tests (full workflows)

### **Day 7 (Oct 17):**
- ⏱️ 09:00-11:00: Write fuzz tests
- ⏱️ 11:00-12:00: Update deployment scripts
- ⏱️ 12:00-14:00: Create documentation (GOVERNANCE.md)
- ⏱️ 14:00-16:00: End-to-end testing
- ⏱️ 16:00-17:00: Update PROGRESS.md and commit

---

## 🎯 Success Criteria

- ✅ All governance tests passing (40+ tests)
- ✅ Fuzz tests with 256+ iterations passing
- ✅ Full proposal lifecycle working
- ✅ Timelock integration functional
- ✅ Delegation working correctly
- ✅ Documentation complete
- ✅ Deployment script updated
- ✅ Zero security vulnerabilities

---

## 📚 References

- [OpenZeppelin Governor](https://docs.openzeppelin.com/contracts/4.x/governance)
- [Compound Governance](https://compound.finance/docs/governance)
- [Uniswap Governance](https://docs.uniswap.org/protocol/concepts/governance/overview)
- [EIP-2612: Permit](https://eips.ethereum.org/EIPS/eip-2612)

---

**Ready to build a production-grade DAO governance system! 🏛️**
