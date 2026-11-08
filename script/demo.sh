#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
RPC="http://127.0.0.1:8545"
ANVIL_PID=""

cleanup() {
  if [ -n "$ANVIL_PID" ]; then
    kill "$ANVIL_PID" 2>/dev/null || true
    wait "$ANVIL_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

if cast block-number --rpc-url "$RPC" >/dev/null 2>&1; then
  echo "[demo] existing Anvil detected, resetting local state"
  cast rpc anvil_reset --rpc-url "$RPC" >/dev/null
else
  echo "[demo] starting a fresh Anvil on $RPC"
  anvil --host 127.0.0.1 --port 8545 --silent >/tmp/ethershield-anvil.log 2>&1 &
  ANVIL_PID=$!
  for _ in $(seq 1 30); do
    if cast block-number --rpc-url "$RPC" >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done
  cast block-number --rpc-url "$RPC" >/dev/null
fi

echo
echo "============================================================"
echo " 1. Deploy the vulnerable contracts"
echo "============================================================"
make deploy-vuln

echo
echo "============================================================"
echo " 2. Run every exploit against the running Anvil node"
echo "============================================================"
make exploit

echo
echo "============================================================"
echo " 3. Automated exploit tests (vulnerable and fixed)"
echo "============================================================"
forge test --match-path 'test/exploits/*' -vv

echo
echo "============================================================"
echo " 4. Deploy the corrected contracts"
echo "============================================================"
make deploy-fixed

echo
echo "============================================================"
echo " 5. Non-regression, fuzz and invariant tests on the fixes"
echo "============================================================"
forge test --match-path 'test/fixed/*' -vv

echo
echo "============================================================"
echo " 6. Static analysis with Slither"
echo "============================================================"
make slither

echo
echo "[demo] complete"
