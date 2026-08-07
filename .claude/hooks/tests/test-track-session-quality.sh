#!/bin/bash
# hook-proof: track-session-quality.sh (PostToolUse quality-signal tracker)
. "$(dirname "$0")/_assert.sh"
HOOK="$HOOKS_DIR/track-session-quality.sh"
STATE="$CLAUDE_PROJECT_DIR/.claude/logs/.session-quality-state"
READS="$CLAUDE_PROJECT_DIR/.claude/logs/.session-files-read"
rm -f "$STATE" "$READS"

case_name "fires: tool count increments and re-read detected"
run_hook '{"tool_name":"Read","tool_input":{"file_path":"/tmp/some-file.md"}}'
assert_exit 0
run_hook '{"tool_name":"Read","tool_input":{"file_path":"/tmp/some-file.md"}}'
assert_exit 0
assert_file_contains "$STATE" '"tool_count":2'
assert_file_contains "$STATE" '"reread_count":1'

case_name "never breaks: malformed stdin still counts a tool"
run_hook 'garbage'
assert_exit 0
assert_file_contains "$STATE" '"tool_count":3'
rm -f "$STATE" "$READS"

finish
