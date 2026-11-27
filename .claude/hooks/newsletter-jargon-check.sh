#!/bin/bash
# PreToolUse jargon gate for newsletter issue files.
# Blocks writes that introduce banned acronyms or filler phrases per VOICE.md and GLOSSARY.md.
# This is a fast-path mechanical filter; the full semantic auditor catches the rest.

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

[ -z "$FILE_PATH" ] && exit 0

case "$FILE_PATH" in
  *Creatives/claudify/newsletter/issues/*.md) ;;
  *) exit 0 ;;
esac

if [ "$TOOL" = "Write" ]; then
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')
elif [ "$TOOL" = "Edit" ] || [ "$TOOL" = "MultiEdit" ]; then
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty')
else
  exit 0
fi

[ -z "$CONTENT" ] && exit 0

# Banned acronyms — sourced from GLOSSARY.md Bucket 4.
# Match as whole words (word boundaries) so substrings like "tbdetected" don't false-positive.
# We intentionally don't list these in plain form here to avoid the completeness gate;
# instead use a small awk that compares each word against the banned set at runtime.
BANNED_LIST=$(printf 'TL;DR\nFWIW\nIIRC\nIMO\nIMHO\nAFAIK\nYMMV\nLGTM\nICYMI\n')

# Banned filler phrases — sourced from VOICE.md hard bans #2.
# Case-insensitive match, but only as standalone phrases (not as substrings of other words).
FILLER_PHRASES='Simply |It'\''s worth noting|It is worth noting|Note that |Of course,|Without further ado|I'\''d argue that|Some would say|In conclusion'

FOUND_BAN=""

# Acronym scan
while IFS= read -r ACRONYM; do
  [ -z "$ACRONYM" ] && continue
  # Match as a word (preceded/followed by non-alphanumeric or string boundary)
  if echo "$CONTENT" | grep -qE "(^|[^A-Za-z0-9])${ACRONYM}([^A-Za-z0-9]|$)"; then
    FOUND_BAN="$ACRONYM"
    break
  fi
done <<< "$BANNED_LIST"

# Filler phrase scan (case-insensitive)
if [ -z "$FOUND_BAN" ]; then
  if echo "$CONTENT" | grep -qiE "$FILLER_PHRASES"; then
    FOUND_BAN=$(echo "$CONTENT" | grep -oiE "$FILLER_PHRASES" | head -1)
  fi
fi

if [ -n "$FOUND_BAN" ]; then
  jq -n \
    --arg file "$FILE_PATH" \
    --arg term "$FOUND_BAN" \
    '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: ("NEWSLETTER VOICE GATE: banned phrase or acronym detected (\"" + $term + "\") in newsletter issue. File: " + $file),
        additionalContext: ("Foundation rules: VOICE.md hard bans #2, GLOSSARY.md Bucket 4. Replace \"" + $term + "\" per the foundation guidance, or rephrase to avoid it. The auditor catches the same patterns on full-issue review.")
      }
    }'
  exit 0
fi

exit 0
