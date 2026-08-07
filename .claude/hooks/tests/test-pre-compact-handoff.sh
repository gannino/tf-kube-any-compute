#!/bin/bash
# hook-proof: pre-compact-handoff.sh (PreCompact state saver)
. "$(dirname "$0")/_assert.sh"
HOOK="$HOOKS_DIR/pre-compact-handoff.sh"
MARKER="$CLAUDE_PROJECT_DIR/.claude/logs/.compaction-occurred"
rm -f "$MARKER"

case_name "fires: marker written and compaction logged"
run_hook '{"trigger":"auto"}'
assert_exit 0
assert_file_exists "$MARKER"
assert_file_contains "$CLAUDE_PROJECT_DIR/.claude/logs/incident-log.md" "COMPACTION"
rm -f "$MARKER"

case_name "never breaks: empty stdin"
run_hook ''
assert_exit 0
rm -f "$MARKER"

finish
