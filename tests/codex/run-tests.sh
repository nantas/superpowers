#!/usr/bin/env bash
# Main runner for Codex-specific compatibility checks.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

RUN_INTEGRATION=false
RUNTIME_COMPAT_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --integration|-i)
            RUN_INTEGRATION=true
            shift
            ;;
        *)
            RUNTIME_COMPAT_ARGS+=("$1")
            shift
            ;;
    esac
done

if [ "$RUN_INTEGRATION" = true ]; then
    RUNTIME_COMPAT_ARGS+=(--integration)
fi

if [ "${#RUNTIME_COMPAT_ARGS[@]}" -gt 0 ]; then
    bash "$SCRIPT_DIR/test-runtime-compat.sh" "${RUNTIME_COMPAT_ARGS[@]}"
else
    bash "$SCRIPT_DIR/test-runtime-compat.sh"
fi
bash "$SCRIPT_DIR/test-brainstorming-contract.sh"
bash "$SCRIPT_DIR/test-brainstorming-complex-contract.sh"
bash "$SCRIPT_DIR/test-skill-context-budget.sh"

if [ "$RUN_INTEGRATION" = true ]; then
    bash "$SCRIPT_DIR/test-wait-completion-evidence.sh"
fi
