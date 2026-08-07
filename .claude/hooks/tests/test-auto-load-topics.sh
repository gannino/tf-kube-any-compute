#!/bin/bash
# hook-proof: auto-load-topics.sh (UserPromptSubmit)
. "$(dirname "$0")/_assert.sh"
HOOK="$HOOKS_DIR/auto-load-topics.sh"

case_name "fires: keyword match surfaces context hints"
run_hook '{"prompt":"please deploy the app"}'
assert_exit 0
assert_stdout_contains "Auto-loaded context hints"
assert_stdout_contains ".claude/memory.md"

case_name "fires-clean: no keyword, silent"
run_hook '{"prompt":"hello there"}'
assert_exit 0
assert_stdout_empty

case_name "never breaks: malformed stdin"
run_hook 'not json at all'
assert_exit 0

finish
