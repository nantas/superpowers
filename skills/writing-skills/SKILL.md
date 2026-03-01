---
name: writing-skills
description: Use when creating new skills, editing existing skills, or verifying skills work before deployment
---

# Writing Skills

## Overview

Skill authoring follows TDD for process documentation.

**Core principle:** if you did not observe baseline failure without the skill, you do not know whether the skill teaches the right behavior.

**REQUIRED BACKGROUND:** Use `superpowers:test-driven-development` concepts (RED -> GREEN -> REFACTOR) before applying this workflow.

**Official complement:** See `anthropic-best-practices.md` for vendor guidance; this skill defines the process discipline for this repository.

## What a Skill Is

A skill is reusable operational guidance.

- Use skills for repeatable techniques, decision patterns, and references.
- Do not write skills as one-off narratives tied to a single session.
- Put project-specific conventions in `CLAUDE.md`, not in a reusable skill.

## The Iron Law

```
NO SKILL CHANGES WITHOUT A FAILING TEST FIRST
```

No exception for "small edits" or "docs-only changes". If test-first was skipped, discard the change and restart properly.

## RED -> GREEN -> REFACTOR (Skill Version)

### RED: Baseline Failure

1. Define pressure scenarios for the behavior this skill should enforce.
2. Run scenarios **without** the skill.
3. Record exact failure behavior and rationalizations.

### GREEN: Minimal Skill

1. Write only the guidance needed to prevent observed failures.
2. Keep `SKILL.md` as an entrypoint with strict rules and quick workflow.
3. Move large examples/reference content to adjacent files and link them.
4. Re-run scenarios **with** the skill and verify improvement.

### REFACTOR: Close Loopholes

1. Capture new rationalizations from retests.
2. Add explicit counters where needed.
3. Re-run until behavior is consistently compliant.

## Discovery and Search Requirements

Keep discovery quality high so agents can find the skill:

1. Frontmatter must only include `name` and `description`.
2. Description must start with `Use when...` and describe triggers, not workflow.
3. Include concrete symptoms and terms users/agents will search for.
4. Keep `SKILL.md` compact; move deep detail into referenced docs.

Detailed guidance is in `cso-guide.md`.

## File Organization Rules

Use a flat directory under `skills/<skill-name>/`.

- `SKILL.md`: mandatory entrypoint.
- Additional files: only for heavy reference or reusable tools.
- Keep short examples inline only when necessary for comprehension.

Use these local references for large material:

- `testing-skills-with-subagents.md`
- `discipline-hardening-guide.md`
- `graphviz-conventions.dot`
- `render-graphs.js`

## Flowcharts and Examples

- Use flowcharts only for non-obvious decisions or loops.
- Do not encode copy-paste code in flowcharts.
- Prefer one strong, runnable example over many shallow variants.

Graphviz conventions: `graphviz-conventions.dot`.

## Testing Expectations by Skill Type

- Discipline skill: pressure tests under time/sunk-cost/authority stress.
- Technique skill: scenario-based application tests.
- Pattern skill: recognition + when-not-to-use tests.
- Reference skill: retrieval + correct application tests.

Full test method: `testing-skills-with-subagents.md`.

## Minimal Creation Checklist

Use `track_tasks` for each item.

- [ ] Baseline scenarios defined and run without skill.
- [ ] Baseline failures/rationalizations recorded verbatim.
- [ ] `name`/`description` satisfy format and trigger quality rules.
- [ ] `SKILL.md` contains concise workflow and hard constraints.
- [ ] Long guidance moved to sidecar docs with explicit links.
- [ ] Scenarios rerun with skill and pass criteria met.
- [ ] New loopholes addressed and re-tested.

## Common Failure Modes

- Writing workflow summary in description (agents skip full skill).
- Repeating heavy guidance inline in `SKILL.md`.
- Shipping without baseline failure evidence.
- Relying on confidence instead of pressure testing.

For rationalization-resistant writing patterns, see `discipline-hardening-guide.md`.

## Bottom Line

Treat skills like production process code:

1. Test first.
2. Keep entrypoint concise.
3. Offload deep detail into on-demand references.
4. Re-test until robust.
