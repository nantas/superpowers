# Discipline Hardening Guide

Use this when a skill must resist rationalization under pressure.

## Objective

Convert abstract rules into behavior that remains stable under:

- time pressure,
- sunk-cost pressure,
- authority pressure,
- fatigue pressure.

## Design Pattern

1. State non-negotiable rule explicitly.
2. List concrete forbidden shortcuts.
3. Add red-flag self-check triggers.
4. Add rationalization table (excuse -> reality).
5. Re-test with pressure scenarios.

## Authoring Tactics

### 1) Ban the loopholes explicitly

Weak:

```markdown
Write tests first.
```

Strong:

```markdown
Write tests first.
No exceptions:
- no keeping pre-written code as reference,
- no "just this once",
- no proceeding on confidence without evidence.
```

### 2) Add spirit/letter guardrails

If a skill is routinely bypassed via phrasing tricks, include explicit language that prevents "spirit vs letter" reframing.

### 3) Build a rationalization table from real failures

Populate from baseline transcripts, not hypothetical guesses.

| Excuse | Reality |
|---|---|
| "This is small" | Small changes still regress behavior. |
| "I will verify later" | Deferred verification is unverified work. |
| "I already checked manually" | Non-repeatable checks do not protect future changes. |

### 4) Add red flags

Examples:

- "just for now"
- "probably fine"
- "close enough"
- "no time to test"

For each red flag, map a mandatory recovery action.

## Test Strategy

1. Run baseline scenario without skill.
2. Capture exact bypass strategy.
3. Add explicit counter text.
4. Re-run same scenario.
5. Repeat until bypass rate is acceptable.

See `testing-skills-with-subagents.md` for scenario construction and scoring.

## Exit Criteria

A discipline skill is ready when:

- pressure scenarios repeatedly produce compliant behavior,
- known loopholes are explicitly blocked,
- no new high-severity rationalization appears in final retest.
