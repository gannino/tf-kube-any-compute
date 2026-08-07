#!/bin/bash
# newsletter-paragraph-collapse-check.sh — block <p> elements with literal blank lines inside
#
# Lifts MISTAKE-018 (paragraph break collapse in email clients) from Tier 2 (auditor
# catches at audit time) to Tier 1 (hook blocks at write-time).
#
# Email clients (Gmail web, Outlook, Apple Mail) collapse multiple consecutive
# whitespace inside a single <p> tag to a single space. A blank-line paragraph break
# in source content renders as one wall-of-text paragraph, losing the intended
# two-beat hook rhythm.
#
# Fix: build.py's prose_paragraph_split() converts \n\n to <br><br> for plain-text
# prose fields. This hook ensures rendered HTML never contains the failure pattern,
# even if build.py is bypassed or regresses.
#
# Runs on PreToolUse Write|Edit|NotebookEdit for files matching *-rendered.html.
# Skips <p> tags with white-space:pre-wrap (which preserves \n correctly — used by
# code blocks and the god-tier prompt body).

set -euo pipefail

INPUT_PAYLOAD=$(cat)

TOOL=$(echo "$INPUT_PAYLOAD" | jq -r '.tool_name // ""')
FILE_PATH=$(echo "$INPUT_PAYLOAD" | jq -r '.tool_input.file_path // ""')

if [[ "$TOOL" != "Write" ]] && [[ "$TOOL" != "Edit" ]] && [[ "$TOOL" != "NotebookEdit" ]]; then
  exit 0
fi

# Only run on rendered HTML
if [[ "$FILE_PATH" != *"-rendered.html" ]]; then
  exit 0
fi

CONTENT=$(echo "$INPUT_PAYLOAD" | jq -r '.tool_input.content // .tool_input.new_string // .tool_input.new_source // ""')

if [[ -z "$CONTENT" ]]; then
  exit 0
fi

# Use python for proper <p>...</p> matching with attribute parsing.
# The checked content is written to a temp file and passed via env var, because
# a `python3 <<HEREDOC` consumes stdin as the SCRIPT itself: an in-script
# sys.stdin.read() would see nothing and the hook could never block.
CONTENT_FILE=$(mktemp)
trap 'rm -f "$CONTENT_FILE"' EXIT
printf '%s' "$CONTENT" > "$CONTENT_FILE"

RESULT=$(NPC_CONTENT_FILE="$CONTENT_FILE" python3 <<'PYEOF'
import os
import re

with open(os.environ["NPC_CONTENT_FILE"], "r", encoding="utf-8") as f:
    content = f.read()

# Match <p ...>...</p> with attributes captured + non-greedy inner
p_pattern = re.compile(r'<p\b([^>]*?)>(.*?)</p>', re.DOTALL)

flagged = []
for match in p_pattern.finditer(content):
    attrs = match.group(1)
    inner = match.group(2)

    # Skip <p> tags that explicitly preserve whitespace
    if 'white-space:pre-wrap' in attrs.replace(' ', '') or 'white-space: pre-wrap' in attrs:
        continue
    if 'white-space:pre' in attrs.replace(' ', '') and 'pre-line' not in attrs and 'pre-wrap' not in attrs:
        continue

    # Check for blank-line paragraph break
    if '\n\n' in inner:
        # Build a short snippet
        snippet = inner.replace('\n', ' ').strip()[:80]
        flagged.append(snippet)

if flagged:
    print("FOUND")
    for s in flagged[:3]:
        print(f"  {s}")
else:
    print("CLEAN")
PYEOF
)

if [[ "$RESULT" == FOUND* ]]; then
  echo "" >&2
  echo "BLOCKED: <p> tag contains literal blank line(s) — will collapse in email clients (MISTAKE-018)." >&2
  echo "  File: $FILE_PATH" >&2
  echo "" >&2
  echo "$RESULT" | tail -n +2 >&2
  echo "" >&2
  echo "  Email clients (Gmail web, Outlook, Apple Mail) collapse \\n\\n inside <p> to one space." >&2
  echo "  Fix: convert blank-line breaks to <br><br>, OR split into two separate <p> tags." >&2
  echo "  build.py's prose_paragraph_split() does this automatically for plain-text prose fields." >&2
  echo "  Re-run /newsletter build $(basename "$FILE_PATH" | sed 's/-rendered\.html//') after fixing." >&2
  echo "" >&2
  exit 2
fi

exit 0
