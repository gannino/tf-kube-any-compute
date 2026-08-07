#!/bin/bash
# Validates the latest Session Handoff in today's daily note.
# Called from /safe-clear (last step) and from PreCompact (gate before compaction).
# Exits 0 on valid, 1 with stderr message on invalid.

set +e

DATE_SHORT=$(date +"%m%d%y")
DAILY_NOTE="$CLAUDE_PROJECT_DIR/Daily Notes/${DATE_SHORT}.md"

if [ ! -f "$DAILY_NOTE" ]; then
  echo "VALIDATE_HANDOFF: no daily note for today ($DATE_SHORT)" >&2
  exit 1
fi

# Extract latest "Session Handoff" section (from last occurrence to end of file)
HANDOFF=$(awk '/^## Session Handoff/{found=1; out=""; out=out $0 "\n"; next} found{out=out $0 "\n"} END{print out}' "$DAILY_NOTE")

if [ -z "$HANDOFF" ]; then
  echo "VALIDATE_HANDOFF: no Session Handoff section found in $DAILY_NOTE" >&2
  exit 1
fi

ERRORS=()

# Required field presence
for FIELD in "Task:" "Done:" "Remaining:" "Files:" "Next:"; do
  if ! echo "$HANDOFF" | grep -q "\*\*$FIELD\*\*"; then
    ERRORS+=("missing field: $FIELD")
  fi
done

# Validate Files: paths exist (extract everything after **Files:** until next ** or newline)
FILES_LINE=$(echo "$HANDOFF" | grep -A0 '^\*\*Files:\*\*' | head -1 | sed 's/^\*\*Files:\*\* *//')
if [ -n "$FILES_LINE" ] && [ "$FILES_LINE" != "[full paths, both modified and key reads]" ]; then
  # Extract path-like tokens (start with / or contain /)
  for PATH_CANDIDATE in $(echo "$FILES_LINE" | grep -oE '(/[^[:space:],]+|[A-Za-z._-]+/[^[:space:],]+)' | head -20); do
    # Strip trailing punctuation
    CLEAN=$(echo "$PATH_CANDIDATE" | sed 's/[,.]$//')
    # Resolve relative paths against project dir
    if [[ "$CLEAN" != /* ]]; then
      CLEAN="$CLAUDE_PROJECT_DIR/$CLEAN"
    fi
    if [ ! -e "$CLEAN" ]; then
      ERRORS+=("Files: path does not exist: $CLEAN")
    fi
  done
fi

# Validate Next: is specific (not just "continue" or empty placeholder)
NEXT_LINE=$(echo "$HANDOFF" | grep -A0 '^\*\*Next:\*\*' | head -1 | sed 's/^\*\*Next:\*\* *//')
if [ -z "$NEXT_LINE" ] || [ "$NEXT_LINE" = "[precise action + which file(s) to read first]" ]; then
  ERRORS+=("Next: is empty or placeholder")
fi
# Reject one-word Next actions
WORD_COUNT=$(echo "$NEXT_LINE" | wc -w | tr -d ' ')
if [ "$WORD_COUNT" -lt 4 ]; then
  ERRORS+=("Next: too vague ('$NEXT_LINE'), needs verb + object + file reference")
fi

# Report
if [ ${#ERRORS[@]} -gt 0 ]; then
  echo "VALIDATE_HANDOFF: $DAILY_NOTE has ${#ERRORS[@]} issue(s):" >&2
  for E in "${ERRORS[@]}"; do echo "  - $E" >&2; done
  exit 1
fi

exit 0
