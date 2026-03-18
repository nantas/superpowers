---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - creates isolated git worktrees with smart directory selection and safety verification
---

# Using Git Worktrees

## Overview

Create isolated branch workspaces without switching the current checkout.

**Core principle:** deterministic location selection + ignore safety + clean baseline verification.

If preflight cached `worktree-exempt=true`, do not create a worktree. Report the exemption and return control to the caller.
This skill requires a completed `using-superpowers preflight`.
If preflight cache is absent, stop and invoke using-superpowers first.

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

1. Verify `using-superpowers preflight` already ran before any path or Git mutation.
2. If preflight cache is absent, stop and invoke using-superpowers first.
3. Check preflight cache for large-worktree decisions.
4. If `worktree-exempt=true`, report that this repo must use a non-worktree branch workflow and stop.
5. Detect project name from repo root.
6. Build full worktree path from selected location and branch name.
7. Create worktree with new branch.
8. Run setup based on detected stack files (`package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`).
9. Run baseline tests.

If large-worktree cache reports `large-worktree-risk=true` and `heavy-checks-skipped=true`, skip baseline tests and report minimal verification only.

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

Callers must honor `worktree-exempt=true` and skip this skill when that cache flag is set.
