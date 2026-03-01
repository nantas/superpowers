---
name: using-superpowers
description: Use when starting any conversation - establishes how to find and use skills through runtime adapters before responding
---

<EXTREMELY-IMPORTANT>
If there is even a 1% chance a skill applies, you MUST invoke it before acting.

If a skill applies, you do not have discretion to skip it.
</EXTREMELY-IMPORTANT>

## Runtime Adapter

Use capability-based actions from `../_shared/runtime-compat.md`:

- `load_skill`
- `track_tasks`
- `spawn_worker`
- `message_worker`
- `wait_worker`
- `close_worker`

Map these to platform-native tools.

## Global Multi-Agent Enforcement Policy (Mandatory)

When work involves a written plan or 2+ independent domains:

1. Select exactly one orchestrator:
   - `subagent-driven-development` for same-session plan execution
   - `executing-plans` for batch/checkpoint execution
   - `dispatching-parallel-agents` for independent concurrent domains
2. Run preflight before the first worker spawn:
   - permissions/locks
   - dependencies/tooling
   - known constraints/exclusions
   - branch/worktree readiness
3. Before any completion claim, invoke `verification-before-completion` with fresh evidence.
4. If worker APIs are incomplete, run fallback-serial flow with equivalent checkpoints.

## Required Mode Declaration (Once Per Session)

Declare:

- execution mode: `parallel-worker` or `fallback-serial`
- permission mode: `normal` or `git-write-restricted`

Mode semantics are defined in `../_shared/runtime-compat.md`.

## Invocation Rule

Invoke relevant/requested skills before any response, including clarifications.

- Process skills first (for approach discipline)
- Implementation skills second (for execution details)

## Integration

For full routing tables, red flags, and detailed invocation flow:

- `routing-policy-reference.md`
- `skill-invocation-reference.md`
