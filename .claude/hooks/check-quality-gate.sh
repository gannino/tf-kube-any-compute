#!/bin/bash
# Stop hook backstop: blocks the turn when session quality has degraded.
# Near-zero cost: single file existence check. No date call, no jq, no stdin read.
# The TRIGGER file (.quality-gate-active) is created by log-stop-verdict.sh
# when 2 or more blocked verdicts accumulate in one session. Deleted by
# /safe-clear Step 0, session-reset.sh, and the post-compaction resume hook.
#
# Exit-2 semantics (Claude Code, July 2026): exit 2 with non-JSON stdout
# hard-blocks. This hook intentionally blocks, so stdout stays EMPTY and the
# message goes to stderr.

GATE_FILE="$CLAUDE_PROJECT_DIR/.claude/logs/.quality-gate-active"

[ ! -f "$GATE_FILE" ] && exit 0

echo "QUALITY GATE: Context quality has degraded (2+ blocked verdicts this session). Run /safe-clear to persist state, then /compact to flush context." >&2
exit 2
