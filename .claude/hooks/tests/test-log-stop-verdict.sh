#!/bin/bash
# hook-proof: log-stop-verdict.sh (Stop verdict logger + gate trigger)
. "$(dirname "$0")/_assert.sh"
HOOK="$HOOKS_DIR/log-stop-verdict.sh"
LOGS="$CLAUDE_PROJECT_DIR/.claude/logs"
GATE="$LOGS/.quality-gate-active"
rm -f "$GATE" "$LOGS"/.session-blocks-* "$LOGS/verdicts.jsonl"

case_name "fires: verdict row written"
run_hook '{"decision":"approve","reason":"clean turn","task_type":"code"}'
assert_exit 0
assert_file_contains "$LOGS/verdicts.jsonl" '"decision":"approve"'

case_name "fires: two blocks activate the quality gate"
run_hook '{"decision":"block","reason":"fixture block one","task_type":"code"}'
assert_exit 0
run_hook '{"decision":"block","reason":"fixture block two","task_type":"code"}'
assert_exit 0
assert_file_exists "$GATE"
rm -f "$GATE" "$LOGS"/.session-blocks-*

case_name "never breaks: unparseable verdict recorded as unknown"
run_hook 'not a json verdict'
assert_exit 0
assert_file_contains "$LOGS/verdicts.jsonl" '"decision":"unknown"'

finish
