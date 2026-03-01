# TDD Rationale and Cases

This document expands the rationale and examples referenced by `SKILL.md`.

## Why order matters

### "I will write tests after implementation"

Tests written after code often pass immediately. Immediate pass does not prove the test can detect missing behavior.

Test-first forces proof that the test fails for the right reason before implementation.

### "I already tested manually"

Manual checks are not durable:

- they are hard to reproduce exactly,
- they are easy to forget,
- they do not automatically protect future changes.

Automated test-first checks are repeatable and regression-safe.

### "Deleting hours of code is wasteful"

Sunk cost is already spent. The decision point is now quality vs uncertainty:

- restart with TDD for confidence,
- or keep unproven code and accept hidden defect risk.

### "TDD is dogmatic; I am being pragmatic"

TDD is pragmatic when measured by total cycle time:

- earlier defect detection,
- safer refactoring,
- faster diagnosis of regressions,
- clearer behavior documentation.

## Common Rationalizations

| Excuse | Reality |
| --- | --- |
| "Too simple to test" | Small code still fails in production contexts. |
| "I will test later" | Later tests cannot prove first-failure behavior. |
| "Existing module has no tests" | New changes are the opportunity to add protection. |
| "Mocks are quicker" | Over-mocking can hide real behavior defects. |

## Worked Bug-Fix Example

### RED

```typescript
test('rejects empty email', async () => {
  const result = await submitForm({ email: '' });
  expect(result.error).toBe('Email required');
});
```

Expected first run: fail because validation is missing.

### GREEN

```typescript
function submitForm(data: FormData) {
  if (!data.email?.trim()) {
    return { error: 'Email required' };
  }
  // unchanged behavior continues
}
```

Expected second run: pass target test; verify broader suite remains green.

### REFACTOR

Extract shared validation helpers only after tests are green.

## Fast diagnostic cues

If TDD feels hard, check design quality:

- difficult setup -> too much coupling
- too many mocks -> poor dependency boundaries
- unclear expected behavior -> requirement ambiguity

Treat test difficulty as design feedback.
