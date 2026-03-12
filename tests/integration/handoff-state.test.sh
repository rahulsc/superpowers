#!/usr/bin/env bash
# Test: Verify state key handoffs between sequential skills.
# For each skill boundary, checks that the keys written by skill N
# appear as reads in skill N+1. This is a grep-based static analysis test.
#
# Does NOT require a running Claude instance or real project directory.

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

SKILLS_DIR="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/skills"

skill_file() {
    echo "$SKILLS_DIR/$1/SKILL.md"
}

# Helper: check that a key appears in a file (written or read)
skill_writes_key() {
    local skill="$1"
    local key="$2"
    local file
    file=$(skill_file "$skill")
    grep -qE "forge-state set $key|forge-state set \"$key\"" "$file" 2>/dev/null
}

skill_reads_key() {
    local skill="$1"
    local key="$2"
    local file
    file=$(skill_file "$skill")
    # Match: forge-state get <key>, forge-gate check <key>, or "Reads from state:" listing the key
    grep -qE "forge-state get $key|forge-state get \"$key\"|forge-gate check $key|forge-gate check \"$key\"|Reads from.*$key" "$file" 2>/dev/null
}

skill_references_key() {
    local skill="$1"
    local key="$2"
    local file
    file=$(skill_file "$skill")
    grep -q "$key" "$file" 2>/dev/null
}

echo "=== handoff-state: verify state key handoffs between sequential skills ==="
echo ""

# ── Boundary 1: brainstorming → setting-up-project ──────────────────────────
echo "--- Boundary 1: brainstorming → setting-up-project ---"

# brainstorming writes design.approved
if skill_writes_key "brainstorming" "design.approved"; then
    pass "brainstorming writes design.approved"
else
    fail "brainstorming does not write design.approved"
fi

# brainstorming writes design.path
if skill_writes_key "brainstorming" "design.path"; then
    pass "brainstorming writes design.path"
else
    fail "brainstorming does not write design.path"
fi

# setting-up-project reads design.approved
if skill_reads_key "setting-up-project" "design.approved"; then
    pass "setting-up-project reads design.approved"
else
    fail "setting-up-project does not read design.approved"
fi

# design.path flows through to writing-plans (not consumed by setting-up-project)
# Verify writing-plans reads design.path (set by brainstorming)
if skill_reads_key "writing-plans" "design.path"; then
    pass "writing-plans reads design.path (brainstorming output flows to writing-plans)"
else
    fail "writing-plans does not read design.path (brainstorming output must reach planning)"
fi

echo ""

# ── Boundary 2: using-git-worktrees → writing-plans ─────────────────────────
echo "--- Boundary 2: using-git-worktrees/setting-up-project → writing-plans ---"

# using-git-worktrees writes worktree.main.path
if skill_writes_key "using-git-worktrees" "worktree.main.path"; then
    pass "using-git-worktrees writes worktree.main.path"
else
    fail "using-git-worktrees does not write worktree.main.path"
fi

# writing-plans reads worktree.main.path
if skill_reads_key "writing-plans" "worktree.main.path"; then
    pass "writing-plans reads worktree.main.path"
else
    fail "writing-plans does not read worktree.main.path"
fi

# writing-plans also reads design.approved (prerequisite gate)
if skill_references_key "writing-plans" "design.approved"; then
    pass "writing-plans references design.approved (gate)"
else
    fail "writing-plans does not reference design.approved gate"
fi

echo ""

# ── Boundary 3: writing-plans → execution skills ─────────────────────────────
echo "--- Boundary 3: writing-plans → execution skills (subagent/team) ---"

# writing-plans writes plan.path
if skill_writes_key "writing-plans" "plan.path"; then
    pass "writing-plans writes plan.path"
else
    fail "writing-plans does not write plan.path"
fi

# writing-plans writes plan.status
if skill_writes_key "writing-plans" "plan.status"; then
    pass "writing-plans writes plan.status"
else
    fail "writing-plans does not write plan.status"
fi

# writing-plans writes plan.total_tasks
if skill_writes_key "writing-plans" "plan.total_tasks"; then
    pass "writing-plans writes plan.total_tasks"
else
    fail "writing-plans does not write plan.total_tasks"
fi

# subagent-driven-development reads plan.path
if skill_reads_key "subagent-driven-development" "plan.path"; then
    pass "subagent-driven-development reads plan.path"
else
    fail "subagent-driven-development does not read plan.path"
fi

# agent-team-driven-development reads plan.path
if skill_reads_key "agent-team-driven-development" "plan.path"; then
    pass "agent-team-driven-development reads plan.path"
else
    fail "agent-team-driven-development does not read plan.path"
fi

echo ""

# ── Boundary 4: execution skills → verification ──────────────────────────────
echo "--- Boundary 4: execution skills → verification-before-completion ---"

# subagent-driven-development writes plan.completed_tasks
if skill_writes_key "subagent-driven-development" "plan.completed_tasks"; then
    pass "subagent-driven-development writes plan.completed_tasks"
else
    fail "subagent-driven-development does not write plan.completed_tasks"
fi

# agent-team-driven-development writes plan.completed_tasks
if skill_writes_key "agent-team-driven-development" "plan.completed_tasks"; then
    pass "agent-team-driven-development writes plan.completed_tasks"
else
    fail "agent-team-driven-development does not write plan.completed_tasks"
fi

# verification-before-completion reads risk.tier (needed to scale evidence)
if skill_reads_key "verification-before-completion" "risk.tier"; then
    pass "verification-before-completion reads risk.tier"
else
    fail "verification-before-completion does not read risk.tier"
fi

# verification-before-completion writes verification.result
if skill_writes_key "verification-before-completion" "verification.result"; then
    pass "verification-before-completion writes verification.result"
else
    fail "verification-before-completion does not write verification.result"
fi

echo ""

# ── Boundary 5: verification → finishing ─────────────────────────────────────
echo "--- Boundary 5: verification-before-completion → finishing-a-development-branch ---"

# finishing-a-development-branch reads verification.result
if skill_reads_key "finishing-a-development-branch" "verification.result"; then
    pass "finishing-a-development-branch reads verification.result"
else
    fail "finishing-a-development-branch does not read verification.result"
fi

# finishing-a-development-branch references worktree cleanup (implementers.*)
if skill_references_key "finishing-a-development-branch" "worktree.implementers"; then
    pass "finishing-a-development-branch references worktree.implementers.* for cleanup"
else
    fail "finishing-a-development-branch does not reference worktree.implementers.* cleanup"
fi

# finishing-a-development-branch writes phase (complete)
if skill_writes_key "finishing-a-development-branch" "phase"; then
    pass "finishing-a-development-branch writes phase"
else
    fail "finishing-a-development-branch does not write phase"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
