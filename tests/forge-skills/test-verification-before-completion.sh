#!/usr/bin/env bash
# Test: skills/verification-before-completion/SKILL.md forge evolution.
# Checks .forge/ migration, risk-tier evidence matrix, forge-state references.
# RED phase: fails until Task 14 is implemented.

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

SKILL_FILE="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/skills/verification-before-completion/SKILL.md"

echo "=== test-verification-before-completion: forge evolution ==="
echo ""

# ---- Existence ----
echo "--- File existence ---"
if [ -f "$SKILL_FILE" ]; then
    pass "skills/verification-before-completion/SKILL.md exists"
else
    fail "skills/verification-before-completion/SKILL.md not found"
    echo ""
    echo "============================================"
    echo "Results: $PASS passed, $FAIL failed"
    echo "============================================"
    exit 1
fi

# ---- Frontmatter ----
echo ""
echo "--- Frontmatter ---"
FRONTMATTER=$(awk '/^---$/{if(++c==1){found=1;next}if(c==2){exit}} found{print}' "$SKILL_FILE")

if echo "$FRONTMATTER" | grep -q "^name: verification-before-completion$"; then
    pass "frontmatter has name: verification-before-completion"
else
    fail "frontmatter missing 'name: verification-before-completion'"
fi

DESC_LINE=$(echo "$FRONTMATTER" | grep "^description:")
if [ -n "$DESC_LINE" ]; then
    DESC_VALUE=$(echo "$DESC_LINE" | sed 's/^description:[[:space:]]*//' | tr -d '"')
    if echo "$DESC_VALUE" | grep -qi "^Use when"; then
        pass "description starts with 'Use when'"
    else
        fail "description must start with 'Use when'; got: '$DESC_VALUE'"
    fi
else
    fail "frontmatter missing 'description' field"
fi

# ---- Size constraint ----
echo ""
echo "--- Size constraint (under 500 lines) ---"
LINE_COUNT=$(wc -l < "$SKILL_FILE")
if [ "$LINE_COUNT" -lt 500 ]; then
    pass "skill file is under 500 lines ($LINE_COUNT lines)"
else
    fail "skill file exceeds 500 lines ($LINE_COUNT lines) — Anthropic limit"
fi

# ---- No .superpowers/ references ----
echo ""
echo "--- No stale .superpowers/ references ---"
if grep -q "\.superpowers/" "$SKILL_FILE"; then
    LINES=$(grep -n "\.superpowers/" "$SKILL_FILE" | head -5)
    fail "skill references .superpowers/ (should use .forge/ only): $LINES"
else
    pass "no .superpowers/ references"
fi

# ---- References .forge/ ----
echo ""
echo "--- References .forge/ for state ---"
if grep -q "\.forge/" "$SKILL_FILE"; then
    pass "skill references .forge/ (correct state path)"
else
    fail "skill does not reference .forge/ — must use .forge/ for state"
fi

# ---- References forge-state or forge-evidence ----
echo ""
echo "--- References forge-state or forge-evidence ---"
if grep -qE "forge-state|forge-evidence" "$SKILL_FILE"; then
    pass "skill references forge-state or forge-evidence"
else
    fail "skill must reference forge-state or forge-evidence for state/evidence management"
fi

# ---- Risk-tier evidence matrix ----
echo ""
echo "--- Risk-tier evidence matrix ---"
# Must have a table that maps risk tiers to required evidence types
if grep -qiE "minimal.*critical|tier.*evidence|risk.*tier" "$SKILL_FILE"; then
    pass "skill contains risk-tier evidence references"
else
    fail "skill must contain a risk-tier evidence matrix mapping tiers to required evidence"
fi

# Check that the matrix covers multiple tiers
TIER_COUNT=0
grep -qiE "\bminimal\b" "$SKILL_FILE" && TIER_COUNT=$((TIER_COUNT + 1))
grep -qiE "\bstandard\b" "$SKILL_FILE" && TIER_COUNT=$((TIER_COUNT + 1))
grep -qiE "\belevated\b" "$SKILL_FILE" && TIER_COUNT=$((TIER_COUNT + 1))
grep -qiE "\bcritical\b" "$SKILL_FILE" && TIER_COUNT=$((TIER_COUNT + 1))

if [ "$TIER_COUNT" -ge 3 ]; then
    pass "skill references at least 3 risk tiers ($TIER_COUNT found)"
else
    fail "skill must reference multiple risk tiers (minimal/standard/elevated/critical); found $TIER_COUNT"
fi

# ---- Evidence requirements vary by tier ----
echo ""
echo "--- Evidence requirements vary by tier ---"
# Minimal tier should require less evidence than critical tier
if grep -qiE "minimal.*test|minimal.*command" "$SKILL_FILE"; then
    MINIMAL_HAS_TESTS=true
else
    MINIMAL_HAS_TESTS=false
fi

if grep -qiE "critical.*(security|rollback|build)" "$SKILL_FILE"; then
    CRITICAL_HAS_MORE=true
else
    CRITICAL_HAS_MORE=false
fi

if [ "$MINIMAL_HAS_TESTS" = true ] && [ "$CRITICAL_HAS_MORE" = true ]; then
    pass "evidence requirements vary by tier (minimal: tests, critical: extended)"
elif [ "$MINIMAL_HAS_TESTS" = true ] || [ "$CRITICAL_HAS_MORE" = true ]; then
    fail "evidence requirements partially vary by tier — need both minimal (tests only) and critical (tests+build+rollback+security)"
else
    fail "evidence requirements do not vary by tier — need minimal (tests only) and critical (tests+build+rollback+security)"
fi

# ---- Uses forge: prefix ----
echo ""
echo "--- Uses forge: prefix for skill invocations ---"
# Check that skill invocations use forge: prefix, not superpowers:
if grep -qE "superpowers:" "$SKILL_FILE"; then
    LINES=$(grep -n "superpowers:" "$SKILL_FILE" | head -5)
    fail "skill uses superpowers: prefix (should use forge:): $LINES"
else
    pass "no superpowers: prefix found"
fi

if grep -qE "forge:" "$SKILL_FILE"; then
    pass "skill uses forge: prefix for skill invocations"
else
    fail "skill must use forge: prefix for skill invocations"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
