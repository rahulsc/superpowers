#!/usr/bin/env bash
# Test: forge-evidence add/list operations
# RED phase: fails until Task 2 (forge-state) is implemented

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

FORGE_BIN="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/.forge/bin"
export PATH="$FORGE_BIN:$PATH"

TMPDIR=$(mktemp -d /tmp/forge-evidence-XXXXXX)
trap "rm -rf '$TMPDIR'" EXIT
export FORGE_PROJECT_DIR="$TMPDIR"

echo "=== test-evidence: forge-evidence add/list ==="
echo ""

# Pre-check: command available
if ! command -v forge-evidence &>/dev/null; then
    fail "forge-evidence not found — expected at .forge/bin/forge-evidence"
    echo ""
    echo "============================================"
    echo "Results: $PASS passed, $FAIL failed"
    echo "============================================"
    exit 1
fi

pass "forge-evidence is on PATH"

# Initialize state
forge-state init --project-dir "$TMPDIR" > /dev/null 2>&1 || true

echo ""
echo "--- add evidence ---"

# Test: add evidence for a task exits 0
if forge-evidence add "task-1" "tests/forge-structure/validate-directory.sh" --project-dir "$TMPDIR" > "$TMPDIR/add.out" 2>&1; then
    pass "forge-evidence add exits 0"
else
    fail "forge-evidence add failed (exit $?)"
    cat "$TMPDIR/add.out"
fi

# Add more artifacts for same task
forge-evidence add "task-1" "tests/forge-structure/validate-schemas.sh" --project-dir "$TMPDIR" > /dev/null 2>&1 || true
forge-evidence add "task-1" "git:abc1234" --project-dir "$TMPDIR" > /dev/null 2>&1 || true

# Add evidence for a different task
forge-evidence add "task-2" "tests/forge-state/test-init.sh" --project-dir "$TMPDIR" > /dev/null 2>&1 || true

echo ""
echo "--- list evidence ---"

# Test: list returns artifacts for task-1
LIST_OUT=$(forge-evidence list "task-1" --project-dir "$TMPDIR" 2>/dev/null)
if echo "$LIST_OUT" | grep -q "validate-directory.sh"; then
    pass "forge-evidence list returns first artifact for task-1"
else
    fail "forge-evidence list missing first artifact; got: $LIST_OUT"
fi

if echo "$LIST_OUT" | grep -q "validate-schemas.sh"; then
    pass "forge-evidence list returns second artifact for task-1"
else
    fail "forge-evidence list missing second artifact; got: $LIST_OUT"
fi

if echo "$LIST_OUT" | grep -q "git:abc1234"; then
    pass "forge-evidence list returns git artifact for task-1"
else
    fail "forge-evidence list missing git artifact; got: $LIST_OUT"
fi

# Test: list for task-1 does not include task-2 artifacts
if echo "$LIST_OUT" | grep -q "test-init.sh"; then
    fail "forge-evidence list for task-1 returned task-2 artifacts (task isolation broken)"
else
    pass "forge-evidence list isolates evidence by task-id"
fi

# Test: list for task-2 returns its artifact
LIST2_OUT=$(forge-evidence list "task-2" --project-dir "$TMPDIR" 2>/dev/null)
if echo "$LIST2_OUT" | grep -q "test-init.sh"; then
    pass "forge-evidence list returns correct artifacts for task-2"
else
    fail "forge-evidence list missing task-2 artifacts; got: $LIST2_OUT"
fi

# Test: list for non-existent task returns empty (not error)
EMPTY_OUT=$(forge-evidence list "task-999" --project-dir "$TMPDIR" 2>&1)
EXIT_CODE=$?
# Should either exit 0 with empty output, or exit 0 with "no evidence" message
# Key requirement: must exit 0 (no evidence is not an error)
if [ $EXIT_CODE -eq 0 ]; then
    pass "forge-evidence list on unknown task exits 0 (not an error)"
else
    fail "forge-evidence list on unknown task should exit 0, got exit $EXIT_CODE"
fi

echo ""
echo "--- Evidence accumulates across adds ---"
for i in a b c; do
    forge-evidence add "task-3" "artifact-$i" --project-dir "$TMPDIR" > /dev/null 2>&1 || true
done
LIST3_OUT=$(forge-evidence list "task-3" --project-dir "$TMPDIR" 2>/dev/null)
COUNT=$(echo "$LIST3_OUT" | grep -c "artifact-[abc]" 2>/dev/null || echo 0)
if [ "$COUNT" -eq 3 ]; then
    pass "forge-evidence accumulates multiple artifacts per task ($COUNT found)"
else
    fail "forge-evidence should have 3 artifacts for task-3, found $COUNT; output: $LIST3_OUT"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [ $FAIL -gt 0 ]; then
    exit 1
fi
exit 0
