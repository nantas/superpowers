#!/usr/bin/env bash
# Test: OpenCode runtime capability probe
# Integration test that verifies capability detection uses native equivalents.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Test: OpenCode Runtime Capability Probe ==="

# Source setup to create isolated environment
source "$SCRIPT_DIR/setup.sh"

# Trap to cleanup on exit
trap cleanup_test_env EXIT

if ! command -v opencode &> /dev/null; then
    echo "  [SKIP] OpenCode not installed - skipping integration probe"
    exit 0
fi

echo "Test 1: Runtime probe response..."
set +e
output=$(run_with_timeout 90 opencode run --print-logs "Use superpowers:using-superpowers. In at most 12 lines: (1) list runtime-native tools/signals available in this session, (2) map them to load_skill, track_tasks, spawn_worker, message_worker, wait_worker, close_worker, and (3) declare worker profile and execution mode. Explicitly state that abstract actions are not literal tool names." 2>&1)
exit_code=$?
set -e

if [ $exit_code -ne 0 ]; then
    if [ $exit_code -eq 124 ]; then
        echo "  [FAIL] OpenCode timed out after 90s"
        exit 1
    fi
    if echo "$output" | grep -Eqi "auth|login|credential|api key|unauthorized|forbidden|not logged"; then
        echo "  [SKIP] OpenCode unavailable due to auth/session state"
        exit 0
    fi
    echo "  [FAIL] OpenCode probe command failed (exit $exit_code)"
    echo "$output" | sed 's/^/    /'
    exit 1
fi

if echo "$output" | grep -Eqi "service=tool\.registry status=started.*skill" \
   && echo "$output" | grep -Eqi "service=tool\.registry status=started.*(task|todowrite)"; then
    echo "  [PASS] runtime logs expose native planning/worker-related tools"
else
    echo "  [FAIL] runtime logs missing expected native planning/worker tool signals"
    echo "$output" | sed 's/^/    /'
    exit 1
fi

if echo "$output" | grep -Eqi "abstract action.*not literal|not literal tool name"; then
    echo "  [PASS] response includes anti-misclassification statement"
else
    echo "  [FAIL] response missing anti-misclassification statement"
    echo "$output" | sed 's/^/    /'
    exit 1
fi

if echo "$output" | grep -Eqi "load_skill|track_tasks|spawn_worker|message_worker|wait_worker|close_worker"; then
    echo "  [PASS] response references adapter actions"
else
    echo "  [FAIL] response missing adapter action mapping"
    echo "$output" | sed 's/^/    /'
    exit 1
fi

if echo "$output" | grep -Eqi "@mention|update_plan|todowrite|task|skill tool"; then
    echo "  [PASS] response references OpenCode-native equivalents"
else
    echo "  [FAIL] response missing OpenCode-native equivalents"
    echo "$output" | sed 's/^/    /'
    exit 1
fi

if echo "$output" | grep -Eqi "full-lifecycle|managed-lifecycle|unavailable|worker profile"; then
    echo "  [PASS] response declares worker profile"
else
    echo "  [FAIL] response missing worker profile declaration"
    echo "$output" | sed 's/^/    /'
    exit 1
fi

if echo "$output" | grep -Eqi "parallel-worker|fallback-serial"; then
    echo "  [PASS] response declares execution mode"
else
    echo "  [FAIL] response missing execution mode declaration"
    echo "$output" | sed 's/^/    /'
    exit 1
fi

echo ""
echo "=== OpenCode runtime capability probe passed ==="
