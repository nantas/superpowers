# Parallel Dispatch Session Example

## Scenario

Six failures across three unrelated files after refactor. Each domain requires enough file reading and reasoning that keeping everything in the controller thread would bloat session context.

- `agent-tool-abort.test.ts` (abort/timing)
- `batch-completion-behavior.test.ts` (completion flow)
- `tool-approval-race-conditions.test.ts` (approval race)

## Dispatch plan

```text
Worker 1 -> abort/timing domain
  packet: goal + scope + prohibited files + summary format + done criteria
  dispatch with fork_context=true
Worker 2 -> batch completion domain
  packet: goal + scope + prohibited files + summary format + done criteria
  dispatch with fork_context=true
Worker 3 -> tool approval race domain
  packet: goal + scope + prohibited files + summary format + done criteria
  dispatch with fork_context=true
```

Controller wait loop:

```text
pending_ids = [worker_1, worker_2, worker_3]
while pending_ids not empty:
  result = wait_worker(pending_ids)  # wait-any
  if result is final:
    close_worker(result.worker_id)
    remove result.worker_id from pending_ids
  if result timed_out:
    reassign that domain to controller context or fallback-serial execution
```

## Outcomes

- Worker 1 replaced brittle sleeps with condition-based waiting.
- Worker 2 fixed event structure mismatch.
- Worker 3 added deterministic wait for async execution completion.

## Integration

- no file conflicts,
- combined test run green,
- regressions not observed.

## Why this worked

Domains were independent, prompts were narrowly scoped, and the controller used workers to shed context load rather than to promise raw speedup.
