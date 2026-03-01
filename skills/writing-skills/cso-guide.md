# CSO Guide for Skill Authors

This guide expands the search/discovery rules referenced by `SKILL.md`.

## 1) Description Field Rules

Description is for trigger detection, not process summary.

- Start with `Use when...`.
- Describe symptoms/contexts that signal applicability.
- Keep it third-person and technology-appropriate.
- Avoid workflow details that could replace reading the skill body.

Good:

```yaml
description: Use when tests fail intermittently due to timing dependencies or race conditions
```

Bad:

```yaml
description: Use for flaky tests by writing polling helpers, then replacing sleep calls
```

## 2) Keyword Coverage

Include terms agents/users actually search:

- Error strings and log symptoms
- Problem words (flaky, hanging, timeout, race, cleanup)
- Tool and runtime names (only when relevant)
- Synonyms for the same operational problem

## 3) Naming

Use descriptive, action-oriented names.

- Prefer verb/gerund forms for workflows.
- Avoid abstract umbrella names that hide use cases.
- Use lowercase kebab-case.

## 4) Token Efficiency

`SKILL.md` should be an entrypoint. Move heavy detail out.

Techniques:

- Put deep API/reference material in sidecar docs.
- Keep one concise representative example in `SKILL.md`.
- Link to tools/scripts for flags and advanced options.
- Remove duplicate explanations already present in referenced skills.

### Practical size guidance

- High-frequency entry skills: keep very small.
- Other skills: keep concise enough to scan quickly.
- Place optional depth in `*.md` references beside the skill.

Verify with:

```bash
wc -w skills/<skill-name>/SKILL.md
```

## 5) Cross-Reference Strategy

- Prefer explicit skill names for required sub-skills.
- Prefer plain file references for local sidecar docs.
- Avoid markdown patterns that force-load large files when not needed.

Examples:

- `REQUIRED SUB-SKILL: Use superpowers:test-driven-development`
- `See testing-skills-with-subagents.md for pressure scenario structure`

## 6) Anti-Patterns

- Description includes full step-by-step workflow.
- Multiple low-quality examples in many languages.
- Large inline reference tables in `SKILL.md`.
- Narrative session logs presented as reusable guidance.

## 7) Fast Quality Gate

Before shipping a skill:

- Trigger description is specific and workflow-free.
- `SKILL.md` is concise and scannable.
- Heavy detail moved to sidecar docs.
- Search terms for symptoms are present.
- Links resolve correctly.
