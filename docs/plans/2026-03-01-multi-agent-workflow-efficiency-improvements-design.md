# Multi-Agent Workflow Efficiency Improvements Design

**Date:** 2026-03-01
**Status:** Draft
**Scope:** superpowers global skills and runtime compatibility layer
**Input Source:** recent multi-agent execution retrospective + codex-agent repo investigation

---

## Executive Summary

Recent multi-agent execution achieved good quality but lower-than-expected throughput. The dominant bottleneck was orchestration overhead (spawn/wait/retry/gate churn), not implementation complexity.

This design proposes a global, skill-level workflow upgrade that preserves quality gates while reducing control-plane cost:

1. Centralize orchestration policy in `using-superpowers`.
2. Add explicit throughput-oriented mode and routing rules across orchestration skills.
3. Move verification from monolithic "full sweep every wave" to staged gates with strict final evidence.
4. Encode Codex runtime adaptation rules in `_shared/runtime-compat.md` as normative behavior.
5. Add test coverage to prevent policy drift.

---

## Problem Statement

The retrospective identified recurring inefficiency patterns:

1. Parallel windows were short; serial merge/gate phases dominated elapsed time.
2. Too many low-cost actions were delegated to workers, increasing queue and lifecycle overhead.
3. Missing preflight checks caused avoidable interruptions (`git`/lock/dep/known-bad tests).
4. Worker thread limits and lifecycle churn forced repeated close/spawn cycles.
5. Verification happened, but at too coarse a granularity for fast iteration.
6. Some cross-component propagation gaps were found only in final review.

---

## Goals

1. Improve end-to-end task throughput for multi-agent sessions.
2. Preserve (or improve) correctness and verification rigor.
3. Provide one global policy source of truth for orchestration decisions.
4. Make behavior portable across Claude/Codex/OpenCode runtimes.

## Non-Goals

1. Hard enforcement at runtime engine level (skills remain prompt-policy driven).
2. Replacing existing core skills with a new monolithic skill.
3. Eliminating full verification; only stage and optimize it.

---

## Design Principles

1. **Centralize policy, distribute execution**: one routing policy, multiple specialized skills.
2. **High-cost actions only through workers**: keep trivial checks in controller context.
3. **Evidence-first completion**: no success claims without fresh verification output.
4. **Fail-fast preflight**: detect environment constraints before starting waves.
5. **Deterministic fallback**: when worker APIs are unavailable, preserve equivalent checkpoints.

---

## Proposed Workflow Architecture

### 1) Global Routing and Policy Gate

**Primary file:** `skills/using-superpowers/SKILL.md`

Add a mandatory section: `Global Multi-Agent Enforcement Policy`.

Policy responsibilities:

1. Route to one orchestration strategy:
   - `subagent-driven-development`: same-session plan execution.
   - `executing-plans`: plan execution with batch checkpoints.
   - `dispatching-parallel-agents`: 2+ independent domains/failures.
2. Require preflight before first worker spawn.
3. Require verification-before-completion before any completion claim.
4. Require explicit fallback declaration when worker capabilities are absent.

### 2) Runtime Capability Contract (Codex-adaptive)

**Primary file:** `skills/_shared/runtime-compat.md`

Promote current guidance into normative MUST rules:

1. If `spawn_worker/message_worker/wait_worker/close_worker` are available, orchestration MUST use them.
2. If partially unavailable, controller MUST enter `FALLBACK MODE` and emulate same checkpoints serially.
3. Controller MUST report selected mode (`parallel-worker` or `fallback-serial`) once per session.

### 3) Two Orchestration Profiles

**Files:**
- `skills/executing-plans/SKILL.md`
- `skills/subagent-driven-development/SKILL.md`
- `skills/dispatching-parallel-agents/SKILL.md`

Introduce explicit profile selection:

1. `high-rigor` (existing default behavior, maximal review depth).
2. `high-throughput` (recommended for implementation-heavy, low-risk parallel tasks).

`high-throughput` constraints:

1. Merge independent tasks into fewer worker assignments where file ownership permits.
2. Keep subagents for implementation/debug domains, not for every single verification command.
3. Enforce per-wave targeted gate + final full gate.

### 4) Preflight Checklist (Mandatory)

Before first wave:

1. Permission/lock writeability check (git refs/worktree operations).
2. Dependency baseline for relevant stacks (e.g., web test runner availability).
3. Known problematic tests/commands list resolution.
4. Branch/worktree readiness and ownership mapping confirmation.

Preflight result must be emitted as a short checklist status block.

