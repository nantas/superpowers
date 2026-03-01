# 2026-03-01 Codex Worktree Rebase Permission & Efficiency Plan

## Background
During a `git rebase` run from a worktree, the agent encountered repeated failures and retries, including:

- `cannot create ... index.lock: Operation not permitted`
- `cannot lock ... .git/config: Operation not permitted`
- `cannot lock ref ... refs/remotes/... .lock: Operation not permitted`

This caused avoidable tool churn (`fail -> escalate -> rerun`) and longer recovery time.

## Problem Classification

### Sandbox-caused issues
1. Any write to Git metadata failed under restricted sandbox when the write target was outside current writable roots.
2. `git push -u` could succeed remotely but fail locally when updating `.git/config` / remote-tracking refs.
3. `git add` / `git rebase --continue` failures on `index.lock` were permission-bound, not workflow mistakes.

### Workflow-caused inefficiencies
1. Escalation was not switched to a global strategy immediately after the first `.git/*.lock` permission failure.
2. Upstream binding was attempted before ensuring remote-tracking refs were refreshed.
3. Status/conflict checks were correct but too fragmented into many small calls.
4. Repeated conflicts on the same files across adjacent commits were resolved manually without `rerere` reuse.

## Goals
1. Reduce failed write attempts during rebase/conflict resolution.
2. Minimize repeated escalation round-trips for Git metadata writes.
3. Establish a deterministic post-push recovery sequence for upstream tracking issues.
4. Reduce duplicate conflict work across adjacent commits.

## Non-goals
1. Disabling sandbox protections globally.
2. Changing Git history strategy (`rebase` vs `merge`) for all teams.
3. Introducing destructive automation (`reset --hard`, forced cleanup) by default.

## Proposed Changes (Superpowers Repo)

### 1) Add a runbook in docs
Create a dedicated operational guide for worktree + rebase in sandboxed environments:

- Preflight checks before rebase (`git status`, `git rev-parse --git-dir --git-common-dir`).
- Permission failure decision rule: first `.lock` permission error triggers escalation mode for all subsequent Git write commands.
- Canonical upstream recovery sequence after `push -u` partial success.
- Recommended `rerere` defaults.

### 2) Add a reusable command sequence template
Add a concise copy-paste section (or helper command doc) with the shortest safe sequence for:

- in-progress rebase recovery
- repeated conflict handling
- post-push upstream correction

### 3) Update agent-facing guidance
Update relevant workflow guidance so agents treat `.git/*.lock Operation not permitted` as a class signal and adapt immediately instead of retrying command-by-command.

Potential touch points:

- `skills/systematic-debugging/`
- `skills/verification-before-completion/`
- any Git/worktree-oriented execution skill used in daily operations

### 4) Add regression tests for behavior expectations
Add/extend tests to verify that guidance includes:

- first-failure escalation switching
- fetch-before-set-upstream sequence
- explicit classification of sandbox vs process issues

## Recommended Operator Workflow
1. `git status` (detect in-progress rebase state first).
2. If rebase is active, resolve current conflicts once and continue.
3. On first `.git/*.lock Operation not permitted`, route all subsequent Git writes through escalation.
4. Enable conflict reuse:
   - `git config --global rerere.enabled true`
   - `git config --global rerere.autoupdate true`
5. After `push -u`, if upstream is inconsistent:
   - `git fetch origin <branch>`
   - `git branch --set-upstream-to=origin/<branch>`

## Acceptance Criteria
1. Rebase recovery no longer repeats the same write command in non-escalated mode after first lock-permission error.
2. Upstream repair follows a fixed 2-step sequence (`fetch` then `set-upstream`) with no extra retries.
3. Documentation clearly distinguishes sandbox-caused failures from operator mistakes.
4. Operators can execute the runbook end-to-end without ad hoc branching decisions.

## Risks and Mitigations
- Risk: Over-escalation broadens privileges more than needed.
  - Mitigation: Limit escalation to Git metadata write operations; keep read commands unprivileged.
- Risk: Guidance drifts from tool/runtime behavior.
  - Mitigation: Add test coverage and keep examples tied to observed error signatures.
- Risk: Worktree-specific path differences cause confusion.
  - Mitigation: Always include `git-common-dir` in preflight and in docs examples.

## Rollout Plan
1. Land runbook doc and command template.
2. Update one or more relevant skills with decision rules.
3. Add/adjust tests for the new guidance expectations.
4. Validate in one real worktree rebase scenario and capture before/after metrics (retries, tool calls, elapsed time).

## Success Metrics
- Fewer permission-related retries per rebase run.
- Lower total tool-call count during conflict-heavy rebase sessions.
- Lower time-to-recover from in-progress rebase state.
- Fewer manual re-resolutions on repeated file conflicts.
