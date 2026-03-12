#!/usr/bin/env bash
# Test: Task 20 — Pack protocol and hello-world pack.
# Checks forge-pack script, hello-world pack files, forge-packs skill,
# and install/remove/list cycle behavior.
# RED phase: fails until Task 20 is implemented.

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

ROOT="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0"

SKILL_FILE="$ROOT/skills/forge-packs/SKILL.md"
FORGE_PACK_SCRIPT="$ROOT/.forge/bin/forge-pack"
HELLO_WORLD_DIR="$ROOT/forge-pack-hello-world"
HW_MANIFEST="$HELLO_WORLD_DIR/pack.yaml"
HW_POLICY="$HELLO_WORLD_DIR/policies/greeting-policy.yaml"
HW_SKILL="$HELLO_WORLD_DIR/skills/greeting-workflow/SKILL.md"
HW_SHARED="$HELLO_WORLD_DIR/shared/greeting-conventions.md"
HW_README="$HELLO_WORLD_DIR/README.md"

echo "=== test-forge-packs: Wave 8 Task 20 ==="
echo ""

# ===========================================================
# PART 1: forge-packs/SKILL.md
# ===========================================================
echo "=========================================="
echo "PART 1: skills/forge-packs/SKILL.md"
echo "=========================================="

echo ""
echo "--- File existence ---"
if [ -f "$SKILL_FILE" ]; then
    pass "forge-packs/SKILL.md exists"
else
    fail "forge-packs/SKILL.md not found"
fi

if [ -f "$SKILL_FILE" ]; then
    # ---- Frontmatter ----
    echo ""
    echo "--- Frontmatter ---"
    SKILL_FM=$(awk '/^---$/{if(++c==1){found=1;next}if(c==2){exit}} found{print}' "$SKILL_FILE")

    if echo "$SKILL_FM" | grep -q "^name: forge-packs$"; then
        pass "forge-packs: frontmatter has name: forge-packs"
    else
        fail "forge-packs: frontmatter missing 'name: forge-packs'"
    fi

    SKILL_DESC_LINE=$(echo "$SKILL_FM" | grep "^description:")
    if [ -n "$SKILL_DESC_LINE" ]; then
        SKILL_DESC_VALUE=$(echo "$SKILL_DESC_LINE" | sed 's/^description:[[:space:]]*//' | tr -d '"')
        if echo "$SKILL_DESC_VALUE" | grep -qi "^Use when"; then
            pass "forge-packs: description starts with 'Use when'"
        else
            fail "forge-packs: description must start with 'Use when'; got: '$SKILL_DESC_VALUE'"
        fi
    else
        fail "forge-packs: frontmatter missing 'description' field"
    fi

    # ---- Size constraint ----
    echo ""
    echo "--- Size constraint (under 500 lines) ---"
    SKILL_LINE_COUNT=$(wc -l < "$SKILL_FILE")
    if [ "$SKILL_LINE_COUNT" -lt 500 ]; then
        pass "forge-packs: SKILL.md under 500 lines ($SKILL_LINE_COUNT lines)"
    else
        fail "forge-packs: SKILL.md exceeds 500 lines ($SKILL_LINE_COUNT lines) — Anthropic limit"
    fi

    # ---- No superpowers: prefix ----
    echo ""
    echo "--- No superpowers: prefix ---"
    if grep -qE "superpowers:" "$SKILL_FILE"; then
        fail "forge-packs: uses superpowers: prefix (should use forge:)"
    else
        pass "forge-packs: no superpowers: prefix"
    fi

    # ---- No .superpowers/ path references ----
    echo ""
    echo "--- No .superpowers/ path references ---"
    if grep -q "\.superpowers/" "$SKILL_FILE"; then
        fail "forge-packs: references .superpowers/ (should use .forge/)"
    else
        pass "forge-packs: no .superpowers/ references"
    fi

    # ---- Documents pack install/update/list commands ----
    echo ""
    echo "--- Pack command documentation ---"
    if grep -qiE "forge-pack install|pack install" "$SKILL_FILE"; then
        pass "forge-packs: documents pack install command"
    else
        fail "forge-packs: must document 'forge-pack install' command"
    fi

    if grep -qiE "forge-pack list|pack list" "$SKILL_FILE"; then
        pass "forge-packs: documents pack list command"
    else
        fail "forge-packs: must document 'forge-pack list' command"
    fi

    if grep -qiE "forge-pack remove|pack remove|forge-pack update|pack update" "$SKILL_FILE"; then
        pass "forge-packs: documents pack remove or update command"
    else
        fail "forge-packs: must document 'forge-pack remove' or 'forge-pack update' command"
    fi

    # ---- Documents pack.yaml manifest schema ----
    echo ""
    echo "--- Pack manifest schema documentation ---"
    if grep -qiE "pack\.yaml" "$SKILL_FILE"; then
        pass "forge-packs: references pack.yaml manifest"
    else
        fail "forge-packs: must document pack.yaml manifest schema"
    fi

    if grep -qiE "forge_compatibility|forge_compat" "$SKILL_FILE"; then
        pass "forge-packs: documents forge_compatibility field"
    else
        fail "forge-packs: must document required 'forge_compatibility' field in pack.yaml"
    fi

    # ---- Documents pack skill namespace ----
    echo ""
    echo "--- Pack skill namespace (forge:<pack>:<skill>) ---"
    if grep -qE "forge:[a-zA-Z]|forge:<" "$SKILL_FILE"; then
        pass "forge-packs: documents forge:<pack-name>:<skill-name> namespace convention"
    else
        fail "forge-packs: must document 'forge:<pack-name>:<skill-name>' skill namespace"
    fi

    # ---- Documents install target path ---
    echo ""
    echo "--- Install path (.forge/packs/<name>/) ---"
    if grep -qE "\.forge/packs/" "$SKILL_FILE"; then
        pass "forge-packs: documents .forge/packs/<name>/ install path"
    else
        fail "forge-packs: must document .forge/packs/<name>/ as install target"
    fi

    # ---- Documents policy merge with source annotation ----
    echo ""
    echo "--- Policy merge with source annotation ---"
    if grep -qiE "source:.*pack|policy.*merge|merge.*policy" "$SKILL_FILE"; then
        pass "forge-packs: documents policy merge with source annotation"
    else
        fail "forge-packs: must document policy merge and source: pack/<name> annotation"
    fi