### 5) Verification Staging Model

**File:** `skills/verification-before-completion/SKILL.md`

Add staged verification protocol:

1. `Task Gate`: changed-files/localized tests.
2. `Wave Gate`: cross-task integration tests for touched domains.
3. `Final Gate`: repository-required checks before completion claim.

Add baseline-diff rule:

1. If failures remain, classify as `new-regression` vs `pre-existing` via baseline rerun on base branch.
2. Only `new-regression` blocks completion.
3. `pre-existing` must be documented with concrete evidence.

### 6) Worker Lifecycle Efficiency Rules

Across orchestration skills:

1. Prefer long-lived workers per wave/domain over frequent spawn/close churn.
2. Reserve `awaiter` pattern for genuinely long-running commands.
3. Controller executes sub-second checks directly.
4. Close workers only at wave boundaries or when thread limits require.

### 7) Context Packaging Contract for Workers

For implementer workers, standardize minimal required context payload:

1. exact task statement,
2. file ownership constraints,
3. required commands,
4. success criteria,
5. prohibited scope.

Avoid broad plan re-reading unless needed.

---

## Policy Text Draft (for `using-superpowers`)

```md
## Global Multi-Agent Enforcement Policy (Mandatory)

When work involves a written plan OR 2+ potentially independent domains:

1. Select exactly one orchestrator skill:
   - same-session plan execution -> subagent-driven-development
   - batch/checkpoint plan execution -> executing-plans
   - independent concurrent domains -> dispatching-parallel-agents

2. Run preflight before first worker spawn:
   - permissions/locks
   - dependencies/tooling
   - known-failing exclusions
   - branch/worktree readiness

3. If worker capabilities exist, use worker lifecycle APIs.
   If not, enter FALLBACK MODE and preserve equivalent checkpoints.

4. Before ANY completion claim, invoke verification-before-completion
   and provide fresh verification evidence.
```

---

## Test Strategy Updates

### A. Triggering and Policy Presence

1. Extend `tests/skill-triggering/run-all.sh` with a prompt that should require orchestration routing + verification gate language.
2. Add prompt fixture for verification gating behavior.

### B. Codex Runtime Compatibility

1. Extend `tests/codex/test-runtime-compat.sh` to assert:
   - routing terminology appears,
   - fallback-mode language appears when worker capabilities are absent,
   - verification gate is referenced before completion claims.

### C. Explicit Request Regression Tests

1. Add one explicit-skill-request prompt where user asks for fast completion.
2. Test fails if response claims completion without evidence language.

---

## Rollout Plan

### Phase 1: Policy Consolidation (Docs-only)

1. Update `using-superpowers` with global policy text.
2. Update `_shared/runtime-compat.md` with MUST-level fallback contract.
3. Reference policy from orchestration and verification skills.

### Phase 2: Behavior Alignment

1. Add preflight/staging sections to orchestration skills.
2. Add staged gate and baseline-diff rules to verification skill.

### Phase 3: Test Hardening

1. Add new prompt fixtures and script assertions.
2. Run existing `skill-triggering` + `codex` suites.

### Phase 4: Adoption and Feedback

1. Track first 5 multi-agent sessions using updated policies.
2. Collect metrics and refine threshold defaults.

---

## Success Metrics

For comparable multi-agent tasks:

1. 20-35% reduction in orchestration overhead time (spawn/wait/retry/merge).
2. 15-30% reduction in total elapsed time.
3. No increase in escaped regressions.
4. 100% completion claims include fresh verification evidence.

---

## Risks and Mitigations

1. **Risk:** policy text becomes too strict and harms agility.
   - **Mitigation:** dual profile (`high-rigor` vs `high-throughput`) with explicit selection.
2. **Risk:** duplicated policy drifts across skills.
   - **Mitigation:** single-source policy in `using-superpowers`; other skills reference it.
3. **Risk:** runtime differences cause inconsistent behavior.
   - **Mitigation:** `_shared/runtime-compat.md` capability-first contract + fallback declaration.
4. **Risk:** teams skip baseline comparison for known failures.
   - **Mitigation:** verification skill requires base-branch evidence for pre-existing failures.

---

## Open Questions

1. Should `high-throughput` become default for non-production-impacting tasks?
2. Should known failing tests be tracked in a dedicated machine-readable file?
3. Should we add a lightweight telemetry summary format for every orchestration session?

---

## Recommended Next Step

Create a paired implementation plan document (`YYYY-MM-DD-...-implementation.md`) that maps each file change and test update into concrete, reviewable tasks.
