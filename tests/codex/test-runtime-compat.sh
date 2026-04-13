#!/usr/bin/env bash
# Test: Codex runtime compatibility for superpowers skills.
# Verifies adapter terminology, Codex tool availability, and wait-based completion gate semantics.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROJECT_DIR="$REPO_ROOT"
RUNTIME_COMPAT_FILE="$REPO_ROOT/skills/_shared/runtime-compat.md"

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
INTEGRATION_SKIPPED=false
RUN_INTEGRATION=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --integration|-i)
            RUN_INTEGRATION=true
            shift
            ;;
        *)
            echo "Ignoring unknown argument: $1" >&2
            shift
            ;;
    esac
done

if [ "${CODEX_RUNTIME_COMPAT_INTEGRATION:-0}" = "1" ]; then
    RUN_INTEGRATION=true
fi

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
rg -n "TodoWrite|Task tool|Task\\(" "$REPO_ROOT/skills" "$REPO_ROOT/docs" "$REPO_ROOT/.opencode/plugins" --glob '!**/plans/**' >"$STATIC_OUT" 2>&1
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

echo "Test 1b: Runtime capability contract safeguards..."
CONTRACT_OUT="$TMP_DIR/contract-scan.txt"

REQUIRED_PATTERNS=(
    "abstract actions, not literal tool names"
    "MUST NOT infer \"capability unavailable\""
    "minimal capability probe"
    "Completion source of truth MUST be"
    "MUST NOT treat file changes, log output, or commit appearance"
    "pending_ids"
    "wait-any"
    "subagent_notification"
    "full-lifecycle"
    "managed-lifecycle"
    "Runtime Equivalence Hints"
    "Codex"
    "OpenCode"
    "Claude Code"
    "Runtime Status Summary Contract"
    "user-facing runtime status summary"
    "plain-language execution behavior"
    "plain-language git write capability"
    "practical impact sentence"
)

MISSING=0
for pattern in "${REQUIRED_PATTERNS[@]}"; do
    if ! grep -qi "$pattern" "$RUNTIME_COMPAT_FILE"; then
        echo "    missing contract pattern: $pattern" | tee -a "$CONTRACT_OUT"
        MISSING=1
    fi
done

if [ "$MISSING" -eq 0 ]; then
    pass "Runtime contract defines alias/probe/profile safeguards across runtimes"
else
    fail "Runtime contract missing required anti-misclassification safeguards"
    sed 's/^/    /' "$CONTRACT_OUT"
fi

echo ""

echo "Test 1c: Large worktree guard policy presence..."
USING_SUPERPOWERS_FILE="$REPO_ROOT/skills/using-superpowers/SKILL.md"
ROUTING_POLICY_FILE="$REPO_ROOT/skills/using-superpowers/routing-policy-reference.md"
USING_GIT_WORKTREES_FILE="$REPO_ROOT/skills/using-git-worktrees/SKILL.md"
WRITING_PLANS_FILE="$REPO_ROOT/skills/writing-plans/SKILL.md"
EXECUTING_PLANS_FILE="$REPO_ROOT/skills/executing-plans/SKILL.md"
SDD_SKILL_FILE="$REPO_ROOT/skills/subagent-driven-development/SKILL.md"
DISPATCH_SKILL_FILE="$REPO_ROOT/skills/dispatching-parallel-agents/SKILL.md"

LARGE_GUARD_PATTERNS=(
    "repo/worktree scale risk"
    "large-worktree-risk"
    "worktree-dirty"
    "large-worktree cache"
    "worktree-exempt"
    "Skip heavy baseline checks"
    "git ls-files | wc -l"
    "git count-objects -v"
    "git status --porcelain"
)

MISSING=0
for pattern in "${LARGE_GUARD_PATTERNS[@]}"; do
    if ! grep -qi "$pattern" "$USING_SUPERPOWERS_FILE" "$ROUTING_POLICY_FILE"; then
        echo "    missing large-worktree pattern: $pattern"
        MISSING=1
    fi
done

if [ "$MISSING" -eq 0 ]; then
    pass "using-superpowers defines fast large-worktree detection and skip prompt policy"
else
    fail "Large-worktree guard policy missing required terms"
fi

if ! grep -qi "large-worktree cache" "$ROUTING_POLICY_FILE"; then
    fail "routing policy missing large-worktree cache reuse guidance"
fi

if ! grep -qi "large-worktree cache" "$USING_GIT_WORKTREES_FILE"; then
    fail "using-git-worktrees missing large-worktree cache reuse guidance"
fi

if ! grep -qi "worktree-exempt" "$USING_SUPERPOWERS_FILE" "$ROUTING_POLICY_FILE" "$USING_GIT_WORKTREES_FILE"; then
    fail "large-worktree policy missing worktree exemption guidance"
