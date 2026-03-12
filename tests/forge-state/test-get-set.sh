#!/usr/bin/env bash
# Test: forge-state get/set roundtrip with both SQLite and JSON backends
# RED phase: fails until Task 2 (forge-state) is implemented

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

FORGE_BIN="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/.forge/bin"
export PATH="$FORGE_BIN:$PATH"

run_backend_tests() {
    local backend="$1"
    local project_dir="$2"
    export FORGE_PROJECT_DIR="$project_dir"
    export FORGE_BACKEND="$backend"

    # Initialize state
    forge-state init --project-dir "$project_dir" > /dev/null 2>&1 || true

    echo "--- Backend: $backend ---"

    # Test: set a key and get it back
    if forge-state set "test.key" "hello-world" --project-dir "$project_dir" > /dev/null 2>&1; then
        pass "[$backend] set exits 0"
    else
        fail "[$backend] set failed"
        return
    fi

    VAL=$(forge-state get "test.key" --project-dir "$project_dir" 2>/dev/null)
    if [ "$VAL" = "hello-world" ]; then
        pass "[$backend] get returns correct value after set"
    else
        fail "[$backend] get returned '$VAL', expected 'hello-world'"
    fi

    # Test: get on non-existent key exits non-zero
    if forge-state get "nonexistent.key.xyz" --project-dir "$project_dir" > /dev/null 2>&1; then
        fail "[$backend] get on non-existent key should exit non-zero, but exited 0"
    else
        pass "[$backend] get on non-existent key exits non-zero"
    fi

    # Test: overwrite existing key
    forge-state set "test.key" "updated-value" --project-dir "$project_dir" > /dev/null 2>&1 || true
    VAL=$(forge-state get "test.key" --project-dir "$project_dir" 2>/dev/null)
    if [ "$VAL" = "updated-value" ]; then
        pass "[$backend] set overwrites existing key"
    else
        fail "[$backend] overwrite failed: got '$VAL', expected 'updated-value'"
    fi

    # Test: keys with dots/colons/slashes work
    forge-state set "task.42.status" "in_progress" --project-dir "$project_dir" > /dev/null 2>&1 || true
    VAL=$(forge-state get "task.42.status" --project-dir "$project_dir" 2>/dev/null)
    if [ "$VAL" = "in_progress" ]; then
        pass "[$backend] keys with dots work"
    else
        fail "[$backend] keys with dots failed: got '$VAL'"
    fi

    # Test: values with spaces work
    forge-state set "test.message" "hello world foo" --project-dir "$project_dir" > /dev/null 2>&1 || true
    VAL=$(forge-state get "test.message" --project-dir "$project_dir" 2>/dev/null)
    if [ "$VAL" = "hello world foo" ]; then
        pass "[$backend] values with spaces work"
    else
        fail "[$backend] values with spaces failed: got '$VAL'"
    fi
}

# ---- SQLite backend ----
TMPDIR_SQLITE=$(mktemp -d /tmp/forge-state-sqlite-XXXXXX)
trap "rm -rf '$TMPDIR_SQLITE'" EXIT

echo "=== test-get-set: get/set roundtrip ==="
echo ""

if ! command -v forge-state &>/dev/null; then
    fail "forge-state not found — expected at .forge/bin/forge-state"
    echo ""
    echo "============================================"
    echo "Results: $PASS passed, $FAIL failed"
    echo "============================================"
    exit 1
fi

# SQLite backend (if sqlite3 is available)
if command -v sqlite3 &>/dev/null; then
    TMPDIR_SQLITE=$(mktemp -d /tmp/forge-sqlite-XXXXXX)
    trap "rm -rf '$TMPDIR_SQLITE'" EXIT
    run_backend_tests "sqlite" "$TMPDIR_SQLITE"
else
    echo "  SKIP: SQLite backend tests (sqlite3 not on PATH)"
fi

echo ""

# JSON backend
TMPDIR_JSON=$(mktemp -d /tmp/forge-json-XXXXXX)
trap "rm -rf '$TMPDIR_JSON'" EXIT
run_backend_tests "json" "$TMPDIR_JSON"

echo ""

# Cross-backend consistency: both produce same value for same key
if command -v sqlite3 &>/dev/null; then
    echo "--- Cross-backend consistency ---"
    TMPDIR_A=$(mktemp -d /tmp/forge-cross-a-XXXXXX)
    TMPDIR_B=$(mktemp -d /tmp/forge-cross-b-XXXXXX)
    trap "rm -rf '$TMPDIR_A' '$TMPDIR_B'" EXIT

    FORGE_BACKEND=sqlite forge-state init --project-dir "$TMPDIR_A" > /dev/null 2>&1 || true
    FORGE_BACKEND=json   forge-state init --project-dir "$TMPDIR_B" > /dev/null 2>&1 || true

    FORGE_BACKEND=sqlite forge-state set "cross.test" "same-value" --project-dir "$TMPDIR_A" > /dev/null 2>&1 || true
    FORGE_BACKEND=json   forge-state set "cross.test" "same-value" --project-dir "$TMPDIR_B" > /dev/null 2>&1 || true

    VAL_A=$(FORGE_BACKEND=sqlite forge-state get "cross.test" --project-dir "$TMPDIR_A" 2>/dev/null)
    VAL_B=$(FORGE_BACKEND=json   forge-state get "cross.test" --project-dir "$TMPDIR_B" 2>/dev/null)

    if [ "$VAL_A" = "$VAL_B" ] && [ "$VAL_A" = "same-value" ]; then
        pass "SQLite and JSON backends produce identical output"
    else
        fail "Backend outputs differ: sqlite='$VAL_A' json='$VAL_B'"
    fi
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [ $FAIL -gt 0 ]; then
    exit 1
fi
exit 0
