#!/bin/bash
# hook-proof: post-compact-resume.sh (SessionStart(compact) fallback resume)
. "$(dirname "$0")/_assert.sh"
HOOK="$HOOKS_DIR/post-compact-resume.sh"
MARKER="$CLAUDE_PROJECT_DIR/.claude/logs/.compaction-occurred"

case_name "fires: marker present, resume instructions injected, marker consumed"
echo "2026-07-24 10:00:00" > "$MARKER"
run_hook ''
assert_exit 0
assert_stdout_contains "POST-COMPACTION RESUME"
assert_file_missing "$MARKER"

case_name "fires-clean: no marker, silent no-op"
run_hook ''
assert_exit 0
assert_stdout_empty

case_name "never breaks: malformed stdin"
run_hook 'garbage'
assert_exit 0

finish