fi

# ===========================================================
# PART 2: .forge/bin/forge-pack script
# ===========================================================
echo ""
echo "=========================================="
echo "PART 2: .forge/bin/forge-pack script"
echo "=========================================="

echo ""
echo "--- File existence ---"
if [ -f "$FORGE_PACK_SCRIPT" ]; then
    pass ".forge/bin/forge-pack script exists"
else
    fail ".forge/bin/forge-pack script not found"
fi

if [ -f "$FORGE_PACK_SCRIPT" ]; then
    # ---- Is executable ----
    echo ""
    echo "--- Is executable ---"
    if [ -x "$FORGE_PACK_SCRIPT" ]; then
        pass ".forge/bin/forge-pack is executable"
    else
        fail ".forge/bin/forge-pack must be executable (chmod +x)"
    fi

    # ---- Is shell script (not Node.js) ----
    echo ""
    echo "--- Is bash shell script (no Node.js dependency) ---"
    SHEBANG=$(head -1 "$FORGE_PACK_SCRIPT")
    if echo "$SHEBANG" | grep -qE "^#!/.*bash|^#!/.*sh"; then
        pass ".forge/bin/forge-pack is a bash/sh script"
    else
        fail ".forge/bin/forge-pack must be a bash shell script, shebang got: '$SHEBANG'"
    fi

    if grep -qiE "node |nodejs|require\(|import " "$FORGE_PACK_SCRIPT"; then
        fail ".forge/bin/forge-pack must not use Node.js (bash only)"
    else
        pass ".forge/bin/forge-pack has no Node.js dependency"
    fi

    # ---- Has install subcommand ----
    echo ""
    echo "--- Has install subcommand ---"
    if grep -qiE "install\b" "$FORGE_PACK_SCRIPT"; then
        pass ".forge/bin/forge-pack handles 'install' subcommand"
    else
        fail ".forge/bin/forge-pack must handle 'install' subcommand"
    fi

    # ---- Has remove subcommand ----
    echo ""
    echo "--- Has remove subcommand ---"
    if grep -qiE "remove\b" "$FORGE_PACK_SCRIPT"; then
        pass ".forge/bin/forge-pack handles 'remove' subcommand"
    else
        fail ".forge/bin/forge-pack must handle 'remove' subcommand"
    fi

    # ---- Has list subcommand ----
    echo ""
    echo "--- Has list subcommand ---"
    if grep -qiE "\blist\b" "$FORGE_PACK_SCRIPT"; then
        pass ".forge/bin/forge-pack handles 'list' subcommand"
    else
        fail ".forge/bin/forge-pack must handle 'list' subcommand"
    fi

    # ---- Validates .forge/project.yaml before any operation ----
    echo ""
    echo "--- Validates .forge/project.yaml exists before operating ---"
    if grep -qE "project\.yaml|\.forge.*project" "$FORGE_PACK_SCRIPT"; then
        pass ".forge/bin/forge-pack checks .forge/project.yaml exists"
    else
        fail ".forge/bin/forge-pack must validate .forge/project.yaml exists before any operation"
    fi

    # ---- Validates pack.yaml schema on install ----
    echo ""
    echo "--- Validates pack.yaml on install ---"
    if grep -qE "pack\.yaml" "$FORGE_PACK_SCRIPT"; then
        pass ".forge/bin/forge-pack validates pack.yaml on install"
    else
        fail ".forge/bin/forge-pack must validate pack.yaml exists and is valid"
    fi

    # ---- Rejects invalid pack.yaml with clear error ----
    echo ""
    echo "--- Rejects missing/invalid pack.yaml with error ---"
    if grep -qiE "Error:|error|invalid|missing|not found" "$FORGE_PACK_SCRIPT"; then
        pass ".forge/bin/forge-pack emits clear error messages"
    else
        fail ".forge/bin/forge-pack must emit clear error messages when pack.yaml is invalid/missing"
    fi

    # ---- Source annotation on policy merge ----
    echo ""
    echo "--- Annotates merged policy rules with source: pack/<name> ---"
    if grep -qiE "source:.*pack|source: pack" "$FORGE_PACK_SCRIPT"; then
        pass ".forge/bin/forge-pack adds 'source: pack/<name>' annotation to merged policy rules"
    else
        fail ".forge/bin/forge-pack must annotate merged policy rules with 'source: pack/<name>'"
    fi

    # ---- Install is idempotent (remove-then-reinstall) ----
    echo ""
    echo "--- Install is idempotent (update in place) ---"
    if grep -qiE "already.*install|install.*already|idempotent|remove.*install|reinstall|update.*place" "$FORGE_PACK_SCRIPT"; then
        pass ".forge/bin/forge-pack handles re-install idempotently"
    else
        fail ".forge/bin/forge-pack must handle re-install idempotently (remove then install)"
    fi
