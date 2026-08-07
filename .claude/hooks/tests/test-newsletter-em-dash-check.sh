#!/bin/bash
# hook-proof: newsletter-em-dash-check.sh (PreToolUse voice gate)
# Blocks via structured JSON (permissionDecision deny) with exit 0, as shipped.
# The banned character is constructed from bytes so this test file never
# contains it literally.
. "$(dirname "$0")/_assert.sh"
HOOK="$HOOKS_DIR/newsletter-em-dash-check.sh"
ISSUE="$CLAUDE_PROJECT_DIR/Creatives/claudify/newsletter/issues/001.md"
EM=$(printf '\xe2\x80\x94')

case_name "blocks: banned dash character in an issue file denied"
PAYLOAD=$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"A sentence %s with the banned character."}}' "$ISSUE" "$EM")
run_hook "$PAYLOAD"
assert_exit 0
assert_stdout_contains '"permissionDecision": "deny"'
assert_stdout_contains "NEWSLETTER VOICE GATE"

case_name "fires-clean: clean issue content passes"
PAYLOAD=$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"A clean sentence with commas, full stops, and nothing banned."}}' "$ISSUE")
run_hook "$PAYLOAD"
assert_exit 0
assert_stdout_empty

case_name "fires-clean: non-newsletter file skipped even with the character"
PAYLOAD=$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s/other.md","content":"contains %s here"}}' "$CLAUDE_PROJECT_DIR" "$EM")
run_hook "$PAYLOAD"
assert_exit 0
assert_stdout_empty

case_name "never blocks: malformed stdin cannot deny (gating hook, class 3)"
run_hook 'garbage'
[ "$EXIT_CODE" -eq 2 ] && fail "malformed stdin must never block"
grep -qF '"permissionDecision": "deny"' "$STDOUT_FILE" && fail "malformed stdin must never deny"

finish
