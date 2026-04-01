---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** This should be run in an isolated workspace. Default to a dedicated worktree, but if preflight cached `worktree-exempt=true`, use the current checkout or another user-approved non-worktree branch workflow.
This skill requires a completed `using-superpowers preflight` so workspace constraints are already known.
If preflight cache is absent, stop and invoke using-superpowers first.

**Save plans to:** `docs/plans/YYYY-MM-DD-<feature-name>.md`

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---

## Status Ledger

Track execution state here. `executing-plans` updates this section in place.

Task | Status | Facts
--- | --- | ---
<!-- executing-plans appends one row per task as execution advances -->
```

Keep the status ledger at the top of the plan so execution can resume safely after context switches.

## Design Traceability Matrix (Required)

Every plan MUST include a `Design Traceability Matrix` section near the top of the document (after `Status Ledger`).

Use this table shape:

```markdown
## Design Traceability Matrix

Design Clause ID | Criticality | Mapped Tasks | Verification Command | Artifact Evidence Field | Failure Signal
--- | --- | --- | --- | --- | ---
DC-01 | critical | Task 2, Task 3 | `pytest tests/foo/test_bar.py -k chain` | `reports/case_a.json:confirmed_chain.steps` | `confirmed_chain.steps is empty`
```

Rules:
- Every `critical` design clause must map to at least one task.
- Every mapped clause must include executable verification and concrete evidence fields.
- Every mapped clause must include an explicit failure signal.
- Do not accept structure-only checks for critical clauses; add semantic checks.

## Authenticity Assertions (Required)

For each critical module, include at least one negative test/assertion that catches fake compliance.

Minimum assertion patterns:
- `assert no placeholder path`
- `assert live mode has tool evidence`
- `assert freeze requires non-empty confirmed_chain.steps`

## Task Structure

````markdown
### Task N: [Component Name]

**User Verification: required|not-required**
Default is `not-required` if omitted.
Place tasks that can be verified together in adjacent Task blocks.
If `required`, you MUST include all four fields below in the task block:
- `Human Verification Checklist`: 3-7 concrete items the user can verify.
- `Acceptance Criteria`: one explicit pass criterion per checklist item.
- `Failure Signals`: what specific result means this item fails.
- `User Decision Prompt`: exact prompt text asking only `通过` or `不通过`.

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

**Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

**Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

**Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

**Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## Remember
- Exact file paths always
- Complete code in plan (not "add validation")
- Exact commands with expected output
- Include `User Verification` on tasks that need human verification before continuing
- Keep human-verification tasks adjacent when they should be validated together
- For every `User Verification: required` task, include checklist + criteria + failure signals + fixed decision prompt
- Reference relevant skills with @ syntax
- DRY, YAGNI, TDD, frequent commits

## Plan Authenticity Audit (Required, Post-Write)

After the plan file is written, and before any execution handoff, run an independent review subagent audit.

Use runtime adapter actions from `../_shared/runtime-compat.md`:
1. `spawn_worker` a read-only reviewer for the plan (no file edits allowed for the worker).
2. Reviewer checks whether the plan can truly satisfy design/requirement semantics, not just structure.
3. `wait_worker` for reviewer completion (completion source of truth).
4. `close_worker` when finished.

Audit rubric (required):
- Design Coverage: critical clauses have task + command + evidence + failure signal mapping.
- Authenticity: no fake live-mode semantics without tool evidence.
- Placeholder Leakage: key artifacts reject placeholder values.
- Semantic Closure: checks verify real closure, not only field presence.
- Negative Tests: critical paths include anti-fake negative cases.

Severity model:
- `P0`: critical mismatch; execution handoff is blocked.
- `P1`: major risk; must be fixed or explicitly accepted as risk in the verdict.
- `P2`: improvement suggestion; does not block by itself.

Pass condition for handoff:
- zero `P0`;
- every `P1` is marked `fixed` or `accepted`.

Append this block to the end of the same plan file:

```markdown
## Plan Audit Verdict
audit_scope: [design doc sections / requirements covered]
finding_summary: P0=<n>, P1=<n>, P2=<n>
critical_mismatches:
- [P0 item or `none`]
major_risks:
- [P1 item + status: fixed|accepted]
anti_placeholder_checks:
- [check + result]
authenticity_checks:
- [check + result]
approval_decision: pass|blocked
```

If `approval_decision` is `blocked`, revise plan and rerun audit until it is `pass`.

## Execution Handoff

After saving the plan and recording a passing `Plan Audit Verdict`, offer execution choice:

**"Plan complete and saved to `docs/plans/<filename>.md`. Two execution options:**

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

**Which approach?"**

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:subagent-driven-development
- Stay in this session
- Fresh subagent per task + code review

**If Parallel Session chosen:**
- Guide them to open new session in the isolated workspace chosen by preflight; if `worktree-exempt=true`, do not require a worktree
- **REQUIRED SUB-SKILL:** New session uses superpowers:executing-plans
