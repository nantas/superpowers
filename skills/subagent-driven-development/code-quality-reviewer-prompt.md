# Code Quality Reviewer Prompt Template

Use this template when dispatching a code quality reviewer subagent.

**Purpose:** Verify implementation is well-built (clean, tested, maintainable)

**Only dispatch after spec compliance review passes.**

```
Runtime adapter (`spawn_worker` -> `wait_worker` -> `close_worker`):
  Worker type: `superpowers:code-reviewer`
  Use template at requesting-code-review/code-reviewer.md
  Completion source of truth: `wait_worker` final status (never artifact polling)

  WHAT_WAS_IMPLEMENTED: [from implementer's report]
  PLAN_OR_REQUIREMENTS: Task N from [plan-file]
  BASE_SHA: [commit before task]
  HEAD_SHA: [current commit]
  DESCRIPTION: [task summary]
```

**Code reviewer returns:** Strengths, Issues (Critical/Important/Minor), Assessment

**Reviewer hard constraints:**
- Any write/edit command is review failure.
- Output must include `checked_files` and a no-write attestation sentence.
