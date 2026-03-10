---
name: subagent-driven-development
description: Use when executing implementation plans with independent tasks in the current session
---

# Subagent-Driven Development

Execute a plan in this session with fresh worker context per task and mandatory review gates.

**Core principle:** implementer -> spec review -> code-quality review, repeated per task.

**Runtime adapter:** `track_tasks`, `spawn_worker`, `message_worker`, `wait_worker`, `close_worker` (see `../_shared/runtime-compat.md`).

## When to Use

Use when:

- a written plan already exists,
- tasks are mostly independent,
- you want to stay in the current session.

Use `executing-plans` instead for handoff/batch execution in a separate session.

## Process

1. Read plan once and extract all tasks with full text/context.
2. Initialize `track_tasks` for all tasks.
3. For each task, run full gate sequence:
   - dispatch implementer worker with exact task text + context,
   - wait for implementer final status via `wait_worker`,
   - close implementer worker via `close_worker`,
   - dispatch spec reviewer,
   - wait for spec reviewer final status via `wait_worker`,
   - close spec reviewer via `close_worker`,
   - if spec review finds issues: implement fixes and re-run spec review until approved,
   - dispatch code-quality reviewer,
   - wait for code-quality reviewer final status via `wait_worker`,
   - close code-quality reviewer via `close_worker`,
   - if code-quality review finds issues: implement fixes and re-run code-quality review until approved,
   - mark task complete.
4. After all tasks, run final overall code review.
5. Hand off to `superpowers:finishing-a-development-branch`.

## Worker Prompt Assets

- `implementer-prompt.md`
- `spec-reviewer-prompt.md`
- `code-quality-reviewer-prompt.md`

## Required Review Order

1. Spec compliance review first.
2. Code quality review second.

Never invert this order.

## Review Loop Rules

If either reviewer reports issues:

1. return task to implementer via `message_worker` when follow-up is supported, otherwise spawn a new implementer worker with fix context,
2. implement fixes,
3. wait for implementer final status via `wait_worker`,
4. close implementer worker via `close_worker`,
5. re-run the same reviewer with `spawn_worker` -> `wait_worker` -> `close_worker`,
6. repeat until approved,
7. only then proceed.

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
- skip either review gate,
- move to next task while review issues remain open.

Always:

- provide complete task context up front,
- resolve worker questions before implementation,
- keep task scope tight and explicit,
- enforce re-review after each fix round.

## Example

A full walkthrough is in `example-workflow.md`.

Minimal sketch:

```text
Task N -> Implementer completes + self-review
      -> Spec reviewer finds gap -> Implementer fixes -> Spec reviewer approves
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
