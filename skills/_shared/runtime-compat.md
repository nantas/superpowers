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

## Abstract Actions

Use these action names in skill instructions and prompt templates:
- `track_tasks`: create/update task status (`pending`, `in_progress`, `completed`)
- `load_skill`: activate/read the target skill before execution
- `spawn_worker`: launch a worker for a scoped task
- `message_worker`: send additional context, clarifications, or fix instructions
- `wait_worker`: block until worker returns or timeout
- `close_worker`: close worker when done

## Execution Mode Contract (Normative)

1. If `spawn_worker`, `message_worker`, `wait_worker`, and `close_worker` are all available, orchestration MUST run in `parallel-worker` mode.
2. If any worker capability is unavailable, orchestration MUST run in `fallback-serial` mode while preserving equivalent checkpoints and stage ordering.
3. Controller MUST declare execution mode once per session before substantial execution.

## Permission Mode Contract (Normative)

1. Permission mode defaults to `normal`.
2. If command output matches Git metadata write lock failures (for example `.git/*.lock` + `Operation not permitted`, `cannot lock ... .git/config`, `cannot lock ref ... refs/remotes/... .lock`), controller MUST switch to `git-write-restricted`.
3. In `git-write-restricted` mode:
   - after first matching failure, controller MUST NOT keep retrying the same Git metadata write in non-escalated mode;
   - controller SHOULD route subsequent Git metadata writes through elevated strategy supported by the runtime;
   - read-only Git commands SHOULD remain unprivileged when possible.
4. Controller MUST declare permission mode once per session and update declaration if mode changes.

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

## Fallback for Non-Multi-Agent Runtimes

When `spawn_worker`-style APIs are unavailable:
1. Execute tasks sequentially in the main agent.
2. Keep the same stages (implement -> review -> fix -> re-review).
3. Use `track_tasks` if available; otherwise maintain a manual checklist in responses.
4. Keep outputs equivalent to multi-agent flow so process semantics stay stable.
