# Skill Invocation Reference

Use this reference when deciding whether and how to invoke skills.

## Core Rule

- If applicability is non-zero, invoke the skill.
- Do this before exploration, file reads, or clarification loops.

## Priority

1. Process discipline skills (brainstorming, debugging, verification)
2. Orchestration skills (subagent/executing/parallel dispatch)
3. Implementation/domain skills

## Frequent Rationalizations (and corrections)

| Rationalization | Correction |
| --- | --- |
| "This is simple" | Simplicity does not remove workflow requirements. |
| "I need to inspect files first" | Skill selection precedes exploration. |
| "I remember the skill" | Re-read current skill text; skills evolve. |
| "One quick action first" | No action before skill check. |

## Checklist Behavior

If an invoked skill includes checklist items, map them to `track_tasks` and keep state explicit.

## Cross-Skill Sequencing

- For feature creation: brainstorming -> writing-plans -> orchestrator.
- For debugging: systematic-debugging -> test-driven-development -> verification-before-completion.
- For plan execution: orchestrator -> review checkpoints -> finishing-a-development-branch.
