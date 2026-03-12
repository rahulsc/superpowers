#!/usr/bin/env bash
# Test: classify-risk scope + blast radius matrix → correct execution_strategy
# RED phase: fails until Task 3 (classify-risk) is implemented
#
# Blast radius x scope matrix:
# | blast\scope   | Small (1-3)         | Medium (4-8)               | Large (9+)                 |
# |---------------|---------------------|----------------------------|----------------------------|
# | Minimal blast | minimal, solo       | standard, solo             | standard, team-optional    |
# | Standard blast| standard, solo      | elevated, team-recommended | elevated, team-required    |
# | High blast    | elevated, solo      | critical, team-required    | critical, team-required    |

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

FORGE_BIN="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/.forge/bin"
export PATH="$FORGE_BIN:$PATH"

TMPDIR=$(mktemp -d /tmp/forge-scope-XXXXXX)
trap "rm -rf '$TMPDIR'" EXIT
export FORGE_PROJECT_DIR="$TMPDIR"

echo "=== test-scope-matrix: execution strategy from scope + blast radius ==="
echo ""

if ! command -v classify-risk &>/dev/null; then
    fail "classify-risk not found — expected at .forge/bin/classify-risk"
    echo ""
    echo "============================================"
    echo "Results: $PASS passed, $FAIL failed"
    echo "============================================"
    exit 1
fi

# Bootstrap minimal policy
mkdir -p "$TMPDIR/.forge/policies"
mkdir -p "$TMPDIR/.forge/local"
cat > "$TMPDIR/.forge/policies/default.yaml" <<'YAML'
rules:
  - match: "db/migrations/**"
    tier: critical
    require: [design-doc, risk-register, plan, tdd, security-review, rollback-evidence, review]
  - match: "auth/**"
    tier: elevated
    require: [design-doc, plan, tdd, evidence, review]
  - match: "src/**"
    tier: standard
    require: [plan, test-evidence, verification]
  - match: "docs/**"
    tier: minimal
    require: [verification]
YAML

# Helper: run classify-risk with scope flag and check execution_strategy
check_strategy() {
    local label="$1"
    local file="$2"
    local scope="$3"
    local expected_strategy="$4"

    OUT=$(classify-risk "$file" --scope "$scope" --project-dir "$TMPDIR" 2>/dev/null)
    if echo "$OUT" | grep -q "execution_strategy=$expected_strategy"; then
        pass "$label → execution_strategy=$expected_strategy"
    else
        ACTUAL=$(echo "$OUT" | grep "^execution_strategy=" | head -1)
        fail "$label → expected execution_strategy=$expected_strategy, got: ${ACTUAL:-<not found>}"
    fi
}

echo "--- Minimal blast radius ---"
# Small scope (1-3): minimal, solo
check_strategy "docs/readme.md --scope 2" "docs/readme.md" 2 "solo"
# Medium scope (4-8): standard, solo
check_strategy "docs/readme.md --scope 6" "docs/readme.md" 6 "solo"
# Large scope (9+): standard, team-optional
check_strategy "docs/readme.md --scope 10" "docs/readme.md" 10 "team-optional"

echo ""
echo "--- Standard blast radius ---"
# Small scope (1-3): standard, solo
check_strategy "src/utils/helper.py --scope 2" "src/utils/helper.py" 2 "solo"
# Medium scope (4-8): elevated, team-recommended
check_strategy "src/utils/helper.py --scope 6" "src/utils/helper.py" 6 "team-recommended"
# Large scope (9+): elevated, team-required
check_strategy "src/utils/helper.py --scope 12" "src/utils/helper.py" 12 "team-required"

echo ""
echo "--- High blast radius ---"
# Small scope (1-3): elevated, solo  (db/migrations/** → critical → high blast)
check_strategy "db/migrations/001.sql --scope 2" "db/migrations/001.sql" 2 "solo"
# Medium scope (4-8): critical, team-required
check_strategy "db/migrations/001.sql --scope 6" "db/migrations/001.sql" 6 "team-required"
# Large scope (9+): critical, team-required
check_strategy "db/migrations/001.sql --scope 15" "db/migrations/001.sql" 15 "team-required"

echo ""
echo "--- The specific example from spec ---"
# elevated + medium scope (4-8) → team-recommended
OUT=$(classify-risk "auth/login.py" --scope 6 --project-dir "$TMPDIR" 2>/dev/null)
if echo "$OUT" | grep -q "execution_strategy=team-recommended"; then
    pass "auth/login.py --scope 6 → team-recommended (spec example)"
else
    ACTUAL=$(echo "$OUT" | grep "^execution_strategy=" | head -1)
    fail "spec example: expected team-recommended, got: ${ACTUAL:-<not found>}"
fi

echo ""
echo "--- Default scope (no --scope flag) is valid ---"
OUT=$(classify-risk "auth/login.py" --project-dir "$TMPDIR" 2>/dev/null)
if echo "$OUT" | grep -q "^execution_strategy="; then
    pass "classify-risk without --scope still produces execution_strategy"
else
    fail "classify-risk without --scope missing execution_strategy field"
fi

echo ""
echo "--- Scope boundaries: 3 is small, 4 is medium, 9 is large ---"
check_strategy "src/utils/helper.py --scope 3" "src/utils/helper.py" 3 "solo"
check_strategy "src/utils/helper.py --scope 4" "src/utils/helper.py" 4 "team-recommended"
check_strategy "src/utils/helper.py --scope 9" "src/utils/helper.py" 9 "team-required"

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [ $FAIL -gt 0 ]; then
    exit 1
fi
exit 0
