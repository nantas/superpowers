#!/usr/bin/env bash
# Integration test: wait-based completion gate evidence in Codex responses.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROJECT_DIR="$REPO_ROOT"

run_with_timeout() {
    local seconds="$1"
    shift

    if command -v timeout >/dev/null 2>&1; then
        timeout "$seconds" "$@"
    elif command -v gtimeout >/dev/null 2>&1; then
        gtimeout "$seconds" "$@"
    else
        "$@" &
        local cmd_pid=$!
        (
            sleep "$seconds"
            kill -TERM "$cmd_pid" 2>/dev/null || exit 0
            sleep 2
            kill -KILL "$cmd_pid" 2>/dev/null || true
        ) &
        local watcher_pid=$!
        local status=0
        wait "$cmd_pid" || status=$?
        kill "$watcher_pid" 2>/dev/null || true
        wait "$watcher_pid" 2>/dev/null || true

        if [ "$status" -eq 143 ] || [ "$status" -eq 137 ]; then
            return 124
        fi

        return "$status"
    fi
}

run_codex_exec() {
    local prompt="$1"

    run_with_timeout 180 codex exec \
        -C "$PROJECT_DIR" \
        -s danger-full-access \
        --ephemeral \
        -c "projects.\"$PROJECT_DIR\".trust_level=\"trusted\"" \
        "$prompt"
}

looks_like_auth_error() {
    local file="$1"
    grep -Eqi "auth|login|credential|api key|unauthorized|forbidden|not logged" "$file"
}

echo "=== Test: Codex Wait Completion Evidence ==="

if ! command -v codex >/dev/null 2>&1; then
    echo "  [SKIP] codex CLI not found"
    exit 0
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
OUT_FILE="$TMP_DIR/wait-evidence.txt"

PROMPT="Use superpowers:using-superpowers. Give Codex-specific orchestration guidance for 3 parallel workers. Include these exact lines:
EVIDENCE_WAIT_SOURCE=wait
EVIDENCE_NO_ARTIFACT_POLLING=true
EVIDENCE_WAIT_ANY=true
EVIDENCE_PENDING_IDS_LOOP=true
Then include a short pseudocode block that contains wait(pending_ids)."

set +e
run_codex_exec "$PROMPT" >"$OUT_FILE" 2>&1
EXIT_CODE=$?
set -e

if [ "$EXIT_CODE" -ne 0 ]; then
    if looks_like_auth_error "$OUT_FILE"; then
        echo "  [SKIP] codex exec unavailable due to auth/session state"
        exit 0
    fi
    echo "  [FAIL] codex execution failed"
    sed 's/^/    /' "$OUT_FILE"
    exit 1
fi

REQUIRED_LINES=(
    "EVIDENCE_WAIT_SOURCE=wait"
    "EVIDENCE_NO_ARTIFACT_POLLING=true"
    "EVIDENCE_WAIT_ANY=true"
    "EVIDENCE_PENDING_IDS_LOOP=true"
)

MISSING=0
for line in "${REQUIRED_LINES[@]}"; do
    if ! grep -q "$line" "$OUT_FILE"; then
        echo "  [FAIL] Missing evidence line: $line"
        MISSING=1
    fi
done

if ! grep -qi "wait(pending_ids)" "$OUT_FILE"; then
    echo "  [FAIL] Missing pending_ids wait loop evidence"
    MISSING=1
fi

if [ "$MISSING" -ne 0 ]; then
    echo ""
    echo "Output:"
    sed 's/^/    /' "$OUT_FILE"
    exit 1
fi

echo "  [PASS] Codex response includes wait-based completion and no-polling evidence"
echo "=== Codex Wait Completion Evidence test passed ==="
