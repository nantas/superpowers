# Superpowers for Codex

Guide for using Superpowers with OpenAI Codex via native skill discovery.

## Quick Install

First-time install (no local clone yet):

```bash
git clone https://github.com/nantas/superpowers.git ~/.codex/superpowers
~/.codex/superpowers/.codex/install-local.sh --repo ~/.codex/superpowers
```

Already in a local `superpowers` checkout:

```bash
./.codex/install-local.sh
```

## Manual Installation

### Prerequisites

- OpenAI Codex CLI
- Git
- Bash (macOS/Linux shell, or Git Bash on Windows)

### Steps

1. Clone the repo:
   ```bash
   git clone https://github.com/nantas/superpowers.git ~/.codex/superpowers
   ```

2. Install skills with the standalone script:
   ```bash
   ~/.codex/superpowers/.codex/install-local.sh --repo ~/.codex/superpowers
   ```

3. Restart Codex (quit and relaunch the CLI).

### Windows

Run with Git Bash:

```bash
git clone https://github.com/nantas/superpowers.git ~/.codex/superpowers
bash ~/.codex/superpowers/.codex/install-local.sh --repo ~/.codex/superpowers
```

## How It Works

Codex has native skill discovery — it scans `~/.agents/skills/` at startup, parses SKILL.md frontmatter, and loads skills on demand. The standalone installer copies the latest files from:

```
~/.codex/superpowers/skills/
```

to:

```
~/.agents/skills/superpowers/
```

The destination is fully refreshed on each install run (no symlink/junction required).
Cloning to `~/.codex/superpowers` alone does not make skills discoverable.

## Tool Mapping

Superpowers skills should use capability-based adapter actions, then map to Codex tools:

| Adapter action | Codex tool(s) |
| --- | --- |
| `track_tasks` | `update_plan` |
| `spawn_worker` / dispatch subagent | `spawn_agent` |
| `message_worker` | `send_input` |
| `wait_worker` | `wait` |
| `close_worker` | `close_agent` |

Compatibility note: prefer capability detection over hardcoding runtime names or tool names in skill instructions.
Do not treat missing abstract action names as missing capability. Detect native tools first, then resolve abstract actions through this mapping.

## Codex Wait Semantics (Required)

Worker completion in Codex MUST come from `wait` final status (`status`/`timed_out` equivalents), not from file/log/commit polling.

- `wait(ids=[...])` is wait-any: one final worker returns per call.
- For parallel workers, maintain `pending_ids` and loop until empty.
- `subagent_notification` is asynchronous context; do not use it as the completion gate for the current stage.

Example:

```text
pending_ids = [worker_a, worker_b, worker_c]
while pending_ids not empty:
  result = wait(pending_ids)  # wait-any
  if result is final:
    remove completed id from pending_ids
    close_agent(completed id)
```

## Capability Detection

Before selecting execution mode, probe available tools in the active session and resolve adapter actions from native tool names:

1. Enumerate available tools in the session.
2. Resolve `track_tasks`/worker actions from the mapping table above.
3. If any worker action is unclear, run a minimal worker smoke probe.
4. Choose `parallel-worker` when equivalent worker lifecycle semantics are available; otherwise choose `fallback-serial`.

## Usage

Skills are discovered automatically. Codex activates them when:
- You mention a skill by name (e.g., "use brainstorming")
- The task matches a skill's description
- The `using-superpowers` skill directs Codex to use one

### Personal Skills

Create your own skills in `~/.agents/skills/`:

```bash
mkdir -p ~/.agents/skills/my-skill
```

Create `~/.agents/skills/my-skill/SKILL.md`:

```markdown
---
name: my-skill
description: Use when [condition] - [what it does]
---

# My Skill

[Your skill content here]
```

The `description` field is how Codex decides when to activate a skill automatically — write it as a clear trigger condition.

## Updating

```bash
cd ~/.codex/superpowers && git pull
~/.codex/superpowers/.codex/install-local.sh --repo ~/.codex/superpowers
```

Restart Codex after updating.

## Uninstalling

```bash
rm ~/.agents/skills/superpowers
```

Optionally delete the clone: `rm -rf ~/.codex/superpowers` (Windows: `Remove-Item -Recurse -Force "$env:USERPROFILE\.codex\superpowers"`).

## Troubleshooting

### Skills not showing up

1. Verify install destination exists: `ls -la ~/.agents/skills/superpowers`
2. Re-run installer: `~/.codex/superpowers/.codex/install-local.sh --repo ~/.codex/superpowers`
3. Restart Codex — skills are discovered at startup

### Windows bash not found

Install Git for Windows, then run installer via Git Bash.

## Testing

Run Codex compatibility checks after skill/doc changes:

```bash
cd ~/.codex/superpowers
./tests/codex/run-tests.sh
```

Include the optional integration evidence check:

```bash
cd ~/.codex/superpowers
./tests/codex/run-tests.sh --integration
```

The test covers:
- static scan for legacy hardcoded tool names in active skills/docs
- runtime contract safeguard scan (anti-misclassification, probe/profile semantics)
- Codex runtime capability probe (`update_plan`, `spawn_agent`, `send_input`, `wait`, `close_agent`)
- behavior smoke check for runtime adapter terminology
- wait-based completion evidence (`wait` as source of truth, no artifact polling, pending_ids loop)

## Getting Help

- Report issues: https://github.com/obra/superpowers/issues
- Main documentation: https://github.com/obra/superpowers
