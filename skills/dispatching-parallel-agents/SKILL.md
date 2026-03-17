---
name: dispatching-parallel-agents
description: Use when facing 2+ independent tasks that can be worked on without shared state or sequential dependencies
---

# Dispatching Parallel Agents

## Overview

Use this workflow when multiple independent domains would consume too much main-session context if handled inline.

**Core principle:** one worker per independent high-context domain.

**Runtime adapter:** use worker lifecycle actions from `../_shared/runtime-compat.md`.

## When to Use

Use when all are true:

- 2+ failures/domains exist,
- each can be investigated without others,
- each domain would otherwise consume meaningful controller context,
- workers will not conflict on shared state/files.

Avoid when failures may share a root cause.

This workflow is for context offload first. It may reduce elapsed time, but speedup is optional and not promised.

## Pattern

### 1) Partition by domain

Group by concrete ownership:

- test file,
- subsystem,
- pipeline stage,
- API boundary.

### 2) Build focused worker prompts

Each prompt must include a minimal task packet:

- explicit goal,
- scope boundary,
- constraints (what not to touch),
- expected return summary.
- completion criteria.

For Codex-oriented runs, prefer `fork_context=true` by default unless the prompt is already fully self-contained and isolated parent context is desired.

### 3) Dispatch concurrently

```text
id_A = spawn_worker(domain_A, fork_context=true)
id_B = spawn_worker(domain_B, fork_context=true)
id_C = spawn_worker(domain_C, fork_context=true)

pending_ids = [id_A, id_B, id_C]
while pending_ids not empty:
  result = wait_worker(pending_ids)  # wait-any
  if result is final:
    close_worker(result.worker_id)
    remove result.worker_id from pending_ids
  if result timed out or drifted:
    recover that domain in controller context or fallback-serial mode
```

### 4) Integrate safely

- review each summary,
- check file overlap/conflicts,
- run combined verification.

## Prompt Contract

A good prompt is:

1. focused (one domain),
2. contextualized (includes key failures/symptoms and uses `fork_context=true` when parent context matters),
3. explicit about acceptable changes,
4. explicit about output format,
5. explicit about what counts as done.

## Common Mistakes

- "Fix everything" (scope too broad)
- missing failure context
- no constraints on touched files
- no required output format
- assuming "parallel" always means "faster"
- treating one wait-any result as completion for the whole wave
- leaving timed-out workers hanging instead of falling back

## Verification

After worker completion:

1. verify no conflicting edits,
2. verify each fix addresses root cause,
3. run cross-domain suite,
4. spot-check for coordinated regressions.

## Example

See `session-example.md` for a full real-session walkthrough.

## Bottom Line

Parallelize independent work when it meaningfully offloads main-session context. Keep scope strict, use `pending_ids` for wait-any behavior, and fallback when workers stall.
