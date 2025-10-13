# MemeForge Deployment Scripts

This directory contains Foundry scripts for deploying and interacting with the MemeForge ecosystem.

## 📁 Files

### `HelperConfig.s.sol`
Network configuration helper that manages deployment settings for different networks:
- **Anvil (Local)**: Uses default private key
- **Sepolia (Testnet)**: Uses environment variable `PRIVATE_KEY`
- **Mainnet**: Uses environment variable `PRIVATE_KEY`

### `DeployMemeForge.s.sol`
Main deployment script that deploys the complete MemeForge ecosystem:
- ERC6551Registry
- TokenBoundAccount (implementation)
- MemeSoulNFT
- Example MemeToken

### `MintMemecoin.s.sol`
Script to mint a Soul NFT and create a token-bound account for a memecoin:
- Mints a Soul NFT
- Creates a TBA via the registry
- Links the TBA to the Soul NFT

---

## 🚀 Usage

### Prerequisites

1. **Set up environment variables** (create `.env` file):
```bash
PRIVATE_KEY=your_private_key_here
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/your-api-key
ETHERSCAN_API_KEY=your_etherscan_api_key
```

2. **Start local Anvil node** (for local testing):
```bash
make anvil
```

---

## 📝 Deployment Commands

### Local Deployment (Anvil)

```bash
# Deploy all contracts
make deploy

# Or use forge directly
forge script script/DeployMemeForge.s.sol:DeployMemeForge --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

### Sepolia Deployment

```bash
# Deploy to Sepolia testnet
make deploy-sepolia

# Or use forge directly
forge script script/DeployMemeForge.s.sol:DeployMemeForge --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY -vvvv
```

---

## 🎨 Minting Commands

### Mint Soul NFT with TBA

**Note:** You need to set contract addresses after deployment.

#### Option 1: Using Environment Variables

```bash
export SOUL_NFT_ADDRESS=0x...
export MEME_TOKEN_ADDRESS=0x...
export REGISTRY_ADDRESS=0x...
export IMPLEMENTATION_ADDRESS=0x...

make mint
```

#### Option 2: Update Default Addresses

Edit `script/MintMemecoin.s.sol` and update:
```solidity
address public DEFAULT_SOUL_NFT_ADDRESS = 0x...;
address public DEFAULT_MEME_TOKEN_ADDRESS = 0x...;
address public DEFAULT_REGISTRY_ADDRESS = 0x...;
address public DEFAULT_IMPLEMENTATION_ADDRESS = 0x...;
```

Then run:
```bash
make mint
```

---

## 📊 Deployment Output

After running `make deploy`, you'll see:

```
=== MemeForge Deployment Summary ===
Network Chain ID: 31337
Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
ERC6551Registry: 0x...
TokenBoundAccount Implementation: 0x...
MemeSoulNFT: 0x...
Example MemeToken: 0x...
=====================================
```

**Save these addresses!** You'll need them for minting and interactions.

---

## 🔧 Script Details

### DeployMemeForge Flow

1. Load network configuration from `HelperConfig`
2. Deploy or use existing `ERC6551Registry`
3. Deploy or use existing `TokenBoundAccount` implementation
4. Deploy `MemeSoulNFT` contract
5. Deploy example `MemeToken` (MeowFi)
6. Log all deployment addresses

### MintMemecoin Flow

1. Load contract addresses (from env or defaults)
2. Get network configuration
3. Fetch memecoin metadata (name, symbol, theme, logo)
4. Mint Soul NFT with metadata
5. Create token-bound account via registry
6. Link TBA to Soul NFT
7. Log minting summary

---

## 🧪 Testing Scripts Locally

You can test the scripts without broadcasting:

```bash
# Dry run (no broadcast)
forge script script/DeployMemeForge.s.sol:DeployMemeForge --rpc-url http://localhost:8545

# With verbose output
forge script script/DeployMemeForge.s.sol:DeployMemeForge --rpc-url http://localhost:8545 -vvvv
```

---

## 📝 Notes

- **via_ir enabled**: The project uses `via_ir = true` in `foundry.toml` to avoid stack-too-deep errors
- **Default Anvil Key**: `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`
- **Default Anvil Address**: `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266`

---

## 🔐 Security

- **Never commit `.env` files** to version control
- **Never use the default Anvil key** on mainnet or testnets with real funds
- **Always verify contracts** on Etherscan after deployment

---

## 📚 Additional Resources

- [Foundry Book - Scripts](https://book.getfoundry.sh/tutorials/solidity-scripting)
- [ERC-6551 Standard](https://eips.ethereum.org/EIPS/eip-6551)
- [MemeForge Documentation](../docs/)
