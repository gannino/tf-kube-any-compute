#!/bin/bash
# hook-proof: inject-related-context.sh (compaction-resume enrichment)
. "$(dirname "$0")/_assert.sh"
HOOK="$HOOKS_DIR/inject-related-context.sh"
DATE_SHORT=$(date +"%m%d%y")
TODAY="$CLAUDE_PROJECT_DIR/Daily Notes/${DATE_SHORT}.md"
OLD="$CLAUDE_PROJECT_DIR/Daily Notes/010101.md"

case_name "fires: related past handoff surfaced by shared keyword"
cat > "$TODAY" <<NOTE
# Daily Note

## Session Handoff, 09:00

**Task:** Finish the deploy pipeline work
**Done:**
- deploy step one
**Remaining:**
- deploy step two
**Decisions:**
- none
**Files:** .claude/memory.md
**Refs:** none
**Open threads:** none
**Next:** Continue the deploy work by reading .claude/memory.md first
NOTE
cat > "$OLD" <<NOTE
# Daily Note

## Session Handoff, 17:00

**Task:** Earlier deploy groundwork
**Files:** .claude/memory.md
**Next:** Ship the deploy config after reading memory
NOTE
run_hook ''
assert_exit 0
assert_stdout_contains "Recent related work"
assert_stdout_contains "010101"

case_name "fires-clean: no daily note, silent"
mv "$TODAY" "$TODAY.bak"
run_hook ''
assert_exit 0
assert_stdout_empty
mv "$TODAY.bak" "$TODAY"

case_name "never breaks: malformed stdin ignored"
run_hook 'garbage'
assert_exit 0
rm -f "$OLD"

finish
