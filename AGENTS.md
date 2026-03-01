# Repository Guidelines

## Project Structure & Module Organization
This repository is a skill library for coding agents.

- `skills/<skill-name>/SKILL.md`: Core skill definitions; optional helper files live beside each skill.
- `commands/`: Reusable command prompts (for example `brainstorm.md`, `write-plan.md`).
- `lib/skills-core.js`: Shared JavaScript utilities used by plugin integrations.
- `hooks/`: Session hooks and launch wrappers.
- `agents/`: Agent role prompts (for example code reviewer persona).
- `tests/`: Validation suites (`claude-code/`, `opencode/`, `skill-triggering/`, `explicit-skill-requests/`, `subagent-driven-dev/`).
- `docs/`: Platform docs, test guidance, and design/implementation plans.

## Build, Test, and Development Commands
There is no separate build step; development is mostly Markdown, shell scripts, and lightweight JS.

- `./tests/claude-code/run-skill-tests.sh`: Run default Claude Code skill tests.
- `./tests/claude-code/run-skill-tests.sh --integration --timeout 1800`: Run slow end-to-end integration tests.
- `./tests/opencode/run-tests.sh`: Run OpenCode plugin test suite.
- `./tests/skill-triggering/run-all.sh`: Verify automatic skill triggering behavior.
- `./tests/explicit-skill-requests/run-all.sh`: Verify explicit skill-request handling.
- `./.codex/install-local.sh`: Install Codex skills from local source by copying `skills/` into `~/.agents/skills/superpowers`.
- `./.codex/install-local.sh --repo /abs/path/to/superpowers`: Copy from an explicit local source repo path.

Run from repo root unless a script’s README says otherwise.

## Local Codex Installation Notes
Use `./.codex/install-local.sh` when developing/testing against a local checkout.

- The installer copies latest skill files from `<repo>/skills` to `~/.agents/skills/superpowers`.
- It does not create symlinks to the source repository.
- It replaces the destination directory on each run to keep files fresh.
- Restart Codex after installation so native skill discovery reloads the updated files.

## Coding Style & Naming Conventions
- Bash: use `#!/usr/bin/env bash`, `set -euo pipefail`, and consistently quote variables.
- JavaScript (`lib/`): follow existing CommonJS style (`require`/`module.exports`) and keep dependencies minimal.
- Skill folder names use kebab-case (example: `test-driven-development`).
- Keep docs direct, actionable, and path/command-specific.

## Testing Guidelines
- Add or update tests whenever skill behavior, triggers, or hooks change.
- Prefer fast suites first, then run integration tests for workflow-level changes.
- Shell tests should follow `test-<behavior>.sh` naming.
- In PRs, include the exact commands you ran and the pass/fail summary.

## Commit & Pull Request Guidelines
- Follow Conventional Commit style seen in history: `fix:`, `feat:`, `docs:`, `refactor:`, `chore:`.
- Keep each commit focused on one logical change.
- PRs should include: goal, affected paths, verification commands, and relevant output snippets.
- Link related issues and clearly flag any behavior changes to skill activation or workflow order.
