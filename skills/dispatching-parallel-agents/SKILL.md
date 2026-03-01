---
name: dispatching-parallel-agents
description: Use when facing 2+ independent tasks that can be worked on without shared state or sequential dependencies
---

# Dispatching Parallel Agents

## Overview

When failures are independent, sequential investigation wastes time.

**Core principle:** one worker per independent domain.

**Runtime adapter:** use worker lifecycle actions from `../_shared/runtime-compat.md`.

## When to Use

Use when all are true:

- 2+ failures/domains exist,
- each can be investigated without others,
- workers will not conflict on shared state/files.

Avoid when failures may share a root cause.

## Pattern

### 1) Partition by domain

Group by concrete ownership:

- test file,
- subsystem,
- pipeline stage,
- API boundary.

### 2) Build focused worker prompts

Each prompt must include:

- scope boundary,
- explicit goal,
- constraints (what not to touch),
- expected return summary.

### 3) Dispatch concurrently

```text
spawn_worker(domain_A)
spawn_worker(domain_B)
spawn_worker(domain_C)
wait_worker(all)
close_worker(all)
```

### 4) Integrate safely

- review each summary,
- check file overlap/conflicts,
- run combined verification.

## Prompt Contract

A good prompt is:

1. focused (one domain),
2. self-contained (includes key failures/symptoms),
3. explicit about acceptable changes,
4. explicit about output format.

## Common Mistakes

- "Fix everything" (scope too broad)
- missing failure context
- no constraints on touched files
- no required output format

## Verification

After worker completion:

1. verify no conflicting edits,
2. verify each fix addresses root cause,
3. run cross-domain suite,
4. spot-check for coordinated regressions.

## Example

See `session-example.md` for a full real-session walkthrough.

## Bottom Line

Parallelize independent work only. Keep scope strict, integrate with evidence.
