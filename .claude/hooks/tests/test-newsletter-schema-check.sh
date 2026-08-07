#!/bin/bash
# hook-proof: newsletter-schema-check.sh (PreToolUse schema gate, Write only)
# Blocks via structured JSON (permissionDecision deny) with exit 0, as shipped.
. "$(dirname "$0")/_assert.sh"
HOOK="$HOOKS_DIR/newsletter-schema-check.sh"
ISSUE="$CLAUDE_PROJECT_DIR/Creatives/claudify/newsletter/issues/001.md"

case_name "blocks: issue Write missing required schema fields denied"
PAYLOAD=$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"---\\nissue: 1\\n---\\n## TIP_HEADLINE\\nonly one section"}}' "$ISSUE")
run_hook "$PAYLOAD"
assert_exit 0
assert_stdout_contains '"permissionDecision": "deny"'
assert_stdout_contains "NEWSLETTER SCHEMA GATE"

case_name "fires-clean: complete schema passes"
BODY='---\nissue: 1\ndate: 2026-08-01\nsubject: s\npreview: p\ntype: t\n---\n## TIP_HEADLINE\nx\n## TLDR\nx\n## TIP_INTRO\nx\n## TIP_BODY\nx\n## DEEP_DIVE_TITLE\nx\n## DEEP_DIVE_URL\nx\n## DEEP_DIVE_DESCRIPTION\nx\n## PROMPT\nx\n## PRO_TIP_HEADLINE\nx\n## PRO_TIP_BODY\nx\n## QUICK_WIN_HEADLINE\nx\n## QUICK_WIN_BODY\nx\n## READ_THIS_WEEK\nx\n## NEXT_TEASE\nx\n'
PAYLOAD=$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"%s"}}' "$ISSUE" "$BODY")
run_hook "$PAYLOAD"
assert_exit 0
assert_stdout_empty

case_name "fires-clean: Edit operations are exempt by design"
PAYLOAD=$(printf '{"tool_name":"Edit","tool_input":{"file_path":"%s","new_string":"partial patch"}}' "$ISSUE")
run_hook "$PAYLOAD"
assert_exit 0
assert_stdout_empty

case_name "never blocks: malformed stdin cannot deny (gating hook, class 3)"
run_hook 'garbage'
[ "$EXIT_CODE" -eq 2 ] && fail "malformed stdin must never block"
grep -qF '"permissionDecision": "deny"' "$STDOUT_FILE" && fail "malformed stdin must never deny"

finish
