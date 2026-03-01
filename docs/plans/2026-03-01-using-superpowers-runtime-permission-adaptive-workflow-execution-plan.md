# 2026-03-01 using-superpowers Runtime/Permission Adaptive Workflow Integration Execution Plan

## Objective
Integrate the workflow optimizations from:
- `docs/plans/2026-03-01-multi-agent-workflow-efficiency-improvements-design.md`
- `docs/plans/2026-03-01-codex-worktree-rebase-permission-efficiency-plan.md`

into the existing runtime adapter foundation documented in:
- `docs/plans/2026-03-01-runtime-adapter-codex-toolcall-multi-agent-compat-implementation.md`

so `using-superpowers` can select and enforce suitable workflow behavior based on:
1. tool/runtime capability,
2. permission mode,
3. task shape.

## Scope
### In scope
1. Add global policy section in `skills/using-superpowers/SKILL.md`.
2. Extend `skills/_shared/runtime-compat.md` with normative mode contract.
3. Add tests for routing/mode language in Codex compatibility and skill-triggering suites.
4. Add prompt fixture(s) for policy-trigger coverage.

### Out of scope
1. Runtime engine-level hard enforcement.
2. New monolithic orchestration skill.
3. Broad refactor of unrelated skills.

## Design Constraints
1. Keep capability-first adapter model.
2. Avoid runtime-name hardcoding when capability checks suffice.
3. Keep fallback behavior explicit and deterministic.
4. Keep completion claims gated by verification evidence.

## Implementation Tasks

### Task 1: Add global policy router to `using-superpowers`
Files:
- `skills/using-superpowers/SKILL.md`

Changes:
1. Add `Global Multi-Agent Enforcement Policy (Mandatory)` section with:
   - routing rule across `subagent-driven-development` / `executing-plans` / `dispatching-parallel-agents`;
   - mandatory preflight before first worker spawn;
   - mandatory completion gate via `verification-before-completion`.
2. Add required mode declaration language:
   - execution mode: `parallel-worker` or `fallback-serial`;
   - permission mode: `normal` or `git-write-restricted`.
3. Add decision table mapping task shape + capability + permission mode to selected workflow.

Acceptance:
1. Policy text includes all three routing dimensions.
2. Mode declaration appears as an explicit required output step.

### Task 2: Extend runtime compatibility contract
Files:
- `skills/_shared/runtime-compat.md`

Changes:
1. Promote behavior to MUST-level language for worker-capability branching.
2. Add permission mode contract:
   - default `normal`;
   - switch to `git-write-restricted` when lock-permission signatures appear (for example `.git/*.lock` with `Operation not permitted`).
3. Add deterministic Git write strategy under restricted mode:
   - after first matching error, do not continue retrying non-escalated Git metadata writes;
   - keep read-only checks unprivileged when possible.
4. Require once-per-session mode declaration.

Acceptance:
1. Contract includes capability and permission dimensions.
2. Trigger signatures and adaptation behavior are explicit.

### Task 3: Update Codex runtime compatibility test
Files:
- `tests/codex/test-runtime-compat.sh`

Changes:
1. Extend smoke check prompt to request routing + mode declaration.
2. Assert output references:
   - routing language,
   - `parallel-worker`/`fallback-serial`,
   - `normal`/`git-write-restricted`,
   - `verification-before-completion` completion gate.

Acceptance:
1. Test fails if new policy language is absent.
2. Existing adapter-term checks remain intact.

### Task 4: Add skill-triggering coverage for policy language
Files:
- `tests/skill-triggering/run-all.sh`
- `tests/skill-triggering/prompts/using-superpowers.txt` (new)

Changes:
1. Add a prompt fixture that describes multi-domain work + permission constraints.
2. Add a run target in `run-all.sh` for this prompt.

Acceptance:
1. Suite includes explicit case asserting `using-superpowers` guidance invocation context.

## Verification Plan
1. Run Codex compatibility checks:
   - `tests/codex/run-tests.sh`
2. Run skill-triggering suite:
   - `tests/skill-triggering/run-all.sh`
3. If integration checks are skipped due auth/session state, retain static checks and report skip reason explicitly.

## Rollout Notes
1. Land policy + runtime contract first.
2. Land tests in same change to prevent policy drift.
3. Follow-up can tune wording thresholds based on first 5 sessions.

## Completion Criteria
1. `using-superpowers` has enforceable routing/preflight/verification policy language.
2. Runtime contract includes permission-mode adaptation.
3. Test suites include assertions for the new routing/mode semantics.
4. Verification outputs are captured and summarized.
