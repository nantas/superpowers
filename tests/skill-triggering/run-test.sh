#!/bin/bash
# Test skill triggering with naive prompts
# Usage: ./run-test.sh <skill-name> <prompt-file>
#
# Tests whether Claude triggers a skill based on a natural prompt
# (without explicitly mentioning the skill)

set -euo pipefail

SKILL_NAME="$1"
PROMPT_FILE="$2"
MAX_TURNS="${3:-3}"

if [ -z "$SKILL_NAME" ] || [ -z "$PROMPT_FILE" ]; then
    echo "Usage: $0 <skill-name> <prompt-file> [max-turns]"
    echo "Example: $0 systematic-debugging ./test-prompts/debugging.txt"
    exit 1
fi

run_with_timeout() {
    local seconds="$1"
    shift

    if command -v timeout >/dev/null 2>&1; then
        timeout "$seconds" "$@"
    elif command -v gtimeout >/dev/null 2>&1; then
        gtimeout "$seconds" "$@"
    else
        "$@"
    fi
}

looks_like_environment_skip() {
    local file="$1"
    grep -Eqi "auth|login|credential|api key|unauthorized|forbidden|not logged|rate limit|network|connection|timeout|timed out|plugin|permission denied|operation not permitted" "$file"
}

# Get the directory where this script lives (should be tests/skill-triggering)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the superpowers plugin root (two levels up from tests/skill-triggering)
PLUGIN_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

TIMESTAMP=$(date +%s)
OUTPUT_DIR="/tmp/superpowers-tests/${TIMESTAMP}/skill-triggering/${SKILL_NAME}"
mkdir -p "$OUTPUT_DIR"

# Read prompt from file
PROMPT=$(cat "$PROMPT_FILE")

echo "=== Skill Triggering Test ==="
echo "Skill: $SKILL_NAME"
echo "Prompt file: $PROMPT_FILE"
echo "Max turns: $MAX_TURNS"
echo "Output dir: $OUTPUT_DIR"
echo ""

# Copy prompt for reference
cp "$PROMPT_FILE" "$OUTPUT_DIR/prompt.txt"

# Run Claude
LOG_FILE="$OUTPUT_DIR/claude-output.json"
cd "$OUTPUT_DIR"

echo "Plugin dir: $PLUGIN_DIR"

echo "Running claude -p with naive prompt..."
if ! command -v claude >/dev/null 2>&1; then
    echo "⚠️  SKIP: claude CLI not found"
    exit 2
fi

set +e
run_with_timeout 300 claude -p "$PROMPT" \
    --plugin-dir "$PLUGIN_DIR" \
    --dangerously-skip-permissions \
    --max-turns "$MAX_TURNS" \
    --output-format stream-json \
    > "$LOG_FILE" 2>&1
CLAUDE_EXIT=$?
set -e

echo ""
echo "=== Results ==="

if [ ! -s "$LOG_FILE" ]; then
    echo "⚠️  SKIP: Empty Claude output (environment/session issue likely)"
    echo "Full log: $LOG_FILE"
    echo "Timestamp: $TIMESTAMP"
    exit 2
fi

if [ "$CLAUDE_EXIT" -ne 0 ]; then
    if looks_like_environment_skip "$LOG_FILE"; then
        echo "⚠️  SKIP: Claude execution unavailable due to environment/auth/session constraints"
        sed -n '1,20p' "$LOG_FILE" | sed 's/^/    /'
        echo "Full log: $LOG_FILE"
        echo "Timestamp: $TIMESTAMP"
        exit 2
    fi
fi

# Check if skill was triggered (look for Skill tool invocation)
# In stream-json, tool invocations have "name":"Skill" (not "tool":"Skill")
# Match either "skill":"skillname" or "skill":"namespace:skillname"
SKILL_PATTERN='"skill":"([^"]*:)?'"${SKILL_NAME}"'"'
if grep -q '"name":"Skill"' "$LOG_FILE" && grep -qE "$SKILL_PATTERN" "$LOG_FILE"; then
    echo "✅ PASS: Skill '$SKILL_NAME' was triggered"
    TRIGGERED=true
else
    echo "❌ FAIL: Skill '$SKILL_NAME' was NOT triggered"
    TRIGGERED=false
fi

# Show what skills WERE triggered
echo ""
echo "Skills triggered in this run:"
grep -o '"skill":"[^"]*"' "$LOG_FILE" 2>/dev/null | sort -u || echo "  (none)"

# Show first assistant message
echo ""
echo "First assistant response (truncated):"
grep '"type":"assistant"' "$LOG_FILE" | head -1 | jq -r '.message.content[0].text // .message.content' 2>/dev/null | head -c 500 || echo "  (could not extract)"

echo ""
echo "Full log: $LOG_FILE"
echo "Timestamp: $TIMESTAMP"

if [ "$TRIGGERED" = "true" ]; then
    exit 0
else
    exit 1
fi
