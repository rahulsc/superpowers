#!/usr/bin/env bash
# Test: .forge/ YAML files parse correctly and have required fields

set -uo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

FORGE_ROOT="/home/rahulsc/Projects/Superpowers/.claude/worktrees/forge-v0/.forge"

# Helper: check YAML is valid using python (widely available) or yq
yaml_valid() {
    local file="$1"
    if command -v python3 &>/dev/null; then
        python3 - "$file" 2>/dev/null <<'PYEOF'
import yaml, sys
yaml.safe_load(open(sys.argv[1]))
PYEOF
    elif command -v yq &>/dev/null; then
        yq e '.' "$file" > /dev/null 2>&1
    else
        # Fallback: just check the file is non-empty and has colon (basic YAML indicator)
        [ -s "$file" ] && grep -q ':' "$file"
    fi
}

# Helper: extract a YAML field value (simple key: value pairs at root level)
yaml_field() {
    local file="$1"
    local field="$2"
    if command -v python3 &>/dev/null; then
        python3 -c "import yaml; d=yaml.safe_load(open('$file')); print(d.get('$field', ''))" 2>/dev/null
    elif command -v yq &>/dev/null; then
        yq e ".$field" "$file" 2>/dev/null
    else
        grep "^$field:" "$file" | head -1 | sed "s/^$field:[[:space:]]*//"
    fi
}

# Helper: check YAML has a root-level key
yaml_has_key() {
    local file="$1"
    local key="$2"
    if command -v python3 &>/dev/null; then
        python3 -c "import yaml, sys; d=yaml.safe_load(open('$file')); sys.exit(0 if '$key' in d else 1)" 2>/dev/null
        return $?
    else
        grep -q "^$key:" "$file" 2>/dev/null
    fi
}

echo "=== validate-schemas: YAML schema validation ==="
echo ""

# --- project.yaml ---
echo "--- .forge/project.yaml ---"
PROJECT_YAML="$FORGE_ROOT/project.yaml"

if [ ! -f "$PROJECT_YAML" ]; then
    fail "project.yaml not found — cannot validate schema"
else
    if yaml_valid "$PROJECT_YAML"; then
        pass "project.yaml is valid YAML"
    else
        fail "project.yaml is not valid YAML"
    fi

    # Required fields
    for field in name version stack commands repo_traits storage; do
        if yaml_has_key "$PROJECT_YAML" "$field"; then
            pass "project.yaml has required field: $field"
        else
            fail "project.yaml missing required field: $field"
        fi
    done

    # storage field defaults to sqlite
    STORAGE_VAL=$(yaml_field "$PROJECT_YAML" "storage")
    if [ "$STORAGE_VAL" = "sqlite" ] || [ "$STORAGE_VAL" = "null" ] || [ -z "$STORAGE_VAL" ]; then
        pass "project.yaml storage field is 'sqlite' (or absent, defaults to sqlite)"
    else
        # Non-sqlite is allowed if explicitly set, just check it's a known value
        if [[ "$STORAGE_VAL" =~ ^(sqlite|json)$ ]]; then
            pass "project.yaml storage field is a known value: $STORAGE_VAL"
        else
            fail "project.yaml storage field has unexpected value: '$STORAGE_VAL' (expected sqlite or json)"
        fi
    fi
fi

echo ""

# --- policies/default.yaml ---
echo "--- .forge/policies/default.yaml ---"
POLICY_YAML="$FORGE_ROOT/policies/default.yaml"

if [ ! -f "$POLICY_YAML" ]; then
    fail "policies/default.yaml not found — cannot validate schema"
else
    if yaml_valid "$POLICY_YAML"; then
        pass "policies/default.yaml is valid YAML"
    else
        fail "policies/default.yaml is not valid YAML"
    fi

    # Must have a 'rules' array
    if yaml_has_key "$POLICY_YAML" "rules"; then
        pass "policies/default.yaml has 'rules' key"
    else
        fail "policies/default.yaml missing 'rules' key"
    fi

    # Each rule must have match and tier; validate via python if available
    if command -v python3 &>/dev/null; then
        RULES_VALID=$(python3 - "$POLICY_YAML" <<'PYEOF'
import yaml, sys
try:
    d = yaml.safe_load(open(sys.argv[1]))
    rules = d.get("rules", [])
    if not isinstance(rules, list):
        print("FAIL: rules is not a list")
        sys.exit(1)
    if len(rules) == 0:
        print("FAIL: rules list is empty")
        sys.exit(1)
    valid_tiers = {"minimal", "standard", "elevated", "critical"}
    for i, rule in enumerate(rules):
        if "match" not in rule:
            print(f"FAIL: rule[{i}] missing 'match'")
            sys.exit(1)
        if "tier" not in rule:
            print(f"FAIL: rule[{i}] missing 'tier'")
            sys.exit(1)
        if rule["tier"] not in valid_tiers:
            print(f"FAIL: rule[{i}] tier '{rule['tier']}' not in {valid_tiers}")
            sys.exit(1)
    print("PASS")
    sys.exit(0)
except Exception as e:
    print(f"FAIL: {e}")
    sys.exit(1)
PYEOF
        )
        if echo "$RULES_VALID" | grep -q "^PASS"; then
            pass "all policy rules have required fields (match, tier) with valid tier values"
        else
            fail "policy rules validation: $RULES_VALID"
        fi
    else
        # Fallback: check tiers textually
        VALID_TIERS="minimal|standard|elevated|critical"
        if grep -qE "tier:\s*($VALID_TIERS)" "$POLICY_YAML"; then
            pass "policy rules contain valid tier values"
        else
            fail "policy rules missing valid tier values (expected: minimal, standard, elevated, critical)"
        fi
    fi
fi

echo ""

# --- workflows/example.yaml ---
echo "--- .forge/workflows/example.yaml ---"
WORKFLOW_YAML="$FORGE_ROOT/workflows/example.yaml"

if [ ! -f "$WORKFLOW_YAML" ]; then
    fail "workflows/example.yaml not found — cannot validate schema"
else
    if yaml_valid "$WORKFLOW_YAML"; then
        pass "workflows/example.yaml is valid YAML"
    else
        fail "workflows/example.yaml is not valid YAML"
    fi
fi

echo ""
echo "============================================"
echo "Results: $PASS passed, $FAIL failed"
echo "============================================"

if [ $FAIL -gt 0 ]; then
    exit 1
fi
exit 0
