---
name: systematic-debugging
description: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes
---

# Systematic Debugging

## Overview

Random fixes create thrash. Root-cause-first debugging is faster and safer.

**Core principle:** investigate first, then fix.

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

If Phase 1 is incomplete, do not propose fixes.

## When to Use

Use for any technical failure:

- test failures
- production bugs
- unexpected behavior
- integration/build/performance issues

Especially mandatory under time pressure or after failed fix attempts.

## Four Phases (Short Form)

You must complete phases in order.

### Phase 1: Root Cause Investigation

1. Read full errors and stack traces.
2. Reproduce with reliable steps.
3. Check recent changes and environment differences.
4. For multi-component systems, instrument boundaries and capture evidence.
5. Trace data flow back to source.

Detailed playbook: `four-phases-playbook.md`.

### Phase 2: Pattern Analysis

1. Find working examples in the same codebase.
2. Compare against references completely (do not skim).
3. List concrete differences between working and broken paths.
4. Validate dependencies/config assumptions.

### Phase 3: Hypothesis and Testing

1. State one explicit hypothesis.
2. Run smallest possible test/change.
3. Evaluate result before any additional changes.
4. If unknowns remain, state them and gather more evidence.

### Phase 4: Implementation

1. Write failing reproduction test first.
2. Implement one root-cause fix.
3. Re-run relevant and regression tests.
4. If fix fails, return to Phase 1.
5. If 3+ fix attempts fail, stop and question architecture with your human partner.

## Red Flags

If you hear these thoughts, stop and reset to Phase 1:

- "quick fix now, investigate later"
- "let's change multiple things and see"
- "probably X"
- "skip test, manual verify"
- "one more attempt" (after repeated failures)

## Rationalization Checks

| Excuse | Correction |
| --- | --- |
| "No time for process" | Process is faster than thrashing. |
| "Simple bug" | Simple bugs still have causes. |
| "Multiple fixes are faster" | You lose causality and create regressions. |
| "I'll test after" | Untested fix is untrusted fix. |

## Supporting References

- `four-phases-playbook.md`
- `root-cause-tracing.md`
- `defense-in-depth.md`
- `condition-based-waiting.md`

## Related Skills

- `superpowers:test-driven-development`
- `superpowers:verification-before-completion`

## Bottom Line

Investigate -> compare -> hypothesize -> test -> implement.

Skipping order is the bug in your process.
