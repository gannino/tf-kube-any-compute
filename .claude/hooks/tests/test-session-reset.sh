#!/bin/bash
# hook-proof: session-reset.sh (SessionStart(user) stale-state reset)
. "$(dirname "$0")/_assert.sh"
HOOK="$HOOKS_DIR/session-reset.sh"
LOGS="$CLAUDE_PROJECT_DIR/.claude/logs"

case_name "fires: stale gate files removed, required dirs ensured"
touch "$LOGS/.quality-gate-active" "$LOGS/.tool-call-count" "$LOGS/.compaction-occurred"
run_hook ''
assert_exit 0
assert_file_missing "$LOGS/.quality-gate-active"
assert_file_missing "$LOGS/.tool-call-count"
assert_file_missing "$LOGS/.compaction-occurred"
[ -d "$CLAUDE_PROJECT_DIR/.claude/agent-memory" ] || fail "agent-memory dir not ensured"
[ -d "$CLAUDE_PROJECT_DIR/Daily Notes" ] || fail "Daily Notes dir not ensured"

case_name "never breaks: malformed stdin"
run_hook 'garbage'
assert_exit 0

finish
