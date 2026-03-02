# Installing Superpowers for Codex

Codex discovers skills from `~/.agents/skills/` at startup.  
Cloning this repository alone is not enough: you must run the installer to copy skills into Codex's discovery path.

## Prerequisites

- Git
- Bash (macOS/Linux shell, or Git Bash on Windows)

## Installation Scenarios

### Scenario 1: First-time install (no local clone yet)

```bash
git clone https://github.com/nantas/superpowers.git ~/.codex/superpowers
~/.codex/superpowers/.codex/install-local.sh --repo ~/.codex/superpowers
```

### Scenario 2: Repo already cloned locally (dev workflow)

Run from this repo root:

```bash
./.codex/install-local.sh
```

Or from anywhere with an explicit path:

```bash
./.codex/install-local.sh --repo /abs/path/to/superpowers
```

### Scenario 3: Update an existing install

```bash
cd ~/.codex/superpowers && git pull
~/.codex/superpowers/.codex/install-local.sh --repo ~/.codex/superpowers
```

## Verify

```bash
ls -la ~/.agents/skills/superpowers
find ~/.agents/skills/superpowers -mindepth 1 -maxdepth 2 -name SKILL.md | wc -l
```

## Restart Codex

After install/update, quit and relaunch Codex so skill discovery reloads.

## Uninstall

```bash
rm -rf ~/.agents/skills/superpowers
```

Optionally remove the clone:

```bash
rm -rf ~/.codex/superpowers
```
