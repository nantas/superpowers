# Writing-Skills Codex Tool Guidance Boundary Design

**Date:** 2026-03-26  
**Status:** Proposed  
**Scope:** `skills/using-superpowers`, `skills/writing-skills`, `skills/_shared/runtime-compat.md`, Codex compatibility tests

---

## Executive Summary

`using-superpowers` is already the global entry gate and preflight owner. This design formalizes a strict boundary:

1. `using-superpowers` is the **only** skill that performs runtime/capability detection (including Codex-specific availability checks).
2. `writing-skills` remains runtime-aware, but only as a **consumer** of preflight results; it must not re-detect environment capabilities.
3. Codex-specific tool guidance in `writing-skills` should focus on **how to execute** with known capabilities, especially interactive clarification via `request_user_input` in incremental, one-decision steps.

This preserves single-source-of-truth runtime detection while improving Codex execution quality for skill-authoring workflows.

---

## Problem Statement

Current state across the two skills creates an ambiguity:

1. `using-superpowers` defines a mandatory preflight gate and already checks Codex-relevant signals (for example `request_user_input` availability).
2. `writing-skills` asks for abstract actions like `track_tasks`, and references subagent testing, but does not define a clear downstream contract for consuming preflight results in Codex sessions.
3. Without a defined boundary, downstream skills may drift into repeated runtime probing or inconsistent user interaction patterns.

Resulting risk:

1. duplicated detection logic,
2. inconsistent tool behavior across sessions,
3. high-friction user prompts that ask for large free-form responses instead of incremental confirmations.

---

## Goals

1. Make runtime/capability detection ownership explicit and centralized in `using-superpowers`.
2. Add Codex-focused tool usage guidance to `writing-skills` without introducing duplicate detection logic.
3. Standardize low-friction, high-density user interaction for Codex (incremental confirmation over large template replies).
4. Add tests that prevent boundary regressions.

## Non-Goals

1. Reworking the global runtime adapter model.
2. Introducing a new orchestrator skill.
3. Converting `writing-skills` into a runtime-router.

---

## Design Decisions

### Decision 1: Single Detection Owner

`using-superpowers` is the only skill allowed to:

1. inspect runtime tool inventory/signals,
2. classify capability/profile modes,
3. determine `request_user_input` availability in Codex,
4. publish session preflight cache for downstream workflows.

Downstream skills consume this cache and must not repeat detection.

### Decision 2: Consumer-Only Codex Guidance in `writing-skills`

`writing-skills` should add a Codex section that states:

1. preflight cache is required input,
2. if cache is absent, stop and invoke `using-superpowers`,
3. use runtime adapter actions and resolved mappings; do not probe local runtime again.

### Decision 3: Incremental Clarification Contract for Codex

For Codex sessions where preflight indicates `request_user_input` is available:

1. ask one decision boundary per interaction,
2. prefer structured options (2-3 choices),
3. avoid asking users to fill large free-form templates in one turn,
4. apply changes incrementally after each confirmed answer.

If unavailable, fall back to concise plain-text questioning with the same one-decision pacing.

### Decision 4: Keep Adapter-First Language

Tool language stays abstract in skills (`track_tasks`, `spawn_worker`, etc.).  
Codex-native examples remain references mapped via `runtime-compat.md`, not alternate control flow.

---

## Proposed Changes

### 1) `skills/using-superpowers/SKILL.md`

Add a normative preflight output contract section:

1. declare required cached fields (capability and clarification related),
2. explicitly state downstream skills consume cache and must not re-probe,
3. include Codex clarification capability result in cache semantics.

Proposed cache shape (documentation contract):

- `worker_profile`: `full-lifecycle | managed-lifecycle | unavailable`
- `execution_mode`: `parallel-worker | fallback-serial`
- `permission_mode`: `normal | git-write-restricted`
- `request_user_input_available`: `true | false`
- `large-worktree-risk`: `true | false`
- `worktree-exempt`: `true | false`
- `heavy-checks-skipped`: `true | false`

### 2) `skills/_shared/runtime-compat.md`

Add a small clarification capability subsection:

1. define `request_user_input` as a first-class clarification capability signal for Codex-oriented guidance,
2. document that this capability is detected once during preflight and reused downstream,
3. keep existing abstract-action contract unchanged.

### 3) `skills/writing-skills/SKILL.md`

Add a new section: `Runtime Integration (Consumer Mode)`.

Required statements:

1. this skill requires completed `using-superpowers preflight`,
2. if cache absent, stop and invoke `using-superpowers`,
3. do not run runtime/capability probing in this skill,
4. for Codex clarification loops, follow incremental confirmation pattern based on cached `request_user_input_available`.

### 4) `skills/writing-skills/testing-skills-with-subagents.md`

Add Codex execution recipe aligned with the boundary:

1. do not perform runtime probing inside scenario tests,
2. when worker lifecycle is available from preflight, use mapped worker lifecycle semantics,
3. maintain wait-based completion truth and cleanup semantics.

### 5) Tests

Update/add Codex-focused checks:

1. assert `writing-skills` contains preflight dependency language,
2. assert `writing-skills` does not include direct runtime probing instructions,
3. assert Codex clarification behavior references incremental confirmation (`request_user_input` available -> structured one-decision flow),
4. assert `using-superpowers` documents downstream cache-consumption contract.

---

## Interaction Pattern Standard (Codex)

For workflows like candidate triage and planning confirmation:

1. system proposes default split,
2. user confirms/adjusts one decision at a time,
3. each confirmation applies immediate incremental update,
4. optional free-form input is deferred to final step.

This pattern keeps information density high while reducing response burden and execution ambiguity.

---

## Rollout Plan

1. Land contract text changes in `using-superpowers` and `runtime-compat` first.
2. Land `writing-skills` consumer-mode updates second.
3. Land tests in the same PR to prevent boundary drift.
4. Run Codex test suite and targeted skill-triggering checks before merge.

---

## Verification Plan

1. `tests/codex/run-tests.sh`
2. targeted checks for:
   - `skills/using-superpowers/SKILL.md`
   - `skills/_shared/runtime-compat.md`
   - `skills/writing-skills/SKILL.md`
   - `skills/writing-skills/testing-skills-with-subagents.md`
3. any new explicit-skill-request or skill-triggering fixtures covering incremental clarification behavior.

---

## Acceptance Criteria

1. Runtime/capability detection ownership is explicitly centralized in `using-superpowers`.
2. `writing-skills` provides Codex-specific execution guidance without duplicate probing.
3. Codex clarification behavior is documented as incremental confirmation, not one-shot template filling.
4. Test coverage fails if boundary or interaction contract regresses.

