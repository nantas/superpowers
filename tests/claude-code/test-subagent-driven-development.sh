#!/usr/bin/env bash
# Test: subagent-driven-development skill
# Verifies that the skill is loaded and follows correct workflow
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: subagent-driven-development skill ==="
echo ""

# Test 1: Verify skill can be loaded
echo "Test 1: Skill loading..."

output=$(run_claude "What is the subagent-driven-development skill? Describe its key steps briefly." 30)

if assert_contains "$output" "subagent-driven-development\|Subagent-Driven Development\|Subagent Driven" "Skill is recognized"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "Load Plan\|read.*plan\|extract.*tasks" "Mentions loading plan"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 2: Verify skill describes correct workflow order
echo "Test 2: Workflow ordering..."

output=$(run_claude "In the subagent-driven-development skill, what comes first: spec compliance review or code quality review? Answer in one sentence with explicit before/after wording." 30)

if assert_contains "$output" "spec.*compliance.*before.*code.*quality\\|spec.*compliance.*comes first.*code.*quality\\|spec.*compliance.*first.*code.*quality\\|code.*quality.*after.*spec.*compliance\\|spec compliance review comes before code quality review" "Spec compliance before code quality"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 3: Verify self-review is mentioned
echo "Test 3: Self-review requirement..."

output=$(run_claude "Does the subagent-driven-development skill require implementers to do self-review? What should they check?" 30)

if assert_contains "$output" "self-review\|self review" "Mentions self-review"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "completeness\|Completeness" "Checks completeness"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 4: Verify plan is read once
echo "Test 4: Plan reading efficiency..."

output=$(run_claude "In subagent-driven-development, how many times should the controller read the plan file? When does this happen?" 30)

if assert_contains "$output" "once\|one time\|single" "Read plan once"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "Step 1\|beginning\|start\|Load Plan" "Read at beginning"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 5: Verify spec compliance reviewer is skeptical
echo "Test 5: Spec compliance reviewer mindset..."

output=$(run_claude "What is the spec compliance reviewer's attitude toward the implementer's report in subagent-driven-development?" 30)

if assert_contains "$output" "not trust\|don't trust\|skeptical\|verify.*independently\|suspiciously" "Reviewer is skeptical"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "read.*code\|inspect.*code\|verify.*code" "Reviewer reads code"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 6: Verify review loops
echo "Test 6: Review loop requirements..."

output=$(run_claude "In subagent-driven-development, what happens if a reviewer finds issues? Is it a one-time review or a loop?" 30)

if assert_contains "$output" "loop\|again\|repeat\|until.*approved\|until.*compliant" "Review loops mentioned"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "implementer.*fix\|fix.*issues" "Implementer fixes issues"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 7: Verify full task text is provided
echo "Test 7: Task context provision..."

output=$(run_claude "In subagent-driven-development, how does the controller provide task information to the implementer subagent? Does it make them read a file or provide it directly?" 30)

if assert_contains "$output" "provide.*directly\|full.*text\|paste\|include.*prompt" "Provides text directly"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "does.*not.*read.*file\|don't.*read.*file\|not make.*read.*file" "Doesn't make subagent read file"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 8: Verify worktree exemption for large Unity repos
echo "Test 8: Worktree exemption..."

output=$(run_claude "In subagent-driven-development, what happens in a large Unity repo that matches the large-worktree-risk guard? Should it still require using-git-worktrees before starting?" 30)

if assert_contains "$output" "worktree-exempt\|skip.*using-git-worktrees\|do not.*using-git-worktrees\|bypass.*worktree" "Mentions worktree exemption"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 9: Verify reviewer no-write constraint
echo "Test 9: Reviewer no-write contract..."

output=$(run_claude "In subagent-driven-development, can a reviewer edit code while reviewing? What output fields prove it stayed read-only?" 30)

if assert_contains "$output" "no.*write\|read-only\|read only\|review failure" "Reviewer write prohibition mentioned"; then
    : # pass
else
    exit 1
fi

if assert_contains "$output" "checked_files\|no-write attestation\|attestation" "Reviewer evidence fields mentioned"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 10: Verify timeout escalation policy
echo "Test 10: Timeout escalation..."

output=$(run_claude "In subagent-driven-development, what should the controller do on first, second, and third worker timeout?" 30)

if assert_contains "$output" "first.*short.*wait\|second.*interrupt\|third.*fallback\|timeout.*escalation" "Timeout escalation policy mentioned"; then
    : # pass
else
    exit 1
fi

echo ""

# Test 11: Verify main branch warning
echo "Test 11: Main branch red flag..."

output=$(run_claude "In subagent-driven-development, is it okay to start implementation directly on the main branch?" 30)

if assert_contains "$output" "worktree\|feature.*branch\|not.*main\|never.*main\|avoid.*main\|don't.*main\|consent\|permission" "Warns against main branch"; then
    : # pass
else
    exit 1
fi

echo ""

echo "=== All subagent-driven-development skill tests passed ==="