fi

# ===========================================================
# PART 3: Hello-world pack files
# ===========================================================
echo ""
echo "=========================================="
echo "PART 3: forge-pack-hello-world/ files"
echo "=========================================="

# ---- Directory existence ----
echo ""
echo "--- Directory existence ---"
if [ -d "$HELLO_WORLD_DIR" ]; then
    pass "forge-pack-hello-world/ directory exists"
else
    fail "forge-pack-hello-world/ directory not found"
fi

# ---- pack.yaml manifest ----
echo ""
echo "--- pack.yaml manifest ---"
if [ -f "$HW_MANIFEST" ]; then
    pass "forge-pack-hello-world/pack.yaml exists"

    # Required fields
    echo ""
    echo "--- pack.yaml required fields ---"
    if grep -q "^name:" "$HW_MANIFEST"; then
        NAME_VAL=$(grep "^name:" "$HW_MANIFEST" | sed 's/^name:[[:space:]]*//')
        if [ "$NAME_VAL" = "hello-world" ]; then
            pass "pack.yaml: name is 'hello-world'"
        else
            fail "pack.yaml: name must be 'hello-world', got: '$NAME_VAL'"
        fi
    else
        fail "pack.yaml: missing required field 'name'"
    fi

    if grep -q "^version:" "$HW_MANIFEST"; then
        pass "pack.yaml: has required field 'version'"
    else
        fail "pack.yaml: missing required field 'version'"
    fi

    if grep -q "^description:" "$HW_MANIFEST"; then
        pass "pack.yaml: has required field 'description'"
    else
        fail "pack.yaml: missing required field 'description'"
    fi

    if grep -q "^forge_compatibility:" "$HW_MANIFEST"; then
        pass "pack.yaml: has required field 'forge_compatibility'"
    else
        fail "pack.yaml: missing required field 'forge_compatibility'"
    fi

    # Optional but expected fields
    echo ""
    echo "--- pack.yaml provides section ---"
    if grep -q "provides:" "$HW_MANIFEST"; then
        pass "pack.yaml: has 'provides' section"
    else
        fail "pack.yaml: missing 'provides' section (should list skills, policies, agents)"
    fi

    if grep -qE "skills:" "$HW_MANIFEST"; then
        pass "pack.yaml: provides.skills listed"
    else
        fail "pack.yaml: provides.skills must list provided skills"
    fi

    if grep -qE "policies:" "$HW_MANIFEST"; then
        pass "pack.yaml: provides.policies listed"
    else
        fail "pack.yaml: provides.policies must list provided policies"
    fi
