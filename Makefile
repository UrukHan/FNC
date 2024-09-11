
-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil

# Anvil configuration
DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
NETWORK := anvil
GAS_PRICE := 20000000000
MAX_FEE_PER_GAS := 30000000000
MAX_PRIORITY_FEE_PER_GAS := 2500000000

# BASE COMMANDS
# ----------------------------------------------------
# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

# Install libraries
install :; forge install OpenZeppelin/openzeppelin-contracts@v5.0.2 --no-commit; \
           forge install gnosis/safe-contracts --no-commit

# Test contracts on fork
test :; FORK=true forge test --fork-url $(AMOY_RPC_URL) -vv

# Test coverage contracts on fork
coverage :; forge coverage --fork-url $(AMOY_RPC_URL)

# Pass Block     ('test test test test test test test test test test test junk' - for get private key anvil)
anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1
# ----------------------------------------------------

help:
	@echo "Usage:"
	@echo "|------- AVAILABALE NETWORKS -------"
	@echo "amoy"
	@echo "|------- COMMON METHODS -------"
	@echo "  remove\n      Remove modules"
	@echo "  install\n      Install libraries"
	@echo ""
	@echo "|------- DEPLOYS -------"
	@echo ""
	@echo "  deploy-safe-factory NETWORK={}\n\
		example: make deploy-safe-factory NETWORK=amoy
	@echo ""
	@echo "  deploy-safe NETWORK={}\n\
		example: make deploy-safe NETWORK=amoy
	@echo ""
	@echo "  deploy-safe-proxy NETWORK={} SAFE_FACTORY_ADDRESS={} SAFE_SINGLETON_ADDRESS={} JSON_ADDRESSES={} REQUIRED_CONFIRMATIONS={}\n\
		example: make deploy-safe-proxy NETWORK=amoy SAFE_FACTORY_ADDRESS=0x009E2a5a72097d0C0c4CC3562e44C9eA5737C856 SAFE_SINGLETON_ADDRESS=0x00 JSON_ADDRESSES='["0x1C3f50CA4f8b96fAa6ab1020D9C54a44ADfAc814", "0x0000000000000000000000000000000000000001"]' REQUIRED_CONFIRMATIONS=2
	@echo ""
	@echo "  deploy-token NETWORK={} TOKEN_NAME={} TOKEN_SYMBOL={} TOKEN_SUPPLY={} SAFE={}\n\
		example: make deploy-token NETWORK=amoy TOKEN_NAME=FNCToken TOKEN_SYMBOL=FNC TOKEN_SUPPLY=1000000000000000000000000000 SAFE=0x0000000000000000000000000000000000000001"
	@echo ""

# NETWORK ARGS
# ----------------------------------------------------
NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast
ifeq ($(NETWORK),amoy)
	NETWORK_ARGS := --rpc-url $(AMOY_RPC_URL) --private-key $(DEPLOYER_PRIVATE_KEY) --broadcast -- --max-fee-per-gas $(MAX_FEE_PER_GAS) --max-priority-fee-per-gas $(MAX_PRIORITY_FEE_PER_GAS)
	SAFE_FACTORY_ADDRESS := $(GNOSIS_SAFE_FACTORY_AMOY)
endif
# ----------------------------------------------------

# DEPLOYS
# ----------------------------------------------------
JSON_ADDRESSES := []              # admin addresses
REQUIRED_CONFIRMATIONS := 0       # the number of signatures required to accept a transaction
DEPLOY_ARGS := --etherscan-api-key $(POLYGON_SCAN_API_KEY) --verify -vv
# ----------------------------------------------------
deploy-safe-factory:
	@forge script script/deployments/DeploySafeFactory.s.sol:DeploySafeFactory $(call DEPLOY_ARGS) $(call NETWORK_ARGS)

deploy-safe:
	@forge script script/DeploySafe.s.sol:DeploySafe $(call DEPLOY_ARGS) $(call NETWORK_ARGS)

deploy-safe-proxy:
	@forge script script/DeploySafeProxy.s.sol:DeploySafeProxy --sig "run(address,string,uint256)" $(SAFE_FACTORY_ADDRESS) $(JSON_ADDRESSES) $(REQUIRED_CONFIRMATIONS) $(NETWORK_ARGS)

deploy-token:
	@forge script script/deployments/DeployFNCToken.s.sol:DeployFNCToken --sig "run(string,string,uint256,address)" "$(TOKEN_NAME)" "$(TOKEN_SYMBOL)" "$(TOKEN_SUPPLY)" $(SAFE) $(call NETWORK_ARGS)


# VERIFIES
ADDRESS := 0x0000000000000000000000000000000000000000
# ----------------------------------------------------
# --optimizer-runs 999999
INIT_DATA := "$(shell cast abi-encode 'constructor(string,string,uint256,address)' '$(TOKEN_NAME)' '$(TOKEN_SYMBOL)' $(TOKEN_SUPPLY) $(OWNER_ADDRESS))"
VERIFIES_ARGS := --watch
ifeq ($(NETWORK),amoy)
	TOKEN_ARGS += --constructor-args $(INIT_DATA) --etherscan-api-key $(POLYGON_SCAN_API_KEY) --compiler-version v0.8.19+commit.7dd6d404 --chain-id '$(DEFAULT_CHAIN_ID)' $(ADDRESS) src/token/Token.sol:Token
endif
verify-token:
	@forge verify-contract $(TOKEN_ARGS)
# ----------------------------------------------------



