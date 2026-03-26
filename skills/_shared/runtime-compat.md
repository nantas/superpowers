# Runtime Compatibility for Skills

Use this module when writing skills that should run across Claude Code, Codex, and other agent runtimes.

## Capability-Based Detection

Detect available capabilities first, then choose behavior. Do not branch on product names when avoidable.

At session start, identify whether runtime supports:
- `track_tasks` (persistent task/checklist tracking)
- `load_skill` (skill activation/loading)
- `spawn_worker` (create subagent/worker)
- `message_worker` (send follow-up instructions)
- `wait_worker` (wait for worker completion)
- `close_worker` (release worker)

## Clarification Capability Contract (Normative)

1. `request_user_input` is a first-class clarification capability signal for Codex-oriented workflows.
2. Clarification capability is detected once during `using-superpowers` preflight and cached for downstream reuse.
3. Downstream skills must consume cached `request_user_input_available` and must not re-probe runtime capability.

## Abstract-Action Resolution Contract (Normative)

1. `track_tasks`, `load_skill`, `spawn_worker`, `message_worker`, `wait_worker`, and `close_worker` are abstract actions, not literal tool names.
2. Controllers MUST resolve abstract actions to runtime-native tools and/or equivalent runtime-managed behavior before mode selection.
3. Controllers MUST NOT infer "capability unavailable" solely because literal abstract action names are absent from the runtime tool list.
4. If resolution is ambiguous, controllers MUST run a minimal capability probe before selecting fallback behavior.

## Capability Probe Procedure (Normative)

At session start (or before first orchestration), build and cache a capability map:

1. Inspect runtime-visible tool inventory/signals for this session.
2. Resolve each abstract action using known runtime aliases/equivalents.
3. If worker lifecycle coverage is unclear, run a minimal worker probe:
   - dispatch one trivial worker task,
   - send follow-up only if runtime supports follow-up semantics,
   - wait for completion/result,
   - close explicitly only if runtime exposes close semantics.
4. Persist the resolved worker profile for the session and reuse it for routing.

## Abstract Actions

Use these action names in skill instructions and prompt templates:
- `track_tasks`: create/update task status (`pending`, `in_progress`, `completed`)
- `load_skill`: activate/read the target skill before execution
- `spawn_worker`: launch a worker for a scoped task
- `message_worker`: send additional context, clarifications, or fix instructions
- `wait_worker`: block until worker returns or timeout; when wait is wait-any over multiple ids, loop until `pending_ids` is empty
- `close_worker`: close worker when done

## Worker Completion Contract (Normative)

1. Completion source of truth MUST be `wait_worker` final status (`status`/`timed_out` or runtime equivalent).
2. Controllers MUST NOT treat file changes, log output, or commit appearance as worker completion.
3. If runtime wait is wait-any for multi-id calls, controllers MUST keep a `pending_ids` set and call `wait_worker(pending_ids)` until empty.
4. Async notification channels (for example Codex `subagent_notification`) MAY add context, but MUST NOT replace `wait_worker` as a stage gate.
5. After each final wait result, controllers SHOULD call `close_worker` when runtime close semantics exist.

## Worker Capability Profiles (Normative)

- `full-lifecycle`: runtime exposes explicit equivalents for dispatch, follow-up, wait, and close.
- `managed-lifecycle`: runtime supports dispatch + result collection while follow-up/close are implicit or emulated by runtime behavior.
- `unavailable`: runtime cannot provide reliable worker dispatch/result semantics for scoped parallel work.

## Execution Mode Contract (Normative)

1. If resolved worker profile is `full-lifecycle` or `managed-lifecycle`, orchestration MUST run in `parallel-worker` mode.
2. If resolved worker profile is `unavailable`, orchestration MUST run in `fallback-serial` mode while preserving equivalent checkpoints and stage ordering.
3. Controller MUST declare execution mode once per session before substantial execution, and SHOULD include resolved worker profile.

## Permission Mode Contract (Normative)

1. Permission mode defaults to `normal`.
2. If command output matches Git metadata write lock failures (for example `.git/*.lock` + `Operation not permitted`, `cannot lock ... .git/config`, `cannot lock ref ... refs/remotes/... .lock`), controller MUST switch to `git-write-restricted`.
3. In `git-write-restricted` mode:
   - after first matching failure, controller MUST NOT keep retrying the same Git metadata write in non-escalated mode;
   - controller SHOULD route subsequent Git metadata writes through elevated strategy supported by the runtime;
   - read-only Git commands SHOULD remain unprivileged when possible.
4. Controller MUST declare permission mode once per session and update declaration if mode changes.

