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
Controller waits for implementer final status
Controller closes implementer worker

Controller -> Spec Reviewer
Spec Reviewer: approved
Controller waits for spec reviewer final status
Controller closes spec reviewer worker

Controller -> Code Reviewer
Code Reviewer: approved
Controller waits for code reviewer final status
Controller closes code reviewer worker

Controller marks Task 1 complete
```

### Task 2 (with review loops)

```text
Controller -> Implementer
Implementer delivers code + tests
Controller waits for implementer final status
Controller closes implementer worker

Controller -> Spec Reviewer
Spec Reviewer: missing required progress reporting
Controller waits for spec reviewer final status
Controller closes spec reviewer worker

Controller -> Implementer (fix)
Implementer adds progress reporting
Controller waits for implementer final status
Controller closes implementer worker

Controller -> Spec Reviewer
Spec Reviewer: approved
Controller waits for spec reviewer final status
Controller closes spec reviewer worker

Controller -> Code Reviewer
Code Reviewer: magic number warning
Controller waits for code reviewer final status
Controller closes code reviewer worker

Controller -> Implementer (fix)
Implementer extracts constant
Controller waits for implementer final status
Controller closes implementer worker

Controller -> Code Reviewer
Code Reviewer: approved
Controller waits for code reviewer final status
Controller closes code reviewer worker

Controller marks Task 2 complete
```

## Finalization

```text
After last task:
- dispatch final reviewer for whole change set
- if approved, invoke finishing-a-development-branch
```

## Operational notes

- Keep implementation ownership per task consistent (follow-up same worker when supported; otherwise re-dispatch with equivalent context).
- Never skip re-review after fixes.
- Never start next task with unresolved review findings.
