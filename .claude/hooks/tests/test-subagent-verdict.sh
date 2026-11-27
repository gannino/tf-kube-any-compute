#!/bin/bash
# hook-proof: subagent-verdict.sh (SubagentStop verdict logger)
. "$(dirname "$0")/_assert.sh"
HOOK="$HOOKS_DIR/subagent-verdict.sh"
T="$CLAUDE_PROJECT_DIR/.claude/logs/fixture-sub-transcript.jsonl"

case_name "fires: subagent verdict row written"
printf '%s\n' '{"role":"assistant","message":{"content":[{"type":"text","text":"Review complete, no issues found."}]}}' > "$T"
run_hook "{\"session_id\":\"s1\",\"transcript_path\":\"$T\",\"subagent_type\":\"auditor\"}"
assert_exit 0
assert_file_contains "$CLAUDE_PROJECT_DIR/.claude/logs/subagent-verdicts.jsonl" '"subagent":"auditor"'

case_name "fires: failure wording flagged"
printf '%s\n' '{"role":"assistant","message":{"content":[{"type":"text","text":"I was blocked and could not finish."}]}}' > "$T"
run_hook "{\"session_id\":\"s2\",\"transcript_path\":\"$T\",\"subagent_type\":\"verifier\"}"
assert_exit 0
assert_file_contains "$CLAUDE_PROJECT_DIR/.claude/logs/subagent-verdicts.jsonl" '"verdict":"flagged"'

case_name "never breaks: malformed stdin"
run_hook 'garbage'
assert_exit 0

finish
