# Worktree Setup Example

```text
1) Announce using-git-worktrees workflow.
2) Check large-worktree cache. If `worktree-exempt=true`, report exemption and stop.
3) Detect `.worktrees/` exists.
4) Verify `.worktrees/` is ignored.
5) Create branch worktree:
   git worktree add .worktrees/auth -b feature/auth
6) Run project setup and baseline tests.
7) Report path and baseline status.
```

Example report:

```text
Worktree ready at /path/to/repo/.worktrees/auth
Baseline tests passing (47 tests, 0 failures)
Ready to implement auth feature
```
