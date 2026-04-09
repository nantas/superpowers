---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work - guides completion of development work by presenting structured options for merge, PR, or cleanup
---

# Finishing a Development Branch

## Overview

Guide completion of development work by presenting clear options and handling chosen workflow.

**Core principle:** Verify tests → ensure commit-ready tree → resolve base branch → present options → execute choice → clean up.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## The Process

### Step 1: Verify Tests

**Before presenting options, verify tests pass:**

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**If tests fail:**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

Stop. Don't proceed to Step 2.

**If tests pass:** Continue to Step 2.

### Step 2: Require a Clean Working Tree

Before branch/merge decisions, ensure no pending local edits:

```bash
git status --porcelain
```

If output is non-empty, do not proceed to Step 3.
Create a checkpoint commit first (default behavior), then continue:

```bash
git add <scoped-files>
git commit -m "<type>: <summary>"
```

Do not proceed with uncommitted changes.

### Step 3: Capture Feature Branch and Workspace Context

```bash
# Current implementation branch
git branch --show-current

# Inspect whether this branch is attached to a dedicated worktree path
git worktree list --porcelain
```

Record:
- `feature-branch` (required)
- `feature-worktree-path` (if present)
- `worktree-managed=true|false`

If `feature-branch` is empty, stop and ask user for branch context before proceeding.

### Step 4: Determine Base Branch

```bash
# Prefer the branch this worktree was created from (reflog entry)
git reflog show --format=%gs --reverse <feature-branch> | rg -m1 "branch: Created from " | sed 's/branch: Created from //'
```

Do not assume main/master.
If the reflog lookup is empty, try default remote branch:

```bash
git symbolic-ref --quiet --short refs/remotes/origin/HEAD | sed 's@^origin/@@'
```

If both checks are empty, ask the user to confirm base branch before proceeding.
If the user confirms main/master, use that.

If `<base-branch> == <feature-branch>`, treat merge target as invalid and ask for a different base branch (or use Option 2/3 instead of local merge).

### Step 5: Present Options

Present exactly these 4 options:

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

**Don't add explanation** - keep options concise.

### Step 6: Execute Choice

#### Option 1: Merge Locally

```bash
# Switch to base branch
git checkout <base-branch>

# Pull latest
git pull

# Merge feature branch
git merge <feature-branch>

# Verify tests on merged result
<test command>

# If tests pass
git branch -d <feature-branch>
```

Then: Cleanup worktree (Step 7)

#### Option 2: Push and Create PR

```bash
# Push branch
git push -u origin <feature-branch>

# Create PR
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
<2-3 bullets of what changed>

## Test Plan
- [ ] <verification steps>
EOF
)"
```

Do not cleanup worktree automatically for Option 2.

#### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

**Don't cleanup worktree.**

#### Option 4: Discard

**Confirm first:**
```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

Wait for exact confirmation.

If confirmed:
```bash
git checkout <base-branch>
git branch -D <feature-branch>
```

Then: Cleanup worktree (Step 7)

### Step 7: Cleanup Worktree

**For Options 1 and 4 only:**

Check if feature branch has a dedicated worktree path:
```bash
git worktree list --porcelain | rg "worktree |branch refs/heads/<feature-branch>"
```

If yes, and `<feature-worktree-path>` is not the current active checkout path:
```bash
git worktree remove <feature-worktree-path>
```

If no dedicated worktree exists, report non-worktree branch workflow and skip cleanup.

**For Options 2 and 3:** Keep worktree/current checkout as-is.

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | ✓ | - | - | ✓ |
| 2. Create PR | - | ✓ | ✓ | - |
| 3. Keep as-is | - | - | ✓ | - |
| 4. Discard | - | - | - | ✓ (force) |

## Common Mistakes

**Skipping test verification**
- **Problem:** Merge broken code, create failing PR
- **Fix:** Always verify tests before offering options

**Open-ended questions**
- **Problem:** "What should I do next?" → ambiguous
- **Fix:** Present exactly 4 structured options

**Automatic worktree cleanup**
- **Problem:** Remove worktree when might need it (Option 2, 3)
- **Fix:** Only cleanup for Options 1 and 4

**Skipping dirty-tree checkpoint**
- **Problem:** Reach merge/PR flow with uncommitted files
- **Fix:** Run `git status --porcelain`; commit first, then continue

**Base branch equals feature branch**
- **Problem:** Invalid self-merge target causes branch confusion
- **Fix:** Treat `<base-branch> == <feature-branch>` as invalid and require a different base

**No confirmation for discard**
- **Problem:** Accidentally delete work
- **Fix:** Require typed "discard" confirmation

## Red Flags

**Never:**
- Proceed with failing tests
- Proceed with uncommitted changes
- Merge without verifying tests on result
- Delete work without confirmation
- Force-push without explicit request

**Always:**
- Verify tests before offering options
- Ensure `git status --porcelain` is clean before branch integration
- Present exactly 4 options
- Get typed confirmation for Option 4
- Clean up worktree for Options 1 & 4 only

## Integration

**Called by:**
- **subagent-driven-development** (Step 7) - After all tasks complete
- **executing-plans** (Step 5) - After all batches complete

**Pairs with:**
- **using-git-worktrees** - Cleans up worktree created by that skill
