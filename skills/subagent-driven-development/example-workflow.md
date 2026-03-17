# Subagent-Driven Development Example Workflow

## Controller startup

```text
- Read plan once.
- Extract all tasks + context.
- Initialize track_tasks.
- Tell user: selected tier, stage sequence, likely time tradeoff, and that this workflow is for context offload/reliability rather than guaranteed speed.
```

## Tier selection example

```text
Task 1: single-file copy update -> lightweight
Task 2: normal feature change in one subsystem -> moderate
Task 3: cross-module auth change -> high-risk
```

## Per-task loop

### Task 1 (`lightweight`)

```text
Controller -> Implementer
Dispatch with fork_context=true + minimal task packet
Implementer asks clarification
Controller answers
Implementer delivers code + tests + self-review
Controller waits for implementer final status
Controller closes implementer worker

Controller marks Task 1 complete
```

### Task 2 (`moderate`, with review loop)

```text
Controller -> Implementer
Dispatch with fork_context=true + minimal task packet
Implementer delivers code + tests
Controller waits for implementer final status
Controller closes implementer worker

Controller -> Reviewer
Reviewer: missing required progress reporting
Controller waits for reviewer final status
Controller closes reviewer worker

Controller -> Implementer (fix)
Implementer adds progress reporting
Controller waits for implementer final status
Controller closes implementer worker

Controller -> Reviewer
Reviewer: approved
Controller waits for reviewer final status
Controller closes reviewer worker

Controller marks Task 2 complete
```

### Task 3 (`high-risk`)

```text
Controller -> Implementer
Dispatch with fork_context=true + minimal task packet
Implementer delivers code + tests
Controller waits for implementer final status
Controller closes implementer worker

Controller -> Spec Reviewer
Dispatch with fork_context=true
Spec Reviewer: approved
Controller waits for spec reviewer final status
Controller closes spec reviewer worker

Controller -> Code Reviewer
Dispatch with fork_context=true
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

Controller marks Task 3 complete
```

## Finalization

```text
After last task:
- dispatch final reviewer for whole change set
- if approved, invoke finishing-a-development-branch
```

## Operational notes

- Keep implementation ownership per task consistent (follow-up same worker when supported; otherwise re-dispatch with equivalent context).
- Reviewer workers should also inherit context when the task depends on parent session history.
- Never skip re-review after fixes.
- Never start next task with unresolved review findings.
- If a worker times out, fallback to controller execution or fallback-serial mode without changing the selected gate semantics.
