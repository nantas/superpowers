# Routing Policy Reference

Detailed routing guidance for `using-superpowers`.

## Routing Table

| Task shape | Worker capability | Permission mode | Route |
| --- | --- | --- | --- |
| Written plan, mostly independent tasks, same session | complete | normal | `subagent-driven-development` + `parallel-worker` |
| Written plan with batch checkpoints/handoff | complete/incomplete | normal | `executing-plans` (parallel when available, otherwise fallback-serial) |
| 2+ independent domains | complete | normal | `dispatching-parallel-agents` + `parallel-worker` |
| Any orchestration flow with missing worker actions | incomplete | normal | Preserve chosen orchestrator semantics in `fallback-serial` |
| Any workflow with git lock/metadata write restrictions | complete/incomplete | git-write-restricted | Continue selected orchestrator; apply restricted git behavior from runtime-compat |

## Preflight Checklist

Run before first worker spawn:

- lock and permission readiness
- branch/worktree validity
- dependency/tooling baseline
- known failing commands and exclusions
- critical command availability

## Fallback Rules

If worker lifecycle operations are missing, do not skip checkpoints.

- keep orchestration semantics,
- execute tasks serially,
- preserve review and verification gates,
- report explicit fallback mode.

## Completion Gate

No completion claim without `verification-before-completion` and fresh command evidence.
