---
name: brainstorming-complex
description: "Use when brainstorming requires deep context discovery loops, context completeness tracking, and drift-aware clarification before design decisions."
---

# Brainstorming (Complex)

Use this skill when regular brainstorming risks premature convergence.

## HARD-GATE

Do NOT invoke implementation skills, write code, scaffold projects, or execute implementation actions before design approval.

## Core Behavior

Use a context-first loop instead of a linear Q&A flow:

1. Explore project context.
2. Build and maintain a context map.
3. Estimate context completeness.
4. Gate each question based on current completeness and unresolved gaps.
5. Re-open context discovery when new user information expands scope.

## Context Map

Track these dimensions as `unknown`, `partial`, `known`, or `conflict`:

- problem and business goal
- current system behavior
- constraints and non-goals
- interfaces and dependencies
- success criteria and acceptance checks
- risks and rollback expectations

## Context Completeness Estimate

Maintain a `context completeness` estimate (0-100).

- Do not move to approach selection while any critical dimension is `unknown` or `conflict`.
- Target threshold before selection questions: completeness >= 75 and no critical conflicts.
- Lower the estimate when contradictions or out-of-scope facts appear.

## Question Gate (Mandatory)

Before asking each question, classify it:

- `information-collection question`: used to close a concrete context gap.
- `selection question`: used to choose between valid approaches.

Gate rules:

1. If completeness is below threshold, ask only an information-collection question.
2. If any critical dimension is `unknown`/`conflict`, ask only an information-collection question.
3. Ask a selection question only after gate conditions are met.
4. Keep one question per message.

## Context Drift (Mandatory Re-entry)

When user responses introduce facts beyond the current map, detect `Context Drift`.

Examples:

- new subsystem or integration constraint
- new policy, compliance, security, or latency requirement
- new success metric or delivery boundary
- contradiction to prior assumptions

On drift:

1. mark affected dimensions as `partial` or `conflict`,
2. decrease completeness estimate,
3. re-open context discovery,
4. resume information-collection questions until stable again.

Do not continue approach selection while drift remains unresolved.

## Workflow

1. Explore repository context (files, docs, recent commits).
2. Initialize the context map and first completeness estimate.
3. Run the gated one-question loop with drift handling.
4. Propose 2-3 approaches only after gate conditions are met.
5. Present design in sections and get approval after each section.
6. Write approved design to `docs/plans/YYYY-MM-DD-<topic>-design.md` and commit.
7. Invoke `superpowers:writing-plans`.

## Terminal State

The terminal state is invoking writing-plans. Do not invoke any other implementation skill directly from this workflow.