fi

if ! grep -qi "heavy-checks-skipped" "$USING_SUPERPOWERS_FILE"; then
    fail "using-superpowers missing heavy-checks-skipped cache field"
fi

if ! grep -qi "worktree-dirty" "$USING_SUPERPOWERS_FILE"; then
    fail "using-superpowers missing worktree-dirty cache field"
fi

if ! grep -qi "worktree-exempt" "$WRITING_PLANS_FILE" "$EXECUTING_PLANS_FILE" "$SDD_SKILL_FILE"; then
    fail "plan workflow skills missing worktree exemption guidance"
fi

WORKTREE_BASE_METADATA_PATTERNS=(
    "branch.<feature-branch>.x-base"
    "Base branch metadata"
)

MISSING=0
for pattern in "${WORKTREE_BASE_METADATA_PATTERNS[@]}"; do
    if ! grep -qi "$pattern" "$USING_GIT_WORKTREES_FILE"; then
        echo "    missing worktree base metadata pattern: $pattern"
        MISSING=1
    fi
done

if [ "$MISSING" -eq 0 ]; then
    pass "using-git-worktrees persists base-branch metadata for finishing workflows"
else
    fail "using-git-worktrees missing base-branch metadata persistence guidance"
fi

EXECUTING_WORKSPACE_PATTERNS=(
    "worktree-exempt=false"
    "REQUIRED SUB-SKILL"
    "superpowers:using-git-worktrees"
    "Never start implementation on"
)

MISSING=0
for pattern in "${EXECUTING_WORKSPACE_PATTERNS[@]}"; do
    if ! grep -qi "$pattern" "$EXECUTING_PLANS_FILE"; then
        echo "    missing executing-plans workspace pattern: $pattern"
        MISSING=1
    fi
done

if [ "$MISSING" -eq 0 ]; then
    pass "executing-plans enforces worktree setup when exemption is false"
else
    fail "executing-plans missing explicit worktree setup enforcement"
fi

PREFLIGHT_GATE_FILES=(
    "$USING_GIT_WORKTREES_FILE"
    "$WRITING_PLANS_FILE"
    "$EXECUTING_PLANS_FILE"
    "$SDD_SKILL_FILE"
    "$DISPATCH_SKILL_FILE"
)

MISSING=0
for file in "${PREFLIGHT_GATE_FILES[@]}"; do
    if ! grep -qi "using-superpowers preflight" "$file"; then
        echo "    missing preflight gate phrase in: $file"
        MISSING=1
    fi
    if ! grep -qi "If preflight cache is absent" "$file"; then
        echo "    missing absent-cache stop phrase in: $file"
        MISSING=1
    fi
    if ! grep -qi "invoke using-superpowers first" "$file"; then
        echo "    missing preflight fallback phrase in: $file"
        MISSING=1
    fi
done

if [ "$MISSING" -eq 0 ]; then
    pass "workflow skills require using-superpowers preflight before proceeding"
else
    fail "workflow skills missing using-superpowers preflight gate language"
fi

echo ""

echo "Test 1c2: request_user_input preflight policy presence..."
REQUEST_INPUT_PATTERNS=(
    "request_user_input"
    "If unavailable"
    "settings"
    "enable"
)

MISSING=0
for pattern in "${REQUEST_INPUT_PATTERNS[@]}"; do
    if ! grep -qi "$pattern" "$USING_SUPERPOWERS_FILE"; then
        echo "    missing request_user_input preflight pattern: $pattern"
        MISSING=1
    fi
done

if [ "$MISSING" -eq 0 ]; then
    pass "using-superpowers preflight documents request_user_input availability check"
else
    fail "using-superpowers preflight missing request_user_input availability guidance"
fi

echo ""

echo "Test 1d: Finishing base-branch detection guidance..."
FINISHING_BRANCH_FILE="$REPO_ROOT/skills/finishing-a-development-branch/SKILL.md"

BASE_BRANCH_PATTERNS=(
    "branch.<feature-branch>.x-base"
    "branch: Created from"
    "HEAD branch"
    "attached worktree"
    "Do not assume main/master"
    "candidates disagree"
    "ask the user to confirm base branch"
)

MISSING=0
for pattern in "${BASE_BRANCH_PATTERNS[@]}"; do
    if ! grep -qi "$pattern" "$FINISHING_BRANCH_FILE"; then
        echo "    missing base-branch pattern: $pattern"
        MISSING=1
    fi
done

if [ "$MISSING" -eq 0 ]; then
    pass "finishing-a-development-branch documents base-branch detection from worktree origin"
else
    fail "finishing-a-development-branch missing base-branch detection guidance"
fi

