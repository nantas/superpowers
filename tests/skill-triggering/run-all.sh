#!/bin/bash
# Run all skill triggering tests
# Usage: ./run-all.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPTS_DIR="$SCRIPT_DIR/prompts"

SKILLS=(
    "using-superpowers"
    "systematic-debugging"
    "test-driven-development"
    "writing-plans"
    "dispatching-parallel-agents"
    "executing-plans"
    "requesting-code-review"
)

echo "=== Running Skill Triggering Tests ==="
echo ""

PASSED=0
FAILED=0
SKIPPED=0
RESULTS=()

run_case() {
    local label="$1"
    local skill="$2"
    local prompt_file="$3"
    local required_regexes="${4:-}"
    local forbidden_regexes="${5:-}"

    echo "Testing: $label"

    set +e
    REQUIRED_REGEXES="$required_regexes" \
    FORBIDDEN_REGEXES="$forbidden_regexes" \
    "$SCRIPT_DIR/run-test.sh" "$skill" "$prompt_file" 3 2>&1 | tee "/tmp/skill-test-${label// /-}.log"
    RUN_EXIT=${PIPESTATUS[0]}
    set -e

    if [ "$RUN_EXIT" -eq 0 ]; then
        PASSED=$((PASSED + 1))
        RESULTS+=("✅ $label")
    elif [ "$RUN_EXIT" -eq 2 ]; then
        SKIPPED=$((SKIPPED + 1))
        RESULTS+=("⚠️ $label")
    else
        FAILED=$((FAILED + 1))
        RESULTS+=("❌ $label")
    fi

    echo ""
    echo "---"
    echo ""
}

for skill in "${SKILLS[@]}"; do
    prompt_file="$PROMPTS_DIR/${skill}.txt"

    if [ ! -f "$prompt_file" ]; then
        echo "⚠️  SKIP: No prompt file for $skill"
        SKIPPED=$((SKIPPED + 1))
        RESULTS+=("⚠️ $skill")
        continue
    fi

    run_case "$skill" "$skill" "$prompt_file"
done

run_case \
    "dispatching-parallel-agents context offload" \
    "dispatching-parallel-agents" \
    "$PROMPTS_DIR/context-offload-multi-agent.txt"

echo ""
echo "=== Summary ==="
for result in "${RESULTS[@]}"; do
    echo "  $result"
done
echo ""
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "Skipped: $SKIPPED"

if [ "$FAILED" -gt 0 ]; then
    exit 1
fi
