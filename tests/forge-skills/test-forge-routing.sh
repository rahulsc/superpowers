#!/usr/bin/env bash
# Test: skills/forge-routing/SKILL.md exists, has correct frontmatter, routing table,
#       references all 19 Forge skills, and contains no stale .superpowers/ references.
# RED phase: fails until Task 5 (forge-routing skill) is implemented

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

SKILL_FILE="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/skills/forge-routing/SKILL.md"

echo "=== test-forge-routing: skills/forge-routing/SKILL.md ==="
echo ""

# ---- Existence ----
echo "--- File existence ---"
if [ -f "$SKILL_FILE" ]; then
    pass "skills/forge-routing/SKILL.md exists"
else
    fail "skills/forge-routing/SKILL.md not found"
    echo ""
    echo "============================================"
    echo "Results: $PASS passed, $FAIL failed"
    echo "============================================"
    exit 1
fi

# ---- Frontmatter ----
echo ""
echo "--- Frontmatter ---"

# Extract frontmatter block (between first pair of ---)
FRONTMATTER=$(awk '/^---$/{if(++c==1){found=1;next}if(c==2){exit}} found{print}' "$SKILL_FILE")

if echo "$FRONTMATTER" | grep -q "^name: forge-routing$"; then
    pass "frontmatter has name: forge-routing"
else
    fail "frontmatter missing 'name: forge-routing'"
fi

DESC_LINE=$(echo "$FRONTMATTER" | grep "^description:")
if [ -n "$DESC_LINE" ]; then
    DESC_VALUE=$(echo "$DESC_LINE" | sed 's/^description: *//')
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

# ---- All 19 Forge skills referenced ----
echo ""
echo "--- References all 19 Forge skills ---"

# The complete skill inventory from design.md section 8
FORGE_SKILLS=(
    "brainstorming"
    "setting-up-project"
    "writing-plans"
    "subagent-driven-development"
    "agent-team-driven-development"
    "validating-wave-compliance"
    "verification-before-completion"
    "requesting-code-review"
    "receiving-code-review"
    "finishing-a-development-branch"
    "systematic-debugging"
    "test-driven-development"
    "forge-routing"
    "writing-skills"
    "using-git-worktrees"
    "composing-teams"
    "adopting-forge"
    "syncing-forge"
    "diagnosing-forge"
)

for skill in "${FORGE_SKILLS[@]}"; do
    if grep -q "$skill" "$SKILL_FILE"; then
        pass "references skill: $skill"
    else
        fail "missing reference to skill: $skill"
    fi
done

# ---- Routing table / routing logic ----
echo ""
echo "--- Routing table / routing logic ---"
if grep -qiE "routing|route|intent|dispatch|skill.*when|when.*skill|table" "$SKILL_FILE"; then
    pass "skill contains routing table or routing logic"
else
    fail "skill missing routing table/logic (expected table mapping intents to skills)"
fi

# ---- No stale .superpowers/ references ----
echo ""
echo "--- No stale .superpowers/ references ---"
if grep -q "\.superpowers/" "$SKILL_FILE"; then
    LINES=$(grep -n "\.superpowers/" "$SKILL_FILE" | head -5)
    fail "skill references .superpowers/ (should use .forge/ only):\n$LINES"
else
    pass "no .superpowers/ references (uses .forge/ only)"
fi

# ---- References .forge/ ----
echo ""
echo "--- References .forge/ ----"
if grep -q "\.forge/" "$SKILL_FILE"; then
    pass "skill references .forge/ (correct config path)"
else
    fail "skill does not reference .forge/ — may be using old path"
fi

# ---- Forge identity present ----
echo ""
echo "--- Forge identity ---"
if grep -qi "forge" "$SKILL_FILE"; then
    pass "skill mentions Forge identity"
else
    fail "skill missing Forge identity — should introduce Forge to the agent"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [ $FAIL -gt 0 ]; then
    exit 1
fi
exit 0
