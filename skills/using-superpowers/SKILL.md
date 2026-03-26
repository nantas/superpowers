---
name: using-superpowers
description: Use when starting any conversation - establishes how to find and use skills through runtime adapters before responding
---

<EXTREMELY-IMPORTANT>
If there is even a 1% chance a skill applies, you MUST invoke it before acting.

If a skill applies, you do not have discretion to skip it.
</EXTREMELY-IMPORTANT>

## Runtime Adapter

Use capability-based actions from `../_shared/runtime-compat.md`: `load_skill`, `track_tasks`, `spawn_worker`, `message_worker`, `wait_worker`, `close_worker`.
Map to native tools after alias resolution.

## Global Multi-Agent Enforcement Policy (Mandatory)

When work involves written plans or 2+ domains:

1. Select exactly one orchestrator: `subagent-driven-development`, `executing-plans`, or `dispatching-parallel-agents`.
2. Run preflight before the first worker spawn: permissions/locks, dependencies/tooling, constraints/exclusions, branch/worktree readiness, repo/worktree scale risk (Unity/monorepo guard), and `request_user_input` availability.
3. Before any completion claim, invoke `verification-before-completion` with fresh evidence.
4. Run `fallback-serial` only when the resolved worker profile is `unavailable` after capability resolution/probing.

Downstream workflow skills must treat this `using-superpowers preflight` as a hard gate.
If preflight cache is absent, they must stop and invoke using-superpowers first.

### Preflight: `request_user_input` Availability

In Codex, check whether `request_user_input` is available before `brainstorming` or `brainstorming-complex`.
If unavailable, remind the user to enable it in settings before long clarification loops. If available, use it and batch simple related questions.

### Preflight: Large Unity/Monorepo Guard

Use fast probes first (index/metadata only). Avoid recursive scans unless requested.
Unity markers: `ProjectSettings/ProjectVersion.txt`, `Assets/`, `Packages/manifest.json`.
Probe with `git ls-files | wc -l`, `git count-objects -v | awk '/size-pack/ {print $2}'`, and `Library/`.

Classify `large-worktree-risk` when Unity markers are present plus tracked files `>= 200000`, pack size `>= 2000000`, or `Library/` exists; or any repo has tracked files `>= 500000`.
If `large-worktree-risk` is true, ask "Large Unity/monorepo detected. Skip heavy baseline checks for this run?" If skipped, record exclusion, proceed with minimal verification, and set `worktree-exempt=true` to bypass `using-git-worktrees` for this session.

Preflight cache: Cache: large-worktree-risk=<true/false>, worktree-exempt=<true/false>, heavy-checks-skipped=<true/false>

### Preflight Output Contract (Normative)

`using-superpowers` is the only skill that performs runtime/capability detection.
Downstream skills consume preflight cache and must not repeat runtime probing.
Resolve Codex clarification capability once and publish `request_user_input_available` for downstream reuse.

Required preflight cache fields:
- `worker_profile`: `full-lifecycle | managed-lifecycle | unavailable`
- `execution_mode`: `parallel-worker | fallback-serial`
- `permission_mode`: `normal | git-write-restricted`
- `request_user_input_available`: `true | false`
- `large-worktree-risk`: `true | false`
- `worktree-exempt`: `true | false`
- `heavy-checks-skipped`: `true | false`

## Required Runtime Status Summary (Once Per Session)

Declare one user-facing runtime status summary in user language.
Include plain-language execution behavior + mode label (`parallel-worker` or `fallback-serial`), plain-language Git write capability + mode label (`normal` or `git-write-restricted`), and one impact sentence.

## Invocation Rule

Invoke relevant/requested skills before any response, including clarifications: process skills first, implementation skills second.

## Integration

For details, see `routing-policy-reference.md` and `skill-invocation-reference.md`.
