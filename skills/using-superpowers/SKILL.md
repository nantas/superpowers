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
Map them to native tools. Resolve aliases first; do not treat missing abstract names as missing capability.

## Global Multi-Agent Enforcement Policy (Mandatory)

When work involves a written plan or 2+ independent domains:

1. Select exactly one orchestrator: `subagent-driven-development`, `executing-plans`, or `dispatching-parallel-agents`.
2. Run preflight before the first worker spawn: permissions/locks, dependencies/tooling, known constraints/exclusions, branch/worktree readiness, repo/worktree scale risk (Unity/monorepo guard), and `request_user_input` availability for clarification-heavy workflows.
3. Before any completion claim, invoke `verification-before-completion` with fresh evidence.
4. Run `fallback-serial` only when the resolved worker profile is `unavailable` after capability resolution/probing.

Downstream workflow skills must treat this `using-superpowers preflight` as a hard gate.
If preflight cache is absent, they must stop and invoke using-superpowers first.

### Preflight: `request_user_input` Availability

In Codex agent environments, check whether `request_user_input` is available before starting `brainstorming` or `brainstorming-complex`.
If unavailable, remind the user to enable it in settings before a long clarification loop. If available, prioritize it and batch simple related questions into one submission.

### Preflight: Large Unity/Monorepo Guard

Use fast probes first (index/metadata only). Avoid recursive scans unless requested.
Unity markers: `ProjectSettings/ProjectVersion.txt`, `Assets/`, `Packages/manifest.json`.
Probe with `git ls-files | wc -l`, `git count-objects -v | awk '/size-pack/ {print $2}'`, and `Library/`.

Classify `large-worktree-risk` when Unity markers are present plus tracked files `>= 200000`, pack size `>= 2000000`, or `Library/` exists; or any repo has tracked files `>= 500000`.
If `large-worktree-risk` is true, ask "Large Unity/monorepo detected. Skip heavy baseline checks for this run?" If skipped, record the exclusion, proceed with minimal verification, and set `worktree-exempt=true` so `using-git-worktrees` is bypassed for that session.

Preflight cache: Cache: large-worktree-risk=<true/false>, worktree-exempt=<true/false>, heavy-checks-skipped=<true/false>

## Required Runtime Status Summary (Once Per Session)

Declare one user-facing runtime status summary in the user's language.
It must include plain-language execution behavior + mode label (`parallel-worker` or `fallback-serial`), plain-language Git write capability + mode label (`normal` or `git-write-restricted`), and one impact sentence.
See `../_shared/runtime-compat.md` for combined-state examples.

## Invocation Rule

Invoke relevant/requested skills before any response, including clarifications: process skills first, implementation skills second.

## Integration

For details, see `routing-policy-reference.md` and `skill-invocation-reference.md`.