## Runtime Status Summary Contract (Normative)

1. Controller MUST provide one user-facing runtime status summary once per session before substantial execution, and MUST update it if execution mode or permission mode changes.
2. The user-facing runtime status summary MUST combine execution mode + permission mode in one coherent statement.
3. The summary MUST include:
   - plain-language execution behavior (what task scheduling behavior the user should expect),
   - plain-language git write capability (what Git metadata writes are expected to work in this session),
   - machine-readable mode labels in parentheses for both values.
4. The summary MUST include a practical impact sentence describing what will happen in this session.
5. In `git-write-restricted` mode, the practical impact sentence MUST state that repeated non-escalated retries for the same Git metadata write are avoided.

### Combined State Reference (User-Facing Examples)

| Execution + Permission | User-facing runtime status summary |
| --- | --- |
| `parallel-worker` + `normal` | Runtime status: Parallel subtask execution (`parallel-worker`) + standard Git write capability (`normal`). Impact: independent tasks run concurrently and normal Git metadata writes can proceed. |
| `parallel-worker` + `git-write-restricted` | Runtime status: Parallel subtask execution (`parallel-worker`) + restricted Git writes (`git-write-restricted`). Impact: independent tasks still run concurrently, but Git metadata writes use restricted/elevated handling after first lock-permission failure. |
| `fallback-serial` + `normal` | Runtime status: Sequential fallback execution (`fallback-serial`) + standard Git write capability (`normal`). Impact: tasks run one-by-one due to runtime limits, while normal Git metadata writes can proceed. |
| `fallback-serial` + `git-write-restricted` | Runtime status: Sequential fallback execution (`fallback-serial`) + restricted Git writes (`git-write-restricted`). Impact: tasks run one-by-one and Git metadata writes avoid repeated non-escalated retries after lock-permission failures. |

## Runtime Equivalence Hints (Reference; Verify Per Session)

| Runtime | track/load | Worker dispatch | Follow-up | Wait/result | Close | Typical profile |
| --- | --- | --- | --- | --- | --- | --- |
| Codex | `update_plan`, native skill loading | `spawn_agent` | `send_input` | `wait` | `close_agent` | `full-lifecycle` |
| OpenCode | `update_plan`, native `skill` tool | subagent dispatch via `@mention` system | threaded follow-up when supported; otherwise re-dispatch with delta context | runtime subagent completion/result channel | often runtime-managed | `managed-lifecycle` |
| Claude Code | runtime planner tool, `Skill` tool | runtime subagent dispatch tool | follow-up instruction when runtime supports it; otherwise re-dispatch | task completion/result output | often implicit on completion | `managed-lifecycle` |

## Codex Mapping

For Codex multi-agent mode, map abstract actions to:

| Abstract action | Codex tool(s) |
| --- | --- |
| `track_tasks` | `update_plan` |
| `load_skill` | Skill discovery + loading from `SKILL.md` (native behavior) |
| `spawn_worker` | `spawn_agent` |
| `message_worker` | `send_input` |
| `wait_worker` | `wait` |
| `close_worker` | `close_agent` |

### Codex Context and Reliability Guardrails (Normative)

1. For Codex-oriented worker dispatch, controllers SHOULD default to `fork_context=true` unless the worker prompt is already fully self-contained and isolating parent context is intentional.
2. Even when `fork_context=true` is used, controllers MUST include a minimal task packet covering objective, scope boundary, prohibited scope, expected return format, and completion criteria.
3. Controllers MUST define a worker time budget or phase timeout and switch to documented fallback behavior if the worker times out, drifts, or cannot complete reliably.
4. In Codex, `close_agent` is cleanup only; controllers MUST NOT treat `close_agent` return payloads as proof of completion.

### Codex Wait Semantics (Normative)

1. `wait(ids=[...])` returns when any listed worker reaches a final state (wait-any), not when all complete.
2. For parallel workers, controllers MUST loop on a `pending_ids` set until all worker ids are removed by final wait results.
3. In Codex, worker completion MUST come from `wait` results, not artifact polling.
4. `subagent_notification` events are asynchronous context updates and MUST NOT be used as completion gates.

## Fallback for Non-Multi-Agent Runtimes

When resolved worker profile is `unavailable`:
1. Execute tasks sequentially in the main agent.
2. Keep the same stages (implement -> review -> fix -> re-review).
3. Use `track_tasks` if available; otherwise maintain a manual checklist in responses.
4. Keep outputs equivalent to multi-agent flow so process semantics stay stable.
5. Preserve the same user-facing expectation statement, including when fallback-serial execution replaces worker orchestration.
