---
name: receiving-code-review
description: Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionable - requires technical rigor and verification, not performative agreement or blind implementation
---

# Code Review Reception

## Overview

Code review handling is a technical workflow, not a social performance.

**Core principle:** verify first, then implement or push back with evidence.

## Response Pattern

1. Read complete feedback.
2. Restate requirement or ask clarification.
3. Verify against current codebase behavior.
4. Decide: implement, ask more, or push back.
5. Apply changes one item at a time with tests.

## Forbidden Behavior

Never:

- performative agreement statements,
- blind implementation before verification,
- partial implementation when key items are unclear.

## Handling Unclear Feedback

If any item is unclear:

1. stop implementation,
2. ask targeted clarification,
3. resume only after understanding dependencies among comments.

## Source-Specific Handling

### Human partner feedback

- trusted direction after understanding,
- still clarify ambiguous scope,
- prioritize direct action over ceremony.

### External reviewer feedback

Validate before adopting:

- technical correctness for this stack,
- compatibility and regression risk,
- alignment with prior architectural decisions,
- actual usage (YAGNI check).

If uncertain, report what cannot be verified and request direction.

## Pushback Rules

Push back when suggestion is:

- technically incorrect,
- context-incomplete,
- conflicting with required compatibility,
- violating YAGNI for unused paths.

Pushback must include concrete technical evidence.

## Implementation Order

1. Clarify all ambiguities.
2. Fix blocking/high-risk issues.
3. Fix simple correctness issues.
4. Fix structural improvements.
5. Re-test after each item or coherent mini-batch.

## Common Mistakes

| Mistake | Correction |
| --- | --- |
| Blind adoption | Validate in repo context first. |
| Defensive pushback | Use evidence, not tone. |
| Batch fixes without verification | Verify each fix path. |
| Ignoring unclear items | Clarify before coding. |

## Examples

See `examples.md` for concise good/bad reply patterns.

## Bottom Line

Review comments are inputs to evaluate, not instructions to obey blindly.
