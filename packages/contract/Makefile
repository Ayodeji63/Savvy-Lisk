-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install cyfrin/foundry-devops@0.1.0 --no-commit && forge install smartcontractkit/chainlink-brownie-contracts@0.6.1 --no-commit && forge install foundry-rs/forge-std@v1.5.3 --no-commit && forge install openzeppelin/openzeppelin-contracts@v4.8.3 --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

coverage :; forge coverage --report debug > coverage-report.txt

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

ifeq ($(findstring --network liskSepolia,$(ARGS)),--network liskSepolia)
	NETWORK_ARGS := --rpc-url $(LISK_SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY2) --broadcast --etherscan-api-key 123 --verify --verifier blockscout  --verifier-url https://sepolia-blockscout.lisk.com/api  -vvvv
endif

ifeq ($(findstring --network scrollSepolia,$(ARGS)),--network scrollSepolia)
	NETWORK_ARGS := --rpc-url $(SCROLL_SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --etherscan-api-key $(SCROLL_API_KEY) --verify   --verifier-url https://api-sepolia.scrollscan.com/api -vvvv 
endif

ifeq ($(findstring --network baseSepolia,$(ARGS)),--network baseSepolia)
	NETWORK_ARGS := --rpc-url $(BASE_SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --etherscan-api-key $(BASE_API_KEY) --verify   --chain-id 84532 -vvvv 
endif

deploy:
	@forge script script/ziniSavings/DeployZini.s.sol:DeployZini $(NETWORK_ARGS)


stablecoin:
	@forge script script/stablecoin/DeployDSC.s.sol:DeployDSC $(NETWORK_ARGS)

mintToken:
	@forge script script/Interactions.s.sol:MintToken $(NETWORK_ARGS)

approve:
	@forge script script/Interactions.s.sol:Engine $(NETWORK_ARGS)
