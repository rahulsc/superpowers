#!/usr/bin/env bash
# Test: skills/agent-team-driven-development/SKILL.md is wired to .forge/,
#       risk-aware, collects evidence, uses forge:validating-wave-compliance.
# RED phase: fails until Task 12 (ATDD evolution) is implemented.

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

SKILL_FILE="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/skills/agent-team-driven-development/SKILL.md"

echo "=== test-agent-team-driven-development: .forge/-wired, risk-aware, wave-compliance ==="
echo ""

# ---- Existence ----
echo "--- File existence ---"
if [ -f "$SKILL_FILE" ]; then
    pass "skills/agent-team-driven-development/SKILL.md exists"
else
    fail "skills/agent-team-driven-development/SKILL.md not found"
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

if echo "$FRONTMATTER" | grep -q "^name: agent-team-driven-development$"; then
    pass "frontmatter has name: agent-team-driven-development"
else
    fail "frontmatter missing 'name: agent-team-driven-development'"
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

# ---- No stale .superpowers/ references ----
echo ""
echo "--- No stale .superpowers/ references ---"
if grep -q "\.superpowers/" "$SKILL_FILE"; then
    LINES=$(grep -n "\.superpowers/" "$SKILL_FILE" | head -5)
    fail "skill still references .superpowers/ (must migrate to .forge/): $LINES"
else
    pass "no .superpowers/ references"
fi

# ---- References .forge/ ----
echo ""
echo "--- References .forge/ ---"
if grep -q "\.forge/" "$SKILL_FILE"; then
    pass "skill references .forge/ (correct state path)"
else
    fail "skill does not reference .forge/ — team state must live in .forge/"
fi

# ---- forge-state or forge-evidence ----
echo ""
echo "--- References forge-state or forge-evidence ---"
if grep -qE "forge-state|forge-evidence" "$SKILL_FILE"; then
    pass "skill references forge-state or forge-evidence"
else
    fail "skill missing forge-state/forge-evidence — team evidence must be tracked in .forge/"
fi

# ---- Risk tier awareness ----
echo ""
echo "--- Risk tier awareness ---"
if grep -qiE "risk.?tier|tier|minimal|standard|elevated|critical" "$SKILL_FILE"; then
    pass "skill references risk tier"
else
    fail "skill missing risk tier — ATDD ceremony must scale to tier"
fi

# ---- forge:validating-wave-compliance ----
echo ""
echo "--- References forge:validating-wave-compliance for between-wave checks ---"
if grep -qE "forge:validating-wave-compliance|validating-wave-compliance" "$SKILL_FILE"; then
    pass "skill references validating-wave-compliance for between-wave checks"
else
    fail "skill missing validating-wave-compliance — ATDD must run compliance check between waves"
fi

# ---- forge: prefix for skill invocations ----
echo ""
echo "--- Uses forge: prefix for skill invocations ---"
if grep -qE "forge:[a-z]" "$SKILL_FILE"; then
    pass "skill uses forge: prefix for skill invocations"
else
    fail "skill missing forge: prefix — should invoke skills as forge:skill-name"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [ $FAIL -gt 0 ]; then
    exit 1
fi
exit 0
