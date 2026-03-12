#!/usr/bin/env bash
# Test: forge-state init creates correct directory structure
# RED phase: fails until Task 2 (forge-state) is implemented

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

# Setup: temp project dir with .forge/bin on PATH
TMPDIR_BASE=$(mktemp -d /tmp/forge-state-init-XXXXXX)
trap "rm -rf '$TMPDIR_BASE'" EXIT

PROJECT_DIR="$TMPDIR_BASE/project"
mkdir -p "$PROJECT_DIR"

# Point to actual forge-state binary location (in the worktree)
FORGE_BIN="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/.forge/bin"
export PATH="$FORGE_BIN:$PATH"
export FORGE_PROJECT_DIR="$PROJECT_DIR"

echo "=== test-init: forge-state init ==="
echo "Temp project dir: $PROJECT_DIR"
echo ""

# Test 1: forge-state command is available
echo "--- Command availability ---"
if command -v forge-state &>/dev/null; then
    pass "forge-state is on PATH"
else
    fail "forge-state not found — expected at .forge/bin/forge-state"
    echo ""
    echo "============================================"
    echo "Results: $PASS passed, $FAIL failed"
    echo "============================================"
    exit 1
fi

# Test 2: forge-state init exits 0
echo ""
echo "--- forge-state init ---"
if forge-state init --project-dir "$PROJECT_DIR" > "$TMPDIR_BASE/init.out" 2>&1; then
    pass "forge-state init exits 0"
else
    EXIT_CODE=$?
    fail "forge-state init failed (exit $EXIT_CODE)"
    cat "$TMPDIR_BASE/init.out"
fi

# Test 3: .forge/local/ directory is created
if [ -d "$PROJECT_DIR/.forge/local" ]; then
    pass ".forge/local/ directory created by init"
else
    fail ".forge/local/ directory not created by init"
fi

# Test 4: .forge/local/.gitignore is created
if [ -f "$PROJECT_DIR/.forge/local/.gitignore" ]; then
    pass ".forge/local/.gitignore created by init"
else
    fail ".forge/local/.gitignore not created by init"
fi

# Test 5: running init twice is idempotent (exits 0, no error)
echo ""
echo "--- Idempotency ---"
if forge-state init --project-dir "$PROJECT_DIR" > "$TMPDIR_BASE/init2.out" 2>&1; then
    pass "forge-state init is idempotent (second run exits 0)"
else
    fail "forge-state init failed on second run"
    cat "$TMPDIR_BASE/init2.out"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [ $FAIL -gt 0 ]; then
    exit 1
fi
exit 0
