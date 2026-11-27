#!/bin/bash
# hook-proofs harness runner.
# Creates a temp fixture project, points CLAUDE_PROJECT_DIR at it, seeds fixture
# files, then executes every test-*.sh (or the single test named as $1), printing
# a PASS/FAIL table and exiting nonzero on any failure.
# No network, runs in under 30 seconds.

set -u

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOKS_DIR="$(dirname "$TESTS_DIR")"

# ── Fixture project ──────────────────────────────────────────────
FIXTURE=$(mktemp -d)
trap 'rm -rf "$FIXTURE"' EXIT
export CLAUDE_PROJECT_DIR="$FIXTURE"
export HOOKS_DIR

mkdir -p "$FIXTURE/.claude/logs" "$FIXTURE/.claude/hooks" "$FIXTURE/.claude/agents" \
         "$FIXTURE/.claude/backups" "$FIXTURE/.claude/skills" \
         "$FIXTURE/.claude/agent-memory/auditor" "$FIXTURE/Daily Notes" \
         "$FIXTURE/Creatives/claudify/newsletter/issues"

# Seed fixture files the hooks read.
cat > "$FIXTURE/.claude/memory.md" <<'EOF'
# Memory
## Now
- Fixture task in flight
EOF

cat > "$FIXTURE/.claude/knowledge-base.md" <<'EOF'
# Knowledge Base
- **Fixture rule**: hooks are tested, not trusted. [Source: empirical, hook-proofs fixture]
EOF

cat > "$FIXTURE/.claude/knowledge-nominations.md" <<'EOF'
# Knowledge Nominations
## Pending
EOF

cat > "$FIXTURE/.claude/agent-memory/auditor/MEMORY.md" <<'EOF'
# Auditor Memory
- Fixture memory entry.
EOF

cat > "$FIXTURE/.claude/hooks/topic-routing.yml" <<'EOF'
deploy:
  - .claude/memory.md
EOF

# mandatory-reads registry for the SubagentStart hook.
if [ -f "$HOOKS_DIR/mandatory-reads.yml" ]; then
  cp "$HOOKS_DIR/mandatory-reads.yml" "$FIXTURE/.claude/hooks/mandatory-reads.yml"
fi
# inject-related-context helper is exercised through its own test, not the fixture copy.

DATE_SHORT=$(date +"%m%d%y")
cat > "$FIXTURE/Daily Notes/${DATE_SHORT}.md" <<EOF
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
EOF

# A plain fixture file for backup/safe-run targets.
echo "fixture content" > "$FIXTURE/fixture.txt"

# ── Run tests ────────────────────────────────────────────────────
# Iterate by basename so a project path containing spaces never word-splits.
if [ "$#" -ge 1 ]; then
  TEST_NAMES="$(basename "$1")"
else
  TEST_NAMES=$(cd "$TESTS_DIR" && ls test-*.sh 2>/dev/null)
fi

PASS=0
FAIL=0
FAILED_NAMES=""

echo ""
echo "hook-proofs: testing shipped hooks in $HOOKS_DIR"
echo "fixture project: $FIXTURE"
echo ""
printf '%-45s %s\n' "TEST" "RESULT"
printf '%-45s %s\n' "----" "------"

for name in $TEST_NAMES; do
  t="$TESTS_DIR/$name"
  [ -f "$t" ] || { printf '%-45s %s\n' "$name" "MISSING"; FAIL=$((FAIL+1)); continue; }
  if bash "$t" 2> "$FIXTURE/.last-test-stderr"; then
    printf '%-45s %s\n' "$name" "PASS"
    PASS=$((PASS+1))
  else
    printf '%-45s %s\n' "$name" "FAIL"
    sed 's/^/    /' "$FIXTURE/.last-test-stderr"
    FAIL=$((FAIL+1))
    FAILED_NAMES="$FAILED_NAMES $name"
  fi
done

echo ""
echo "hook-proofs summary: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  echo "failed:$FAILED_NAMES"
  exit 1
fi
exit 0
