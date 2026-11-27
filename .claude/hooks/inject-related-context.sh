#!/bin/bash
# Scans recent daily notes for Session Handoffs that share domain keywords with today's
# latest handoff. Outputs a compact "Recent related work" block to stdout.
# Called from post-compact-resume.sh to enrich the resume context.

set +e

DATE_SHORT=$(date +"%m%d%y")
TODAY_NOTE="$CLAUDE_PROJECT_DIR/Daily Notes/${DATE_SHORT}.md"
DAILY_DIR="$CLAUDE_PROJECT_DIR/Daily Notes"
ROUTING="$CLAUDE_PROJECT_DIR/.claude/hooks/topic-routing.yml"

[ ! -f "$TODAY_NOTE" ] && exit 0
[ ! -d "$DAILY_DIR" ] && exit 0

# Extract latest Session Handoff
HANDOFF=$(awk '/^## Session Handoff/{found=1; out=""; out=out $0 "\n"; next} found{out=out $0 "\n"} END{print out}' "$TODAY_NOTE")
[ -z "$HANDOFF" ] && exit 0

# Extract topic keywords from routing config (just the keys)
if [ ! -f "$ROUTING" ]; then exit 0; fi
KEYWORDS=$(grep -E '^[a-z" ][a-z" -]+:$' "$ROUTING" | sed 's/:$//' | sed 's/"//g')

# Find which keywords appear in this handoff (case-insensitive)
MATCHED_KEYWORDS=()
HANDOFF_LOWER=$(echo "$HANDOFF" | tr '[:upper:]' '[:lower:]')
while IFS= read -r KW; do
  [ -z "$KW" ] && continue
  if echo "$HANDOFF_LOWER" | grep -qF "$KW"; then
    MATCHED_KEYWORDS+=("$KW")
  fi
done <<< "$KEYWORDS"

[ ${#MATCHED_KEYWORDS[@]} -eq 0 ] && exit 0

# Search the last 7 daily notes (excluding today) for handoffs containing any matched keyword
RELATED=()
COUNT=0
# Iterate via while-read so paths containing spaces (e.g. "Daily Notes") never word-split.
while IFS= read -r NOTE; do
  [ -z "$NOTE" ] && continue
  BASENAME=$(basename "$NOTE" .md)
  [ "$BASENAME" = "$DATE_SHORT" ] && continue
  [ $COUNT -ge 5 ] && break

  # Read note in lowercase, check for keyword matches in Session Handoff sections only
  if [ -f "$NOTE" ]; then
    NOTE_LOWER=$(grep -A1000 '^## Session Handoff' "$NOTE" 2>/dev/null | tr '[:upper:]' '[:lower:]')
    for KW in "${MATCHED_KEYWORDS[@]}"; do
      if echo "$NOTE_LOWER" | grep -qF "$KW"; then
        # Get the first Task: from Session Handoffs in this note
        TASK=$(grep -m1 -A20 '^## Session Handoff' "$NOTE" | grep -m1 '\*\*Task:\*\*' | sed 's/\*\*Task:\*\* *//' | head -1)
        [ -z "$TASK" ] && TASK="(no task line)"
        RELATED+=("$BASENAME: $TASK [matched: $KW]")
        COUNT=$((COUNT + 1))
        break  # one entry per note
      fi
    done
  fi
done < <(ls -t "$DAILY_DIR"/*.md 2>/dev/null | head -8)

# Output if matches found
if [ ${#RELATED[@]} -gt 0 ]; then
  echo ""
  echo "Recent related work (last 7 days, by domain match):"
  for R in "${RELATED[@]}"; do
    echo "  - Daily Notes/$R"
  done
fi

exit 0
