#!/bin/bash
# hook-proof: log-changes.sh (PostToolUse Write|Edit audit trail)
. "$(dirname "$0")/_assert.sh"
HOOK="$HOOKS_DIR/log-changes.sh"

case_name "fires: write logged to audit trail"
run_hook "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$CLAUDE_PROJECT_DIR/fixture.txt\"}}"
assert_exit 0
assert_file_contains "$CLAUDE_PROJECT_DIR/.claude/logs/audit-trail.md" "fixture.txt"

case_name "fires-clean: no file path, silent skip"
run_hook '{"tool_name":"Write","tool_input":{}}'
assert_exit 0

case_name "never breaks: malformed stdin"
run_hook 'garbage'
assert_exit 0

finish