else
    fail "forge-pack-hello-world/pack.yaml not found"
fi

# ---- policies/greeting-policy.yaml ----
echo ""
echo "--- policies/greeting-policy.yaml ---"
if [ -f "$HW_POLICY" ]; then
    pass "forge-pack-hello-world/policies/greeting-policy.yaml exists"

    echo ""
    echo "--- Policy has rules section ---"
    if grep -q "rules:" "$HW_POLICY"; then
        pass "greeting-policy.yaml: has 'rules' section"
    else
        fail "greeting-policy.yaml: must have a 'rules' section"
    fi

    echo ""
    echo "--- Policy has match and tier fields ---"
    if grep -q "match:" "$HW_POLICY"; then
        pass "greeting-policy.yaml: has 'match' field in rules"
    else
        fail "greeting-policy.yaml: rule must have 'match' field"
    fi

    if grep -q "tier:" "$HW_POLICY"; then
        pass "greeting-policy.yaml: has 'tier' field in rules"
    else
        fail "greeting-policy.yaml: rule must have 'tier' field"
    fi

    echo ""
    echo "--- Policy tier is minimal ---"
    if grep -q "tier: minimal" "$HW_POLICY"; then
        pass "greeting-policy.yaml: tier is 'minimal' as expected for demo pack"
    else
        fail "greeting-policy.yaml: tier must be 'minimal' for the sample greeting rule"
    fi
else
    fail "forge-pack-hello-world/policies/greeting-policy.yaml not found"
fi

