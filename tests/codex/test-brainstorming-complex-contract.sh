#!/usr/bin/env bash
# Test: brainstorming-complex skill contract
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

SKILL_FILE="$REPO_ROOT/skills/brainstorming-complex/SKILL.md"
COMMAND_FILE="$REPO_ROOT/commands/brainstorm-complex.md"

echo "=== Test: Brainstorming Complex Contract ==="

if [ ! -f "$SKILL_FILE" ]; then
    echo "  [FAIL] Missing skill file: $SKILL_FILE"
    exit 1
fi

if [ ! -f "$COMMAND_FILE" ]; then
    echo "  [FAIL] Missing command entrypoint: $COMMAND_FILE"
    exit 1
fi

REQUIRED_PATTERNS=(
    "name: brainstorming-complex"
    "Use when"
    "context completeness"
    "Question Gate"
    "information-collection"
    "selection question"
    "Context Drift"
    "re-open context discovery"
    "User-Facing Communication Contract"
    "user language"
    "Adaptive Verbosity Rules"
    "Term Mapping"
    "next question purpose"
    "The terminal state is invoking writing-plans"
)

MISSING=0
for pattern in "${REQUIRED_PATTERNS[@]}"; do
    if ! grep -qi "$pattern" "$SKILL_FILE"; then
        echo "  [FAIL] Missing skill pattern: $pattern"
        MISSING=1
    fi
done

if ! grep -qi "Invoke the superpowers:brainstorming-complex skill" "$COMMAND_FILE"; then
    echo "  [FAIL] command file does not invoke superpowers:brainstorming-complex"
    MISSING=1
fi

if [ "$MISSING" -ne 0 ]; then
    exit 1
fi

echo "  [PASS] brainstorming-complex skill contract present"
echo "=== Brainstorming Complex Contract test passed ==="
