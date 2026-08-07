#!/bin/bash
# hook-proof: backup-before-write.sh (PreToolUse Write|Edit)
. "$(dirname "$0")/_assert.sh"
HOOK="$HOOKS_DIR/backup-before-write.sh"

case_name "fires: backup created for existing file"
run_hook "{\"tool_input\":{\"file_path\":\"$CLAUDE_PROJECT_DIR/fixture.txt\"}}"
assert_exit 0
BK=$(ls "$CLAUDE_PROJECT_DIR/.claude/backups/$(date +%Y-%m-%d)/"fixture.txt.*.bak 2>/dev/null | head -1)
[ -n "$BK" ] || fail "no backup file created"

case_name "fires-clean: missing file skipped"
run_hook '{"tool_input":{"file_path":"/nonexistent/nope.txt"}}'
assert_exit 0

case_name "never breaks: malformed stdin"
run_hook 'garbage'
assert_exit 0

finish