# ---- skills/greeting-workflow/SKILL.md ----
echo ""
echo "--- skills/greeting-workflow/SKILL.md ---"
if [ -f "$HW_SKILL" ]; then
    pass "forge-pack-hello-world/skills/greeting-workflow/SKILL.md exists"

    echo ""
    echo "--- Skill frontmatter ---"
    HW_FM=$(awk '/^---$/{if(++c==1){found=1;next}if(c==2){exit}} found{print}' "$HW_SKILL")

    if echo "$HW_FM" | grep -q "^name: greeting-workflow$"; then
        pass "greeting-workflow SKILL.md: frontmatter has name: greeting-workflow"
    else
        fail "greeting-workflow SKILL.md: frontmatter missing 'name: greeting-workflow'"
    fi

    HW_DESC_LINE=$(echo "$HW_FM" | grep "^description:")
    if [ -n "$HW_DESC_LINE" ]; then
        HW_DESC_VALUE=$(echo "$HW_DESC_LINE" | sed 's/^description:[[:space:]]*//' | tr -d '"')
        if echo "$HW_DESC_VALUE" | grep -qi "^Use when"; then
            pass "greeting-workflow SKILL.md: description starts with 'Use when'"
        else
            fail "greeting-workflow SKILL.md: description must start with 'Use when'; got: '$HW_DESC_VALUE'"
        fi
    else
        fail "greeting-workflow SKILL.md: frontmatter missing 'description' field"
    fi

    echo ""
    echo "--- Skill size constraint ---"
    HW_SKILL_LINES=$(wc -l < "$HW_SKILL")
    if [ "$HW_SKILL_LINES" -lt 500 ]; then
        pass "greeting-workflow SKILL.md: under 500 lines ($HW_SKILL_LINES lines)"
    else
        fail "greeting-workflow SKILL.md: exceeds 500 lines ($HW_SKILL_LINES lines)"
    fi

    echo ""
    echo "--- No superpowers: prefix in skill ---"
    if grep -qE "superpowers:" "$HW_SKILL"; then
        fail "greeting-workflow SKILL.md: uses superpowers: prefix (should use forge:)"
    else
        pass "greeting-workflow SKILL.md: no superpowers: prefix"
    fi

    echo ""
    echo "--- No .superpowers/ references in skill ---"
    if grep -q "\.superpowers/" "$HW_SKILL"; then
        fail "greeting-workflow SKILL.md: references .superpowers/ (should use .forge/)"
    else
        pass "greeting-workflow SKILL.md: no .superpowers/ references"
    fi
else
    fail "forge-pack-hello-world/skills/greeting-workflow/SKILL.md not found"
fi

# ---- shared/greeting-conventions.md ----
echo ""
echo "--- shared/greeting-conventions.md ---"
if [ -f "$HW_SHARED" ]; then
    pass "forge-pack-hello-world/shared/greeting-conventions.md exists"

    echo ""
    echo "--- Shared knowledge is non-empty ---"
    SHARED_LINES=$(wc -l < "$HW_SHARED")
    if [ "$SHARED_LINES" -gt 3 ]; then
        pass "greeting-conventions.md: non-trivial content ($SHARED_LINES lines)"
    else
        fail "greeting-conventions.md: too short ($SHARED_LINES lines) — must have meaningful content"
    fi
else
    fail "forge-pack-hello-world/shared/greeting-conventions.md not found"
fi

# ---- README.md ----
echo ""
echo "--- README.md ---"
if [ -f "$HW_README" ]; then
    pass "forge-pack-hello-world/README.md exists"
else
    fail "forge-pack-hello-world/README.md not found"
fi

# ===========================================================
# PART 4: Dedicated test files in tests/forge-pack/
# ===========================================================
echo ""
echo "=========================================="
echo "PART 4: tests/forge-pack/ test suite files"
echo "=========================================="

TESTS_PACK_DIR="$ROOT/tests/forge-pack"

echo ""
echo "--- tests/forge-pack/ directory ---"
if [ -d "$TESTS_PACK_DIR" ]; then
    pass "tests/forge-pack/ directory exists"
else
    fail "tests/forge-pack/ directory not found"
fi

echo ""
echo "--- install-remove-cycle test file ---"
if [ -f "$TESTS_PACK_DIR/install-remove-cycle.test.sh" ]; then
    pass "tests/forge-pack/install-remove-cycle.test.sh exists"
else
    fail "tests/forge-pack/install-remove-cycle.test.sh not found"
fi

echo ""
echo "--- policy-merge test file ---"
if [ -f "$TESTS_PACK_DIR/policy-merge.test.sh" ]; then
    pass "tests/forge-pack/policy-merge.test.sh exists"
