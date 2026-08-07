#!/bin/bash
# hook-proof: validate-handoff.sh (handoff validator; documented exit 1 on invalid)
. "$(dirname "$0")/_assert.sh"
HOOK="$HOOKS_DIR/validate-handoff.sh"
DATE_SHORT=$(date +"%m%d%y")
TODAY="$CLAUDE_PROJECT_DIR/Daily Notes/${DATE_SHORT}.md"

case_name "fires: valid handoff passes"
cat > "$TODAY" <<NOTE
# Daily Note

## Session Handoff, 09:00

**Task:** Prove every shipped hook fires and blocks as documented
**Done:**
- Seeded the fixture project
**Remaining:**
- Run the remaining proofs
**Decisions:**
- Test against a fixture, never the real project
**Files:** .claude/memory.md
**Refs:** none
**Open threads:** none
**Next:** Run bash .claude/hooks/tests/run-all.sh and read the PASS/FAIL table
NOTE
run_hook ''
assert_exit 0

case_name "blocks: missing daily note reported on stderr with exit 1"
mv "$TODAY" "$TODAY.bak"
run_hook ''
assert_exit 1
assert_stdout_empty
assert_stderr_contains "VALIDATE_HANDOFF"
mv "$TODAY.bak" "$TODAY"

case_name "blocks: vague Next rejected"
cat > "$TODAY.vague" <<NOTE
## Session Handoff, 10:00

**Task:** x
**Done:**
- y
**Remaining:**
- z
**Files:** .claude/memory.md
**Next:** Continue
NOTE
cp "$TODAY" "$TODAY.good"
cp "$TODAY.vague" "$TODAY"
run_hook ''
assert_exit 1
assert_stderr_contains "too vague"
cp "$TODAY.good" "$TODAY"
rm -f "$TODAY.vague" "$TODAY.good"

finish
