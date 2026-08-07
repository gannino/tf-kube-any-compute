#!/bin/bash
# hook-proof: check-quality-gate.sh (Stop backstop, exit-2 blocker)
. "$(dirname "$0")/_assert.sh"
HOOK="$HOOKS_DIR/check-quality-gate.sh"
GATE="$CLAUDE_PROJECT_DIR/.claude/logs/.quality-gate-active"

case_name "fires-clean: no gate file, allows"
rm -f "$GATE"
run_hook ''
assert_exit 0
assert_stdout_empty

case_name "blocks: gate file present, exit 2, EMPTY stdout (exit-2 JSON semantics)"
touch "$GATE"
run_hook ''
assert_exit 2
assert_stdout_empty
assert_stderr_contains "QUALITY GATE"
assert_stderr_contains "/safe-clear"
rm -f "$GATE"

case_name "never breaks: malformed stdin ignored"
run_hook 'garbage'
assert_exit 0

finish
