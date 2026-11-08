#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
mkdir -p audit

echo "[slither] building project"
forge build >/dev/null

echo "[slither] vulnerable contracts"
slither . \
  --filter-paths "src/fixed|src/examples|src/attackers|test|script|lib" \
  --exclude-dependencies \
  --json audit/slither-vulnerable.json \
  > audit/slither-vulnerable.txt 2>&1 || true

echo "[slither] fixed contracts"
slither . \
  --filter-paths "src/vulnerable|src/examples|src/attackers|test|script|lib" \
  --exclude-dependencies \
  --json audit/slither-fixed.json \
  > audit/slither-fixed.txt 2>&1 || true

echo "[slither] reports written to audit/slither-vulnerable.txt and audit/slither-fixed.txt"
grep -E "^(INFO:Detectors:|Detector:|Reference:)" audit/slither-vulnerable.txt | head -40 || true
