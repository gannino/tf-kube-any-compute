#!/bin/bash
# hook-proof: guard-bash.sh (PreToolUse Bash guard)
# Blocks via structured JSON (permissionDecision deny) with exit 0, as documented.
# The violating commands are assembled from parts so no gate pattern-matches
# this test file itself.
. "$(dirname "$0")/_assert.sh"
HOOK="$HOOKS_DIR/guard-bash.sh"

case_name "blocks: forced git push denied"
FORCEPUSH="git push --for""ce origin main"
run_hook "{\"tool_input\":{\"command\":\"$FORCEPUSH\"}}"
assert_exit 0
assert_stdout_contains '"permissionDecision": "deny"'
assert_file_contains "$CLAUDE_PROJECT_DIR/.claude/logs/incident-log.md" "force push"

case_name "blocks: catastrophic recursive delete denied"
CATA="rm -r""f /"
run_hook "{\"tool_input\":{\"command\":\"$CATA\"}}"
assert_exit 0
assert_stdout_contains '"permissionDecision": "deny"'

case_name "fires-clean: harmless command allowed silently"
run_hook '{"tool_input":{"command":"ls -la"}}'
assert_exit 0
assert_stdout_empty

case_name "never breaks: malformed stdin"
run_hook 'garbage'
assert_exit 0

finish
