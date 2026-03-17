# Codex Multi-Agent Workflow Reliability Design

**Date:** 2026-03-17
**Status:** Approved
**Scope:** `dispatching-parallel-agents`, `subagent-driven-development`, shared Codex multi-agent policy and tests
**Input Sources:**
- external research note: `/Users/nantasmac/projects/obsidian-mind/00_收件箱/[External]_codex_Research_Codex多Agent模式问题定位.md`
- current skills in this repository

---

## Executive Summary

This design improves Superpowers multi-agent workflows for Codex without replacing the current skill architecture.

The primary goal is not raw speed. The primary goal is to reduce main-session context pressure while making subagent execution more reliable under Codex's actual multi-agent semantics.

The design adopts a medium-scope refactor:

1. Treat subagents as context offload workers by default.
2. Make `fork_context=true` the default policy for Codex-oriented multi-agent workflows.
3. Encode wait-any-safe orchestration rules explicitly.
4. Replace fixed heavy review gates with risk-tiered gates.
5. Require user-facing expectation setting before running heavyweight subagent workflows.
6. Lock the new behavior with repository tests before user dogfooding.

---

## Problem Statement

Recent investigation found that the main issues are not explained by a single Codex implementation defect.

The bigger problem is a mismatch between current workflow assumptions and Codex runtime semantics:

1. `wait_agent` is wait-any, not wait-all.
2. `spawn_agent` does not fork parent context unless `fork_context=true` is set explicitly.
3. child agents inherit runtime/config snapshots, not the parent's full live environment.
4. `close_agent` can return a last-known status that is easy to misread as final completion.

In practice this creates three user-visible failures:

1. subagents re-derive missing context and become slow or fail,
2. controller flows can mis-detect completion,
3. users see "subagent" and assume acceleration, even when the workflow is actually trading speed for context isolation and rigor.

---

## Goals

1. Reduce main-session context load during large or multi-domain tasks.
2. Increase subagent reliability by removing avoidable context-loss failure modes.
3. Preserve the existing skill architecture instead of introducing a new top-level orchestrator.
4. Make workflow tradeoffs explicit to users before execution.
5. Add tests that verify the new Codex-oriented behavior before real-session dogfooding.

## Non-Goals

1. Rebuilding all multi-agent routing around a new framework.
2. Guaranteeing multi-agent execution is faster than the main agent.
3. Solving every possible Codex runtime inconsistency in the skill layer.
4. Removing review gates entirely from development workflows.

---

## Design Principles

1. **Context offload over speed claims**: use subagents when they save main-session context, even if wall-clock time does not improve.
2. **Reliability before throughput**: avoid context starvation and orchestration ambiguity first.
3. **Codex semantics must be explicit**: wait-any, context fork behavior, and close semantics cannot stay implicit.
4. **Keep workflow-specific rules local, shared safeguards shared**: centralize universal protections while preserving skill-level specialization.
5. **Expectation management is part of reliability**: misleading users about likely runtime behavior is itself a workflow defect.

---

## Key Policy Changes

### 1) Default to `fork_context=true`

For Codex-oriented multi-agent workflows, spawned workers should default to `fork_context=true`.

Rationale:

1. the main failure mode observed in research is missing parent context,
2. the user explicitly values context offload and reliability above speed,
3. defaulting to no fork makes workers spend time rebuilding context and increases failure risk.

Allowed exception:

- disable fork only when the prompt is already fully self-contained and isolating parent context is intentional.

### 2) Keep a Minimal Task Packet Even When Forking

`fork_context=true` does not remove the need for clear task instructions.

Each worker dispatch should still include:

1. current objective,
2. scope boundary,
3. prohibited scope,
4. expected return format,
5. completion criteria.

This prevents "has context, lacks task framing" failures.

### 3) Encode Wait-Any-Safe Orchestration

Any flow waiting on multiple workers must maintain `pending_ids` and loop until all target workers reach final status.

Required rule:

1. never treat one `wait_agent(ids=[...])` call as wait-all,
2. do not mark a phase complete until `pending_ids` is empty,
3. treat async notifications as informational only, not as completion gates.

### 4) Treat `close_agent` as Cleanup, Not Proof of Completion

Workflow instructions must state that `close_agent` is not a final completion signal.

Completion truth should come from worker final status observed via wait lifecycle behavior, not from close return payloads.

### 5) Add Timeout and Fallback Rules

Workers should not be allowed to hang indefinitely.

Required behavior:

1. assign a time budget per worker or phase,
2. if budget expires or results drift, recover the task in controller context or fall back to serial execution,
3. document fallback clearly in workflow instructions.

---

## Workflow Changes

### `dispatching-parallel-agents`

Current skill value:

- good basic domain partitioning pattern,
- already references wait-any looping with `pending_ids`.

Required changes:

1. change the framing from "parallelize independent work for speed" to "offload independent high-context domains from the main session",
2. make `fork_context=true` the default worker policy,
3. require minimal task packets for each domain,
4. add explicit timeout and fallback-serial rules,
5. state that small read-only tasks may still be valid offload candidates if they would otherwise pollute controller context, but are not expected to be faster.

