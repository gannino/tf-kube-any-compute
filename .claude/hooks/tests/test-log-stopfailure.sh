#!/bin/bash
# hook-proof: log-stopfailure.sh (StopFailure incident logger)
. "$(dirname "$0")/_assert.sh"
HOOK="$HOOKS_DIR/log-stopfailure.sh"
INCIDENTS="$CLAUDE_PROJECT_DIR/.claude/logs/incident-log.md"

case_name "fires: failing hook name and error logged"
run_hook '{"hook_name":"check-quality-gate.sh","error":"boom: fixture failure"}'
assert_exit 0
assert_file_contains "$INCIDENTS" "STOPFAILURE"
assert_file_contains "$INCIDENTS" "check-quality-gate.sh"

case_name "fires: missing fields degrade to unknown, still logged"
run_hook '{}'
assert_exit 0
assert_file_contains "$INCIDENTS" "hook: unknown"

case_name "never breaks: malformed stdin"
run_hook 'garbage'
assert_exit 0

finish
