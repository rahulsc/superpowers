#!/usr/bin/env bash
# Test: forge-task-completed hook blocks when evidence missing, allows when present
# RED phase: fails until Task 4 (enforcement hooks) is implemented

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

FORGE_BIN="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/.forge/bin"
HOOKS_DIR="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/hooks"
export PATH="$FORGE_BIN:$HOOKS_DIR:$PATH"

echo "=== test-task-completed: forge-task-completed hook ==="
echo ""

HOOK="$HOOKS_DIR/forge-task-completed"

if [ ! -f "$HOOK" ]; then
    fail "forge-task-completed hook not found at hooks/forge-task-completed"
    echo ""
    echo "============================================"
    echo "Results: $PASS passed, $FAIL failed"
    echo "============================================"
    exit 1
fi

pass "forge-task-completed hook exists"

# Setup: temp project with .forge/ initialized
TMPDIR=$(mktemp -d /tmp/forge-task-XXXXXX)
trap "rm -rf '$TMPDIR'" EXIT
export FORGE_PROJECT_DIR="$TMPDIR"

mkdir -p "$TMPDIR/.forge/policies"
mkdir -p "$TMPDIR/.forge/local"
cat > "$TMPDIR/.forge/policies/default.yaml" <<'YAML'
rules:
  - match: "auth/**"
    tier: elevated
    require: [design-doc, plan, tdd, evidence, review]
  - match: "docs/**"
    tier: minimal
    require: [verification]
YAML

if command -v forge-state &>/dev/null; then
    forge-state init --project-dir "$TMPDIR" > /dev/null 2>&1 || true
fi

echo ""
echo "--- No evidence for task → exits 2, descriptive error ---"
# Run hook with a task that has no evidence
OUT=$(FORGE_PROJECT_DIR="$TMPDIR" FORGE_TASK_ID="task-elevate-1" FORGE_TASK_FILES="auth/login.py" bash "$HOOK" 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 2 ]; then
    pass "task-completed with no evidence exits 2"
else
    fail "task-completed with no evidence should exit 2, got exit $EXIT_CODE"
fi

if echo "$OUT" | grep -qi "cannot complete\|missing.*verification\|missing.*evidence\|require"; then
    pass "task-completed error message mentions missing evidence"
else
    fail "task-completed should say 'Cannot complete: missing verification evidence'; got: $OUT"
fi

echo ""
echo "--- Minimal tier: only verification required ---"
# Add verification evidence for a docs task
DOCS_TASK="task-docs-1"
if command -v forge-evidence &>/dev/null; then
    forge-evidence add "$DOCS_TASK" "verification:docs/readme.md passed" --project-dir "$TMPDIR" > /dev/null 2>&1 || true
    OUT=$(FORGE_PROJECT_DIR="$TMPDIR" FORGE_TASK_ID="$DOCS_TASK" FORGE_TASK_FILES="docs/readme.md" bash "$HOOK" 2>&1)
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 0 ]; then
        pass "minimal tier task with verification evidence → exits 0"
    else
        fail "minimal tier task with verification evidence should exit 0, got $EXIT_CODE; output: $OUT"
    fi
else
    echo "  SKIP: forge-evidence not available (Task 2 not implemented)"
fi

echo ""
echo "--- Elevated tier: requires design-doc, plan, tdd, evidence, review ---"
ELEVATED_TASK="task-auth-1"

# Without any evidence → should fail
OUT=$(FORGE_PROJECT_DIR="$TMPDIR" FORGE_TASK_ID="$ELEVATED_TASK" FORGE_TASK_FILES="auth/login.py" bash "$HOOK" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -eq 2 ]; then
    pass "elevated tier with no evidence exits 2"
else
    fail "elevated tier with no evidence should exit 2, got $EXIT_CODE"
fi

# Add all required elevated artifacts
if command -v forge-evidence &>/dev/null; then
    for artifact in design-doc plan tdd evidence review; do
        forge-evidence add "$ELEVATED_TASK" "$artifact" --project-dir "$TMPDIR" > /dev/null 2>&1 || true
    done

    OUT=$(FORGE_PROJECT_DIR="$TMPDIR" FORGE_TASK_ID="$ELEVATED_TASK" FORGE_TASK_FILES="auth/login.py" bash "$HOOK" 2>&1)
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 0 ]; then
        pass "elevated tier task with all required evidence → exits 0"
    else
        fail "elevated tier task with all evidence should exit 0, got $EXIT_CODE; output: $OUT"
    fi

    # Partial evidence: only some artifacts → still fails
    PARTIAL_TASK="task-auth-partial"
    forge-evidence add "$PARTIAL_TASK" "design-doc" --project-dir "$TMPDIR" > /dev/null 2>&1 || true
    forge-evidence add "$PARTIAL_TASK" "plan" --project-dir "$TMPDIR" > /dev/null 2>&1 || true
    # Missing: tdd, evidence, review

    OUT=$(FORGE_PROJECT_DIR="$TMPDIR" FORGE_TASK_ID="$PARTIAL_TASK" FORGE_TASK_FILES="auth/login.py" bash "$HOOK" 2>&1)
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 2 ]; then
        pass "elevated tier with partial evidence (missing tdd, evidence, review) exits 2"
    else
        fail "partial evidence should still exit 2, got $EXIT_CODE; output: $OUT"
    fi
fi

echo ""
echo "--- Error message lists what is missing ---"
OUT=$(FORGE_PROJECT_DIR="$TMPDIR" FORGE_TASK_ID="task-never-seen" FORGE_TASK_FILES="auth/login.py" bash "$HOOK" 2>&1)
# The error should mention at least one of the required artifacts
if echo "$OUT" | grep -qiE "design-doc|plan|tdd|evidence|review|missing|required"; then
    pass "error message lists missing artifacts or requirements"
else
    fail "error message should list missing artifacts; got: $OUT"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [ $FAIL -gt 0 ]; then
    exit 1
fi
exit 0
