#!/usr/bin/env bash
# Test: OpenCode runtime adapter contract wording
# Verifies adapter-first mapping language and anti-misclassification guardrails.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PLUGIN_FILE="$REPO_ROOT/.opencode/plugins/superpowers.js"
README_FILE="$REPO_ROOT/docs/README.opencode.md"

echo "=== Test: OpenCode Runtime Adapter Contract ==="

echo "Test 1: Plugin adapter actions are present..."
REQUIRED_ACTIONS=(
    "load_skill"
    "track_tasks"
    "spawn_worker"
    "message_worker"
    "wait_worker"
    "close_worker"
)

for action in "${REQUIRED_ACTIONS[@]}"; do
    if grep -q "$action" "$PLUGIN_FILE"; then
        echo "  [PASS] plugin references $action"
    else
        echo "  [FAIL] plugin missing adapter action: $action"
        exit 1
    fi
done

echo ""
echo "Test 2: Plugin avoids legacy Task/TodoWrite translation framing..."
if grep -Eq 'TodoWrite|Task tool' "$PLUGIN_FILE"; then
    echo "  [FAIL] plugin still contains legacy Task/TodoWrite mapping text"
    exit 1
else
    echo "  [PASS] plugin uses adapter-first mapping language"
fi

echo ""
echo "Test 3: README includes anti-misclassification guidance..."
if grep -Eq "spawn_worker.*abstract action" "$README_FILE"; then
    echo "  [PASS] README explains abstract action vs native tools"
else
    echo "  [FAIL] README missing abstract action clarification"
    exit 1
fi

if grep -q "Do not infer capability loss from missing abstract names" "$README_FILE"; then
    echo "  [PASS] README includes capability-loss guardrail"
else
    echo "  [FAIL] README missing capability-loss guardrail"
    exit 1
fi

echo ""
echo "=== OpenCode runtime adapter contract tests passed ==="