Recommended usage test:

- if the main session would retain substantial file, failure, or reasoning context after doing the work locally, the task is a candidate for offload.

Not recommended:

- tiny tasks where the controller needs the full reasoning chain immediately,
- overlapping write scopes,
- cases where parallelism is used only because "subagent sounds faster".

### `subagent-driven-development`

Current skill issue:

- fixed `implementer -> spec reviewer -> code-quality reviewer` gate is too heavy as a default,
- users can infer a speed promise that the workflow does not actually make,
- reviewer passes can suffer from the same missing-context problem as implementers.

Required changes:

1. replace fixed full gate with risk-tiered gate selection,
2. default reviewer workers to `fork_context=true`,
3. add controller-side preflight statement before execution,
4. clarify that the workflow's main benefits are context offload and reliability, not guaranteed acceleration.

Risk tiers:

1. **Lightweight**
   - implementer + self-check
   - use for small, low-risk, narrow-scope tasks
2. **Moderate**
   - implementer + one reviewer
   - use for normal feature or fix tasks with moderate correctness risk
3. **High-Risk**
   - implementer + spec reviewer + code-quality reviewer
   - use for cross-module, high-impact, or ambiguity-heavy tasks

### Mandatory User-Facing Expectation Statement

Before running `subagent-driven-development`, the controller must tell the user:

1. which gate tier will run,
2. the full stage sequence,
3. that the workflow is being chosen for context offload and reliability,
4. that elapsed time may be longer than direct main-session execution,
5. why that tradeoff is acceptable for the current task.

This avoids false expectations that "subagent" implies parallel speedup.

---

## Shared vs Local Policy Split

### Shared Policy Layer

Put these rules in shared Codex multi-agent guidance so all relevant skills inherit them consistently:

1. default `fork_context=true`,
2. minimal worker task packet requirement,
3. wait-any-safe `pending_ids` orchestration,
4. timeout + fallback rule,
5. `close_agent` is not a completion proof,
6. user-facing expectation statement when workflow value is not primarily speed.

### Workflow-Local Rules

Keep these in their respective skills:

1. `dispatching-parallel-agents`
   - domain partitioning guidance,
   - parallel vs serial recovery choice,
   - offload suitability heuristics
2. `subagent-driven-development`
   - risk-tier selection,
   - reviewer ordering,
   - workflow preflight statement content

---

## Testing Strategy

The user requires autonomous repository tests before real-session verification. Therefore the rollout must be test-first.

### 1) `tests/codex/`

Add or extend tests that assert Codex-specific multi-agent protections are present:

1. `fork_context=true` default guidance,
2. wait-any / `pending_ids` completion handling,
3. timeout + fallback language,
4. `close_agent` not treated as final completion proof.

### 2) `tests/skill-triggering/`

Add prompts verifying that context-offload intent can route to multi-agent workflows even without an explicit "make it faster" framing.

### 3) `tests/explicit-skill-requests/`

Add explicit request cases for `subagent-driven-development` that fail unless the response includes:

1. gate-tier declaration,
2. full stage sequence,
3. no guaranteed speed claim,
4. context-offload / reliability framing.

### 4) `tests/subagent-driven-dev/` or targeted fixtures

Add coverage that distinguishes lightweight, moderate, and high-risk gate selection so small tasks do not automatically trigger full reviewer chains.

---

## Rollout Plan

### Phase 1: Test-first contract definition

1. add failing tests for the new Codex policy expectations,
2. add failing tests for subagent-driven-development expectation setting and gate tiering.

### Phase 2: Shared policy updates

1. update shared runtime/policy guidance with the new defaults and warnings,
2. ensure the wording is universal enough for reuse across both target skills.

### Phase 3: Workflow updates

1. revise `dispatching-parallel-agents`,
2. revise `subagent-driven-development`,
3. keep changes focused on reliability and user expectation alignment.

### Phase 4: Verification

1. run relevant Codex, triggering, explicit-request, and workflow test suites,
2. only after automated validation, proceed to live-session dogfooding.

---

## Risks and Mitigations

1. **Risk:** default `fork_context=true` increases context transfer cost.
   - **Mitigation:** optimize for reliability and offload first; allow opt-out for fully self-contained tasks.
2. **Risk:** tiered gates introduce subjective choice.
   - **Mitigation:** document concrete risk criteria and test expected examples.
3. **Risk:** expectation statements add friction.
   - **Mitigation:** keep them short and mandatory only for heavyweight development workflow starts.
4. **Risk:** shared policy and workflow text drift apart later.
   - **Mitigation:** anchor universal rules in shared guidance and test for their presence.

---

## Success Criteria

This design is successful if:

1. multi-agent skills explicitly reflect Codex wait-any and fork semantics,
2. subagent workflows fail less often due to missing context,
3. main-session context usage is reduced on large tasks,
4. users are warned upfront when a workflow trades speed for reliability and context isolation,
5. automated repository tests pass before manual dogfooding begins.
