#!/bin/bash
# hook-proof: newsletter-contrast-check.sh (PreToolUse contrast gate)
# Documented block mechanism: exit 2 with the explanation on stderr and stdout
# EMPTY (load-bearing under the July exit-2 JSON semantics).
. "$(dirname "$0")/_assert.sh"
HOOK="$HOOKS_DIR/newsletter-contrast-check.sh"
NLFILE="$CLAUDE_PROJECT_DIR/Creatives/claudify/newsletter/template.html"

case_name "blocks: deny-listed low-contrast hex, exit 2, EMPTY stdout"
PAYLOAD=$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"<p style=\\"color:#9a9aad\\">text</p>"}}' "$NLFILE")
run_hook "$PAYLOAD"
assert_exit 2
assert_stdout_empty
assert_stderr_contains "Low-contrast"

case_name "fires-clean: approved grey passes"
PAYLOAD=$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"<p style=\\"color:#4a4a5a\\">text</p>"}}' "$NLFILE")
run_hook "$PAYLOAD"
assert_exit 0
assert_stdout_empty

case_name "fires-clean: non-newsletter file skipped"
PAYLOAD=$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s/other.html","content":"#9a9aad"}}' "$CLAUDE_PROJECT_DIR")
run_hook "$PAYLOAD"
assert_exit 0

case_name "never breaks: malformed stdin exits without blocking"
run_hook 'garbage'
[ "$EXIT_CODE" -eq 2 ] && fail "malformed stdin must never block"

finish
