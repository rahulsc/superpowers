#!/usr/bin/env bash
# Test: skills/writing-plans/SKILL.md is updated to be risk-aware, team-aware,
#       Forge state integrated, and uses forge: prefix.
# RED phase: fails until Task 9 (writing-plans evolution) is implemented.

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

SKILL_FILE="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/skills/writing-plans/SKILL.md"

echo "=== test-writing-plans: risk-aware, team-aware, Forge state integrated ==="
echo ""

# ---- Existence ----
echo "--- File existence ---"
if [ -f "$SKILL_FILE" ]; then
    pass "skills/writing-plans/SKILL.md exists"
else
    fail "skills/writing-plans/SKILL.md not found"
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

if echo "$FRONTMATTER" | grep -q "^name: writing-plans$"; then
    pass "frontmatter has name: writing-plans"
else
    fail "frontmatter missing 'name: writing-plans'"
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
    fail "skill does not reference .forge/ — must use .forge/ not .superpowers/"
fi

# ---- Risk tier in plan structure ----
echo ""
echo "--- Risk tier referenced in plan structure ---"
if grep -qiE "risk.?tier|tier|minimal|standard|elevated|critical" "$SKILL_FILE"; then
    pass "skill references risk tier in plan structure"
else
    fail "skill missing risk tier — plans must scale detail to tier (minimal/standard/elevated/critical)"
fi

# ---- classify-risk or risk tier awareness ----
if grep -qiE "classify-risk|risk.*class|tier.*aware|risk.*aware" "$SKILL_FILE"; then
    pass "skill references classify-risk or risk-tier awareness"
else
    fail "skill should reference classify-risk or tier-aware planning"
fi

# ---- Team roster from state ----
echo ""
echo "--- Team roster from state ---"
if grep -qiE "team.*roster|roster.*team|team.*state|state.*team|composing-teams|team\.roster" "$SKILL_FILE"; then
    pass "skill references team roster from state"
else
    fail "skill missing team roster reference — team plans need roster from forge-state"
fi

# ---- forge-gate check for design.approved or plan.approved ----
echo ""
echo "--- forge-gate check for design.approved or plan.approved ---"
if grep -qE "forge-gate.*check|forge-gate.*design\.approved|forge-gate.*plan\.approved|design\.approved|plan\.approved" "$SKILL_FILE"; then
    pass "skill references forge-gate check for design.approved or plan.approved"
else
    fail "skill missing forge-gate check — must gate on design.approved before writing plan"
fi

# ---- Wave analysis section for team plans ----
echo ""
echo "--- Wave analysis section for team plans ---"
if grep -qiE "wave.*analys|analys.*wave|wave.*parallel|parallel.*wave|wave.*plan|plan.*wave|wave [0-9]" "$SKILL_FILE"; then
    pass "skill contains wave analysis section for team plans"
else
    fail "skill missing wave analysis — team plans must identify parallelizable waves"
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
