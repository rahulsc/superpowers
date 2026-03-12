#!/usr/bin/env bash
# Test: multiple policy files, highest tier wins; invalid tier errors
# RED phase: fails until Task 3 (classify-risk) is implemented

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

FORGE_BIN="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/.forge/bin"
export PATH="$FORGE_BIN:$PATH"

TMPDIR=$(mktemp -d /tmp/forge-multipolicy-XXXXXX)
trap "rm -rf '$TMPDIR'" EXIT
export FORGE_PROJECT_DIR="$TMPDIR"

echo "=== test-multi-policy: multiple policies, highest tier wins ==="
echo ""

if ! command -v classify-risk &>/dev/null; then
    fail "classify-risk not found — expected at .forge/bin/classify-risk"
    echo ""
    echo "============================================"
    echo "Results: $PASS passed, $FAIL failed"
    echo "============================================"
    exit 1
fi

echo "--- Setup: two policy files with overlapping patterns ---"
mkdir -p "$TMPDIR/.forge/policies"
mkdir -p "$TMPDIR/.forge/local"

# base policy: low tiers
cat > "$TMPDIR/.forge/policies/default.yaml" <<'YAML'
rules:
  - match: "src/**"
    tier: standard
    require: [plan, test-evidence, verification]
  - match: "docs/**"
    tier: minimal
    require: [verification]
YAML

# security policy: escalates some patterns
cat > "$TMPDIR/.forge/policies/security.yaml" <<'YAML'
rules:
  - match: "src/auth/**"
    tier: elevated
    require: [design-doc, plan, tdd, evidence, review]
  - match: "src/payments/**"
    tier: critical
    require: [design-doc, risk-register, plan, tdd, security-review, rollback-evidence, review]
YAML

echo ""
echo "--- Highest tier wins when multiple rules match ---"

# src/auth/token.py matches both 'src/**' (standard) and 'src/auth/**' (elevated)
# → elevated wins
OUT=$(classify-risk "src/auth/token.py" --project-dir "$TMPDIR" 2>/dev/null)
if echo "$OUT" | grep -q "tier=elevated"; then
    pass "src/auth/token.py → elevated (beats standard from default policy)"
else
    fail "src/auth/token.py should be elevated, got: $OUT"
fi

# src/payments/checkout.py matches 'src/**' (standard) and 'src/payments/**' (critical)
# → critical wins
OUT=$(classify-risk "src/payments/checkout.py" --project-dir "$TMPDIR" 2>/dev/null)
if echo "$OUT" | grep -q "tier=critical"; then
    pass "src/payments/checkout.py → critical (beats standard from default policy)"
else
    fail "src/payments/checkout.py should be critical, got: $OUT"
fi

# docs/readme.md only matches default policy (minimal)
OUT=$(classify-risk "docs/readme.md" --project-dir "$TMPDIR" 2>/dev/null)
if echo "$OUT" | grep -q "tier=minimal"; then
    pass "docs/readme.md → minimal (only matched in default policy)"
else
    fail "docs/readme.md should be minimal, got: $OUT"
fi

echo ""
echo "--- Multiple files: highest tier wins across files ---"
# Passing multiple files: one critical, one minimal → critical
OUT=$(classify-risk "src/payments/checkout.py" "docs/readme.md" --project-dir "$TMPDIR" 2>/dev/null)
if echo "$OUT" | grep -q "tier=critical"; then
    pass "multiple files spanning tiers → highest tier (critical) wins"
else
    fail "multiple files should yield critical tier, got: $OUT"
fi

# Passing two minimal files → minimal
OUT=$(classify-risk "docs/readme.md" "docs/api.md" --project-dir "$TMPDIR" 2>/dev/null)
if echo "$OUT" | grep -q "tier=minimal"; then
    pass "two minimal files → minimal tier"
else
    fail "two minimal files should yield minimal tier, got: $OUT"
fi

echo ""
echo "--- matched_rules reflects all matched rules ---"
OUT=$(classify-risk "src/auth/token.py" --project-dir "$TMPDIR" 2>/dev/null)
MATCHED=$(echo "$OUT" | grep "^matched_rules=" | head -1)
if [ -n "$MATCHED" ]; then
    pass "matched_rules field is present: $MATCHED"
else
    fail "matched_rules field missing in output: $OUT"
fi

echo ""
echo "--- Invalid tier in policy file → error, non-zero exit ---"
mkdir -p "$TMPDIR/.forge/policies"
cat > "$TMPDIR/.forge/policies/bad.yaml" <<'YAML'
rules:
  - match: "bad/**"
    tier: supercritical
    require: [everything]
YAML

OUT=$(classify-risk "bad/something.py" --project-dir "$TMPDIR" 2>&1)
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
    pass "invalid tier 'supercritical' in policy → non-zero exit"
else
    fail "invalid tier 'supercritical' should cause non-zero exit"
fi

if echo "$OUT" | grep -qi "invalid\|unknown\|error\|supercritical"; then
    pass "invalid tier emits error message"
else
    fail "invalid tier should emit error message; got: $OUT"
fi

# Remove the bad policy for remaining tests
rm "$TMPDIR/.forge/policies/bad.yaml"

echo ""
echo "--- No policy files at all: inferred tier ---"
TMPDIR2=$(mktemp -d /tmp/forge-nopolicy-XXXXXX)
trap "rm -rf '$TMPDIR2'" EXIT
mkdir -p "$TMPDIR2/.forge/local"
# No policies dir at all
OUT=$(classify-risk "any/file.py" --project-dir "$TMPDIR2" 2>/dev/null)
EXIT_CODE=$?
if [ $EXIT_CODE -eq 0 ]; then
    if echo "$OUT" | grep -q "source=inferred"; then
        pass "no policies → tier inferred, exits 0"
    else
        pass "no policies → exits 0 (graceful degradation)"
    fi
else
    fail "classify-risk with no policies should exit 0 (graceful), got exit $EXIT_CODE"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [ $FAIL -gt 0 ]; then
    exit 1
fi
exit 0
