#!/usr/bin/env bash
# Test: Codex runtime compatibility for superpowers skills.
# Verifies adapter terminology, Codex tool availability, and a behavior smoke check.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROJECT_DIR="$REPO_ROOT"

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
INTEGRATION_SKIPPED=false

pass() {
    echo "  [PASS] $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
    echo "  [FAIL] $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

skip() {
    echo "  [SKIP] $1"
    SKIP_COUNT=$((SKIP_COUNT + 1))
}

run_with_timeout() {
    local seconds="$1"
    shift

    if command -v timeout >/dev/null 2>&1; then
        timeout "$seconds" "$@"
    elif command -v gtimeout >/dev/null 2>&1; then
        gtimeout "$seconds" "$@"
    else
        "$@"
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

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "========================================"
echo " Codex Runtime Compatibility Test"
echo "========================================"
echo ""
echo "Repository: $PROJECT_DIR"
echo "Test time: $(date)"
echo ""

# Test 1: Static compatibility scan

echo "Test 1: Static compatibility scan..."
STATIC_OUT="$TMP_DIR/static-scan.txt"
set +e
rg -n "TodoWrite|Task tool|Task\\(" "$REPO_ROOT/skills" "$REPO_ROOT/docs" --glob '!**/plans/**' >"$STATIC_OUT" 2>&1
RG_EXIT=$?
set -e

if [ "$RG_EXIT" -eq 1 ]; then
    pass "No legacy TodoWrite/Task tool references in active skills/docs"
elif [ "$RG_EXIT" -eq 0 ]; then
    fail "Found legacy references (expected zero):"
    sed 's/^/    /' "$STATIC_OUT"
else
    fail "Static scan command failed"
    sed 's/^/    /' "$STATIC_OUT"
fi

echo ""

# Integration tests require codex CLI.
if ! command -v codex >/dev/null 2>&1; then
    skip "codex CLI not found; skipping runtime integration checks"
    INTEGRATION_SKIPPED=true
fi

# Test 2: Codex capability probe
if [ "$INTEGRATION_SKIPPED" = false ]; then
    echo "Test 2: Codex capability probe..."
    CAP_OUT="$TMP_DIR/capabilities.txt"

    set +e
    run_codex_exec "List the exact tool names available to you in this session as plain newline-separated text, then stop." >"$CAP_OUT" 2>&1
    CAP_EXIT=$?
    set -e

    if [ "$CAP_EXIT" -ne 0 ]; then
        if looks_like_auth_error "$CAP_OUT"; then
            skip "codex exec unavailable due to auth/session state; skipping runtime integration checks"
            INTEGRATION_SKIPPED=true
        else
            fail "codex capability probe failed"
            sed 's/^/    /' "$CAP_OUT"
            INTEGRATION_SKIPPED=true
        fi
    else
        REQUIRED_TOOLS=(
            "functions.update_plan"
            "functions.spawn_agent"
            "functions.send_input"
            "functions.wait"
            "functions.close_agent"
        )

        MISSING=0
        for tool in "${REQUIRED_TOOLS[@]}"; do
            if ! grep -q "$tool" "$CAP_OUT"; then
                echo "    missing tool: $tool"
                MISSING=1
            fi
        done

        if [ "$MISSING" -eq 0 ]; then
            pass "Codex exposes required multi-agent/planner tools"
        else
            fail "Codex toolset missing one or more required tools"
        fi
    fi

    echo ""
fi

# Test 3: Behavior smoke check
if [ "$INTEGRATION_SKIPPED" = false ]; then
    echo "Test 3: Runtime adapter behavior smoke check..."
    SMOKE_OUT="$TMP_DIR/smoke.txt"

    set +e
    run_codex_exec "Use superpowers:using-superpowers. In one short answer, list: runtime adapter actions for task tracking and worker orchestration; the three orchestrator route names; execution mode names; permission mode names; and the required completion verification gate skill." >"$SMOKE_OUT" 2>&1
    SMOKE_EXIT=$?
    set -e

    if [ "$SMOKE_EXIT" -ne 0 ]; then
        if looks_like_auth_error "$SMOKE_OUT"; then
            skip "codex exec unavailable during smoke check (auth/session state)"
        else
            fail "runtime adapter smoke check failed"
            sed 's/^/    /' "$SMOKE_OUT"
        fi
    else
        REQUIRED_TERMS=(
            "track_tasks"
            "spawn_worker"
            "wait_worker"
            "close_worker"
            "subagent-driven-development"
            "executing-plans"
            "dispatching-parallel-agents"
            "parallel-worker"
            "fallback-serial"
            "normal"
            "git-write-restricted"
            "verification-before-completion"
        )

        MISSING=0
        for term in "${REQUIRED_TERMS[@]}"; do
            if ! grep -qi "$term" "$SMOKE_OUT"; then
                echo "    missing term: $term"
                MISSING=1
            fi
        done

        if grep -Eqi "TodoWrite|Task tool" "$SMOKE_OUT"; then
            echo "    found legacy term in smoke output"
            MISSING=1
        fi

        if [ "$MISSING" -eq 0 ]; then
            pass "Model response includes routing, mode, and verification gate terminology"
        else
            fail "Smoke response missing required policy terms or contains legacy terms"
            sed 's/^/    /' "$SMOKE_OUT"
        fi
    fi

    echo ""
fi

echo "========================================"
echo " Test Results Summary"
echo "========================================"
echo ""
echo "  Passed:  $PASS_COUNT"
echo "  Failed:  $FAIL_COUNT"
echo "  Skipped: $SKIP_COUNT"
echo ""

if [ "$FAIL_COUNT" -gt 0 ]; then
    echo "STATUS: FAILED"
    exit 1
fi

echo "STATUS: PASSED"
exit 0
