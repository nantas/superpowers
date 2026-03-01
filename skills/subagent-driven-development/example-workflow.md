# Subagent-Driven Development Example Workflow

## Controller startup

```text
- Read plan once.
- Extract all tasks + context.
- Initialize track_tasks.
```

## Per-task loop

### Task 1

```text
Controller -> Implementer
Implementer asks clarification
Controller answers
Implementer delivers code + tests + self-review

Controller -> Spec Reviewer
Spec Reviewer: approved

Controller -> Code Reviewer
Code Reviewer: approved

Controller marks Task 1 complete
```

### Task 2 (with review loops)

```text
Controller -> Implementer
Implementer delivers code + tests

Controller -> Spec Reviewer
Spec Reviewer: missing required progress reporting

Controller -> Implementer (fix)
Implementer adds progress reporting

Controller -> Spec Reviewer
Spec Reviewer: approved

Controller -> Code Reviewer
Code Reviewer: magic number warning

Controller -> Implementer (fix)
Implementer extracts constant

Controller -> Code Reviewer
Code Reviewer: approved

Controller marks Task 2 complete
```

## Finalization

```text
After last task:
- dispatch final reviewer for whole change set
- if approved, invoke finishing-a-development-branch
```

## Operational notes

- Keep one implementer worker per task for continuity.
- Never skip re-review after fixes.
- Never start next task with unresolved review findings.
