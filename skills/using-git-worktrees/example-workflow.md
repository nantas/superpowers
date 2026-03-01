# Worktree Setup Example

```text
1) Announce using-git-worktrees workflow.
2) Detect `.worktrees/` exists.
3) Verify `.worktrees/` is ignored.
4) Create branch worktree:
   git worktree add .worktrees/auth -b feature/auth
5) Run project setup and baseline tests.
6) Report path and baseline status.
```

Example report:

```text
Worktree ready at /path/to/repo/.worktrees/auth
Baseline tests passing (47 tests, 0 failures)
Ready to implement auth feature
```