else
    fail "tests/forge-pack/policy-merge.test.sh not found"
fi

echo ""
echo "--- invalid-manifest test file ---"
if [ -f "$TESTS_PACK_DIR/invalid-manifest.test.sh" ]; then
    pass "tests/forge-pack/invalid-manifest.test.sh exists"
else
    fail "tests/forge-pack/invalid-manifest.test.sh not found"
fi

# ===========================================================
# PART 5: Functional install/remove cycle (live execution)
# ===========================================================
echo ""
echo "=========================================="
echo "PART 5: Functional install/remove cycle"
echo "=========================================="

# Only run if forge-pack script and hello-world pack both exist
if [ -f "$FORGE_PACK_SCRIPT" ] && [ -f "$HW_MANIFEST" ] && [ -x "$FORGE_PACK_SCRIPT" ]; then
    TMPDIR_TEST=$(mktemp -d)
    trap 'rm -rf "$TMPDIR_TEST"' EXIT

    # Create minimal .forge/ structure so pre-flight check passes
    mkdir -p "$TMPDIR_TEST/.forge/policies" "$TMPDIR_TEST/.forge/packs"
    # Minimal project.yaml
    cat > "$TMPDIR_TEST/.forge/project.yaml" <<'YAML'
name: test-project
version: 0.1.0
YAML

    echo ""
    echo "--- forge-pack list (empty) ---"
    LIST_OUT=$(cd "$TMPDIR_TEST" && "$FORGE_PACK_SCRIPT" list 2>&1)
    if echo "$LIST_OUT" | grep -qiE "no packs|none|empty|0 pack"; then
        pass "forge-pack list: reports no packs when none installed"
    else
        fail "forge-pack list: expected empty-pack message when no packs installed; got: '$LIST_OUT'"
    fi

    echo ""
    echo "--- forge-pack install hello-world ---"
    INSTALL_OUT=$(cd "$TMPDIR_TEST" && "$FORGE_PACK_SCRIPT" install "$HELLO_WORLD_DIR" 2>&1)
    INSTALL_RC=$?
    if [ $INSTALL_RC -eq 0 ]; then
        pass "forge-pack install: exits 0 for valid pack"
    else
        fail "forge-pack install: exited non-zero ($INSTALL_RC); output: $INSTALL_OUT"
    fi

    echo ""
    echo "--- Pack directory created after install ---"
    if [ -d "$TMPDIR_TEST/.forge/packs/hello-world" ]; then
        pass "forge-pack install: created .forge/packs/hello-world/"
    else
        fail "forge-pack install: .forge/packs/hello-world/ not created"
    fi

    echo ""
    echo "--- Policy rules with source: pack/hello-world after install ---"
    if grep -rq "source: pack/hello-world" "$TMPDIR_TEST/.forge/policies/" 2>/dev/null; then
        pass "forge-pack install: merged policy rules include 'source: pack/hello-world'"
    else
        fail "forge-pack install: policy rules missing 'source: pack/hello-world' annotation"
    fi

    echo ""
    echo "--- forge-pack list shows hello-world after install ---"
    LIST_AFTER=$(cd "$TMPDIR_TEST" && "$FORGE_PACK_SCRIPT" list 2>&1)
    if echo "$LIST_AFTER" | grep -qi "hello-world"; then
        pass "forge-pack list: shows hello-world after install"
    else
        fail "forge-pack list: expected 'hello-world' in output; got: '$LIST_AFTER'"
    fi

    echo ""
    echo "--- forge-pack remove hello-world ---"
    REMOVE_OUT=$(cd "$TMPDIR_TEST" && "$FORGE_PACK_SCRIPT" remove hello-world 2>&1)
    REMOVE_RC=$?
    if [ $REMOVE_RC -eq 0 ]; then
        pass "forge-pack remove: exits 0 for installed pack"
    else
        fail "forge-pack remove: exited non-zero ($REMOVE_RC); output: $REMOVE_OUT"
    fi

    echo ""
    echo "--- Pack directory gone after remove ---"
    if [ ! -d "$TMPDIR_TEST/.forge/packs/hello-world" ]; then
        pass "forge-pack remove: deleted .forge/packs/hello-world/"
    else
        fail "forge-pack remove: .forge/packs/hello-world/ still exists (not cleaned up)"
    fi

    echo ""
    echo "--- No orphaned policy rules after remove ---"
    if ! grep -rq "source: pack/hello-world" "$TMPDIR_TEST/.forge/policies/" 2>/dev/null; then
        pass "forge-pack remove: no orphaned 'source: pack/hello-world' rules in policies"
    else
        fail "forge-pack remove: orphaned policy rules with 'source: pack/hello-world' still exist"
    fi

    echo ""
    echo "--- forge-pack list empty again after remove ---"
    LIST_FINAL=$(cd "$TMPDIR_TEST" && "$FORGE_PACK_SCRIPT" list 2>&1)
    if echo "$LIST_FINAL" | grep -qiE "no packs|none|empty|0 pack"; then
        pass "forge-pack list: empty again after removal"
    else
        fail "forge-pack list: expected empty after remove; got: '$LIST_FINAL'"
    fi

    # ---- Invalid manifest rejection ----
    echo ""
    echo "--- Rejects install with missing pack.yaml ---"
    BADPACK=$(mktemp -d)
    # No pack.yaml in this dir
    REJECT_OUT=$(cd "$TMPDIR_TEST" && "$FORGE_PACK_SCRIPT" install "$BADPACK" 2>&1)
    REJECT_RC=$?
    rm -rf "$BADPACK"
    if [ $REJECT_RC -ne 0 ]; then
        pass "forge-pack install: rejects missing pack.yaml (exit $REJECT_RC)"
    else
        fail "forge-pack install: should exit non-zero for missing pack.yaml, but exited 0"
    fi

    # ---- Requires .forge/project.yaml ----
    echo ""
    echo "--- Requires .forge/project.yaml to exist ---"
    NOPROJ=$(mktemp -d)
    # No .forge/project.yaml at all
    NOPROJ_OUT=$(cd "$NOPROJ" && "$FORGE_PACK_SCRIPT" list 2>&1)
    NOPROJ_RC=$?
    rm -rf "$NOPROJ"
    if [ $NOPROJ_RC -ne 0 ]; then
        pass "forge-pack: rejects operation when .forge/project.yaml missing (exit $NOPROJ_RC)"
    else
        fail "forge-pack: should exit non-zero when .forge/project.yaml missing, but exited 0"
    fi

    # ---- Idempotent re-install ----
    echo ""
    echo "--- Idempotent re-install ---"
    cd "$TMPDIR_TEST" && "$FORGE_PACK_SCRIPT" install "$HELLO_WORLD_DIR" >/dev/null 2>&1
    REIMP_OUT=$(cd "$TMPDIR_TEST" && "$FORGE_PACK_SCRIPT" install "$HELLO_WORLD_DIR" 2>&1)
    REIMP_RC=$?
    if [ $REIMP_RC -eq 0 ]; then
        pass "forge-pack install: re-install is idempotent (exit 0)"
    else
        fail "forge-pack install: re-install should succeed idempotently, got exit $REIMP_RC"
    fi

    # Count source annotations — should be exactly one set (not doubled)
    SOURCE_COUNT=$(grep -r "source: pack/hello-world" "$TMPDIR_TEST/.forge/policies/" 2>/dev/null | wc -l)
    if [ "$SOURCE_COUNT" -eq 1 ]; then
        pass "forge-pack install: re-install does not duplicate policy rules ($SOURCE_COUNT annotation)"
    else
        fail "forge-pack install: idempotent re-install duplicated policy rules (found $SOURCE_COUNT 'source: pack/hello-world' entries, expected 1)"
    fi
else
    echo ""
    echo "  (SKIP: forge-pack script or hello-world pack not found — skipping live execution tests)"
    fail "Functional tests skipped because forge-pack and/or forge-pack-hello-world prerequisites are missing"
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
