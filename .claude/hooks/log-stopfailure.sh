#!/bin/bash
# StopFailure hook: logs any Stop-phase hook that failed to run.
# Cheap honesty: the trust layer reports its own failures to the incident log
# instead of failing silent. Never blocks, always exit 0.

set +e

LOG_DIR="$CLAUDE_PROJECT_DIR/.claude/logs"
INCIDENT_LOG="$LOG_DIR/incident-log.md"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
mkdir -p "$LOG_DIR" 2>/dev/null

INPUT=$(cat 2>/dev/null || echo '{}')

HOOK_NAME=$(echo "$INPUT" | jq -r '.hook_name // .failed_hook // .hook // "unknown"' 2>/dev/null)
ERROR=$(echo "$INPUT" | jq -r '.error // .stderr // .message // "no error text captured"' 2>/dev/null | head -1 | cut -c1-200)
[ -z "$HOOK_NAME" ] && HOOK_NAME="unknown"
[ -z "$ERROR" ] && ERROR="no error text captured"

echo "- \`$TIMESTAMP\` | STOPFAILURE | ERROR | hook: $HOOK_NAME | $ERROR" >> "$INCIDENT_LOG" 2>/dev/null

exit 0
