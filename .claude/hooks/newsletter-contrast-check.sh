#!/bin/bash
# newsletter-contrast-check.sh — block low-contrast hex color values in newsletter files
#
# Lifts MISTAKE-005 (low-contrast grey text recurring across template) from Tier 2
# (auditor catches at audit time) to Tier 1 (hook blocks at write-time).
#
# This hook runs on PreToolUse Write|Edit|NotebookEdit for files under
# Creatives/claudify/newsletter/. If the content being written contains a hex value
# from the deny-list of known-low-contrast colors, the write is blocked with an
# explanation and a recommended replacement.
#
# Deny-list extends as new low-contrast values are discovered. The list lives here
# because hooks are the right tier for mechanical pattern bans.

set -euo pipefail

INPUT_PAYLOAD=$(cat)

TOOL=$(echo "$INPUT_PAYLOAD" | jq -r '.tool_name // ""')
FILE_PATH=$(echo "$INPUT_PAYLOAD" | jq -r '.tool_input.file_path // ""')

# Only run on Write/Edit/NotebookEdit
if [[ "$TOOL" != "Write" ]] && [[ "$TOOL" != "Edit" ]] && [[ "$TOOL" != "NotebookEdit" ]]; then
  exit 0
fi

# Only run on newsletter files
if [[ "$FILE_PATH" != *"/newsletter/"* ]]; then
  exit 0
fi

# Get the content being written:
# - Write: tool_input.content
# - Edit: tool_input.new_string
# - NotebookEdit: tool_input.new_source
CONTENT=$(echo "$INPUT_PAYLOAD" | jq -r '.tool_input.content // .tool_input.new_string // .tool_input.new_source // ""')

if [[ -z "$CONTENT" ]]; then
  exit 0
fi

# Known-bad low-contrast hex values on light backgrounds.
# Add new entries when MISTAKES-LOG documents a contrast regression.
# Each value here has a documented MISTAKE-NNN reference in the log.
LOW_CONTRAST_DENY_LIST=(
  "#9a9aad"  # MISTAKE-005 — 2.6:1 on light bg, was used 5x in template
  "#aaaaad"  # extrapolated — same family, very low contrast
  "#bbbbbb"  # very low contrast on white (~2.8:1)
  "#cccccc"  # very low contrast on white (~2.0:1)
  "#dddddd"  # very low contrast on white (~1.5:1)
  "#eeeeee"  # essentially invisible on white
  "#9b9b9b"  # ~3.0:1 borderline
  "#a0a0a0"  # ~3.1:1 borderline
)

FOUND_VALUES=""
for hex in "${LOW_CONTRAST_DENY_LIST[@]}"; do
  if echo "$CONTENT" | grep -iqF "$hex"; then
    FOUND_VALUES+=" $hex"
  fi
done

if [[ -n "$FOUND_VALUES" ]]; then
  echo "" >&2
  echo "BLOCKED: Low-contrast hex color value detected in newsletter file." >&2
  echo "  File: $FILE_PATH" >&2
  echo "  Found:$FOUND_VALUES" >&2
  echo "" >&2
  echo "  WCAG AA requires 4.5:1 contrast ratio for body text." >&2
  echo "  These values fail on light backgrounds (see MISTAKE-005 in MISTAKES-LOG.md)." >&2
  echo "" >&2
  echo "  Approved subordinate greys for light backgrounds:" >&2
  echo "    #4a4a5a  (~8.4:1) — body text" >&2
  echo "    #6a6a7a  (~5.7:1) — subordinate / secondary text" >&2
  echo "    #5070f7  (link blue, brand)" >&2
  echo "" >&2
  exit 2
fi

exit 0
