#!/bin/bash
# hook-proof: log-failures.sh (PostToolUseFailure logger)
. "$(dirname "$0")/_assert.sh"
HOOK="$HOOKS_DIR/log-failures.sh"

case_name "fires: permission failure categorized and logged"
run_hook '{"tool_name":"Bash","error":"EACCES: Permission denied"}'
assert_exit 0
assert_file_contains "$CLAUDE_PROJECT_DIR/.claude/logs/failure-log.md" "PERMISSION"

case_name "fires: network failure categorized"
run_hook '{"tool_name":"WebFetch","error":"ECONNREFUSED connect"}'
assert_exit 0
assert_file_contains "$CLAUDE_PROJECT_DIR/.claude/logs/failure-log.md" "NETWORK"

case_name "never breaks: malformed stdin"
run_hook 'garbage'
assert_exit 0

finish
