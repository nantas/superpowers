# Four Phases Playbook

Expanded execution guide for `systematic-debugging`.

## Phase 1: Root Cause Investigation

### 1) Read errors completely

- capture exact message, code, path, line
- read full stack, not only top frame
- note warnings that indicate misconfiguration

### 2) Reproduce reliably

- write exact reproduction steps
- record frequency (always/intermittent)
- capture inputs, env, and timing conditions

If you cannot reproduce, increase instrumentation before proposing fixes.

### 3) Check recent changes

- inspect recent commits/diffs
- compare dependency and config changes
- compare environment deltas across machines/CI

### 4) Gather evidence across boundaries

For multi-layer systems (workflow -> script -> runtime -> downstream):

1. log input entering each boundary
2. log output leaving each boundary
3. validate env/config propagation
4. verify state transitions at each layer

Boundary instrumentation pattern:

```text
for each boundary:
  observe inbound data
  observe outbound data
  check expected invariants
```

### 5) Trace data flow back to source

When a bad value appears deep in stack:

- identify where it first becomes wrong
- walk callers backwards to origin
- fix at origin, not at symptom point

Use `root-cause-tracing.md` for detailed tracing technique.

## Phase 2: Pattern Analysis

1. Find a working path in the same codebase.
2. Compare working and failing paths line-by-line.
3. Enumerate all deltas (logic, order, config, assumptions).
4. Validate required dependencies and invariants.

Do not assume a difference is irrelevant until tested.

## Phase 3: Hypothesis and Testing

1. State one hypothesis:

```text
Hypothesis: X is failing because Y under condition Z.
```

2. Test minimally:

- one variable at a time
- smallest code/config change possible
- keep unrelated code untouched

3. Evaluate strictly:

- confirmed -> proceed to implementation
- not confirmed -> new hypothesis
- ambiguous -> gather more evidence

## Phase 4: Implementation

1. Create failing test for the discovered root cause.
2. Implement one focused fix.
3. Run targeted tests and regressions.
4. Verify no unrelated regressions were introduced.

If fix attempt fails:

- attempt count < 3: return to Phase 1 with new evidence
- attempt count >= 3: stop and review architecture (possible design-level issue)

## Decision Guardrails

- Never propose fix before Phase 1 evidence.
- Never stack speculative fixes.
- Never treat confidence as verification.

## Handoff Template

```text
Issue:
Reproduction:
Evidence:
Hypothesis:
Minimal test/change:
Result:
Next step:
```
