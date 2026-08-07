#!/bin/bash
# hook-proof: subagent-mandatory-reads.sh (SubagentStart injection)
. "$(dirname "$0")/_assert.sh"
HOOK="$HOOKS_DIR/subagent-mandatory-reads.sh"

case_name "fires: listed agent gets its registry files plus its own MEMORY.md"
run_hook '{"subagent_type":"auditor"}'
assert_exit 0
assert_stdout_contains "MANDATORY READS for subagent 'auditor'"
assert_stdout_contains "knowledge-base.md"
assert_stdout_contains "Fixture rule"
assert_stdout_contains "agent-memory/auditor/MEMORY.md"

case_name "fires: unlisted agent falls back to default reads"
run_hook '{"subagent_type":"some-custom-agent"}'
assert_exit 0
assert_stdout_contains "MANDATORY READS for subagent 'some-custom-agent'"
assert_stdout_contains "Fixture rule"

case_name "never breaks: malformed stdin degrades to default, still exit 0"
run_hook 'garbage'
assert_exit 0

finish
