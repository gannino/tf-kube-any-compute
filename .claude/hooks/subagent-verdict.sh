#!/bin/bash
# SubagentStop hook, logs a concise verdict when a subagent finishes.
# Mirrors log-stop-verdict.sh but at the subagent layer, so the multi-agent
# system becomes self-auditing, not just self-logging.
# Writes a structured JSONL row for trend analysis plus a human-readable
# audit line. Never blocks, always exits 0.

INPUT=$(cat)
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
LOG_DIR="$CLAUDE_PROJECT_DIR/.claude/logs"
SUBAGENT_LOG="$LOG_DIR/subagent-verdicts.jsonl"
AUDIT_TRAIL="$LOG_DIR/audit-trail.md"

mkdir -p "$LOG_DIR"

# Parse the SubagentStop payload defensively. Every field is optional,
# missing values fall back to a safe placeholder so the row is always valid.
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
SUBAGENT=$(echo "$INPUT" | jq -r '.subagent_type // .agent_type // .subagent_name // empty' 2>/dev/null)
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)

# Default the agent label when the payload does not name one.
[ -z "$SUBAGENT" ] && SUBAGENT="unknown"

# Derive a one-line summary from the subagent's last transcript message, if the
# transcript exists and is readable. This is the "verdict" signal, kept short.
# Transcripts are JSONL, the last assistant line carries the closing message.
SUMMARY=""
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  LAST_ASSISTANT=$(grep '"role":"assistant"' "$TRANSCRIPT" 2>/dev/null | tail -1)
  if [ -n "$LAST_ASSISTANT" ]; then
    # Pull text from the message content array, join, collapse whitespace.
    SUMMARY=$(echo "$LAST_ASSISTANT" \
      | jq -r '[(.message.content[]? | select(.type == "text") | .text)] | join(" ") // empty' 2>/dev/null \
      | tr '\n' ' ' \
      | sed 's/  */ /g' \
      | cut -c1-280)
  fi
fi
[ -z "$SUMMARY" ] && SUMMARY="(no closing message captured)"

# Derive a coarse verdict from the summary text. Pattern match is best-effort
# and case-insensitive, anything unmatched is recorded as "complete".
VERDICT="complete"
if echo "$SUMMARY" | grep -qiE '\b(fail|failed|error|blocked|cannot|could not|unable to)\b'; then
  VERDICT="flagged"
fi

# Trim the transcript path to a project-relative form for cleaner logs.
RELATIVE_TRANSCRIPT="${TRANSCRIPT#$CLAUDE_PROJECT_DIR/}"

# Write the structured JSONL row.
jq -c -n \
  --arg ts "$TIMESTAMP" \
  --arg session_id "$SESSION_ID" \
  --arg subagent "$SUBAGENT" \
  --arg verdict "$VERDICT" \
  --arg summary "$SUMMARY" \
  --arg transcript "$RELATIVE_TRANSCRIPT" \
  --arg stop_active "$STOP_ACTIVE" \
  '{timestamp: $ts, session_id: $session_id, subagent: $subagent, verdict: $verdict, summary: $summary, transcript: $transcript, stop_hook_active: $stop_active}' \
  >> "$SUBAGENT_LOG" 2>/dev/null

# Write the human-readable audit line, matching the incident/audit trail format.
# Uppercase the verdict tag via tr for portability (no bash 4 ${x^^}).
VERDICT_TAG=$(echo "$VERDICT" | tr '[:lower:]' '[:upper:]')
echo "- \`$TIMESTAMP\` | SUBAGENT | $VERDICT_TAG | $SUBAGENT | $SUMMARY" >> "$AUDIT_TRAIL"

exit 0
