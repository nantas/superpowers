# Routing Policy Reference

Detailed routing guidance for `using-superpowers`.

## Routing Table

| Task shape | Resolved worker profile | Permission mode | Route |
| --- | --- | --- | --- |
| Written plan, mostly independent tasks, same session | `full-lifecycle` or `managed-lifecycle` | normal | `subagent-driven-development` + `parallel-worker` |
| Written plan with batch checkpoints/handoff | any | normal | `executing-plans` (parallel for non-`unavailable`, otherwise fallback-serial) |
| 2+ independent domains | `full-lifecycle` or `managed-lifecycle` | normal | `dispatching-parallel-agents` + `parallel-worker` |
| Any orchestration flow with no reliable worker dispatch/result semantics | `unavailable` | normal | Preserve chosen orchestrator semantics in `fallback-serial` |
| Any workflow with git lock/metadata write restrictions | any | `git-write-restricted` | Continue selected orchestrator; apply restricted git behavior from runtime-compat |

## Preflight Checklist

Run before first worker spawn:

- lock and permission readiness
- branch/worktree validity
- repo/worktree scale risk (Unity/monorepo guard)
- dependency/tooling baseline
- known failing commands and exclusions
- critical command availability

Orchestrators and `using-git-worktrees` must treat this as a hard gate.
If preflight cache is absent, stop and invoke `using-superpowers` before continuing.

For Unity/very large repos, prefer quick metadata probes (`git ls-files`, `git count-objects -v`, Unity marker paths) before any heavy scan.
If large-worktree risk is detected, ask whether to skip heavy baseline checks and record that choice in exclusions.
If large-worktree risk is detected, set `worktree-exempt=true` and bypass `using-git-worktrees` for that session.
If a large-worktree cache exists, reuse it and do not re-ask unless context changes.

## Fallback Rules

If resolved worker profile is `unavailable`, do not skip checkpoints.

- keep orchestration semantics,
- execute tasks serially,
- preserve review and verification gates,
- report explicit fallback mode.

## Completion Gate

No completion claim without `verification-before-completion` and fresh command evidence.

## User-Facing Runtime Status

When declaring runtime state, combine execution + permission into one user-facing line plus impact sentence.

- `parallel-worker` + `normal`: independent tasks run concurrently; normal Git metadata writes expected to work.
- `parallel-worker` + `git-write-restricted`: independent tasks run concurrently; Git metadata writes use restricted/elevated handling after lock-permission failures.
- `fallback-serial` + `normal`: tasks run one-by-one due to runtime limits; normal Git metadata writes expected to work.
- `fallback-serial` + `git-write-restricted`: tasks run one-by-one and Git metadata writes avoid repeated non-escalated retries after lock-permission failures.
