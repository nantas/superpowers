#!/usr/bin/env bash
# Test: writing-plans/executing-plans semantic gate contract
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

WRITING_PLANS_FILE="$REPO_ROOT/skills/writing-plans/SKILL.md"
EXECUTING_PLANS_FILE="$REPO_ROOT/skills/executing-plans/SKILL.md"

PASS_COUNT=0
FAIL_COUNT=0

pass() {
    echo "  [PASS] $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
    echo "  [FAIL] $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

require_patterns() {
    local file="$1"
    local label="$2"
    shift 2
    local missing=0

    for pattern in "$@"; do
        if ! grep -qi "$pattern" "$file"; then
            echo "    missing pattern: $pattern"
            missing=1
        fi
    done

    if [ "$missing" -eq 0 ]; then
        pass "$label"
    else
        fail "$label"
    fi
}

echo "========================================"
echo " Plan Semantic Gates Contract Test"
echo "========================================"
echo ""

if [ ! -f "$WRITING_PLANS_FILE" ] || [ ! -f "$EXECUTING_PLANS_FILE" ]; then
    echo "  [FAIL] missing required skill file(s)"
    exit 1
fi

echo "Test 1: writing-plans defines post-write authenticity audit and anti-fake checks..."
require_patterns "$WRITING_PLANS_FILE" \
    "writing-plans includes traceability, audit, and anti-placeholder rules" \
    "Design Traceability Matrix" \
    "Plan Authenticity Audit" \
    "Plan Audit Verdict" \
    "approval_decision" \
    "P0" \
    "P1" \
    "P2" \
    "assert no placeholder path" \
    "assert live mode has tool evidence" \
    "assert freeze requires non-empty confirmed_chain.steps"

echo ""
echo "Test 2: executing-plans enforces verdict gate before execution..."
require_patterns "$EXECUTING_PLANS_FILE" \
    "executing-plans blocks execution when audit verdict is missing or not pass" \
    "Design Traceability Matrix" \
    "Plan Audit Verdict" \
    "approval_decision" \
    "blocked"

echo ""
echo "Test 3: executing-plans reports semantic progress status fields..."
require_patterns "$EXECUTING_PLANS_FILE" \
    "executing-plans includes fixed semantic status fields in progress reports" \
    "design_coverage_status" \
    "authenticity_status" \
    "semantic_closure_status"

echo ""
echo "Test 4: human verification gate requires explicit acceptance contract..."
require_patterns "$WRITING_PLANS_FILE" \
    "writing-plans requires explicit user verification checklist and verdict prompt" \
    "Human Verification Checklist" \
    "Acceptance Criteria" \
    "Failure Signals" \
    "通过" \
    "不通过"

require_patterns "$EXECUTING_PLANS_FILE" \
    "executing-plans requires fixed human-gate stop structure and binary decision" \
    "Gate Scope" \
    "What to Verify" \
    "Pass Criteria" \
    "Evidence" \
    "Decision" \
    "Do not ask whether to enter finishing flow" \
    "通过" \
    "不通过"

echo ""
echo "========================================"
echo " Test Results Summary"
echo "========================================"
echo ""
echo "  Passed: $PASS_COUNT"
echo "  Failed: $FAIL_COUNT"
echo ""

if [ "$FAIL_COUNT" -gt 0 ]; then
    echo "STATUS: FAILED"
    exit 1
fi

echo "STATUS: PASSED"
exit 0
