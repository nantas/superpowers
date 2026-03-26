# Writing-Skills Codex Tool Guidance Boundary Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement the runtime-boundary contract so `using-superpowers` is the single runtime-detection owner and `writing-skills` consumes preflight cache with Codex-specific clarification guidance.

**Architecture:** Drive changes with TDD: first add failing Codex compatibility assertions, then patch skill docs in the smallest slices needed, then run full verification. Keep runtime adapter language abstract in shared docs while adding a strict consumer contract in `writing-skills`. Land boundary/contract docs and tests together so regressions fail fast.

**Tech Stack:** Markdown skills/docs, Bash test scripts, `rg`/`grep`, Codex compatibility suite.

---

## Status Ledger

Track execution state here. `executing-plans` updates this section in place.

Task | Status | Facts
--- | --- | ---
<!-- executing-plans appends one row per task as execution advances -->

### Task 1: Add Failing Boundary Regression Checks (RED)

**User Verification: not-required**

**Files:**
- Modify: `tests/codex/test-runtime-compat.sh`
- Test: `tests/codex/test-runtime-compat.sh`

**Step 1: Write the failing test block**

Add a new static scan section after existing static checks:

```bash
echo ""
echo "Test 1h: Writing-skills boundary and clarification contract..."
WRITING_SKILLS_FILE="$REPO_ROOT/skills/writing-skills/SKILL.md"
WRITING_SKILLS_SUBAGENT_FILE="$REPO_ROOT/skills/writing-skills/testing-skills-with-subagents.md"

BOUNDARY_PATTERNS=(
    "only skill that performs runtime/capability detection"
    "downstream skills consume cache"
    "must not repeat detection"
)

WRITING_SKILLS_PATTERNS=(
    "requires completed using-superpowers preflight"
    "If preflight cache is absent"
    "invoke using-superpowers"
    "do not run runtime/capability probing"
    "request_user_input_available"
    "one decision boundary per interaction"
)

SUBAGENT_PATTERNS=(
    "do not perform runtime probing inside scenario tests"
    "worker lifecycle is available from preflight"
    "wait-based completion"
    "cleanup semantics"
)
```

**Step 2: Run test to verify it fails**

Run: `bash tests/codex/test-runtime-compat.sh`
Expected: `STATUS: FAILED` with missing pattern lines from new Test 1h block.

**Step 3: Keep RED scope minimal**

Do not modify any skill docs in this task; only keep failing assertions in the test script.

**Step 4: Re-run the same test to confirm stable RED**

Run: `bash tests/codex/test-runtime-compat.sh`
Expected: same `STATUS: FAILED` category, confirming deterministic failing baseline.

**Step 5: Commit**

```bash
git add tests/codex/test-runtime-compat.sh
git commit -m "test: add failing boundary contract checks for writing-skills"
```

### Task 2: Document Preflight Output Ownership in `using-superpowers` (GREEN-1)

**User Verification: not-required**

**Files:**
- Modify: `skills/using-superpowers/SKILL.md`
- Test: `tests/codex/test-runtime-compat.sh`

**Step 1: Add normative preflight output contract section**

Insert a section similar to:

```markdown
### Preflight Output Contract (Normative)

`using-superpowers` is the only skill that performs runtime/capability detection.
Downstream skills consume preflight cache and must not repeat runtime probing.

Required preflight cache fields:
- `worker_profile`: `full-lifecycle | managed-lifecycle | unavailable`
- `execution_mode`: `parallel-worker | fallback-serial`
- `permission_mode`: `normal | git-write-restricted`
- `request_user_input_available`: `true | false`
- `large-worktree-risk`: `true | false`
- `worktree-exempt`: `true | false`
- `heavy-checks-skipped`: `true | false`
```

**Step 2: Add explicit downstream-consumer statement**

Add one short paragraph under preflight saying downstream skills must treat cache as source of truth and must not re-detect capabilities.

**Step 3: Verify new contract text exists**

Run: `rg -n "only skill that performs runtime/capability detection|request_user_input_available|must not repeat runtime probing" skills/using-superpowers/SKILL.md`
Expected: 3+ matches from newly added section.

**Step 4: Re-run failing suite to observe remaining failures only**

Run: `bash tests/codex/test-runtime-compat.sh`
Expected: still `STATUS: FAILED`, but no missing patterns for `using-superpowers` boundary ownership.

**Step 5: Commit**

```bash
git add skills/using-superpowers/SKILL.md
git commit -m "docs: define preflight cache ownership contract in using-superpowers"
```

### Task 3: Add Clarification Capability Contract to Runtime Shared Doc (GREEN-2)

**User Verification: not-required**

**Files:**
- Modify: `skills/_shared/runtime-compat.md`
- Test: `tests/codex/test-runtime-compat.sh`

**Step 1: Add `request_user_input` clarification capability subsection**

Add a subsection near capability detection:

```markdown
## Clarification Capability Contract (Normative)

1. `request_user_input` is a first-class clarification capability signal for Codex-oriented workflows.
2. Clarification capability is detected once during `using-superpowers` preflight and cached for downstream reuse.
3. Downstream skills must consume cached `request_user_input_available` and must not re-probe runtime capability.
```

**Step 2: Keep abstract-action contract unchanged**

Ensure existing abstract actions (`track_tasks`, `spawn_worker`, etc.) remain unchanged and no runtime-router logic is added here.

**Step 3: Verify subsection presence**

Run: `rg -n "Clarification Capability Contract|request_user_input|cached .*request_user_input_available" skills/_shared/runtime-compat.md`
Expected: matches in the new subsection.

