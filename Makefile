SHELL := /bin/bash
RPC := http://127.0.0.1:8545
SCRIPT_FLAGS := --legacy --with-gas-price 2000000000 --start-fresh

.PHONY: install build anvil check-anvil deploy-vuln deploy-fixed test exploit fixed fuzz slither demo coverage clean \
	deploy-reentrancy deploy-access-control deploy-tx-origin deploy-signature-replay deploy-front-running deploy-dos deploy-advanced \
	exploit-reentrancy exploit-access-control exploit-tx-origin exploit-signature-replay exploit-front-running exploit-dos exploit-advanced

install:
	@if [ ! -d lib/forge-std ]; then forge install foundry-rs/forge-std --no-commit; fi
	@if [ ! -d lib/openzeppelin-contracts ]; then forge install OpenZeppelin/openzeppelin-contracts@v5.0.2 --no-commit; fi
	@pip3 install -q slither-analyzer solc-select
	@solc-select install 0.8.24 >/dev/null 2>&1 || true
	@solc-select use 0.8.24

build:
	forge build

anvil:
	anvil --host 127.0.0.1 --port 8545

check-anvil:
	@cast block-number --rpc-url $(RPC) >/dev/null 2>&1 || (echo "Anvil is not running. Start it with: make anvil"; exit 1)

deploy-vuln: check-anvil
	forge script script/DeployVulnerable.s.sol:DeployVulnerable --rpc-url $(RPC) --broadcast $(SCRIPT_FLAGS)

deploy-fixed: check-anvil
	forge script script/DeployFixed.s.sol:DeployFixed --rpc-url $(RPC) --broadcast $(SCRIPT_FLAGS)

test:
	forge test

exploit: check-anvil
	@for s in Reentrancy AccessControl TxOrigin SignatureReplay FrontRunning DoS Advanced; do \
		echo "=== Exploit$$s ==="; \
		forge script script/Exploit$$s.s.sol:Exploit$$s --rpc-url $(RPC) --broadcast $(SCRIPT_FLAGS) || exit 1; \
	done

fixed:
	forge test --match-path 'test/fixed/*'

fuzz:
	forge test --match-path 'test/fixed/*' --match-test 'testFuzz|invariant' -vvv

slither:
	bash script/slither.sh

demo:
	bash script/demo.sh

coverage:
	forge coverage --report summary

clean:
	forge clean
	rm -rf broadcast cache deployments/*.json

deploy-reentrancy: check-anvil
	forge script script/DeployReentrancy.s.sol:DeployReentrancy --rpc-url $(RPC) --broadcast $(SCRIPT_FLAGS)

deploy-access-control: check-anvil
	forge script script/DeployAccessControl.s.sol:DeployAccessControl --rpc-url $(RPC) --broadcast $(SCRIPT_FLAGS)

deploy-tx-origin: check-anvil
	forge script script/DeployTxOrigin.s.sol:DeployTxOrigin --rpc-url $(RPC) --broadcast $(SCRIPT_FLAGS)

deploy-signature-replay: check-anvil
	forge script script/DeploySignatureReplay.s.sol:DeploySignatureReplay --rpc-url $(RPC) --broadcast $(SCRIPT_FLAGS)

deploy-front-running: check-anvil
	forge script script/DeployFrontRunning.s.sol:DeployFrontRunning --rpc-url $(RPC) --broadcast $(SCRIPT_FLAGS)

deploy-dos: check-anvil
	forge script script/DeployDoS.s.sol:DeployDoS --rpc-url $(RPC) --broadcast $(SCRIPT_FLAGS)

deploy-advanced: check-anvil
	forge script script/DeployAdvanced.s.sol:DeployAdvanced --rpc-url $(RPC) --broadcast $(SCRIPT_FLAGS)

exploit-reentrancy: check-anvil
	forge script script/ExploitReentrancy.s.sol:ExploitReentrancy --rpc-url $(RPC) --broadcast $(SCRIPT_FLAGS)

exploit-access-control: check-anvil
	forge script script/ExploitAccessControl.s.sol:ExploitAccessControl --rpc-url $(RPC) --broadcast $(SCRIPT_FLAGS)

exploit-tx-origin: check-anvil
	forge script script/ExploitTxOrigin.s.sol:ExploitTxOrigin --rpc-url $(RPC) --broadcast $(SCRIPT_FLAGS)

exploit-signature-replay: check-anvil
	forge script script/ExploitSignatureReplay.s.sol:ExploitSignatureReplay --rpc-url $(RPC) --broadcast $(SCRIPT_FLAGS)

exploit-front-running: check-anvil
	forge script script/ExploitFrontRunning.s.sol:ExploitFrontRunning --rpc-url $(RPC) --broadcast $(SCRIPT_FLAGS)

exploit-dos: check-anvil
	forge script script/ExploitDoS.s.sol:ExploitDoS --rpc-url $(RPC) --broadcast $(SCRIPT_FLAGS)

exploit-advanced: check-anvil
	forge script script/ExploitAdvanced.s.sol:ExploitAdvanced --rpc-url $(RPC) --broadcast $(SCRIPT_FLAGS)
