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
   - answer implementer questions before coding,
   - dispatch spec reviewer; fix until spec-compliant,
   - dispatch code-quality reviewer; fix until approved,
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

1. return task to the same implementer worker,
2. implement fixes,
3. re-run the same reviewer,
4. repeat until approved,
5. only then proceed.

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
