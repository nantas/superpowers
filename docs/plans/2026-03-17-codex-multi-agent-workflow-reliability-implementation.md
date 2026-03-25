# Codex Multi-Agent Workflow Reliability Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Update Superpowers multi-agent skills to prioritize context offload and reliability under Codex semantics, with automated test coverage before manual dogfooding.

**Architecture:** Introduce Codex-specific shared policy guardrails first, then update the two affected workflow skills to consume those guardrails. Drive the rollout with failing tests that capture wait-any handling, default context forking, timeout/fallback behavior, user expectation setting, and tiered review gates.

**Tech Stack:** Markdown skill docs, Bash test scripts in `tests/`, existing shell tooling (`rg`, `bash`, `sed`), repository test runners.

---

### Task 1: Add failing Codex contract tests for shared multi-agent safeguards

**Files:**
- Modify: `tests/codex/test-runtime-compat.sh`
- Modify: `tests/codex/run-tests.sh`
- Test: `tests/codex/test-runtime-compat.sh`

**Step 1: Read the current Codex runtime compatibility tests**

Run: `sed -n '1,240p' tests/codex/test-runtime-compat.sh`
Expected: existing assertions for runtime compatibility wording and current policy language.

**Step 2: Add failing assertions for the new shared safeguards**

Add assertions that fail until the relevant skill/shared policy docs mention:

```bash
assert_contains "fork_context=true"
assert_contains "pending_ids"
assert_contains "wait-any"
assert_contains "fallback"
assert_contains "close_agent"
```

The test should check the shared guidance and any directly referenced skill docs that define Codex worker lifecycle behavior.

**Step 3: Run the Codex contract test and confirm RED**

Run: `bash tests/codex/test-runtime-compat.sh`
Expected: FAIL because one or more new assertions are not yet satisfied.

**Step 4: Ensure the Codex test runner still includes this test**

Run: `sed -n '1,200p' tests/codex/run-tests.sh`
Expected: the runtime compatibility test remains part of the default Codex suite.

**Step 5: Commit the red test change**

```bash
git add tests/codex/test-runtime-compat.sh tests/codex/run-tests.sh
git commit -m "test(codex): add multi-agent reliability contract assertions"
```

### Task 2: Add failing tests for `subagent-driven-development` expectation setting and gate tiering

**Files:**
- Modify: `tests/explicit-skill-requests/run-all.sh`
- Create: `tests/explicit-skill-requests/prompts/subagent-driven-development-expectations.txt`
- Create: `tests/explicit-skill-requests/prompts/subagent-driven-development-tiering.txt`
- Modify: one or more explicit skill request assertions/scripts under `tests/explicit-skill-requests/`
- Test: `tests/explicit-skill-requests/run-all.sh`

**Step 1: Inspect the current explicit skill request test harness**

Run: `rg -n "subagent-driven-development|explicit-skill" tests/explicit-skill-requests`
Expected: existing prompt fixtures and assertion scripts for explicit skill invocation behavior.

**Step 2: Add a prompt fixture that should force expectation setting**

Create a prompt that explicitly asks for `subagent-driven-development` on a task where user context savings matter.

Expected response requirements:

```text
- names the workflow tier
- describes the stage sequence
- says it may be slower than direct execution
- explains the benefit as context offload/reliability
```

**Step 3: Add a prompt fixture that should force lightweight or moderate tier selection**

Create a small-scope task prompt that fails unless the response avoids defaulting to the full reviewer chain.

**Step 4: Run explicit skill request tests and confirm RED**

Run: `bash tests/explicit-skill-requests/run-all.sh`
Expected: FAIL until the skill text is updated.

**Step 5: Commit the red test change**

```bash
git add tests/explicit-skill-requests
git commit -m "test(skills): cover subagent workflow expectations and gate tiering"
```

### Task 3: Add failing trigger tests for context-offload-driven routing

**Files:**
- Create: `tests/skill-triggering/prompts/context-offload-multi-agent.txt`
- Modify: `tests/skill-triggering/run-all.sh`
- Modify: `tests/skill-triggering/run-test.sh`
- Test: `tests/skill-triggering/run-all.sh`

**Step 1: Inspect current trigger fixtures and assertions**

Run: `ls tests/skill-triggering/prompts && sed -n '1,240p' tests/skill-triggering/run-test.sh`
Expected: current prompt fixtures and matching logic for skill-triggering behavior.

**Step 2: Add a prompt where the user prioritizes saving main-session context rather than speed**

The prompt should describe multiple independent high-context domains and explicitly mention session context pressure.

Expected behavior:

```text
The response should route to a multi-agent workflow even without a "make this faster" request.
```

**Step 3: Run trigger tests and confirm RED**

Run: `bash tests/skill-triggering/run-all.sh`
Expected: FAIL until routing language is updated.

**Step 4: Commit the red test change**

```bash
git add tests/skill-triggering
git commit -m "test(triggers): route multi-agent workflows for context offload cases"
```

### Task 4: Update shared Codex multi-agent guidance

**Files:**
- Modify: `skills/_shared/runtime-compat.md`
- Modify: any shared policy reference used by multi-agent workflow skills
- Test: `bash tests/codex/test-runtime-compat.sh`

**Step 1: Read the current shared runtime compatibility guidance**

Run: `sed -n '1,260p' skills/_shared/runtime-compat.md`
Expected: current adapter guidance for worker lifecycle actions.

