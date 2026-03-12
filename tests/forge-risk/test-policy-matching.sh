#!/usr/bin/env bash
# Test: classify-risk maps file paths to correct tiers via policy matching
# RED phase: fails until Task 3 (classify-risk) is implemented

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

FORGE_BIN="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/.forge/bin"
export PATH="$FORGE_BIN:$PATH"

# Set up an isolated temp project with a .forge/policies/default.yaml
TMPDIR=$(mktemp -d /tmp/forge-risk-policy-XXXXXX)
trap "rm -rf '$TMPDIR'" EXIT
export FORGE_PROJECT_DIR="$TMPDIR"

echo "=== test-policy-matching: classify-risk file-to-tier mapping ==="
echo ""

# Pre-check: command available
if ! command -v classify-risk &>/dev/null; then
    fail "classify-risk not found — expected at .forge/bin/classify-risk"
    echo ""
    echo "============================================"
    echo "Results: $PASS passed, $FAIL failed"
    echo "============================================"
    exit 1
fi

pass "classify-risk is on PATH"

# Bootstrap the .forge/ layout needed for policy matching
mkdir -p "$TMPDIR/.forge/policies"
mkdir -p "$TMPDIR/.forge/local"

cat > "$TMPDIR/.forge/policies/default.yaml" <<'YAML'
rules:
  - match: "db/migrations/**"
    tier: critical
    require:
      - design-doc
      - risk-register
      - plan
      - tdd
      - security-review
      - rollback-evidence
      - review
  - match: "auth/**"
    tier: elevated
    require:
      - design-doc
      - plan
      - tdd
      - evidence
      - review
  - match: "src/**"
    tier: standard
    require:
      - plan
      - test-evidence
      - verification
  - match: "docs/**"
    tier: minimal
    require:
      - verification
YAML

echo "--- Tier: critical (db/migrations/**) ---"
OUT=$(classify-risk "db/migrations/001.sql" --project-dir "$TMPDIR" 2>/dev/null)
if echo "$OUT" | grep -q "tier=critical"; then
    pass "db/migrations/001.sql → tier=critical"
else
    fail "db/migrations/001.sql should be tier=critical; got: $OUT"
fi

echo ""
echo "--- Tier: elevated (auth/**) ---"
OUT=$(classify-risk "auth/login.py" --project-dir "$TMPDIR" 2>/dev/null)
if echo "$OUT" | grep -q "tier=elevated"; then
    pass "auth/login.py → tier=elevated"
else
    fail "auth/login.py should be tier=elevated; got: $OUT"
fi

echo ""
echo "--- Tier: minimal (docs/**) ---"
OUT=$(classify-risk "docs/readme.md" --project-dir "$TMPDIR" 2>/dev/null)
if echo "$OUT" | grep -q "tier=minimal"; then
    pass "docs/readme.md → tier=minimal"
else
    fail "docs/readme.md should be tier=minimal; got: $OUT"
fi

echo ""
echo "--- Tier: inferred (no match) ---"
OUT=$(classify-risk "some/unmatched/path.txt" --project-dir "$TMPDIR" 2>/dev/null)
if echo "$OUT" | grep -q "source=inferred"; then
    pass "unmatched path → source=inferred"
else
    fail "unmatched path should have source=inferred; got: $OUT"
fi

echo ""
echo "--- Output format: key=value pairs ---"
OUT=$(classify-risk "auth/login.py" --project-dir "$TMPDIR" 2>/dev/null)
for field in tier source execution_strategy required_artifacts matched_rules; do
    if echo "$OUT" | grep -q "^${field}="; then
        pass "output contains field: $field"
    else
        fail "output missing field: $field (got: $OUT)"
    fi
done

echo ""
echo "--- required_artifacts for critical tier ---"
OUT=$(classify-risk "db/migrations/001.sql" --project-dir "$TMPDIR" 2>/dev/null)
for artifact in design-doc risk-register plan tdd security-review rollback-evidence review; do
    if echo "$OUT" | grep -q "$artifact"; then
        pass "critical tier required_artifacts includes: $artifact"
    else
        fail "critical tier required_artifacts missing: $artifact (got: $OUT)"
    fi
done

echo ""
echo "--- required_artifacts for minimal tier ---"
OUT=$(classify-risk "docs/readme.md" --project-dir "$TMPDIR" 2>/dev/null)
if echo "$OUT" | grep -q "required_artifacts=.*verification"; then
    pass "minimal tier required_artifacts contains: verification"
else
    fail "minimal tier required_artifacts should be 'verification'; got: $OUT"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [ $FAIL -gt 0 ]; then
    exit 1
fi
exit 0
