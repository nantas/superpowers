---
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
---

# Executing Plans

## Overview

Load plan, review critically, execute tasks in runtime batches, and keep plan state current in the status ledger.

**Core principle:** Keep execution moving unless there is a real decision gate.

**Runtime adapter:** Use abstract actions from `../_shared/runtime-compat.md` (`track_tasks`, and worker actions when needed).

**Announce at start:** "I'm using the executing-plans skill to implement this plan."
This skill requires a completed `using-superpowers preflight`.
If preflight cache is absent, stop and invoke using-superpowers first.

## The Process

### Step 1: Load and Review Plan
1. Verify `using-superpowers preflight` already ran for this session.
2. If preflight cache is absent, stop and invoke using-superpowers first.
3. Read preflight workspace cache fields: `worktree-exempt`, `large-worktree-risk`, `worktree-dirty`.
4. Select execution workspace before touching implementation tasks:
   - If cache reports `worktree-exempt=true`, stay on current checkout (or another user-approved non-worktree feature branch workflow).
   - If cache reports `worktree-exempt=false`, **REQUIRED SUB-SKILL:** use `superpowers:using-git-worktrees` before executing plan tasks.
   - Never start implementation on `main/master` without explicit user consent.
5. Read plan file.
6. Validate required planning gates before execution:
   - `Design Traceability Matrix` exists.
   - `Plan Audit Verdict` exists at the end of the plan.
   - `approval_decision` exists and equals `pass`.
7. If any required gate is missing or `approval_decision != pass`: mark plan `blocked`, report the exact missing gate, and stop for plan correction.
8. Review critically - identify any additional questions or concerns about the plan.
9. If concerns: Raise them with your human partner before starting.
10. If no concerns: initialize `track_tasks` and proceed.

### Step 2: Build Runtime Batches

1. Read each task's `User Verification` field (`required` or `not-required`).
2. If `User Verification` is missing, treat it as not-required.
3. For non-verification work, default cadence is every 3 tasks.
4. For verification work, combine adjacent `User Verification: required` tasks into one human verification gate.
5. Use batch boundaries for progress persistence, not automatic waiting.

### Step 3: Execute and Persist State

For each task in the active batch:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Update top-of-plan status ledger entry (`Task | Status | Facts`)
5. Mark task as completed or blocked

Status ledger rules:
- Keep one row per task in the top section.
- Facts must capture both passing checks and blocker details.
- Allowed status values: `in_progress`, `completed`, `blocked`.

### Step 4: Decide Whether to Pause or Continue

When a batch completes, do not wait for feedback by default.
Continue automatically unless one of these stop conditions is true:
- blocked
- unexpected result
- human verification gate reached (all required tasks in the gate are implemented and self-verified)

When stopping:
- Show what was implemented
- Show verification output
- Include fixed status fields: `design_coverage_status`, `authenticity_status`, `semantic_closure_status`
- State the exact reason for stopping and ask only for the required user decision.

If stopping because a human verification gate is reached, the stop message MUST include this exact structure:
- `Gate Scope`: exact Task IDs covered by this gate.
- `What to Verify`: 3-7 concrete user-check items.
- `Pass Criteria`: one pass criterion for each check item.
- `Evidence`: command output snippets and/or artifact paths for each check item.
- `Decision`: ask only `通过` or `不通过`.

Human verification gate constraints:
- Do not ask whether to enter finishing flow.
- Do not ask open-ended "what do you think" questions.
- If the user responds `不通过`, mark gate task(s) as `blocked` with failed criterion details.
- If the user responds `通过`, continue execution; after all tasks complete, hand off directly to finishing flow.

When not stopping:
- Report concise progress
- Include fixed status fields: `design_coverage_status`, `authenticity_status`, `semantic_closure_status`
- Select next runtime batch
- Repeat

### Step 5: Complete Development

After all tasks complete and verified:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch
- Hand off directly to superpowers:finishing-a-development-branch
- Do not ask whether to enter finishing flow

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker mid-batch (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- `Design Traceability Matrix` is missing
- `Plan Audit Verdict` is missing
- `approval_decision` is not `pass`
- You don't understand an instruction
- Verification fails repeatedly
- A human verification gate is reached and user validation is required
- An unexpected result invalidates assumptions in the plan

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when plan says to
- Update the plan status ledger after each batch
- Keep executing unless a real decision gate is hit
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent

## Integration

**Required workflow skills:**
- **superpowers:using-git-worktrees** - REQUIRED unless preflight cached `worktree-exempt=true`; large Unity/monorepo repos must stay on a non-worktree branch workflow
- **superpowers:writing-plans** - Creates the plan this skill executes
- **superpowers:finishing-a-development-branch** - Complete development after all tasks
