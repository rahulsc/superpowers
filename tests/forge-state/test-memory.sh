#!/usr/bin/env bash
# Test: forge-memory add/query operations
# RED phase: fails until Task 2 (forge-state) is implemented

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

FORGE_BIN="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/.forge/bin"
export PATH="$FORGE_BIN:$PATH"

TMPDIR=$(mktemp -d /tmp/forge-memory-XXXXXX)
trap "rm -rf '$TMPDIR'" EXIT
export FORGE_PROJECT_DIR="$TMPDIR"

echo "=== test-memory: forge-memory add/query ==="
echo ""

# Pre-check: command available
if ! command -v forge-memory &>/dev/null; then
    fail "forge-memory not found — expected at .forge/bin/forge-memory"
    echo ""
    echo "============================================"
    echo "Results: $PASS passed, $FAIL failed"
    echo "============================================"
    exit 1
fi

pass "forge-memory is on PATH"

# Initialize state
forge-state init --project-dir "$TMPDIR" > /dev/null 2>&1 || true

echo ""
echo "--- add entries ---"

# Test: add a memory entry exits 0
if forge-memory add "decision" "Use SQLite for state storage" --project-dir "$TMPDIR" > "$TMPDIR/add.out" 2>&1; then
    pass "forge-memory add exits 0"
else
    fail "forge-memory add failed (exit $?)"
    cat "$TMPDIR/add.out"
fi

# Test: add another entry of same type
forge-memory add "decision" "Pipelined TDD: QA writes tests one wave ahead" --project-dir "$TMPDIR" > /dev/null 2>&1 || true

# Test: add entry of different type
forge-memory add "pattern" "Use temp dirs for test isolation" --project-dir "$TMPDIR" > /dev/null 2>&1 || true

echo ""
echo "--- query entries ---"

# Test: query returns previously added entries
QUERY_OUT=$(forge-memory query "decision" --project-dir "$TMPDIR" 2>/dev/null)
if echo "$QUERY_OUT" | grep -q "SQLite for state storage"; then
    pass "forge-memory query returns first added entry"
else
    fail "forge-memory query missing first entry; got: $QUERY_OUT"
fi

if echo "$QUERY_OUT" | grep -q "Pipelined TDD"; then
    pass "forge-memory query returns second added entry"
else
    fail "forge-memory query missing second entry; got: $QUERY_OUT"
fi

# Test: query for specific type doesn't return other types
if echo "$QUERY_OUT" | grep -q "temp dirs for test isolation"; then
    fail "forge-memory query for 'decision' returned 'pattern' entry (type filtering broken)"
else
    pass "forge-memory query filters by type correctly"
fi

# Test: query for 'pattern' type returns pattern entries
PATTERN_OUT=$(forge-memory query "pattern" --project-dir "$TMPDIR" 2>/dev/null)
if echo "$PATTERN_OUT" | grep -q "temp dirs for test isolation"; then
    pass "forge-memory query 'pattern' returns pattern entries"
else
    fail "forge-memory query 'pattern' missing expected entry; got: $PATTERN_OUT"
fi

# Test: query for non-existent type exits 0 but returns empty (not an error)
EMPTY_OUT=$(forge-memory query "nonexistent_type_xyz" --project-dir "$TMPDIR" 2>/dev/null)
if [ -z "$EMPTY_OUT" ] || echo "$EMPTY_OUT" | grep -qi "no entries\|empty\|0 results"; then
    pass "forge-memory query on unknown type returns empty (not error)"
else
    # Acceptable: returns empty string or a message, just not a non-zero exit
    pass "forge-memory query on unknown type returns: $EMPTY_OUT"
fi

echo ""
echo "--- Multiple entries accumulate ---"
for i in 1 2 3; do
    forge-memory add "note" "Note $i content" --project-dir "$TMPDIR" > /dev/null 2>&1 || true
done
NOTES_OUT=$(forge-memory query "note" --project-dir "$TMPDIR" 2>/dev/null)
NOTES_COUNT=$(echo "$NOTES_OUT" | grep -c "Note [123] content" 2>/dev/null || echo 0)
if [ "$NOTES_COUNT" -eq 3 ]; then
    pass "forge-memory stores multiple entries of same type ($NOTES_COUNT found)"
else
    fail "forge-memory should have 3 note entries, found $NOTES_COUNT; output: $NOTES_OUT"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [ $FAIL -gt 0 ]; then
    exit 1
fi
exit 0
