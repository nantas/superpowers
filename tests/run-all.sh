#!/usr/bin/env bash
# Unified test runner for superpowers.
# Default: run fast Codex + OpenCode suites.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RUN_CODEX=true
RUN_OPENCODE=true
RUN_CLAUDE=false
RUN_SKILL_TRIGGERING=false
RUN_EXPLICIT=false

OPENCODE_INTEGRATION=false
CLAUDE_INTEGRATION=false
VERBOSE=false

usage() {
    cat <<'USAGE'
Usage: ./tests/run-all.sh [options]

Defaults:
  Runs fast suites only: codex + opencode

Options:
  --with-claude               Include Claude-based suites (claude-code, skill-triggering, explicit-skill-requests)
  --with-opencode-integration Run OpenCode integration tests (--integration)
  --with-claude-integration   Run Claude integration tests (--integration)
  --verbose, -v               Stream suite output directly
  --help, -h                  Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --with-claude)
            RUN_CLAUDE=true
            RUN_SKILL_TRIGGERING=true
            RUN_EXPLICIT=true
            shift
            ;;
        --with-opencode-integration)
            OPENCODE_INTEGRATION=true
            shift
            ;;
        --with-claude-integration)
            CLAUDE_INTEGRATION=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

pass_count=0
fail_count=0
skip_count=0

run_suite() {
    local suite_name="$1"
    shift

    local -a cmd=("$@")

    echo "----------------------------------------"
    echo "Running suite: $suite_name"
    echo "----------------------------------------"

    local start end duration
    start=$(date +%s)

    if [ "$VERBOSE" = true ]; then
        if "${cmd[@]}"; then
            end=$(date +%s)
            duration=$((end - start))
            echo "  [PASS] $suite_name (${duration}s)"
            pass_count=$((pass_count + 1))
        else
            end=$(date +%s)
            duration=$((end - start))
            echo "  [FAIL] $suite_name (${duration}s)"
            fail_count=$((fail_count + 1))
        fi
    else
        local out_file
        out_file=$(mktemp)
        if "${cmd[@]}" >"$out_file" 2>&1; then
            end=$(date +%s)
            duration=$((end - start))
            echo "  [PASS] $suite_name (${duration}s)"
            pass_count=$((pass_count + 1))
        else
            end=$(date +%s)
            duration=$((end - start))
            echo "  [FAIL] $suite_name (${duration}s)"
            echo ""
            sed 's/^/    /' "$out_file"
            fail_count=$((fail_count + 1))
        fi
        rm -f "$out_file"
    fi

    echo ""
}

skip_suite() {
    local suite_name="$1"
    local reason="$2"
    echo "----------------------------------------"
    echo "Running suite: $suite_name"
    echo "----------------------------------------"
    echo "  [SKIP] $reason"
    echo ""
    skip_count=$((skip_count + 1))
}

echo "========================================"
echo " Superpowers Unified Test Runner"
echo "========================================"
echo ""
echo "Repository: $REPO_ROOT"
echo "Test time: $(date)"
echo ""

if [ "$RUN_CODEX" = true ]; then
    run_suite "codex" bash "$SCRIPT_DIR/codex/run-tests.sh"
fi

if [ "$RUN_OPENCODE" = true ]; then
    if ! command -v node >/dev/null 2>&1; then
        skip_suite "opencode" "node not installed"
    else
        if [ "$OPENCODE_INTEGRATION" = true ]; then
            run_suite "opencode" bash "$SCRIPT_DIR/opencode/run-tests.sh" --integration
        else
            run_suite "opencode" bash "$SCRIPT_DIR/opencode/run-tests.sh"
        fi
    fi
fi

if [ "$RUN_CLAUDE" = true ]; then
    if ! command -v claude >/dev/null 2>&1; then
        skip_suite "claude-code" "claude CLI not installed"
    else
        if [ "$CLAUDE_INTEGRATION" = true ]; then
            run_suite "claude-code" bash "$SCRIPT_DIR/claude-code/run-skill-tests.sh" --integration
        else
            run_suite "claude-code" bash "$SCRIPT_DIR/claude-code/run-skill-tests.sh"
        fi
    fi
fi

if [ "$RUN_SKILL_TRIGGERING" = true ]; then
    if ! command -v claude >/dev/null 2>&1; then
        skip_suite "skill-triggering" "claude CLI not installed"
    else
        run_suite "skill-triggering" bash "$SCRIPT_DIR/skill-triggering/run-all.sh"
    fi
fi

if [ "$RUN_EXPLICIT" = true ]; then
    if ! command -v claude >/dev/null 2>&1; then
        skip_suite "explicit-skill-requests" "claude CLI not installed"
    else
        run_suite "explicit-skill-requests" bash "$SCRIPT_DIR/explicit-skill-requests/run-all.sh"
    fi
fi

echo "========================================"
echo " Test Results Summary"
echo "========================================"
echo ""
echo "  Passed:  $pass_count"
echo "  Failed:  $fail_count"
echo "  Skipped: $skip_count"
echo ""

if [ "$fail_count" -gt 0 ]; then
    echo "STATUS: FAILED"
    exit 1
fi

echo "STATUS: PASSED"
exit 0
