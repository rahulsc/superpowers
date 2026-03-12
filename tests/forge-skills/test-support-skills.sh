#!/usr/bin/env bash
# Test: Task 17 — Support skills evolution (systematic-debugging, using-git-worktrees,
#       composing-teams, writing-skills).
# Checks forge: prefix migration, .superpowers/ removal, skill-specific requirements.
# RED phase: fails until Task 17 is implemented.

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

ROOT="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0"

DEBUG_FILE="$ROOT/skills/systematic-debugging/SKILL.md"
WORKTREE_FILE="$ROOT/skills/using-git-worktrees/SKILL.md"
TEAMS_FILE="$ROOT/skills/composing-teams/SKILL.md"
WRITING_FILE="$ROOT/skills/writing-skills/SKILL.md"

echo "=== test-support-skills: Wave 7 Task 17 ==="
echo ""

# ===========================================================
# Helper: run common checks for a skill file
# ===========================================================
check_common() {
    local LABEL="$1"
    local FILE="$2"
    local SKILL_NAME="$3"

    echo ""
    echo "=========================================="
    echo "$LABEL: $SKILL_NAME"
    echo "=========================================="

    # ---- Existence ----
    echo ""
    echo "--- File existence ---"
    if [ -f "$FILE" ]; then
        pass "$LABEL: SKILL.md exists"
    else
        fail "$LABEL: SKILL.md not found"
        return 1
    fi

    # ---- Frontmatter ----
    echo ""
    echo "--- Frontmatter ---"
    local FM
    FM=$(awk '/^---$/{if(++c==1){found=1;next}if(c==2){exit}} found{print}' "$FILE")

    if echo "$FM" | grep -q "^name: $SKILL_NAME$"; then
        pass "$LABEL: frontmatter has name: $SKILL_NAME"
    else
        fail "$LABEL: frontmatter missing 'name: $SKILL_NAME'"
    fi

    local DESC_LINE
    DESC_LINE=$(echo "$FM" | grep "^description:")
    if [ -n "$DESC_LINE" ]; then
        local DESC_VALUE
        DESC_VALUE=$(echo "$DESC_LINE" | sed 's/^description:[[:space:]]*//' | tr -d '"')
        if echo "$DESC_VALUE" | grep -qi "^Use when"; then
            pass "$LABEL: description starts with 'Use when'"
        else
            fail "$LABEL: description must start with 'Use when'; got: '$DESC_VALUE'"
        fi
    else
        fail "$LABEL: frontmatter missing 'description' field"
    fi

    # ---- Size constraint ----
    echo ""
    echo "--- Size constraint (under 500 lines) ---"
    local LINE_COUNT
    LINE_COUNT=$(wc -l < "$FILE")
    if [ "$LINE_COUNT" -lt 500 ]; then
        pass "$LABEL: under 500 lines ($LINE_COUNT lines)"
    else
        fail "$LABEL: exceeds 500 lines ($LINE_COUNT lines) — Anthropic limit"
    fi

    # ---- No superpowers: prefix ----
    echo ""
    echo "--- No superpowers: prefix ---"
    if grep -qE "superpowers:" "$FILE"; then
        local LINES
        LINES=$(grep -cn "superpowers:" "$FILE" || true)
        fail "$LABEL: uses superpowers: prefix ($LINES occurrences, should use forge:)"
    else
        pass "$LABEL: no superpowers: prefix"
    fi

    # ---- No .superpowers/ path references ----
    echo ""
    echo "--- No .superpowers/ path references ---"
    if grep -q "\.superpowers/" "$FILE"; then
        local LINES
        LINES=$(grep -cn "\.superpowers/" "$FILE" || true)
        fail "$LABEL: references .superpowers/ ($LINES occurrences, should use .forge/)"
    else
        pass "$LABEL: no .superpowers/ references"
    fi

    # ---- Uses forge: prefix ----
    echo ""
    echo "--- Uses forge: prefix ---"
    if grep -qE "forge:" "$FILE"; then
        pass "$LABEL: uses forge: prefix"
    else
        fail "$LABEL: must use forge: prefix for skill invocations"
    fi

    return 0
}

# ===========================================================
# SKILL 1: systematic-debugging
# ===========================================================
check_common "systematic-debugging" "$DEBUG_FILE" "systematic-debugging"

if [ -f "$DEBUG_FILE" ]; then
    # ---- References forge-state or forge-memory ----
    echo ""
    echo "--- References forge-state or forge-memory ---"
    if grep -qE "forge-state|forge-memory" "$DEBUG_FILE"; then
        pass "systematic-debugging: references forge-state or forge-memory"
    else
        fail "systematic-debugging: must reference forge-state or forge-memory for state tracking"
    fi

    # ---- No duplicate Team Context section ----
    echo ""
    echo "--- No duplicate 'Team Context' section ---"
    TC_COUNT=$(grep -c "^#\+.*Team Context" "$DEBUG_FILE" || true)
    if [ "$TC_COUNT" -le 1 ]; then
        pass "systematic-debugging: no duplicate 'Team Context' section ($TC_COUNT found)"
    else
        fail "systematic-debugging: has $TC_COUNT duplicate 'Team Context' sections (should be at most 1)"
    fi
fi

# ===========================================================
# SKILL 2: using-git-worktrees
# ===========================================================
check_common "using-git-worktrees" "$WORKTREE_FILE" "using-git-worktrees"

if [ -f "$WORKTREE_FILE" ]; then
    # ---- References forge-state set worktree.main.path ----
    echo ""
    echo "--- References forge-state set worktree ---"
    if grep -qE "forge-state.*set.*worktree" "$WORKTREE_FILE"; then
        pass "using-git-worktrees: references forge-state set worktree"
    else
        fail "using-git-worktrees: must reference 'forge-state set worktree.main.path' for state tracking"
    fi
fi

# ===========================================================
# SKILL 3: composing-teams
# ===========================================================
check_common "composing-teams" "$TEAMS_FILE" "composing-teams"

if [ -f "$TEAMS_FILE" ]; then
    # ---- References forge-state set team.roster ----
    echo ""
    echo "--- References forge-state set team.roster ---"
    if grep -qE "forge-state.*set.*team\.roster" "$TEAMS_FILE"; then
        pass "composing-teams: references forge-state set team.roster"
    else
        fail "composing-teams: must reference 'forge-state set team.roster' for roster persistence"
    fi
fi

# ===========================================================
# SKILL 4: writing-skills
# ===========================================================
check_common "writing-skills" "$WRITING_FILE" "writing-skills"

if [ -f "$WRITING_FILE" ]; then
    # ---- Has pack authoring section ----
    echo ""
    echo "--- Pack authoring section ---"
    if grep -qiE "pack.*author|authoring.*pack|pack.*protocol|creating.*pack|pack.*structure" "$WRITING_FILE"; then
        pass "writing-skills: has pack authoring section"
    else
        fail "writing-skills: must have a pack authoring section (pack creation/structure/protocol)"
    fi
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
