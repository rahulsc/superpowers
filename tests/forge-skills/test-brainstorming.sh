#!/usr/bin/env bash
# Test: skills/brainstorming/SKILL.md is stripped to design-only.
# Verifies removal of worktree/team/state concerns and correct handoff to
# forge:setting-up-project.
# RED phase: fails until Task 8 (brainstorming evolution) is implemented.

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

SKILL_FILE="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/skills/brainstorming/SKILL.md"

echo "=== test-brainstorming: design-only, no worktree/team/state concerns ==="
echo ""

# ---- Existence ----
echo "--- File existence ---"
if [ -f "$SKILL_FILE" ]; then
    pass "skills/brainstorming/SKILL.md exists"
else
    fail "skills/brainstorming/SKILL.md not found"
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

if echo "$FRONTMATTER" | grep -q "^name: brainstorming$"; then
    pass "frontmatter has name: brainstorming"
else
    fail "frontmatter missing 'name: brainstorming'"
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

# ---- Design doc only ----
echo ""
echo "--- Produces design doc only (design-only scope) ---"
if grep -qiE "design doc|design document|\.forge/shared|docs/plans" "$SKILL_FILE"; then
    pass "skill references design document output"
else
    fail "skill missing design document output reference"
fi

# ---- Removed: worktree creation ----
echo ""
echo "--- Does NOT invoke worktree creation ---"
if grep -qE "EnterWorktree|git worktree add" "$SKILL_FILE"; then
    LINES=$(grep -n "EnterWorktree\|git worktree add" "$SKILL_FILE" | head -3)
    fail "skill still references worktree creation (must be removed — moved to setting-up-project): $LINES"
else
    pass "no EnterWorktree or 'git worktree add' (worktree creation removed)"
fi

# using-git-worktrees invocation (skill invocation, not just a mention)
if grep -qE "Skill.*using-git-worktrees|invoke.*using-git-worktrees|using-git-worktrees.*skill" "$SKILL_FILE"; then
    LINES=$(grep -n "using-git-worktrees" "$SKILL_FILE" | head -3)
    fail "skill invokes using-git-worktrees (must be removed — moved to setting-up-project): $LINES"
else
    pass "does not invoke using-git-worktrees skill"
fi

# ---- Removed: composing-teams invocation ----
echo ""
echo "--- Does NOT invoke composing-teams ---"
if grep -qE "Skill.*composing-teams|invoke.*composing-teams|composing-teams.*skill|forge:composing-teams" "$SKILL_FILE"; then
    LINES=$(grep -n "composing-teams" "$SKILL_FILE" | head -3)
    fail "skill invokes composing-teams (must be removed — moved to setting-up-project): $LINES"
else
    pass "does not invoke composing-teams skill"
fi

# ---- Removed: state.yml writes for worktree/phase ----
echo ""
echo "--- Does NOT write worktree or phase state ---"
if grep -qE "state\.yml|worktree\.(main|branch)|phase.*write|write.*phase" "$SKILL_FILE"; then
    LINES=$(grep -n "state\.yml\|worktree\.\(main\|branch\)\|phase.*write\|write.*phase" "$SKILL_FILE" | head -3)
    fail "skill still writes worktree/phase to state (must be removed): $LINES"
else
    pass "no state.yml writes for worktree or phase"
fi

# ---- Removed: .superpowers/ references ----
echo ""
echo "--- No stale .superpowers/ references ---"
if grep -q "\.superpowers/" "$SKILL_FILE"; then
    LINES=$(grep -n "\.superpowers/" "$SKILL_FILE" | head -5)
    fail "skill references .superpowers/ (should use .forge/ only): $LINES"
else
    pass "no .superpowers/ references"
fi

# ---- Added: handoff to forge:setting-up-project ----
echo ""
echo "--- Handoff to forge:setting-up-project after design approval ---"
if grep -qE "setting-up-project|forge:setting-up-project" "$SKILL_FILE"; then
    pass "skill references forge:setting-up-project as handoff after design approval"
else
    fail "skill missing handoff to forge:setting-up-project — brainstorming ends at design approval, setup is next"
fi

# ---- Added: .forge/ reference ----
echo ""
echo "--- References .forge/ ---"
if grep -q "\.forge/" "$SKILL_FILE"; then
    pass "skill references .forge/ (correct config path)"
else
    fail "skill does not reference .forge/ — brainstorming output should go to .forge/shared or docs/plans"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [ $FAIL -gt 0 ]; then
    exit 1
fi
exit 0
