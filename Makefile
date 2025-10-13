-include .env

.PHONY: all test clean deploy mint help install snapshot format anvil deploy-sepolia

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

help:
	@echo "Usage:"
	@echo "  make deploy              - Deploy MemeForge to local Anvil"
	@echo "  make deploy-sepolia      - Deploy MemeForge to Sepolia testnet"
	@echo "  make mint                - Mint a Soul NFT with TBA (set contract addresses)"
	@echo "  make test                - Run all tests"
	@echo "  make test-verbose        - Run tests with verbose output"
	@echo "  make anvil               - Start local Anvil node"
	@echo "  make build               - Build the project"
	@echo "  make clean               - Clean build artifacts"
	@echo "  make coverage            - Generate test coverage report"
	@echo "  make format              - Format Solidity code"

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install foundry-rs/forge-std@v1.8.1 --no-commit && forge install openzeppelin/openzeppelin-contracts@v5.0.2 --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

test-verbose :; forge test -vvv

coverage :; forge coverage --report debug > coverage-report.txt

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

# Deploy to local Anvil
deploy:
	@forge script script/DeployMemeForge.s.sol:DeployMemeForge $(NETWORK_ARGS)

# Deploy to Sepolia
deploy-sepolia:
	@forge script script/DeployMemeForge.s.sol:DeployMemeForge --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

# Mint a Soul NFT with Token-Bound Account
mint:
	@forge script script/MintMemecoin.s.sol:MintMemecoin $(NETWORK_ARGS)
