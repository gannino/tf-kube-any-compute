#!/bin/bash
# PostToolUse hook: tracks session quality signals for tier-based context management.
# Updates .claude/logs/.session-quality-state JSON with tool count, re-reads, heavy ops.
# Stop hook reads this state to compute tier and surface recommendations.
# Must be fast (<200ms) and never fail.

set +e  # never break the session

LOG_DIR="$CLAUDE_PROJECT_DIR/.claude/logs"
STATE="$LOG_DIR/.session-quality-state"
READS_LOG="$LOG_DIR/.session-files-read"

mkdir -p "$LOG_DIR"

# Read tool input from stdin (PostToolUse payload)
PAYLOAD=$(cat 2>/dev/null || echo '{}')

# Initialise state if missing
if [ ! -f "$STATE" ]; then
  echo '{"tool_count":0,"reread_count":0,"heavy_ops":0,"started":"'"$(date +%s)"'"}' > "$STATE"
fi
[ ! -f "$READS_LOG" ] && touch "$READS_LOG"

# Extract current values (no jq dependency, use grep)
TOOL_COUNT=$(grep -o '"tool_count":[0-9]*' "$STATE" 2>/dev/null | cut -d: -f2)
REREAD_COUNT=$(grep -o '"reread_count":[0-9]*' "$STATE" 2>/dev/null | cut -d: -f2)
HEAVY_OPS=$(grep -o '"heavy_ops":[0-9]*' "$STATE" 2>/dev/null | cut -d: -f2)
STARTED=$(grep -o '"started":"[0-9]*"' "$STATE" 2>/dev/null | cut -d'"' -f4)
TOOL_COUNT=${TOOL_COUNT:-0}
REREAD_COUNT=${REREAD_COUNT:-0}
HEAVY_OPS=${HEAVY_OPS:-0}
STARTED=${STARTED:-$(date +%s)}

# Increment tool counter
TOOL_COUNT=$((TOOL_COUNT + 1))

# Detect tool name and file path from payload
TOOL_NAME=$(echo "$PAYLOAD" | grep -o '"tool_name":"[^"]*"' | head -1 | cut -d'"' -f4)
FILE_PATH=$(echo "$PAYLOAD" | grep -o '"file_path":"[^"]*"' | head -1 | cut -d'"' -f4)

# Re-read detection (Read tool only)
if [ "$TOOL_NAME" = "Read" ] && [ -n "$FILE_PATH" ]; then
  if grep -Fxq "$FILE_PATH" "$READS_LOG" 2>/dev/null; then
    REREAD_COUNT=$((REREAD_COUNT + 1))
  else
    echo "$FILE_PATH" >> "$READS_LOG"
  fi
fi

# Heavy-op detection: intentionally omitted in the base product. Its heavy
# commands are Claude Code slash commands, which never appear in the Bash
# command payload, so there is nothing reliable to match. heavy_ops stays 0
# by design (the field is kept in the state JSON below for compatibility).

# Write back state (atomic)
cat > "$STATE" <<EOF
{"tool_count":$TOOL_COUNT,"reread_count":$REREAD_COUNT,"heavy_ops":$HEAVY_OPS,"started":"$STARTED"}
EOF

# Mirror to legacy counter for backward compat
echo "$TOOL_COUNT" > "$LOG_DIR/.tool-call-count"

exit 0
