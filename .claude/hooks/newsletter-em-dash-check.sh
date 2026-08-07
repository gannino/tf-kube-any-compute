#!/bin/bash
# PreToolUse em dash gate for newsletter issue files.
# Hard-blocks any write/edit that introduces an em dash character into a Claudify Weekly issue.
# Foundation rule: VOICE.md hard ban #1 ("em dashes never appear in any output").

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Skip if no file path
[ -z "$FILE_PATH" ] && exit 0

# Only fire on newsletter issue files
case "$FILE_PATH" in
  *Creatives/claudify/newsletter/issues/*.md) ;;
  *) exit 0 ;;
esac

# Get content based on tool type
if [ "$TOOL" = "Write" ]; then
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')
elif [ "$TOOL" = "Edit" ] || [ "$TOOL" = "MultiEdit" ]; then
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty')
else
  exit 0
fi

[ -z "$CONTENT" ] && exit 0

# Scan for em dash. Use printf to construct the byte sequence so this script itself
# does not contain a literal em dash that would trip its own check or the completeness gate.
EM_DASH=$(printf '\xe2\x80\x94')

if echo "$CONTENT" | grep -qF "$EM_DASH"; then
  jq -n \
    --arg file "$FILE_PATH" \
    '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: ("NEWSLETTER VOICE GATE: em dash detected in newsletter issue. Foundation rule: VOICE.md hard ban #1. File: " + $file),
        additionalContext: "Em dashes are banned in all newsletter content. Replace with comma, full stop, parentheses, or restructure the sentence. See foundations/VOICE.md hard ban #1 for examples."
      }
    }'
  exit 0
fi

exit 0
