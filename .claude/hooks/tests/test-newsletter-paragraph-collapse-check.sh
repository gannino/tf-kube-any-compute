#!/bin/bash
# hook-proof: newsletter-paragraph-collapse-check.sh (PreToolUse render gate)
# Documented block mechanism: exit 2 with the explanation on stderr and stdout
# EMPTY, when a <p> element in a *-rendered.html file contains a literal blank
# line (MISTAKE-018: email clients collapse it to one wall of text).
. "$(dirname "$0")/_assert.sh"
HOOK="$HOOKS_DIR/newsletter-paragraph-collapse-check.sh"
RENDERED="$CLAUDE_PROJECT_DIR/Creatives/claudify/newsletter/issue-001-rendered.html"

case_name "blocks: blank line inside <p>, exit 2, EMPTY stdout"
PAYLOAD=$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"<p>first beat\\n\\nsecond beat</p>"}}' "$RENDERED")
run_hook "$PAYLOAD"
assert_exit 2
assert_stdout_empty
assert_stderr_contains "MISTAKE-018"

case_name "fires-clean: br-separated beats pass"
PAYLOAD=$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"<p>first beat<br><br>second beat</p>"}}' "$RENDERED")
run_hook "$PAYLOAD"
assert_exit 0

case_name "fires-clean: pre-wrap paragraphs are exempt"
PAYLOAD=$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"<p style=\\"white-space:pre-wrap\\">a\\n\\nb</p>"}}' "$RENDERED")
run_hook "$PAYLOAD"
assert_exit 0

case_name "never breaks: malformed stdin exits without blocking"
run_hook 'garbage'
[ "$EXIT_CODE" -eq 2 ] && fail "malformed stdin must never block"

finish
