#!/usr/bin/env bash
# Test: Verify no "superpowers" references remain in skills/, hooks/, agents/
# and that the three removed skill directories no longer exist.
#
# RED test: Will fail if cleanup (Task 21 Sub-goal B) has not yet run.

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

WORKTREE="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0"

echo "=== no-superpowers-references: verify cleanup of superpowers references ==="
echo ""

# ── 1. No "superpowers" string in skill/hook/agent source files ──────────────
echo "--- Section 1: No 'superpowers' references in source files ---"

MATCH_OUTPUT=$(grep -rn "superpowers" \
    "$WORKTREE/skills/" \
    "$WORKTREE/hooks/" \
    "$WORKTREE/agents/" \
    --include="*.md" \
    --include="*.json" \
    --include="*.sh" \
    --include="*.js" \
    2>/dev/null || true)

if [ -z "$MATCH_OUTPUT" ]; then
    pass "no 'superpowers' references found in skills/, hooks/, agents/"
else
    MATCH_COUNT=$(echo "$MATCH_OUTPUT" | wc -l)
    fail "found $MATCH_COUNT 'superpowers' reference(s) — must be cleaned up:"
    echo "$MATCH_OUTPUT" | head -20 | sed 's/^/    /'
    if [ "$(echo "$MATCH_OUTPUT" | wc -l)" -gt 20 ]; then
        echo "    ... (truncated, showing first 20 of $MATCH_COUNT)"
    fi
fi

echo ""

# ── 2. Removed skill directories do not exist ────────────────────────────────
echo "--- Section 2: Removed skill directories are gone ---"

REMOVED_DIRS=(
    "skills/using-superpowers"
    "skills/dispatching-parallel-agents"
    "skills/executing-plans"
)

for dir in "${REMOVED_DIRS[@]}"; do
    full_path="$WORKTREE/$dir"
    if [ -d "$full_path" ]; then
        fail "directory still exists (must be removed): $dir"
    else
        pass "directory correctly absent: $dir"
    fi
done

echo ""

# ── 3. No .superpowers/ references in source files ───────────────────────────
echo "--- Section 3: No '.superpowers/' path references in source files ---"

SP_PATH_MATCHES=$(grep -rn "\.superpowers/" \
    "$WORKTREE/skills/" \
    "$WORKTREE/hooks/" \
    "$WORKTREE/agents/" \
    --include="*.md" \
    --include="*.json" \
    --include="*.sh" \
    --include="*.js" \
    2>/dev/null || true)

if [ -z "$SP_PATH_MATCHES" ]; then
    pass "no '.superpowers/' path references found in source files"
else
    SP_COUNT=$(echo "$SP_PATH_MATCHES" | wc -l)
    fail "found $SP_COUNT '.superpowers/' reference(s) — should use .forge/ instead:"
    echo "$SP_PATH_MATCHES" | head -20 | sed 's/^/    /'
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [ $FAIL -gt 0 ]; then
    echo ""
    echo "NOTE: This is a RED test if Task 21 cleanup has not yet run."
    echo "Fix by running the cleanup task to remove/replace all references."
    exit 1
fi
exit 0
