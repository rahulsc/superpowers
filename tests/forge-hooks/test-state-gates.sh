#!/usr/bin/env bash
# Test: forge-gate state gate checker — check/set/unset gates
# RED phase: fails until Task 4 (enforcement hooks) is implemented

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

FORGE_BIN="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/.forge/bin"
HOOKS_DIR="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/hooks"
export PATH="$FORGE_BIN:$HOOKS_DIR:$PATH"

echo "=== test-state-gates: forge-gate check/set/unset ==="
echo ""

GATE_CMD="$HOOKS_DIR/forge-gate"

if [ ! -f "$GATE_CMD" ]; then
    # Try forge/bin as well
    if command -v forge-gate &>/dev/null; then
        GATE_CMD=$(which forge-gate)
    else
        fail "forge-gate not found at hooks/forge-gate or .forge/bin/forge-gate"
        echo ""
        echo "============================================"
        echo "Results: $PASS passed, $FAIL failed"
        echo "============================================"
        exit 1
    fi
fi

pass "forge-gate found at: $GATE_CMD"

# Setup: temp project with forge-state initialized
TMPDIR=$(mktemp -d /tmp/forge-gates-XXXXXX)
trap "rm -rf '$TMPDIR'" EXIT
export FORGE_PROJECT_DIR="$TMPDIR"

mkdir -p "$TMPDIR/.forge/local"
if command -v forge-state &>/dev/null; then
    forge-state init --project-dir "$TMPDIR" > /dev/null 2>&1 || true
fi

echo ""
echo "--- Gate not set → exits 2 with failure message ---"
OUT=$(bash "$GATE_CMD" check "design.approved" --project-dir "$TMPDIR" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 2 ]; then
    pass "forge-gate check unset gate exits 2"
else
    fail "forge-gate check unset gate should exit 2, got $EXIT_CODE"
fi

if echo "$OUT" | grep -qi "gate\|fail\|not.*set\|missing\|design.approved"; then
    pass "forge-gate unset gate emits failure message"
else
    fail "forge-gate unset gate should emit failure message; got: $OUT"
fi

echo ""
echo "--- Set gate via forge-state, then gate passes ---"
if command -v forge-state &>/dev/null; then
    forge-state set "design.approved" "true" --project-dir "$TMPDIR" > /dev/null 2>&1

    OUT=$(bash "$GATE_CMD" check "design.approved" --project-dir "$TMPDIR" 2>&1)
    EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then
        pass "forge-gate check passes after forge-state set design.approved true"
    else
        fail "forge-gate check should pass after setting design.approved=true, got $EXIT_CODE; output: $OUT"
    fi
else
    echo "  SKIP: forge-state not available (Task 2 not implemented)"
    # Still test that forge-gate can set its own gates
fi

echo ""
echo "--- plan.approved gate ---"
OUT=$(bash "$GATE_CMD" check "plan.approved" --project-dir "$TMPDIR" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -eq 2 ]; then
    pass "forge-gate check plan.approved (unset) exits 2"
else
    fail "forge-gate check plan.approved (unset) should exit 2, got $EXIT_CODE"
fi

if command -v forge-state &>/dev/null; then
    forge-state set "plan.approved" "true" --project-dir "$TMPDIR" > /dev/null 2>&1

    OUT=$(bash "$GATE_CMD" check "plan.approved" --project-dir "$TMPDIR" 2>&1)
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 0 ]; then
        pass "forge-gate check plan.approved passes after set"
    else
        fail "forge-gate check plan.approved should pass after set, got $EXIT_CODE"
    fi
fi

echo ""
echo "--- verification.passed gate ---"
OUT=$(bash "$GATE_CMD" check "verification.passed" --project-dir "$TMPDIR" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -eq 2 ]; then
    pass "forge-gate check verification.passed (unset) exits 2"
else
    fail "forge-gate check verification.passed (unset) should exit 2, got $EXIT_CODE"
fi

if command -v forge-state &>/dev/null; then
    forge-state set "verification.passed" "true" --project-dir "$TMPDIR" > /dev/null 2>&1

    OUT=$(bash "$GATE_CMD" check "verification.passed" --project-dir "$TMPDIR" 2>&1)
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 0 ]; then
        pass "forge-gate check verification.passed passes after set"
    else
        fail "forge-gate check verification.passed should pass after set, got $EXIT_CODE"
    fi
fi

echo ""
echo "--- Gate with value 'false' does NOT pass ---"
if command -v forge-state &>/dev/null; then
    forge-state set "test.gate.false" "false" --project-dir "$TMPDIR" > /dev/null 2>&1

    OUT=$(bash "$GATE_CMD" check "test.gate.false" --project-dir "$TMPDIR" 2>&1)
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 2 ]; then
        pass "gate set to 'false' still exits 2 (not truthy)"
    else
        fail "gate set to 'false' should still exit 2, got $EXIT_CODE"
    fi
fi

echo ""
echo "--- forge-gate set: sets gate directly ---"
OUT=$(bash "$GATE_CMD" set "test.direct.gate" "true" --project-dir "$TMPDIR" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    pass "forge-gate set exits 0"
else
    fail "forge-gate set should exit 0, got $EXIT_CODE"
fi

OUT=$(bash "$GATE_CMD" check "test.direct.gate" --project-dir "$TMPDIR" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    pass "forge-gate check passes after forge-gate set"
else
    fail "forge-gate check after forge-gate set should pass, got $EXIT_CODE"
fi

echo ""
echo "--- wave.compliance gate ---"
OUT=$(bash "$GATE_CMD" check "wave.compliance" --project-dir "$TMPDIR" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -eq 2 ]; then
    pass "forge-gate check wave.compliance (unset) exits 2"
else
    fail "forge-gate check wave.compliance (unset) should exit 2, got $EXIT_CODE"
fi

if command -v forge-state &>/dev/null; then
    forge-state set "wave.compliance" "true" --project-dir "$TMPDIR" > /dev/null 2>&1

    OUT=$(bash "$GATE_CMD" check "wave.compliance" --project-dir "$TMPDIR" 2>&1)
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 0 ]; then
        pass "forge-gate check wave.compliance passes after set"
    else
        fail "forge-gate check wave.compliance should pass after set, got $EXIT_CODE"
    fi
fi

echo ""
echo "--- Missing gate name → error ---"
OUT=$(bash "$GATE_CMD" check --project-dir "$TMPDIR" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
    pass "forge-gate check without gate name exits non-zero"
else
    fail "forge-gate check without gate name should exit non-zero"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [ $FAIL -gt 0 ]; then
    exit 1
fi
exit 0