if grep -qi "reflog show --format=%gs --reverse" "$FINISHING_BRANCH_FILE"; then
    fail "finishing-a-development-branch still uses incompatible reflog --reverse command"
else
    pass "finishing-a-development-branch avoids reflog --reverse incompatibility"
fi

FINISHING_HYGIENE_PATTERNS=(
    "git status --porcelain"
    "Do not proceed with uncommitted changes"
    "<base-branch> == <feature-branch>"
    "git -C <other-worktree-path> status --porcelain"
    "dirty in another worktree"
    "Do not use blanket .*git reset"
    "Print base-branch evidence"
    "Only cleanup for Options 1 and 4"
)

MISSING=0
for pattern in "${FINISHING_HYGIENE_PATTERNS[@]}"; do
    if ! grep -qi "$pattern" "$FINISHING_BRANCH_FILE"; then
        echo "    missing finishing hygiene pattern: $pattern"
        MISSING=1
    fi
done

if [ "$MISSING" -eq 0 ]; then
    pass "finishing-a-development-branch enforces clean-tree and non-self-merge safeguards"
else
    fail "finishing-a-development-branch missing clean-tree/non-self-merge safeguards"
fi

echo ""

echo "Test 1f: Codex multi-agent reliability guardrails..."
RELIABILITY_PATTERNS=(
    "fork_context=true"
    "pending_ids"
    "wait-any"
    "fallback"
    "close_agent"
    "max_steps"
    "must_stop_after"
    "forbidden_write_set"
    "first timeout"
    "second timeout"
    "third timeout"
)

MISSING=0
for pattern in "${RELIABILITY_PATTERNS[@]}"; do
    if ! grep -qi "$pattern" "$RUNTIME_COMPAT_FILE" "$DISPATCH_SKILL_FILE" "$SDD_SKILL_FILE"; then
        echo "    missing multi-agent reliability pattern: $pattern" | tee -a "$CONTRACT_OUT"
        MISSING=1
    fi
done

if [ "$MISSING" -eq 0 ]; then
    pass "Codex multi-agent docs define fork, wait-any, fallback, and close safeguards"
else
    fail "Codex multi-agent docs missing required reliability safeguards"
    sed 's/^/    /' "$CONTRACT_OUT"
fi

echo ""

echo "Test 1g: Plan execution checkpoint policy..."
PLAN_POLICY_PATTERNS=(
    "User Verification: required|not-required"
    "missing, treat it as not-required"
    "default cadence is every 3 tasks"
    "do not wait for feedback"
    "status ledger"
    "Task | Status | Facts"
    "Design Traceability Matrix"
    "Plan Quality Check"
    "Optional, Non-Blocking"
    "Do not require an independent subagent review as a hard gate for handoff"
    "Task blocks define executable steps and verification commands"
    "design_coverage_status"
    "authenticity_status"
    "semantic_closure_status"
    "blocked"
    "unexpected result"
    "human verification gate"
    "Gate Scope"
    "What to Verify"
    "Pass Criteria"
    "Evidence"
    "Decision"
    "通过"
    "不通过"
    "Hand off directly to superpowers:finishing-a-development-branch"
    "Do not ask whether to enter finishing flow"
)

MISSING=0
for pattern in "${PLAN_POLICY_PATTERNS[@]}"; do
    if ! grep -qi "$pattern" "$WRITING_PLANS_FILE" "$EXECUTING_PLANS_FILE"; then
        echo "    missing plan policy pattern: $pattern"
        MISSING=1
    fi
done

if [ "$MISSING" -eq 0 ]; then
    pass "writing/executing plans define dynamic batches, status-ledger updates, and non-duplicative finishing handoff"
else
    fail "plan execution policy missing required checkpoint/status semantics"
fi

echo ""

echo "Test 1h: Writing-skills boundary and clarification contract..."
WRITING_SKILLS_FILE="$REPO_ROOT/skills/writing-skills/SKILL.md"
WRITING_SKILLS_SUBAGENT_FILE="$REPO_ROOT/skills/writing-skills/testing-skills-with-subagents.md"

BOUNDARY_PATTERNS=(
    "only skill that performs runtime/capability detection"
    "downstream skills consume preflight cache"
    "must not repeat runtime probing"
    "request_user_input_available"
)

WRITING_SKILLS_PATTERNS=(
    "requires completed .*using-superpowers preflight"
    "If preflight cache is absent"
    "invoke .*using-superpowers"
    "Do not run runtime/capability probing"
    "request_user_input_available"
    "one decision boundary per interaction"
)

SUBAGENT_PATTERNS=(
    "Do not perform runtime probing inside scenario tests"
    "worker lifecycle is available from preflight"
    "wait-based completion"
    "cleanup semantics"
)

