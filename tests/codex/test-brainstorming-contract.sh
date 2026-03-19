#!/usr/bin/env bash
# Test: brainstorming skill contract
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

SKILL_FILE="$REPO_ROOT/skills/brainstorming/SKILL.md"
COMMAND_FILE="$REPO_ROOT/commands/brainstorm.md"

echo "=== Test: Brainstorming Contract ==="

if [ ! -f "$SKILL_FILE" ]; then
    echo "  [FAIL] Missing skill file: $SKILL_FILE"
    exit 1
fi

if [ ! -f "$COMMAND_FILE" ]; then
    echo "  [FAIL] Missing command entrypoint: $COMMAND_FILE"
    exit 1
fi

REQUIRED_PATTERNS=(
    "name: brainstorming"
    "request_user_input"
    "Prioritize"
    "one question per message"
    "combine"
    "simple questions"
)

MISSING=0
for pattern in "${REQUIRED_PATTERNS[@]}"; do
    if ! grep -qi "$pattern" "$SKILL_FILE"; then
        echo "  [FAIL] Missing skill pattern: $pattern"
        MISSING=1
    fi
done

if ! grep -qi "Invoke the superpowers:brainstorming skill" "$COMMAND_FILE"; then
    echo "  [FAIL] command file does not invoke superpowers:brainstorming"
    MISSING=1
fi

if [ "$MISSING" -ne 0 ]; then
    exit 1
fi

echo "  [PASS] brainstorming skill contract present"
echo "=== Brainstorming Contract test passed ==="