**Step 2: Add the new shared guardrails**

Add concise rules covering:

```md
- default fork_context=true for Codex-oriented worker dispatch
- worker task packet minimum fields
- wait-any means maintain pending_ids until empty
- timeout budgets require fallback behavior
- close_agent is cleanup, not completion proof
```

**Step 3: Keep wording reusable across both workflow skills**

Do not hardcode `dispatching-parallel-agents` or `subagent-driven-development` specifics in the shared layer.

**Step 4: Run the Codex contract test and confirm GREEN**

Run: `bash tests/codex/test-runtime-compat.sh`
Expected: PASS for the shared-policy assertions added in Task 1, or fewer remaining failures limited to workflow-specific skills.

**Step 5: Commit**

```bash
git add skills/_shared/runtime-compat.md
git commit -m "docs(runtime): codify Codex multi-agent reliability safeguards"
```

### Task 5: Refactor `dispatching-parallel-agents` around context offload and reliable waits

**Files:**
- Modify: `skills/dispatching-parallel-agents/SKILL.md`
- Modify: `skills/dispatching-parallel-agents/session-example.md`
- Test: `bash tests/codex/test-runtime-compat.sh`
- Test: `bash tests/skill-triggering/run-all.sh`

**Step 1: Read the current skill and example**

Run: `sed -n '1,260p' skills/dispatching-parallel-agents/SKILL.md && sed -n '1,260p' skills/dispatching-parallel-agents/session-example.md`
Expected: current emphasis on domain partitioning and wait-any loop example.

**Step 2: Update the skill framing**

Revise the skill so it states:

```md
- use parallel workers to offload independent high-context domains
- speedup is optional, not promised
- fork_context=true by default unless prompt is fully self-contained
- maintain pending_ids for wait-any semantics
- apply timeout + fallback-serial rules
```

**Step 3: Update the example walkthrough**

Show a controller that:

```text
- builds domain-specific task packets
- spawns with fork_context=true
- waits in a pending_ids loop
- recovers timed-out work in controller context when needed
```

**Step 4: Run targeted tests**

Run: `bash tests/codex/test-runtime-compat.sh`
Expected: PASS for dispatch-related assertions.

Run: `bash tests/skill-triggering/run-all.sh`
Expected: PASS for the new context-offload routing case.

**Step 5: Commit**

```bash
git add skills/dispatching-parallel-agents/SKILL.md skills/dispatching-parallel-agents/session-example.md
git commit -m "docs(skills): make parallel agents context-offload first"
```

### Task 6: Refactor `subagent-driven-development` to use tiered gates and expectation statements

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md`
- Modify: `skills/subagent-driven-development/example-workflow.md`
- Test: `bash tests/explicit-skill-requests/run-all.sh`
- Test: `bash tests/codex/test-runtime-compat.sh`

**Step 1: Read the current workflow skill and example**

Run: `sed -n '1,320p' skills/subagent-driven-development/SKILL.md && sed -n '1,260p' skills/subagent-driven-development/example-workflow.md`
Expected: current fixed full-gate workflow and example.

**Step 2: Replace fixed gating with tiered gating**

Document three levels:

```md
- lightweight: implementer + self-check
- moderate: implementer + one reviewer
- high-risk: implementer + spec reviewer + code-quality reviewer
```

Add concrete decision guidance so the workflow does not over-escalate small tasks.

**Step 3: Add the mandatory pre-execution user statement**

Require the controller to state:

```text
- selected tier
- stage sequence
- likely time tradeoff
- reason for using the workflow: context offload and reliability
```

**Step 4: Default reviewers to forked context**

Add wording that reviewers also inherit context by default unless a self-contained isolated review is explicitly desired.

**Step 5: Update the example walkthrough**

The example should show tier selection and user expectation management before worker dispatch.

**Step 6: Run targeted tests**

Run: `bash tests/explicit-skill-requests/run-all.sh`
Expected: PASS for expectation-setting and tier-selection cases.

Run: `bash tests/codex/test-runtime-compat.sh`
Expected: PASS for workflow-specific Codex assertions tied to this skill.

**Step 7: Commit**

```bash
git add skills/subagent-driven-development/SKILL.md skills/subagent-driven-development/example-workflow.md
git commit -m "docs(skills): tier subagent development gates for reliability"
```

### Task 7: Run the full relevant verification set and document results

**Files:**
- Modify: `docs/testing.md`
- Optionally modify: any test README that needs new coverage documentation
- Test: `bash tests/codex/run-tests.sh`
- Test: `bash tests/skill-triggering/run-all.sh`
- Test: `bash tests/explicit-skill-requests/run-all.sh`

**Step 1: Update testing documentation**

Add short entries for the new or changed coverage:

```md
- Codex multi-agent reliability contract assertions
- subagent expectation-setting coverage
- context-offload trigger coverage
```

**Step 2: Run the Codex suite**

Run: `bash tests/codex/run-tests.sh`
Expected: PASS

**Step 3: Run trigger tests**

Run: `bash tests/skill-triggering/run-all.sh`
Expected: PASS

**Step 4: Run explicit-skill-request tests**

Run: `bash tests/explicit-skill-requests/run-all.sh`
Expected: PASS

**Step 5: Record exact commands and outcomes**

Prepare a short verification summary for the eventual PR or handoff.

**Step 6: Commit**

```bash
git add docs/testing.md
git commit -m "docs: record multi-agent reliability test coverage"
```
