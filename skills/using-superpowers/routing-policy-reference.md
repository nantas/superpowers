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
- dependency/tooling baseline
- known failing commands and exclusions
- critical command availability

## Fallback Rules

If resolved worker profile is `unavailable`, do not skip checkpoints.

- keep orchestration semantics,
- execute tasks serially,
- preserve review and verification gates,
- report explicit fallback mode.

## Completion Gate

No completion claim without `verification-before-completion` and fresh command evidence.
