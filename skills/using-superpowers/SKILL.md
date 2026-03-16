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
Do not treat missing abstract action names as missing capability; resolve native equivalents first.

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
   - repo/worktree scale risk (Unity/monorepo guard)
3. Before any completion claim, invoke `verification-before-completion` with fresh evidence.
4. Run fallback-serial only when the resolved worker profile is `unavailable` after capability resolution/probing.

### Preflight: Large Unity/Monorepo Guard

Use fast probes first (index/metadata only). Avoid recursive scans unless user requests them.

- Unity markers: `ProjectSettings/ProjectVersion.txt`, `Assets/`, `Packages/manifest.json`
- Tracked files: `git ls-files | wc -l`
- Pack size KiB: `git count-objects -v | awk '/size-pack/ {print $2}'`
- Heavy generated tree presence: `Library/`

Classify `large-worktree-risk` when either condition is true:

- Unity markers present and one of: tracked files `>= 200000`, pack size `>= 2000000`, `Library/` exists.
- Tracked files `>= 500000` (any repo type).

When `large-worktree-risk` is true, ask before expensive checks:
"Large Unity/monorepo detected. Skip heavy baseline checks for this run?"
If skipped, record this under known constraints/exclusions and proceed with minimal verification.

Large-worktree cache: Cache: large-worktree-risk=<true/false>, heavy-checks-skipped=<true/false>

## Required Runtime Status Summary (Once Per Session)

Declare one user-facing runtime status summary in the user's language.

The declaration MUST include:

- plain-language execution behavior + mode label (`parallel-worker` or `fallback-serial`)
- plain-language Git write capability + mode label (`normal` or `git-write-restricted`)
- one practical impact sentence

Mode semantics and combined-state examples are defined in `../_shared/runtime-compat.md`.

Reference format:

- `Runtime status: Parallel subtask execution (parallel-worker) + standard Git write capability (normal). Impact: independent tasks run concurrently and normal Git metadata writes can proceed.`
- `Runtime status: Sequential fallback execution (fallback-serial) + restricted Git writes (git-write-restricted). Impact: tasks run one-by-one and repeated non-escalated retries for the same Git metadata write are avoided after lock failures.`

## Invocation Rule

Invoke relevant/requested skills before any response, including clarifications.

- Process skills first
- Implementation skills second

## Integration

For full routing tables, red flags, and detailed invocation flow:

- `routing-policy-reference.md`
- `skill-invocation-reference.md`
