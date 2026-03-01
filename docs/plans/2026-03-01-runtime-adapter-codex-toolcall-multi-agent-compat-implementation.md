# Runtime Adapter + Codex Tool Call + Multi-Agent Compatibility (Implementation Record)

**Date:** 2026-03-01
**Status:** Completed (implemented)
**Primary Commit:** `a827074c94069af5dfd100e40be302021508e9a7`
**Related Commit:** `6444fec49f5f1988cc3f69ac575efd9126472bbc` (repo AGENTS guidance)

---

## Purpose

This document records the **already implemented** compatibility work for Superpowers skills to:

1. Support Codex-native tool-calling semantics.
2. Unify multi-agent orchestration terminology across runtimes.
3. Add Codex-specific compatibility test coverage and unified test entrypoint.

This is an implementation supplement (post-change record), not a proposal.

---

## Delivered Scope (from commit `a827074`)

### 1) Added shared runtime compatibility contract

**File added:**
- `skills/_shared/runtime-compat.md`

**Delivered behavior:**
- Introduced capability-based adapter actions:
  - `track_tasks`
  - `load_skill`
  - `spawn_worker`
  - `message_worker`
  - `wait_worker`
  - `close_worker`
- Added explicit Codex mapping:
  - `track_tasks` -> `update_plan`
  - `spawn_worker` -> `spawn_agent`
  - `message_worker` -> `send_input`
  - `wait_worker` -> `wait`
  - `close_worker` -> `close_agent`
- Defined fallback behavior for non-multi-agent runtimes while preserving process checkpoints.

### 2) Migrated skill language to adapter actions (de-hardcode runtime terms)

**Updated files:**
- `skills/using-superpowers/SKILL.md`
- `skills/subagent-driven-development/SKILL.md`
- `skills/executing-plans/SKILL.md`
- `skills/dispatching-parallel-agents/SKILL.md`
- `skills/requesting-code-review/SKILL.md`
- `skills/subagent-driven-development/implementer-prompt.md`
- `skills/subagent-driven-development/spec-reviewer-prompt.md`
- `skills/subagent-driven-development/code-quality-reviewer-prompt.md`
- `skills/writing-skills/SKILL.md`
- `skills/writing-skills/persuasion-principles.md`

**Delivered behavior:**
- Replaced legacy references like `TodoWrite` / `Task tool` with adapter terminology.
- Updated workflow instructions and DOT flow nodes to use `load_skill` / `track_tasks` / worker actions.
- Updated subagent prompt templates to express dispatch via adapter semantics (`spawn_worker`, then `wait_worker`/`close_worker`).

### 3) Updated documentation for Codex/OpenCode compatibility guidance

**Updated files:**
- `docs/README.codex.md`
- `docs/README.opencode.md`
- `docs/testing.md`

**Delivered behavior:**
- Added/updated mapping tables and compatibility notes.
- Documented capability-first strategy (avoid runtime-name hardcoding where possible).
- Documented Codex-specific runtime compatibility test entrypoints.

### 4) Added Codex compatibility test suite + unified runner

**Added files:**
- `tests/codex/run-tests.sh`
- `tests/codex/test-runtime-compat.sh`
- `tests/run-all.sh`

**Delivered behavior:**
- Added static scan to catch legacy hardcoded terms in active skills/docs.
- Added Codex runtime capability probe for required tools.
- Added smoke check to ensure adapter terminology appears in model behavior.
- Added unified test runner with optional suites/integration flags.

---

## Change Size

From commit stats (`a827074`):

- **17 files changed**
- **577 insertions, 41 deletions**

---

## What This Implementation Standardizes

1. Skills describe orchestration in **portable adapter actions**, not platform-specific tool names.
2. Codex mapping is explicit and test-backed.
3. Multi-agent workflows can preserve semantics across runtimes with fallback rules.
4. Test entrypoint is unified (`tests/run-all.sh`) and includes Codex compatibility coverage.

---

## Verification Artifacts Included in the Implementation

The implementation introduces verification mechanisms in-repo:

- `tests/codex/test-runtime-compat.sh`
  - static scan for legacy terms
  - tool capability probe
  - behavior smoke check
- `tests/codex/run-tests.sh`
- `tests/run-all.sh`

Note: This document records delivered test infrastructure and scope from commits; it does not claim a fresh re-run at documentation time.

---

## Follow-up Documentation Links

- Design/intent context: `docs/plans/2026-03-01-multi-agent-workflow-efficiency-improvements-design.md`
- This implementation record: `docs/plans/2026-03-01-runtime-adapter-codex-toolcall-multi-agent-compat-implementation.md`

