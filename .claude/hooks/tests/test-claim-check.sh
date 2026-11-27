#!/bin/bash
# hook-proof: claim-check.sh (Stop/SubagentStop, advisory anti-fabrication)
. "$(dirname "$0")/_assert.sh"
HOOK="$HOOKS_DIR/claim-check.sh"
T="$CLAUDE_PROJECT_DIR/.claude/logs/fixture-transcript.jsonl"

case_name "fires: unverified claim surfaced, advisory exit 0"
printf '%s\n' '{"role":"assistant","message":{"content":[{"type":"text","text":"All tests pass and the migration is applied."}]}}' > "$T"
run_hook "{\"transcript_path\":\"$T\",\"session_id\":\"s1\",\"hook_event_name\":\"Stop\"}"
assert_exit 0
assert_stderr_contains "UNVERIFIED CLAIM"
assert_file_exists "$CLAUDE_PROJECT_DIR/.claude/logs/claim-check.jsonl"

case_name "fires-clean: claim backed by evidence stays silent"
printf '%s\n' '{"role":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"npm test"}}]}}' > "$T"
printf '%s\n' '{"role":"user","message":{"content":[{"type":"tool_result","content":[{"type":"text","text":"npm test ... 12 passing"}]}]}}' >> "$T"
printf '%s\n' '{"role":"assistant","message":{"content":[{"type":"text","text":"All tests pass."}]}}' >> "$T"
run_hook "{\"transcript_path\":\"$T\",\"session_id\":\"s2\",\"hook_event_name\":\"Stop\"}"
assert_exit 0
grep -qF "UNVERIFIED CLAIM" "$STDERR_FILE" && fail "flagged a backed claim"

case_name "never breaks: missing transcript / empty stdin, silent"
run_hook '{"transcript_path":"/nonexistent","session_id":"s3"}'
assert_exit 0
run_hook ''
assert_exit 0

finish
