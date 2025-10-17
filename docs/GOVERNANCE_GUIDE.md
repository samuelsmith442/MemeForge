# 🏛️ MemeForge Governance Guide

## Table of Contents
- [Overview](#overview)
- [Quick Start](#quick-start)
- [Governance Parameters](#governance-parameters)
- [How to Participate](#how-to-participate)
- [Proposal Lifecycle](#proposal-lifecycle)
- [Voting](#voting)
- [Execution](#execution)
- [Best Practices](#best-practices)
- [FAQ](#faq)

---

## Overview

MemeForge uses a **fully on-chain DAO governance system** powered by OpenZeppelin Governor. Token holders can propose and vote on changes to the protocol, making MemeForge truly community-owned.

### Key Features
- ✅ **Token-Weighted Voting** - 1 token = 1 vote
- ✅ **Timelock Security** - 2-day delay before execution
- ✅ **Transparent** - All proposals and votes on-chain
- ✅ **Permissionless** - Anyone can execute passed proposals
- ✅ **Flexible** - Adjust parameters through governance

---

## Quick Start

### 1. Get Voting Power
```solidity
// Delegate your tokens to yourself to activate voting power
token.delegate(yourAddress);
```

### 2. Create a Proposal (requires 1,000+ tokens)
```solidity
address[] memory targets = [tokenAddress];
uint256[] memory values = [0];
bytes[] memory calldatas = [abi.encodeWithSignature("setRewardRate(uint256)", 2e15)];
string memory description = "Proposal #1: Increase reward rate to 0.002";

governor.propose(targets, values, calldatas, description);
```

### 3. Vote (after 1-day delay)
```solidity
// 0 = Against, 1 = For, 2 = Abstain
governor.castVote(proposalId, 1);
```

### 4. Queue & Execute (after voting ends)
```solidity
// Queue in timelock
governor.queue(targets, values, calldatas, keccak256(bytes(description)));

// Wait 2 days, then execute
governor.execute(targets, values, calldatas, keccak256(bytes(description)));
```

---

## Governance Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| **Voting Delay** | 1 day | Time before voting starts after proposal creation |
| **Voting Period** | 1 week | Duration of voting |
| **Proposal Threshold** | 1,000 tokens | Minimum tokens needed to create proposal |
| **Quorum** | 4% of supply | Minimum participation for proposal to pass |
| **Timelock Delay** | 2 days | Security delay before execution |

---

## How to Participate

### Step 1: Acquire Tokens
- Buy tokens on DEX
- Receive tokens from staking rewards
- Receive tokens from community

### Step 2: Delegate Voting Power

**Why delegate?**
- Voting power is based on **delegated** balance, not just token balance
- You must delegate to yourself or another address to participate

**How to delegate:**

```solidity
// Option 1: Delegate to yourself
token.delegate(msg.sender);

// Option 2: Delegate to someone else
token.delegate(trustedAddress);
```

**Important Notes:**
- Delegation is required even if voting for yourself
- Delegation doesn't transfer tokens, only voting power
- You can change delegation at any time
- Voting power is snapshotted at proposal creation

### Step 3: Monitor Proposals

**Where to find proposals:**
- On-chain events: `ProposalCreated`
- Governance dashboard (if available)
- Community Discord/Forum

**Proposal States:**
- **Pending** - Waiting for voting delay to pass
- **Active** - Voting is open
- **Succeeded** - Passed and ready to queue
- **Defeated** - Failed (didn't reach quorum or majority voted against)
- **Queued** - Waiting in timelock
- **Executed** - Successfully executed
- **Canceled** - Canceled by proposer

---

## Proposal Lifecycle

```
┌─────────────┐
│   CREATE    │  Proposer creates proposal (needs 1,000+ tokens)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   PENDING   │  1-day voting delay
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   ACTIVE    │  1-week voting period
└──────┬──────┘
       │
       ├─── Passed ───┐
       │              ▼
       │         ┌─────────────┐
       │         │  SUCCEEDED  │
       │         └──────┬──────┘
       │                │
       │                ▼
       │         ┌─────────────┐
       │         │   QUEUED    │  2-day timelock delay
       │         └──────┬──────┘
       │                │
       │                ▼
       │         ┌─────────────┐
       │         │  EXECUTED   │  ✅ Changes applied
       │         └─────────────┘
       │
       └─── Failed ───┐
                      ▼
               ┌─────────────┐
               │  DEFEATED   │  ❌ No changes
               └─────────────┘
```

---

## Voting

### How to Vote

**Option 1: Simple Vote**
```solidity
// Cast your vote
governor.castVote(proposalId, support);
// support: 0 = Against, 1 = For, 2 = Abstain
```

**Option 2: Vote with Reason**
```solidity
// Cast vote with explanation
governor.castVoteWithReason(proposalId, support, "I support this because...");
```

**Option 3: Vote by Signature (Gasless)**
```solidity
// Sign vote off-chain, submit on-chain
governor.castVoteBySig(proposalId, support, v, r, s);
```

### Voting Options

| Option | Value | Effect |
|--------|-------|--------|
| **Against** | 0 | Vote against the proposal |
| **For** | 1 | Vote in favor of the proposal |
| **Abstain** | 2 | Count towards quorum but don't affect outcome |

### Voting Power

- Voting power = Your delegated token balance **at proposal creation**
- Buying/selling tokens after proposal creation doesn't affect your vote
- You can only vote once per proposal
- Voting power is proportional to token holdings

### Quorum Requirement

For a proposal to pass:
1. **Quorum must be reached**: At least 4% of total supply must participate
2. **Majority must vote For**: More For votes than Against votes

**Example:**
- Total supply: 1,000,000 tokens
- Quorum needed: 40,000 tokens (4%)
- If 50,000 tokens vote (30k For, 20k Against) → **Passes** ✅
- If 30,000 tokens vote (25k For, 5k Against) → **Fails** ❌ (below quorum)

---

## Execution

### Queue Proposal

After a proposal succeeds, it must be queued in the timelock:

```solidity
governor.queue(
    targets,
    values,
    calldatas,
    keccak256(bytes(description))
);
```

**Important:** The description hash must match exactly!

### Wait for Timelock

- Proposals must wait **2 days** in the timelock
- This gives the community time to react to governance decisions
- Emergency response window for critical issues

### Execute Proposal

After the timelock delay, anyone can execute:

```solidity
governor.execute(
    targets,
    values,
    calldatas,
    keccak256(bytes(description))
);
```

**Note:** Execution is permissionless - any address can call it!

---

## Best Practices

### For Proposers

1. **Build Consensus First**
   - Discuss proposal in community forums
   - Gather feedback before submitting
   - Ensure you have support

2. **Write Clear Descriptions**
   - Explain what the proposal does
   - Include rationale and expected impact
   - Provide technical details

3. **Test Thoroughly**
   - Simulate proposal execution
   - Verify calldata is correct
   - Check for unintended consequences

4. **Monitor Your Proposal**
   - Engage with voters
   - Answer questions
   - Address concerns

### For Voters

1. **Do Your Research**
   - Read the full proposal
   - Understand the implications
   - Check technical details

2. **Vote Your Conviction**
   - Vote based on merit, not politics
   - Consider long-term effects
   - Use Abstain if unsure

3. **Participate Actively**
   - Vote on every proposal
   - Engage in discussions
   - Help reach quorum

4. **Delegate Wisely**
   - If you can't participate, delegate to someone who will
   - Choose delegates who share your values
   - Monitor delegate voting behavior

---

## FAQ

### General Questions

**Q: Do I need to pay gas to vote?**
A: Yes, voting is an on-chain transaction that requires gas. Consider using vote-by-signature for gasless voting.

**Q: Can I change my vote?**
A: No, votes are final once cast.

**Q: What happens if I transfer my tokens after voting?**
A: Your vote remains valid. Voting power is snapshotted at proposal creation.

**Q: Can I vote if I haven't delegated?**
A: No, you must delegate your tokens (even to yourself) to activate voting power.

### Proposal Questions

**Q: How do I know if my proposal will pass?**
A: Monitor community sentiment and ensure you have enough support before proposing.

**Q: Can I cancel my proposal?**
A: Yes, the proposer can cancel before execution (if they still meet the threshold).

**Q: What if my proposal fails?**
A: You can create a new proposal with modifications based on feedback.

**Q: Can I propose multiple actions in one proposal?**
A: Yes! You can include multiple targets, values, and calldatas in a single proposal.

### Technical Questions

**Q: How do I get the proposal ID?**
A: The `propose()` function returns the proposal ID. You can also find it in the `ProposalCreated` event.

**Q: How do I check proposal status?**
A: Call `governor.state(proposalId)` to get the current state.

**Q: What if execution fails?**
A: The proposal remains in the Queued state and can be executed again once the issue is fixed.

**Q: Can governance be upgraded?**
A: Only through governance itself! The community can vote to upgrade the governor contract.

---

## Example Proposals

### 1. Change Reward Rate

```solidity
// Increase staking rewards from 0.001 to 0.002 per second
address[] memory targets = new address[](1);
uint256[] memory values = new uint256[](1);
bytes[] memory calldatas = new bytes[](1);

targets[0] = address(token);
values[0] = 0;
calldatas[0] = abi.encodeWithSignature("setRewardRate(uint256)", 2e15);

string memory description = "Proposal #1: Increase reward rate to incentivize staking";

uint256 proposalId = governor.propose(targets, values, calldatas, description);
```

### 2. Enable/Disable Staking

```solidity
// Pause staking in case of emergency
address[] memory targets = new address[](1);
uint256[] memory values = new uint256[](1);
bytes[] memory calldatas = new bytes[](1);

targets[0] = address(token);
values[0] = 0;
calldatas[0] = abi.encodeWithSignature("setStakingActive(bool)", false);

string memory description = "Emergency Proposal: Pause staking due to security concern";

uint256 proposalId = governor.propose(targets, values, calldatas, description);
```

### 3. Multi-Action Proposal

```solidity
// Change reward rate AND update VRF config
address[] memory targets = new address[](2);
uint256[] memory values = new uint256[](2);
bytes[] memory calldatas = new bytes[](2);

targets[0] = address(token);
values[0] = 0;
calldatas[0] = abi.encodeWithSignature("setRewardRate(uint256)", 2e15);

targets[1] = address(stakingVault);
values[1] = 0;
calldatas[1] = abi.encodeWithSignature("updateVRFConfig(bytes32,uint32)", keyHash, gasLimit);

string memory description = "Proposal #3: Update rewards and VRF configuration";

uint256 proposalId = governor.propose(targets, values, calldatas, description);
```

---

## Security Considerations

### Timelock Protection

The 2-day timelock provides:
- Time to detect malicious proposals
- Opportunity to exit if you disagree
- Emergency response window
- Transparency and predictability

### Attack Vectors

**Flash Loan Attacks:**
- ❌ Not possible - voting power uses historical snapshots
- Buying tokens after proposal creation doesn't give voting power

**Governance Takeover:**
- Requires acquiring 51% of tokens
- Expensive and difficult
- Community can fork if necessary

**Proposal Spam:**
- Mitigated by 1,000 token threshold
- Costly to spam proposals

### Best Security Practices

1. **Verify Proposals**
   - Always check calldata
   - Simulate execution
   - Look for suspicious actions

2. **Monitor Governance**
   - Watch for unusual proposals
   - Participate actively
   - Report concerns

3. **Diversify Delegation**
   - Don't concentrate power
   - Delegate to trusted community members
   - Monitor delegate behavior

---

## Resources

- **OpenZeppelin Governor Docs**: https://docs.openzeppelin.com/contracts/governance
- **Tally (Governance Dashboard)**: https://tally.xyz
- **Snapshot (Off-chain Voting)**: https://snapshot.org
- **MemeForge Discord**: [Your Discord Link]
- **MemeForge Forum**: [Your Forum Link]

---

## Support

Need help with governance?

- 💬 **Discord**: Join our governance channel
- 📧 **Email**: governance@memeforge.xyz
- 📚 **Docs**: Read the technical documentation
- 🐛 **Issues**: Report bugs on GitHub

---

**Remember: With great power comes great responsibility. Vote wisely! 🗳️**
