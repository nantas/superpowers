#!/bin/bash
# Run all explicit skill request tests
# Usage: ./run-all.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPTS_DIR="$SCRIPT_DIR/prompts"

echo "=== Running All Explicit Skill Request Tests ==="
echo ""

PASSED=0
FAILED=0
RESULTS=()

run_case() {
    local label="$1"
    local skill="$2"
    local prompt_file="$3"
    local required_regexes="${4:-}"
    local forbidden_regexes="${5:-}"

    echo ">>> $label"

    set +e
    REQUIRED_REGEXES="$required_regexes" \
    FORBIDDEN_REGEXES="$forbidden_regexes" \
    "$SCRIPT_DIR/run-test.sh" "$skill" "$prompt_file"
    RUN_EXIT=$?
    set -e

    if [ "$RUN_EXIT" -eq 0 ]; then
        PASSED=$((PASSED + 1))
        RESULTS+=("PASS: $label")
    elif [ "$RUN_EXIT" -eq 2 ]; then
        RESULTS+=("SKIP: $label")
    else
        FAILED=$((FAILED + 1))
        RESULTS+=("FAIL: $label")
    fi
    echo ""
}

# Test: subagent-driven-development, please
run_case "Test 1: subagent-driven-development-please" \
    "subagent-driven-development" \
    "$PROMPTS_DIR/subagent-driven-development-please.txt"

# Test: use systematic-debugging
run_case "Test 2: use-systematic-debugging" \
    "systematic-debugging" \
    "$PROMPTS_DIR/use-systematic-debugging.txt"

# Test: please use brainstorming
run_case "Test 3: please-use-brainstorming" \
    "brainstorming" \
    "$PROMPTS_DIR/please-use-brainstorming.txt"

# Test: mid-conversation execute plan
run_case "Test 4: mid-conversation-execute-plan" \
    "subagent-driven-development" \
    "$PROMPTS_DIR/mid-conversation-execute-plan.txt"

run_case "Test 5: subagent-driven-development-expectations" \
    "subagent-driven-development" \
    "$PROMPTS_DIR/subagent-driven-development-expectations.txt" \
    "lightweight|moderate|high-risk
implementer
slower|longer
context offload|context savings|main-session context|reliability"

run_case "Test 6: subagent-driven-development-tiering" \
    "subagent-driven-development" \
    "$PROMPTS_DIR/subagent-driven-development-tiering.txt" \
    "lightweight|moderate
self-check|one reviewer|single reviewer"

run_case "Test 7: finishing-branch-dirty-non-worktree" \
    "finishing-a-development-branch" \
    "$PROMPTS_DIR/finishing-branch-dirty-non-worktree.txt" \
    "git status --porcelain
git branch --show-current
Do not proceed with uncommitted changes|checkpoint commit|commit first|must be committed first|uncommitted changes must be committed first
<base-branch> == <feature-branch>|different base branch|invalid.*merge target"

echo "=== Summary ==="
printf '%s\n' "${RESULTS[@]}"
echo ""
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "Total: $((PASSED + FAILED))"

if [ "$FAILED" -gt 0 ]; then
    exit 1
fi
