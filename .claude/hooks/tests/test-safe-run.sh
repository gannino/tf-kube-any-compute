#!/bin/bash
# hook-proof: safe-run.sh (PreToolUse Bash reversibility snapshots)
. "$(dirname "$0")/_assert.sh"
HOOK="$HOOKS_DIR/safe-run.sh"
MANIFEST="$CLAUDE_PROJECT_DIR/.claude/logs/safe-run-manifest.jsonl"

case_name "fires: snapshot taken before a reversible delete"
TARGET="$CLAUDE_PROJECT_DIR/fixture.txt"
[ -f "$TARGET" ] || echo "fixture content" > "$TARGET"
run_hook "{\"tool_input\":{\"command\":\"rm $TARGET\"}}"
assert_exit 0
assert_file_exists "$MANIFEST"
assert_file_contains "$MANIFEST" "fixture.txt"
SNAP=$(find "$CLAUDE_PROJECT_DIR/.claude/logs/.safe-run-trash" -name "fixture.txt" 2>/dev/null | head -1)
[ -n "$SNAP" ] || fail "no snapshot copy of the target found in trash"

case_name "fires-clean: read-only command takes no snapshot, allows"
run_hook '{"tool_input":{"command":"ls -la"}}'
assert_exit 0
assert_stdout_empty

case_name "never breaks: empty and malformed stdin"
run_hook ''
assert_exit 0
run_hook 'garbage'
assert_exit 0

finish
