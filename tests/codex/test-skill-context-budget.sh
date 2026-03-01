#!/usr/bin/env bash
# Test: skill context loading budget and force-load guard for core skills.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

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

check_budget() {
    local file="$1"
    local max_words="$2"

    local words
    words=$(wc -w < "$file" | tr -d ' ')

    if [ "$words" -le "$max_words" ]; then
        pass "$(basename "$(dirname "$file")")/$(basename "$file") words=$words <= $max_words"
    else
        fail "$(basename "$(dirname "$file")")/$(basename "$file") words=$words > $max_words"
    fi
}

echo "========================================"
echo " Skill Context Budget Test"
echo "========================================"
echo ""

check_budget "$REPO_ROOT/skills/writing-skills/SKILL.md" 1200
check_budget "$REPO_ROOT/skills/systematic-debugging/SKILL.md" 900
check_budget "$REPO_ROOT/skills/test-driven-development/SKILL.md" 900
check_budget "$REPO_ROOT/skills/subagent-driven-development/SKILL.md" 800
check_budget "$REPO_ROOT/skills/using-superpowers/SKILL.md" 450

echo ""
echo "Checking force-load markdown references in core skills..."
if rg -n "@[A-Za-z0-9_./-]+\\.md" \
    "$REPO_ROOT/skills/using-superpowers/SKILL.md" \
    "$REPO_ROOT/skills/writing-skills/SKILL.md" \
    "$REPO_ROOT/skills/test-driven-development/SKILL.md"; then
    fail "found @*.md force-load references in core skills"
else
    pass "no @*.md force-load references in core skills"
fi

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
