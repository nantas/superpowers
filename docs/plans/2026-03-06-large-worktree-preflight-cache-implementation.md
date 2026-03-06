# Large Worktree Preflight Cache Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add cached large-worktree risk decisions to preflight so downstream skills can reuse them without re-asking or re-scanning.

**Architecture:** Extend `using-superpowers` preflight to record `large-worktree-risk` and the user’s skip decision once per session. Update `using-git-worktrees` and routing policy to consume the cached decision and avoid heavy baseline checks when skipped. Add a static test to ensure the policy language remains present.

**Tech Stack:** Markdown skills, bash tests, git metadata probes.

---

### Task 1: Update `using-superpowers` with cache semantics

**Files:**
- Modify: `skills/using-superpowers/SKILL.md`

**Step 1: Write the failing test**

Add a new required pattern to the static policy scan so the test fails until the cache language exists.

```bash
rg -n "large-worktree cache" tests/codex/test-runtime-compat.sh
```

Expected: no match yet (FAIL for new assertion).

**Step 2: Run test to verify it fails**

Run:
```bash
bash tests/codex/test-runtime-compat.sh
```
Expected: FAIL in the new `Test 1c` assertion (missing `large-worktree cache`).

**Step 3: Write minimal implementation**

Add a short cache note to the preflight section so later skills can reuse the decision without re-asking. Include a single-line template such as:

```text
Cache: large-worktree-risk=<true/false>, heavy-checks-skipped=<true/false>
```

**Step 4: Run test to verify it passes**

Run:
```bash
bash tests/codex/test-runtime-compat.sh
```
Expected: PASS.

**Step 5: Commit**

```bash
git add skills/using-superpowers/SKILL.md tests/codex/test-runtime-compat.sh
git commit -m "docs: cache large-worktree preflight decision"
```

### Task 2: Consume cache in `using-git-worktrees`

**Files:**
- Modify: `skills/using-git-worktrees/SKILL.md`

**Step 1: Write the failing test**

Add a static assertion that `using-git-worktrees` mentions reusing the cached decision.

```bash
rg -n "large-worktree cache" skills/using-git-worktrees/SKILL.md
```

Expected: no match yet (FAIL for new assertion).

**Step 2: Run test to verify it fails**

Run:
```bash
bash tests/codex/test-runtime-compat.sh
```
Expected: FAIL in the new `Test 1c` assertion (missing cached reuse in `using-git-worktrees`).

**Step 3: Write minimal implementation**

Add a short note under `using-git-worktrees` creation steps:

```text
If preflight cached `large-worktree-risk=true` and `heavy-checks-skipped=true`, skip baseline tests and report minimal verification only.
```

**Step 4: Run test to verify it passes**

Run:
```bash
bash tests/codex/test-runtime-compat.sh
```
Expected: PASS.

**Step 5: Commit**

```bash
git add skills/using-git-worktrees/SKILL.md tests/codex/test-runtime-compat.sh
git commit -m "docs: reuse large-worktree cache in worktree setup"
```

### Task 3: Update routing policy to reflect cached reuse

**Files:**
- Modify: `skills/using-superpowers/routing-policy-reference.md`

**Step 1: Write the failing test**

Add a static assertion to ensure routing policy includes cache reuse semantics.

```bash
rg -n "large-worktree cache" skills/using-superpowers/routing-policy-reference.md
```

Expected: no match yet (FAIL for new assertion).

**Step 2: Run test to verify it fails**

Run:
```bash
bash tests/codex/test-runtime-compat.sh
```
Expected: FAIL in the new `Test 1c` assertion (missing cache wording).

**Step 3: Write minimal implementation**

Add one sentence after the large-repo note:

```text
If cache exists, reuse it and do not re-ask unless context changes.
```

**Step 4: Run test to verify it passes**

Run:
```bash
bash tests/codex/test-runtime-compat.sh
```
Expected: PASS.

**Step 5: Commit**

```bash
git add skills/using-superpowers/routing-policy-reference.md tests/codex/test-runtime-compat.sh
git commit -m "docs: reuse large-worktree cache in routing policy"
```

### Task 4: Update static test to cover cache terms

**Files:**
- Modify: `tests/codex/test-runtime-compat.sh`

**Step 1: Write the failing test**

Add new patterns to `Test 1c` (e.g., `large-worktree cache`, `heavy-checks-skipped`).

**Step 2: Run test to verify it fails**

Run:
```bash
bash tests/codex/test-runtime-compat.sh
```
Expected: FAIL until the docs updates are complete.

**Step 3: Write minimal implementation**

Add the missing patterns so the test enforces cache reuse language.

**Step 4: Run test to verify it passes**

Run:
```bash
bash tests/codex/test-runtime-compat.sh
```
Expected: PASS.

**Step 5: Commit**

```bash
git add tests/codex/test-runtime-compat.sh
git commit -m "test: enforce large-worktree cache policy"
```
