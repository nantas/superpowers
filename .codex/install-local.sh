#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Install Superpowers skills for Codex from a local source repository.

Usage:
  ./.codex/install-local.sh [--repo /abs/path/to/superpowers] [--namespace NAME] [--target-dir DIR]

Options:
  --repo PATH       Absolute path to local superpowers repo.
                    Default: parent of this script (current repo root)
  --namespace NAME  Install destination name under target dir (default: superpowers)
  --target-dir DIR  Skills base dir (default: ~/.agents/skills)
  -h, --help        Show this help

Behavior:
  - Copies latest files from <repo>/skills to <target-dir>/<namespace>
  - Replaces the destination directory on each run (sync via full refresh)
  - Does not create symlinks
USAGE
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
namespace="superpowers"
target_dir="$HOME/.agents/skills"

while [ $# -gt 0 ]; do
  case "$1" in
    --repo)
      [ $# -ge 2 ] || { echo "missing value for --repo" >&2; exit 1; }
      repo_root="$2"
      shift 2
      ;;
    --namespace)
      [ $# -ge 2 ] || { echo "missing value for --namespace" >&2; exit 1; }
      namespace="$2"
      shift 2
      ;;
    --target-dir)
      [ $# -ge 2 ] || { echo "missing value for --target-dir" >&2; exit 1; }
      target_dir="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

case "$repo_root" in
  /*) ;;
  *)
    echo "--repo must be an absolute path: $repo_root" >&2
    exit 1
    ;;
esac

source_skills="$repo_root/skills"
if [ ! -d "$source_skills" ]; then
  echo "skills directory not found: $source_skills" >&2
  exit 1
fi

mkdir -p "$target_dir"

destination="$target_dir/$namespace"
staging="${destination}.tmp.$$"

cleanup() {
  rm -rf "$staging"
}
trap cleanup EXIT

rm -rf "$staging"
mkdir -p "$staging"
cp -R "$source_skills/." "$staging/"

rm -rf "$destination"
mv "$staging" "$destination"
trap - EXIT

skill_count="$(find "$destination" -mindepth 1 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')"

echo "installed superpowers skills from local source"
echo "  source:      $source_skills"
echo "  destination: $destination"
echo "  skill files: $skill_count"
echo "next: restart Codex (quit and relaunch)"
