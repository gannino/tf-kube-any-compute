#!/bin/bash
# hook-proof: post-compact.sh (PostCompact first-class resume, no marker files)
. "$(dirname "$0")/_assert.sh"
HOOK="$HOOKS_DIR/post-compact.sh"
LOGS="$CLAUDE_PROJECT_DIR/.claude/logs"
DATE_SHORT=$(date +"%m%d%y")

case_name "fires: resume instructions + latest handoff surfaced, counters reset"
touch "$LOGS/.tool-call-count" "$LOGS/.quality-gate-active"
run_hook '{}'
assert_exit 0
assert_stdout_contains "POST-COMPACTION RESUME"
assert_stdout_contains "Session Handoff"
assert_stdout_contains "Next action"
assert_file_missing "$LOGS/.tool-call-count"
assert_file_missing "$LOGS/.quality-gate-active"

case_name "fires-clean: no daily note still resumes without a handoff block"
TODAY="$CLAUDE_PROJECT_DIR/Daily Notes/${DATE_SHORT}.md"
[ -f "$TODAY" ] && mv "$TODAY" "$TODAY.bak"
run_hook '{}'
assert_exit 0
assert_stdout_contains "POST-COMPACTION RESUME"
[ -f "$TODAY.bak" ] && mv "$TODAY.bak" "$TODAY"

case_name "never breaks: malformed stdin"
run_hook 'garbage'
assert_exit 0

finish
