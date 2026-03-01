---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - creates isolated git worktrees with smart directory selection and safety verification
---

# Using Git Worktrees

## Overview

Create isolated branch workspaces without switching the current checkout.

**Core principle:** deterministic location selection + ignore safety + clean baseline verification.

## Directory Selection Priority

1. existing `.worktrees/`
2. existing `worktrees/`
3. `CLAUDE.md` preference
4. ask user

If both local directories exist, prefer `.worktrees/`.

## Safety Verification

For project-local worktrees, verify ignore status before creation:

```bash
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

If not ignored, add ignore rule and commit before continuing.

Global location (`~/.config/superpowers/worktrees/...`) does not require repo ignore checks.

## Creation Steps

1. Detect project name from repo root.
2. Build full worktree path from selected location and branch name.
3. Create worktree with new branch.
4. Run setup based on detected stack files (`package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`).
5. Run baseline tests.

If baseline tests fail, report and ask whether to proceed.

## Reporting Format

```text
Worktree ready at <path>
Baseline tests: <pass/fail summary>
Ready for <feature>
```

## Red Flags

Never:

- create local worktree without ignore verification,
- proceed on failing baseline without explicit consent,
- assume directory policy when ambiguous.

## Example

See `example-workflow.md`.

## Integration

Common companions:

- `superpowers:subagent-driven-development`
- `superpowers:executing-plans`
- `superpowers:finishing-a-development-branch`
