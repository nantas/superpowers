# Code Review Response Examples

## 1) Performative Agreement (Bad)

```text
Reviewer: Remove legacy path.
Response: "You're absolutely right! Great point!"
```

Why bad: no verification, no technical evaluation.

## 2) Technical Verification (Good)

```text
Reviewer: Remove legacy path.
Response: "Checked deployment targets: pre-13 support still required. Removing path breaks compatibility. I can either keep it and fix bug X, or drop pre-13 support if approved."
```

Why good: evidence-based, decision-oriented.

## 3) YAGNI Validation (Good)

```text
Reviewer: Add full metrics export endpoint.
Response: "Searched usage and found no callers for this endpoint. Should we remove it per YAGNI instead of expanding it?"
```

Why good: validates usage before adding complexity.

## 4) Clarification Before Action (Good)

```text
Partner: Fix items 1-6.
Response: "I understand 1,2,3,6. I need clarification on 4 and 5 before implementation because they may affect schema changes."
```

Why good: prevents incorrect partial implementation.
