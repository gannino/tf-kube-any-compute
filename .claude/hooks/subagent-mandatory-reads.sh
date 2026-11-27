#!/bin/bash
# SubagentStart hook: injects each subagent's mandatory reads as context.
# Replaces prose hope ("read knowledge-base.md before acting") with a
# deterministic injection: reads the agent type from the payload, looks up
# .claude/hooks/mandatory-reads.yml (agent-name -> file list, plus a default),
# and emits the file contents (capped) so the agent starts with its rulebook
# loaded, not requested.
#
# Fail-open: no payload, no registry, or no readable files means silence and
# exit 0. Never blocks a spawn, never errors a session.

set +e

REGISTRY="$CLAUDE_PROJECT_DIR/.claude/hooks/mandatory-reads.yml"
[ ! -f "$REGISTRY" ] && exit 0

PER_FILE_CAP=6000    # bytes emitted per file
MAX_FILES=4          # files injected per agent

INPUT=$(cat 2>/dev/null || echo '{}')

AGENT=""
if command -v jq >/dev/null 2>&1; then
  AGENT=$(echo "$INPUT" | jq -r '.subagent_type // .agent_type // .subagent_name // empty' 2>/dev/null)
fi
if [ -z "$AGENT" ]; then
  AGENT=$(echo "$INPUT" | grep -o '"subagent_type":"[^"]*"' 2>/dev/null | head -1 | cut -d'"' -f4)
fi
[ -z "$AGENT" ] && AGENT="default"

# Look up the agent's line in the registry: "agent: path1, path2".
# Fall back to the "default:" line when the agent is not listed.
LINE=$(grep -E "^${AGENT}:" "$REGISTRY" 2>/dev/null | head -1)
[ -z "$LINE" ] && LINE=$(grep -E '^default:' "$REGISTRY" 2>/dev/null | head -1)
[ -z "$LINE" ] && exit 0

FILES=$(printf '%s' "$LINE" | cut -d: -f2- | tr ',' '\n' | sed -e 's/^ *//' -e 's/ *$//')

# Convention bonus: an agent's own MEMORY.md is always a mandatory read when it exists.
AGENT_MEMORY=".claude/agent-memory/${AGENT}/MEMORY.md"
if [ -f "$CLAUDE_PROJECT_DIR/$AGENT_MEMORY" ]; then
  case "$FILES" in
    *"$AGENT_MEMORY"*) : ;;
    *) FILES=$(printf '%s\n%s' "$FILES" "$AGENT_MEMORY") ;;
  esac
fi

EMITTED=0
HEADER_PRINTED=0
while IFS= read -r REL; do
  [ -z "$REL" ] && continue
  [ "$EMITTED" -ge "$MAX_FILES" ] && break
  FULL="$CLAUDE_PROJECT_DIR/$REL"
  case "$REL" in /*) FULL="$REL" ;; esac
  [ ! -f "$FULL" ] && continue
  if [ "$HEADER_PRINTED" -eq 0 ]; then
    echo "MANDATORY READS for subagent '$AGENT' (injected by hook, not requested by prose):"
    HEADER_PRINTED=1
  fi
  echo ""
  echo "----- $REL -----"
  head -c "$PER_FILE_CAP" "$FULL" 2>/dev/null
  echo ""
  EMITTED=$((EMITTED + 1))
done <<EOF
$FILES
EOF

if [ "$HEADER_PRINTED" -eq 1 ]; then
  echo ""
  echo "Treat the rules above as binding constraints for this task."
fi

exit 0
