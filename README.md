# 🔥 MemeForge

> **AI-Powered Memecoin Creation Platform with Built-in Utility**

MemeForge is a revolutionary Web3 platform where users input a theme or meme idea, and AI generates a complete memecoin ecosystem—including name, logo, smart contract, and utility mechanisms. Each memecoin is linked to an NFT identity using ERC-6551 token-bound accounts, enabling unique on-chain personalities and advanced functionality.

[![Built with Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg)](https://getfoundry.sh/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

---

## 🌟 Features

- **🤖 AI-Generated Memecoins**: Input a theme, get a complete token ecosystem
- **🎨 Automated Logo Generation**: AI-powered visual branding
- **🔗 ERC-6551 Token-Bound Accounts**: Each memecoin has its own NFT "soul" that can hold assets
- **💰 Built-in Staking**: Earn rewards by staking your memecoins
- **🗳️ DAO Governance**: Community-driven decision making
- **🎁 AI-Generated Rewards**: Stake to earn unique NFT art and content
- **🌉 Cross-Chain**: Deploy on multiple chains via Chainlink CCIP
- **🚀 Modern SaaS UI**: Beautiful, intuitive interface built with Next.js

---

## 🏗️ Architecture

### Smart Contracts
```
MemeForge/
├── MemeToken.sol          # ERC-20 memecoin with utilities
├── MemeSoulNFT.sol        # ERC-721 NFT for token identity
├── TokenBoundAccount.sol  # ERC-6551 implementation
├── StakingVault.sol       # Staking mechanism
├── MemeGovernance.sol     # DAO governance
└── MemeForgeFactory.sol   # Deployment factory
```

### Tech Stack
- **Smart Contracts**: Solidity ^0.8.20, Foundry, OpenZeppelin
- **Token Standards**: ERC-20, ERC-721, ERC-6551
- **Cross-Chain**: Chainlink CCIP
- **AI**: OpenAI API, DALL·E
- **Frontend**: Next.js 14, Tailwind CSS, shadcn/ui
- **Web3**: wagmi, viem, RainbowKit

---

## 🚀 Quick Start

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Node.js](https://nodejs.org/) v18+
- [Git](https://git-scm.com/)

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/MemeForge.git
cd MemeForge

# Install Foundry dependencies
forge install

# Build contracts
forge build

# Run tests
forge test
```

---

## 🧪 Development

### Build Contracts
```bash
forge build
```

### Run Tests
```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run specific test
forge test --match-test testStaking
```

### Deploy Locally
```bash
# Start local Anvil node
anvil

# Deploy contracts (in another terminal)
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
```

### Deploy to Sepolia
```bash
forge script script/Deploy.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify
```

---

## 📚 Documentation

- [Project Plan](./PROJECT_PLAN.md) - Development roadmap and timeline
- [Architecture](./docs/ARCHITECTURE.md) - System design and contracts
- [ERC-6551 Guide](./docs/ERC6551.md) - Token-bound accounts explained
- [API Reference](./docs/API.md) - Smart contract interfaces
- [Deployment Guide](./docs/DEPLOYMENT.md) - How to deploy

---

## 🎯 Roadmap

- [x] Phase 1: Core smart contracts (ERC-20, ERC-721, ERC-6551)
- [ ] Phase 2: Staking and governance utilities
- [ ] Phase 3: AI integration backend
- [ ] Phase 4: Frontend development
- [ ] Phase 5: Cross-chain with Chainlink CCIP
- [ ] Phase 6: Mainnet deployment

See [PROJECT_PLAN.md](./PROJECT_PLAN.md) for detailed timeline.

---

## 🤝 Contributing

This is an ETHGlobal hackathon project. Contributions, issues, and feature requests are welcome!

---

## 📚 Documentation

Complete documentation is available in the [`docs/`](docs/) folder:

- **[Documentation Index](docs/INDEX.md)** - Complete documentation index
- **[Architecture](docs/ARCHITECTURE.md)** - System architecture
- **[Deployment Setup](docs/setup/DEPLOYMENT_SETUP.md)** - Deployment guide
- **[Frontend Guide](docs/frontend/FRONTEND_README.md)** - Frontend documentation
- **[MCP Setup](docs/setup/MCP_SETUP.md)** - MCP server configuration
- **[Security Review](docs/SECURITY_REVIEW.md)** - Security analysis

See [PROJECT_STATUS.md](PROJECT_STATUS.md) for current progress and [PROJECT_PLAN.md](PROJECT_PLAN.md) for the complete development roadmap.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [OpenZeppelin](https://openzeppelin.com/) - Secure smart contract libraries
- [Foundry](https://getfoundry.sh/) - Blazing fast Ethereum development toolkit
- [ERC-6551](https://eips.ethereum.org/EIPS/eip-6551) - Token-bound accounts standard
- [Chainlink](https://chain.link/) - Cross-chain infrastructure
- [OpenAI](https://openai.com/) - AI generation capabilities

---

**Built with ❤️ for ETHGlobal Hackathon**
