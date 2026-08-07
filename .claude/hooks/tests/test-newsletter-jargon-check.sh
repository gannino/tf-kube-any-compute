#!/bin/bash
# hook-proof: newsletter-jargon-check.sh (PreToolUse voice gate)
# Blocks via structured JSON (permissionDecision deny) with exit 0, as shipped.
# Banned tokens are assembled from parts so this test file never contains them.
. "$(dirname "$0")/_assert.sh"
HOOK="$HOOKS_DIR/newsletter-jargon-check.sh"
ISSUE="$CLAUDE_PROJECT_DIR/Creatives/claudify/newsletter/issues/001.md"

case_name "blocks: banned acronym in an issue file denied"
ACRO="FW""IW"
PAYLOAD=$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"%s this tip is useful."}}' "$ISSUE" "$ACRO")
run_hook "$PAYLOAD"
assert_exit 0
assert_stdout_contains '"permissionDecision": "deny"'

case_name "blocks: banned filler phrase denied"
FILLER="Without further ad""o"
PAYLOAD=$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"%s, the tip."}}' "$ISSUE" "$FILLER")
run_hook "$PAYLOAD"
assert_exit 0
assert_stdout_contains '"permissionDecision": "deny"'

case_name "fires-clean: clean content passes"
PAYLOAD=$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"A direct sentence about the tip."}}' "$ISSUE")
run_hook "$PAYLOAD"
assert_exit 0
assert_stdout_empty

case_name "never blocks: malformed stdin cannot deny (gating hook, class 3)"
run_hook 'garbage'
[ "$EXIT_CODE" -eq 2 ] && fail "malformed stdin must never block"
grep -qF '"permissionDecision": "deny"' "$STDOUT_FILE" && fail "malformed stdin must never deny"

finish
