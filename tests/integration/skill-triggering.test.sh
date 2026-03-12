#!/usr/bin/env bash
# Test: Verify all skill SKILL.md files have descriptions starting with "Use when"
# and that descriptions are under 1024 characters.
#
# These constraints ensure skills are discoverable by Claude's routing layer.

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

SKILLS_DIR="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/skills"

echo "=== skill-triggering: verify skill descriptions for routing compatibility ==="
echo ""

# ── Check each skill ──────────────────────────────────────────────────────────
echo "--- Skill description checks (Use when prefix + <1024 chars) ---"

found_skills=0
for skill_dir in "$SKILLS_DIR"/*/; do
    skill_name=$(basename "$skill_dir")
    skill_file="$skill_dir/SKILL.md"

    if [ ! -f "$skill_file" ]; then
        fail "$skill_name: SKILL.md not found at $skill_file"
        continue
    fi

    found_skills=$((found_skills + 1))

    # Extract description field from YAML frontmatter
    # Frontmatter is bounded by --- lines; description: is within it
    DESC_LINE=$(grep "^description:" "$skill_file" | head -1)

    if [ -z "$DESC_LINE" ]; then
        fail "$skill_name: missing description field in frontmatter"
        continue
    fi

    # Strip "description: " prefix and surrounding quotes
    DESC_VALUE=$(echo "$DESC_LINE" | sed 's/^description:[[:space:]]*//' | sed "s/^['\"]//;s/['\"]$//")

    # Check "Use when" prefix (case-insensitive)
    if echo "$DESC_VALUE" | grep -qi "^Use when"; then
        pass "$skill_name: description starts with 'Use when'"
    else
        fail "$skill_name: description must start with 'Use when'; got: '${DESC_VALUE:0:60}...'"
    fi

    # Check length < 1024 characters
    DESC_LEN=${#DESC_VALUE}
    if [ "$DESC_LEN" -lt 1024 ]; then
        pass "$skill_name: description under 1024 chars ($DESC_LEN chars)"
    else
        fail "$skill_name: description exceeds 1024 chars ($DESC_LEN chars) — trim it"
    fi
done

echo ""

# ── Summary check ─────────────────────────────────────────────────────────────
echo "--- Summary ---"
if [ "$found_skills" -eq 0 ]; then
    fail "no skills found in $SKILLS_DIR — directory may be missing or empty"
else
    pass "found $found_skills skill(s) in skills/"
fi

# ── Expected minimum skill count ──────────────────────────────────────────────
# Forge currently has 21 defined skills; warn if count drops unexpectedly
EXPECTED_MIN=20
if [ "$found_skills" -ge "$EXPECTED_MIN" ]; then
    pass "skill count ($found_skills) meets minimum expected ($EXPECTED_MIN)"
else
    fail "skill count ($found_skills) is below minimum expected ($EXPECTED_MIN) — a skill may have been accidentally removed"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
