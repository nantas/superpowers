---
name: subagent-driven-development
description: Use when executing implementation plans with independent tasks in the current session
---

# Subagent-Driven Development

Execute a plan in this session with fresh worker context per task and risk-tiered review gates.

**Core principle:** choose the lightest gate that still preserves reliability, then repeat that gate per task.

**Runtime adapter:** `track_tasks`, `spawn_worker`, `message_worker`, `wait_worker`, `close_worker` (see `../_shared/runtime-compat.md`).

## When to Use

Use when:

- a written plan already exists,
- tasks are mostly independent,
- you want to offload task context from the main session,
- you want to stay in the current session.

Use `executing-plans` instead for handoff/batch execution in a separate session.

## User Expectation Statement

Before dispatching any worker, the controller MUST tell the user:

1. which workflow tier will run (`lightweight`, `moderate`, or `high-risk`),
2. the planned stage sequence,
3. that this workflow is being chosen for context offload and reliability,
4. that it may be slower or longer-running than direct main-session execution.

Do not assume "subagent" implies parallel speedup.

## Gate Tiers

Choose one tier per task or task batch:

1. `lightweight`
   - implementer -> self-check
   - use for narrow, low-risk, single-scope work
2. `moderate`
   - implementer -> one reviewer
   - use for normal feature/fix work with moderate correctness risk
3. `high-risk`
   - implementer -> spec reviewer -> code-quality reviewer
   - use for cross-module, high-impact, or ambiguity-heavy work

Default to the lightest tier that the task can safely justify. Do not default small tasks to the full reviewer chain.

## Process

1. Read plan once and extract all tasks with full text/context.
2. Initialize `track_tasks` for all tasks.
3. Announce the selected tier, stage sequence, and expected time/reliability tradeoff to the user.
4. For each task, dispatch workers with exact task text + a minimal task packet (goal, scope, prohibited scope, expected return format, completion criteria).
5. For each task, run the selected gate sequence:
   - dispatch implementer worker with exact task text + context; for Codex-oriented runs, prefer `fork_context=true`,
   - wait for implementer final status via `wait_worker`,
   - close implementer worker via `close_worker`,
   - if tier is `moderate`: dispatch one reviewer, wait, close, and loop until approved,
   - if tier is `high-risk`: dispatch spec reviewer, wait, close, loop until approved; then dispatch code-quality reviewer, wait, close, loop until approved,
   - mark task complete.
6. After all tasks, run final overall code review.
7. Hand off to `superpowers:finishing-a-development-branch`.

## Worker Prompt Assets

- `implementer-prompt.md`
- `spec-reviewer-prompt.md`
- `code-quality-reviewer-prompt.md`

## Required Review Order

1. Spec compliance review first.
2. Code quality review second.

Never invert this order when the selected tier includes both reviewers.

## Review Loop Rules

If either reviewer reports issues:

1. return task to implementer via `message_worker` when follow-up is supported, otherwise spawn a new implementer worker with fix context,
2. implement fixes,
3. wait for implementer final status via `wait_worker`,
4. close implementer worker via `close_worker`,
5. re-run the same reviewer with `spawn_worker` -> `wait_worker` -> `close_worker`; for Codex-oriented runs, prefer `fork_context=true` for reviewer workers too,
6. repeat until approved,
7. only then proceed.

If a worker times out or drifts materially from the task:

1. close or recover the worker as supported by the runtime,
2. fallback to controller execution or fallback-serial mode for that task,
3. keep the same tier semantics even when execution falls back.

## Completion Signal Rules

1. Completion gate source of truth is reviewer/implementer `wait_worker` final status.
2. Never use file changes, log output, or commit appearance as completion signals.
3. For parallel waits, keep `pending_ids` and loop `wait_worker(pending_ids)` until empty.
4. Treat async worker notifications as informational context only, not completion gates.

## Red Flags

Never:

- execute on `main/master` without explicit user consent,
- run implementation workers in parallel on overlapping files,
- ask workers to read the plan file themselves,
- skip the selected review gate for the current tier,
- move to next task while review issues remain open.

Always:

- provide complete task context up front,
- prefer `fork_context=true` when parent context matters,
- resolve worker questions before implementation,
- keep task scope tight and explicit,
- tell the user when the workflow trades speed for reliability/context isolation,
- enforce re-review after each fix round.

## Example

A full walkthrough is in `example-workflow.md`.

Minimal sketch:

```text
Task N (lightweight) -> Implementer completes + self-check -> mark task done
Task N (moderate) -> Implementer completes -> one reviewer approves
Task N (high-risk) -> Spec reviewer finds gap -> Implementer fixes -> Spec reviewer approves
                   -> Code reviewer finds quality issue -> Implementer fixes -> Code reviewer approves
      -> mark task done
```

## Integration

Required companion skills:

- `superpowers:using-git-worktrees`
- `superpowers:requesting-code-review`
- `superpowers:finishing-a-development-branch`

Workers should follow:

- `superpowers:test-driven-development`

Alternative orchestration:

- `superpowers:executing-plans` for separate-session execution.
