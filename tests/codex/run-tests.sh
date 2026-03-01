#!/usr/bin/env bash
# Main runner for Codex-specific compatibility checks.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

bash "$SCRIPT_DIR/test-runtime-compat.sh" "$@"