MISSING=0
for pattern in "${BOUNDARY_PATTERNS[@]}"; do
    if ! grep -qi "$pattern" "$USING_SUPERPOWERS_FILE"; then
        echo "    missing using-superpowers boundary pattern: $pattern"
        MISSING=1
    fi
done

for pattern in "${WRITING_SKILLS_PATTERNS[@]}"; do
    if ! grep -qi "$pattern" "$WRITING_SKILLS_FILE"; then
        echo "    missing writing-skills pattern: $pattern"
        MISSING=1
    fi
done

for pattern in "${SUBAGENT_PATTERNS[@]}"; do
    if ! grep -qi "$pattern" "$WRITING_SKILLS_SUBAGENT_FILE"; then
        echo "    missing writing-skills subagent pattern: $pattern"
        MISSING=1
    fi
done

if [ "$MISSING" -eq 0 ]; then
    pass "Writing-skills docs enforce preflight boundary and incremental clarification contract"
else
    fail "Writing-skills boundary/clarification contract missing required patterns"
fi

echo ""

echo "Test 1e: Subagent lifecycle template safeguards..."
IMPLEMENTER_PROMPT_FILE="$REPO_ROOT/skills/subagent-driven-development/implementer-prompt.md"
SPEC_REVIEWER_PROMPT_FILE="$REPO_ROOT/skills/subagent-driven-development/spec-reviewer-prompt.md"
QUALITY_REVIEWER_PROMPT_FILE="$REPO_ROOT/skills/subagent-driven-development/code-quality-reviewer-prompt.md"
REQUESTING_REVIEWER_PROMPT_FILE="$REPO_ROOT/skills/requesting-code-review/code-reviewer.md"

MISSING=0
if ! grep -q 'spawn_worker` -> `wait_worker` -> `close_worker' "$IMPLEMENTER_PROMPT_FILE"; then
    echo "    implementer prompt missing spawn->wait->close lifecycle"
    MISSING=1
fi

if ! grep -q 'spawn_worker` -> `wait_worker` -> `close_worker' "$SPEC_REVIEWER_PROMPT_FILE"; then
    echo "    spec reviewer prompt missing spawn->wait->close lifecycle"
    MISSING=1
fi

if ! grep -q 'spawn_worker` -> `wait_worker` -> `close_worker' "$QUALITY_REVIEWER_PROMPT_FILE"; then
    echo "    code-quality reviewer prompt missing spawn->wait->close lifecycle"
    MISSING=1
fi

SDD_PATTERNS=(
    "Completion gate source of truth"
    "Never use file changes, log output, or commit appearance"
    "pending_ids"
    "max_steps"
    "must_stop_after"
    "forbidden_write_set"
    "first timeout"
    "second timeout"
    "third timeout"
)

for pattern in "${SDD_PATTERNS[@]}"; do
    if ! grep -qi "$pattern" "$SDD_SKILL_FILE"; then
        echo "    subagent-driven-development missing pattern: $pattern"
        MISSING=1
    fi
done

REVIEWER_PATTERNS=(
    "any write = review failure"
    "checked_files"
    "no-write attestation"
)

for pattern in "${REVIEWER_PATTERNS[@]}"; do
    if ! grep -qi "$pattern" "$SPEC_REVIEWER_PROMPT_FILE" "$QUALITY_REVIEWER_PROMPT_FILE" "$REQUESTING_REVIEWER_PROMPT_FILE"; then
        echo "    reviewer prompts missing pattern: $pattern"
        MISSING=1
    fi
done

if [ "$MISSING" -eq 0 ]; then
    pass "Subagent workflow/templates require wait-based completion gates and lifecycle closure"
else
    fail "Subagent workflow/templates missing wait lifecycle and completion-gate safeguards"
fi

echo ""

# Integration tests are opt-in because they invoke `codex exec`.
if [ "$RUN_INTEGRATION" = false ]; then
    skip "integration checks disabled by default; pass --integration to enable codex exec checks"
    INTEGRATION_SKIPPED=true
elif ! command -v codex >/dev/null 2>&1; then
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
    run_codex_exec "Use superpowers:using-superpowers. In one short answer, list: runtime adapter actions for task tracking and worker orchestration; the three orchestrator route names; execution mode names; permission mode names; the required completion verification gate skill; and a user-facing runtime status summary that combines execution + permission state in plain language. Also include these exact phrases: 'wait is completion source of truth', 'no artifact polling', 'wait-any needs pending_ids loop', and 'user-facing runtime status summary'." >"$SMOKE_OUT" 2>&1
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
            "wait is completion source of truth"
            "no artifact polling"
            "wait-any needs pending_ids loop"
            "user-facing runtime status summary"
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
