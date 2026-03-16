#!/usr/bin/env bash
# Test: Claude runtime capability probe behavior
# Verifies runtime-capability reasoning uses native equivalents, not literal abstract names.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: Claude Runtime Capability Probe ==="
echo ""

probe_prompt="Use superpowers:using-superpowers. In one short answer: list runtime-visible native tools/signals in this session, map them to load_skill/track_tasks/spawn_worker/message_worker/wait_worker/close_worker, declare worker profile/execution mode/permission mode, provide a user-facing runtime status summary combining execution + permission in plain language, and explicitly state that abstract actions are not literal tool names."

set +e
output=$(run_claude "$probe_prompt" 90 2>&1)
exit_code=$?
set -e

if [ "$exit_code" -ne 0 ]; then
    if echo "$output" | grep -Eqi "auth|login|credential|api key|unauthorized|forbidden|not logged"; then
        echo "  [SKIP] Claude runtime probe unavailable due to auth/session state"
        exit 0
    fi
    echo "  [FAIL] Claude runtime probe command failed (exit $exit_code)"
    echo "$output" | sed 's/^/    /'
    exit 1
fi

if assert_contains "$output" "abstract action\|not literal tool" "Anti-misclassification statement"; then
    :
else
    exit 1
fi

if assert_contains "$output" "load_skill\|track_tasks\|spawn_worker\|message_worker\|wait_worker\|close_worker" "Adapter actions mapped"; then
    :
else
    exit 1
fi

if assert_contains "$output" "full-lifecycle\|managed-lifecycle\|unavailable\|worker profile\|profile:" "Worker profile declared"; then
    :
else
    exit 1
fi

if assert_contains "$output" "parallel-worker\|fallback-serial\|execution mode\|foreground\|background" "Execution mode declared"; then
    :
else
    exit 1
fi

if assert_contains "$output" "normal\|git-write-restricted\|permission mode" "Permission mode declared"; then
    :
else
    exit 1
fi

if assert_contains "$output" "user-facing runtime status\|plain language\|what this means\|runtime status" "User-facing runtime summary declared"; then
    :
else
    exit 1
fi

echo ""
echo "=== Claude runtime capability probe passed ==="
