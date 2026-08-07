#!/bin/bash
# SessionStart(user) hook — resets stale state on fresh session start.
# Cleans up gate files, validates agent definitions, checks permissions.

LOG_DIR="$CLAUDE_PROJECT_DIR/.claude/logs"
AGENTS_DIR="$CLAUDE_PROJECT_DIR/.claude/agents"
HOOKS_DIR="$CLAUDE_PROJECT_DIR/.claude/hooks"

mkdir -p "$LOG_DIR"

# ═══════════════════════════════════════════════════════
# 1. Reset stale gate files (prevents cross-session deadlocks)
# ═══════════════════════════════════════════════════════
rm -f "$LOG_DIR/.quality-gate-active" \
      "$LOG_DIR/.tool-call-count" \
      "$LOG_DIR/.compaction-occurred" 2>/dev/null

# Clean up stale session-blocks files (older than current hour)
find "$LOG_DIR" -name ".session-blocks-*" -mmin +120 -delete 2>/dev/null

# ═══════════════════════════════════════════════════════
# 2. Validate hook scripts are executable
# ═══════════════════════════════════════════════════════
if [ -d "$HOOKS_DIR" ]; then
  HOOK_ISSUES=0
  for hook in "$HOOKS_DIR"/*.sh; do
    [ ! -f "$hook" ] && continue
    if [ ! -x "$hook" ]; then
      chmod +x "$hook" 2>/dev/null
      HOOK_ISSUES=$((HOOK_ISSUES + 1))
    fi
  done
  if [ "$HOOK_ISSUES" -gt 0 ]; then
    echo "- \`$(date +"%Y-%m-%d %H:%M:%S")\` | SESSION | INFO | Fixed permissions on $HOOK_ISSUES hook scripts" >> "$LOG_DIR/incident-log.md"
  fi
fi

# ═══════════════════════════════════════════════════════
# 3. Validate agent definitions exist and have frontmatter
# ═══════════════════════════════════════════════════════
if [ -d "$AGENTS_DIR" ]; then
  AGENT_ISSUES=""
  for agent in "$AGENTS_DIR"/*.md; do
    [ ! -f "$agent" ] && continue
    AGENT_NAME=$(basename "$agent" .md)

    # Check for frontmatter (starts with ---)
    if ! head -1 "$agent" | grep -q '^---'; then
      AGENT_ISSUES="$AGENT_ISSUES $AGENT_NAME(no-frontmatter)"
    fi
  done

  if [ -n "$AGENT_ISSUES" ]; then
    echo "- \`$(date +"%Y-%m-%d %H:%M:%S")\` | SESSION | WARN | Agent issues:$AGENT_ISSUES" >> "$LOG_DIR/incident-log.md"
  fi
fi

# ═══════════════════════════════════════════════════════
# 4. Ensure required directories exist
# ═══════════════════════════════════════════════════════
mkdir -p "$CLAUDE_PROJECT_DIR/.claude/agent-memory" \
         "$CLAUDE_PROJECT_DIR/.claude/backups" \
         "$CLAUDE_PROJECT_DIR/.claude/skills" \
         "$CLAUDE_PROJECT_DIR/Daily Notes" 2>/dev/null

# ═══════════════════════════════════════════════════════
# 5. Prune old log files (keep last 30 days)
# ═══════════════════════════════════════════════════════
if [ -f "$LOG_DIR/audit-trail.md" ]; then
  LINE_COUNT=$(wc -l < "$LOG_DIR/audit-trail.md" | tr -d ' ')
  if [ "$LINE_COUNT" -gt 5000 ]; then
    # Keep last 2000 lines
    tail -2000 "$LOG_DIR/audit-trail.md" > "$LOG_DIR/audit-trail.md.tmp"
    mv "$LOG_DIR/audit-trail.md.tmp" "$LOG_DIR/audit-trail.md"
    echo "- \`$(date +"%Y-%m-%d %H:%M:%S")\` | SESSION | INFO | Pruned audit trail from $LINE_COUNT to 2000 lines" >> "$LOG_DIR/incident-log.md"
  fi
fi

# ═══════════════════════════════════════════════════════
# 6. Advisory: pending knowledge-nomination floor (backup trigger for the /sync drain)
# ═══════════════════════════════════════════════════════
NOMS="$CLAUDE_PROJECT_DIR/.claude/knowledge-nominations.md"
if [ -f "$NOMS" ]; then
  PENDING=$(awk '/^## Pending/{f=1;next} /^## /{f=0} f && /^- /{c++} END{print c+0}' "$NOMS" 2>/dev/null)
  [ -z "$PENDING" ] && PENDING=0
  if [ "$PENDING" -ge 5 ]; then
    echo "REMINDER: $PENDING knowledge nominations pending. Run /sync to auto-drain them (the auditor promotes durable rules and resets the count). Advisory only, never blocks."
  fi
fi

# ═══════════════════════════════════════════════════════
# 7. Advisory: validate topic-routing.yml targets resolve (warn, never block)
# ═══════════════════════════════════════════════════════
ROUTING="$CLAUDE_PROJECT_DIR/.claude/hooks/topic-routing.yml"
if [ -f "$ROUTING" ]; then
  grep -vE '^[[:space:]]*#' "$ROUTING" 2>/dev/null | grep -oE '[A-Za-z0-9_./-]+\.(md|yml|yaml|sh|txt|json)' | sort -u | while read -r p; do
    [ -e "$CLAUDE_PROJECT_DIR/$p" ] || echo "REMINDER: topic-routing.yml points to '$p', which does not exist. Fix the path or remove the entry. Advisory only, never blocks."
  done | head -10
fi

exit 0
