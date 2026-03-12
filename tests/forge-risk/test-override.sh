#!/usr/bin/env bash
# Test: classify-risk --override flag records user override via forge-state
# RED phase: fails until Task 3 (classify-risk) is implemented

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

FORGE_BIN="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/.forge/bin"
export PATH="$FORGE_BIN:$PATH"

TMPDIR=$(mktemp -d /tmp/forge-override-XXXXXX)
trap "rm -rf '$TMPDIR'" EXIT
export FORGE_PROJECT_DIR="$TMPDIR"

echo "=== test-override: classify-risk --override records state ==="
echo ""

if ! command -v classify-risk &>/dev/null; then
    fail "classify-risk not found — expected at .forge/bin/classify-risk"
    echo ""
    echo "============================================"
    echo "Results: $PASS passed, $FAIL failed"
    echo "============================================"
    exit 1
fi

# Bootstrap .forge/
mkdir -p "$TMPDIR/.forge/policies"
mkdir -p "$TMPDIR/.forge/local"
cat > "$TMPDIR/.forge/policies/default.yaml" <<'YAML'
rules:
  - match: "docs/**"
    tier: minimal
    require: [verification]
  - match: "src/**"
    tier: standard
    require: [plan, test-evidence, verification]
YAML

# Initialize forge-state if available (Task 2)
if command -v forge-state &>/dev/null; then
    forge-state init --project-dir "$TMPDIR" > /dev/null 2>&1 || true
fi

echo "--- Override: force tier=critical on a docs/ file ---"
OUT=$(classify-risk --override critical "docs/readme.md" --project-dir "$TMPDIR" 2>/dev/null)

if echo "$OUT" | grep -q "tier=critical"; then
    pass "--override critical forces tier=critical"
else
    fail "--override critical should force tier=critical; got: $OUT"
fi

if echo "$OUT" | grep -q "source=override"; then
    pass "--override sets source=override"
else
    fail "--override should set source=override; got: $OUT"
fi

echo ""
echo "--- Override: force tier=elevated ---"
OUT=$(classify-risk --override elevated "src/utils/helper.py" --project-dir "$TMPDIR" 2>/dev/null)
if echo "$OUT" | grep -q "tier=elevated"; then
    pass "--override elevated forces tier=elevated"
else
    fail "--override elevated should force tier=elevated; got: $OUT"
fi

echo ""
echo "--- Override is recorded in forge-state ---"
if command -v forge-state &>/dev/null; then
    # Run override
    classify-risk --override critical "docs/readme.md" --project-dir "$TMPDIR" > /dev/null 2>&1 || true

    # Check that the override was persisted in state
    # The key format may vary; test for any key containing 'override' with value 'critical'
    STATE_OUT=$(forge-state get "risk.override.docs/readme.md" --project-dir "$TMPDIR" 2>/dev/null || \
                forge-state get "classify-risk.override" --project-dir "$TMPDIR" 2>/dev/null || \
                echo "__NOT_FOUND__")

    if [ "$STATE_OUT" != "__NOT_FOUND__" ] && [ -n "$STATE_OUT" ]; then
        pass "override recorded in forge-state"
    else
        # Try listing all state to see if any override key was written
        ALL_KEYS=$(forge-state list --project-dir "$TMPDIR" 2>/dev/null || echo "")
        if echo "$ALL_KEYS" | grep -qi "override"; then
            pass "override recorded in forge-state (found in key list)"
        else
            fail "override not recorded in forge-state — expected a 'risk.override.*' key"
        fi
    fi
else
    echo "  SKIP: forge-state not available (Task 2 not implemented)"
fi

echo ""
echo "--- Override is idempotent: second override replaces first ---"
classify-risk --override elevated "docs/readme.md" --project-dir "$TMPDIR" > /dev/null 2>&1 || true
OUT=$(classify-risk --override critical "docs/readme.md" --project-dir "$TMPDIR" 2>/dev/null)
if echo "$OUT" | grep -q "tier=critical"; then
    pass "second override replaces first (idempotent)"
else
    fail "second override did not replace first; got: $OUT"
fi

echo ""
echo "--- Invalid override tier rejected ---"
OUT=$(classify-risk --override invalid_tier "docs/readme.md" --project-dir "$TMPDIR" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
    pass "invalid override tier exits non-zero"
else
    fail "invalid override tier should exit non-zero"
fi

if echo "$OUT" | grep -qi "invalid\|unknown\|error"; then
    pass "invalid override tier emits error message"
else
    fail "invalid override tier should emit error message; got: $OUT"
fi

echo ""
echo "--- Override on any/file.py (path not in policies) ---"
OUT=$(classify-risk --override critical "any/file.py" --project-dir "$TMPDIR" 2>/dev/null)
if echo "$OUT" | grep -q "tier=critical" && echo "$OUT" | grep -q "source=override"; then
    pass "--override critical any/file.py → tier=critical, source=override"
else
    fail "--override critical any/file.py failed; got: $OUT"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [ $FAIL -gt 0 ]; then
    exit 1
fi
exit 0
