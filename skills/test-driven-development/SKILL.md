---
name: test-driven-development
description: Use when implementing any feature or bugfix, before writing implementation code
---

# Test-Driven Development (TDD)

## Overview

Write the test first, watch it fail for the expected reason, then write the smallest implementation that passes.

**Core principle:** if you never observed the failure first, you do not know whether your test actually validates behavior.

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

If code was written first, discard it and restart from a failing test.

## When to Use

Always for:

- new features
- bug fixes
- behavior changes
- refactors that can affect behavior

Exception only with explicit human approval (e.g., throwaway prototype).

## Red -> Green -> Refactor

### RED

1. Write one minimal test for one behavior.
2. Keep naming specific and behavior-focused.
3. Prefer real code path; avoid unnecessary mocking.

### Verify RED

Run test and confirm:

- it fails,
- for the expected missing-behavior reason,
- not because of typo/setup errors.

### GREEN

1. Implement minimal code to satisfy the failing test.
2. Do not add extra features.
3. Do not refactor unrelated code.

### Verify GREEN

Run tests and confirm:

- target test passes,
- related tests remain green,
- output is clean (no hidden failures/warnings).

### REFACTOR

After green only:

- remove duplication,
- improve naming/structure,
- keep behavior unchanged.

Then repeat with the next failing test.

## Quality Rules for Tests

- one behavior per test
- clear test names
- assertions on outcomes/behavior, not implementation internals
- include edge and failure cases for important logic

## Verification Checklist

- [ ] Every new behavior starts with a failing test.
- [ ] Each failing test was observed before implementation.
- [ ] Failure reason matched intended missing behavior.
- [ ] Minimal implementation used to pass test.
- [ ] Full relevant test set re-run and passing.
- [ ] No regressions introduced.

## Red Flags

Stop and restart if you see:

- code before test
- "I'll add tests later"
- test passing immediately on first run
- "manual verification is enough"
- "this is too small for TDD"

## Related Guidance

- Rationale, common objections, and worked examples: `tdd-rationale-and-cases.md`
- Mocking/test utility pitfalls: `testing-anti-patterns.md`
- For bug investigations before writing tests: `superpowers:systematic-debugging`

## Final Rule

```
Production code -> failing test existed first
Otherwise -> not TDD
```
