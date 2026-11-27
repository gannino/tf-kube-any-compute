#!/bin/bash
# PreToolUse schema completeness gate for newsletter issue files.
# Blocks Write of an issue file that's missing required schema fields.
# Foundation rule: ISSUE-SCHEMA.md (required fields) + format requirements documented inline.
#
# Note: only fires on full Write of an issue file (not Edit/MultiEdit which patch in place).
# Edit operations on existing issues are presumed to start from a complete file; the auditor
# catches schema drift on full-issue audit.

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

[ -z "$FILE_PATH" ] && exit 0

case "$FILE_PATH" in
  *Creatives/claudify/newsletter/issues/*.md) ;;
  *) exit 0 ;;
esac

# Only validate full Writes; Edit/MultiEdit are surgical patches that don't reasonably
# get the whole file content into one check.
[ "$TOOL" = "Write" ] || exit 0

CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')
[ -z "$CONTENT" ] && exit 0

# Required frontmatter keys (between --- markers at the top of the file)
REQUIRED_FRONTMATTER=$(printf 'issue\ndate\nsubject\npreview\ntype\n')

# Required content sections (## HEADER lines)
REQUIRED_SECTIONS=$(printf 'TIP_HEADLINE\nTLDR\nTIP_INTRO\nTIP_BODY\nDEEP_DIVE_TITLE\nDEEP_DIVE_URL\nDEEP_DIVE_DESCRIPTION\nPROMPT\nPRO_TIP_HEADLINE\nPRO_TIP_BODY\nQUICK_WIN_HEADLINE\nQUICK_WIN_BODY\nREAD_THIS_WEEK\nNEXT_TEASE\n')

MISSING=""

# Frontmatter check: extract the block between the first two --- markers
FRONTMATTER=$(echo "$CONTENT" | awk '/^---[[:space:]]*$/{c++; next} c==1{print} c==2{exit}')

while IFS= read -r KEY; do
  [ -z "$KEY" ] && continue
  if ! echo "$FRONTMATTER" | grep -qE "^${KEY}:"; then
    MISSING="${MISSING}- frontmatter key missing: ${KEY}\n"
  fi
done <<< "$REQUIRED_FRONTMATTER"

# Section check: each required section must be a level-2 heading
while IFS= read -r SECTION; do
  [ -z "$SECTION" ] && continue
  if ! echo "$CONTENT" | grep -qE "^## ${SECTION}[[:space:]]*$"; then
    MISSING="${MISSING}- section missing: ## ${SECTION}\n"
  fi
done <<< "$REQUIRED_SECTIONS"

if [ -n "$MISSING" ]; then
  REASON=$(printf "%b" "$MISSING")
  jq -n \
    --arg file "$FILE_PATH" \
    --arg reason "$REASON" \
    '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: ("NEWSLETTER SCHEMA GATE: missing required fields. File: " + $file),
        additionalContext: ("The following are required by ISSUE-SCHEMA.md but were not found in the file content:\n" + $reason + "\nAdd each missing item before retrying the write. See ISSUE-SCHEMA.md for field definitions.")
      }
    }'
  exit 0
fi

exit 0