**Step 4: Re-run boundary test script**

Run: `bash tests/codex/test-runtime-compat.sh`
Expected: still `STATUS: FAILED`, with remaining failures concentrated in `writing-skills` files.

**Step 5: Commit**

```bash
git add skills/_shared/runtime-compat.md
git commit -m "docs: add codex clarification capability contract to runtime compat"
```

### Task 4: Add `writing-skills` Runtime Consumer Mode Contract (GREEN-3)

**User Verification: not-required**

**Files:**
- Modify: `skills/writing-skills/SKILL.md`
- Test: `tests/codex/test-runtime-compat.sh`
- Test: `tests/codex/test-skill-context-budget.sh`

**Step 1: Add `Runtime Integration (Consumer Mode)` section**

Insert a new section with explicit required statements:

```markdown
## Runtime Integration (Consumer Mode)

This skill requires completed `using-superpowers preflight`.
If preflight cache is absent, stop and invoke `using-superpowers` first.
Do not run runtime/capability probing in this skill.

Use cached preflight capability fields as input, especially `request_user_input_available`.
For Codex clarification loops:
1. Ask one decision boundary per interaction.
2. Prefer 2-3 structured options.
3. Avoid one-shot large free-form templates.
4. Apply incremental updates after each confirmed answer.
```

**Step 2: Add runtime-adapter reference line**

Add a short line referencing `@skills/_shared/runtime-compat.md` for abstract action mappings and `@superpowers:using-superpowers` for preflight ownership.

**Step 3: Verify section content with grep**

Run: `rg -n "Runtime Integration \(Consumer Mode\)|using-superpowers preflight|do not run runtime/capability probing|one decision boundary" skills/writing-skills/SKILL.md`
Expected: matches for all four phrases.

**Step 4: Verify context budget still passes**

Run: `bash tests/codex/test-skill-context-budget.sh`
Expected: PASS for `skills/writing-skills/SKILL.md` budget line.

**Step 5: Commit**

```bash
git add skills/writing-skills/SKILL.md
git commit -m "docs: add writing-skills runtime consumer-mode contract"
```

### Task 5: Add Codex Subagent Testing Recipe in `writing-skills` Reference (GREEN-4)

**User Verification: not-required**

**Files:**
- Modify: `skills/writing-skills/testing-skills-with-subagents.md`
- Test: `tests/codex/test-runtime-compat.sh`

**Step 1: Add Codex execution recipe subsection**

Append a section such as:

```markdown
## Codex Execution Recipe (Boundary-Aligned)

1. Do not perform runtime probing inside scenario tests; consume preflight cache from `using-superpowers`.
2. When worker lifecycle is available from preflight, use mapped worker lifecycle semantics from runtime compatibility guidance.
3. Completion truth comes from wait-based completion semantics; do not infer completion from artifacts.
4. Preserve cleanup semantics after final wait results when runtime exposes explicit close behavior.
```

**Step 2: Ensure wording aligns with shared runtime contract**

Use terms already present in `skills/_shared/runtime-compat.md` (`wait`, `wait-any`, cleanup/close).

**Step 3: Verify new recipe text exists**

Run: `rg -n "Do not perform runtime probing|worker lifecycle is available from preflight|wait-based completion|cleanup semantics" skills/writing-skills/testing-skills-with-subagents.md`
Expected: 4 matches in the new subsection.

**Step 4: Run boundary test script again**

Run: `bash tests/codex/test-runtime-compat.sh`
Expected: static contract tests PASS; integration sections may PASS or SKIP depending on local Codex auth.

**Step 5: Commit**

```bash
git add skills/writing-skills/testing-skills-with-subagents.md
git commit -m "docs: align writing-skills subagent testing with preflight boundary"
```

### Task 6: Final Verification and PR-Ready Evidence

**User Verification: not-required**

**Files:**
- Test: `tests/codex/test-runtime-compat.sh`
- Test: `tests/codex/test-skill-context-budget.sh`
- Modify: `docs/plans/2026-03-26-writing-skills-codex-tool-guidance-boundary-implementation.md` (Status Ledger only, if needed)

**Step 1: Run full Codex runtime compatibility suite**

Run: `bash tests/codex/test-runtime-compat.sh`
Expected: `STATUS: PASSED` or explicit integration `SKIP` with zero FAIL lines.

**Step 2: Run skill context budget checks**

Run: `bash tests/codex/test-skill-context-budget.sh`
Expected: PASS for all checked files, including `skills/writing-skills/SKILL.md` and `skills/using-superpowers/SKILL.md`.

**Step 3: Capture verification output snippets**

Collect key PASS/SKIP lines for PR summary and commit notes.

**Step 4: Confirm changed files match design scope only**

Run: `git status --short`
Expected: only planned files changed (`using-superpowers`, `runtime-compat`, `writing-skills`, codex test, plan/status docs).

**Step 5: Commit final test/documentation alignment**

```bash
git add tests/codex/test-runtime-compat.sh skills/using-superpowers/SKILL.md skills/_shared/runtime-compat.md skills/writing-skills/SKILL.md skills/writing-skills/testing-skills-with-subagents.md
git commit -m "test: enforce codex runtime-boundary contract for writing-skills"
```

## Implementation Notes

- Apply `@superpowers:test-driven-development` strictly: keep RED visible before each GREEN slice.
- Use `@superpowers:verification-before-completion` before any final success claim.
- Execute this plan with `@superpowers:executing-plans` and update Status Ledger after each task.
