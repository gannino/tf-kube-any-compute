#!/bin/bash
# Stop + SubagentStop hook: claim-check, an anti-fabrication / claim-vs-evidence gate.
#
# WHAT IT DOES
#   Scans the final assistant turn for HIGH-SIGNAL completion claims ("tests pass",
#   "deployed", "fixed", "migration applied", "all green", "build succeeds") and, for
#   each claim, looks back through the SAME transcript for matching BACKING EVIDENCE:
#   a real test-runner invocation with exit output, a build log, a diff touching the
#   files named, or an actual command that was run. A claim with no evidence behind it
#   is surfaced as a loud "UNVERIFIED CLAIM" verdict and logged to claim-check.jsonl.
#
#   It makes "done" mean something by demanding evidence the model cannot author itself.
#   It REDUCES fabrication; it does NOT guarantee correctness. A passing test-runner
#   invocation proves a command ran, not that the change is right. This hook closes the
#   loop the verifier agent opens ("No evidence, no pass") at the session boundary.
#
# ADVISORY, NEVER A WALL (critical design constraints)
#   * A Stop hook CANNOT block, and this one does not try to. It is purely ADVISORY:
#     a loud verdict surfaced to the user, never a gate that stops the turn.
#   * It ALWAYS exits 0. It never returns a blocking JSON decision. Nothing it does can
#     prevent the session (or subagent) from finishing.
#   * It is FAIL-OPEN. If the transcript is missing, unreadable, or unparseable, it stays
#     SILENT and exits 0. It never errors, never warns about itself, never breaks a session.
#   * It keeps false positives low on purpose: a tight high-signal verb set only, and the
#     claim must be about THIS session's work (an asserted, present-result statement), not
#     a plan, a question, a hedge, or a future intention.
#   * jq is OPTIONAL. The hook detects jq and uses it for clean JSONL when present; when
#     jq is absent it degrades to a hand-rolled writer and still works. It never requires jq.
#
# STYLE
#   Mirrors log-stop-verdict.sh / subagent-verdict.sh: read stdin JSON, parse defensively,
#   log under .claude/logs/, always exit 0, no blocking. Bash 3.2 safe (no associative
#   arrays, no ${x^^}); set -u safe.

set -u

# ── Resolve project dir (CLAUDE_PROJECT_DIR may be unset in some launch contexts) ──
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
LOG_DIR="$PROJECT_DIR/.claude/logs"
CLAIM_LOG="$LOG_DIR/claim-check.jsonl"
INCIDENT_LOG="$LOG_DIR/incident-log.md"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# ── Read the hook payload from stdin (Stop / SubagentStop) ──
INPUT=$(cat 2>/dev/null || echo '{}')

# Detect jq once. We never require it; it only buys us cleaner field extraction + JSON.
HAVE_JQ=0
if command -v jq >/dev/null 2>&1; then
  HAVE_JQ=1
fi

# ───────────────────────── helpers (defined before any call) ─────────────────────────

# Pull a value from the payload by key, with a jq path and a grep fallback.
# Usage: payload_field <jq-path> <grep-key>
payload_field() {
  local jq_path="$1"
  local grep_key="$2"
  local val=""
  if [ "$HAVE_JQ" -eq 1 ]; then
    val=$(printf '%s' "$INPUT" | jq -r "$jq_path // empty" 2>/dev/null)
  fi
  if [ -z "$val" ]; then
    # Fallback: first "key":"value" occurrence, value only.
    val=$(printf '%s' "$INPUT" | grep -o "\"$grep_key\":\"[^\"]*\"" 2>/dev/null | head -1 | cut -d'"' -f4)
  fi
  printf '%s' "$val"
}

# JSON-escape a string for the no-jq writer. Escapes backslash and quote, flattens tabs
# and newlines to spaces. The values we write (timestamp, ids, class tags) are already
# tame; this is belt-and-braces so a malformed line can never corrupt the JSONL.
json_escape() {
  printf '%s' "$1" \
    | tr '\t\n' '  ' \
    | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# Append one structured JSONL row. status = verified | unverified.
# Uses jq when available; degrades to a hand-built line otherwise.
# Usage: write_jsonl_row <status> <claims> <unverified>
write_jsonl_row() {
  local status="$1"
  local claims="$2"
  local unverified="$3"
  mkdir -p "$LOG_DIR" 2>/dev/null
  if [ "$HAVE_JQ" -eq 1 ]; then
    # -c is REQUIRED: JSONL is one object per line. Without it jq pretty-prints across
    # multiple lines and the .jsonl file stops being valid JSONL.
    jq -c -n \
      --arg ts "$TIMESTAMP" \
      --arg session_id "$SESSION_ID" \
      --arg event "$HOOK_EVENT" \
      --arg agent "$SUBAGENT" \
      --arg status "$status" \
      --arg claims "$claims" \
      --arg unverified "$unverified" \
      '{timestamp:$ts, session_id:$session_id, event:$event, agent:$agent, status:$status, claims:$claims, unverified:$unverified}' \
      >> "$CLAIM_LOG" 2>/dev/null
  else
    printf '{"timestamp":"%s","session_id":"%s","event":"%s","agent":"%s","status":"%s","claims":"%s","unverified":"%s"}\n' \
      "$(json_escape "$TIMESTAMP")" "$(json_escape "$SESSION_ID")" "$(json_escape "$HOOK_EVENT")" \
      "$(json_escape "$SUBAGENT")" "$(json_escape "$status")" "$(json_escape "$claims")" "$(json_escape "$unverified")" \
      >> "$CLAIM_LOG" 2>/dev/null
  fi
}

# Record a detected claim class without duplicates.
add_claim() {
  case " $CLAIMS " in
    *" $1 "*) : ;;            # already recorded
    *) CLAIMS="$CLAIMS $1" ;;
  esac
}

# Human-readable label per class for the verdict line.
class_label() {
  case "$1" in
    tests)   printf 'tests pass' ;;
    build)   printf 'build succeeds' ;;
    deploy)  printf 'deployed' ;;
    migrate) printf 'migration applied' ;;
    fix)     printf 'issue fixed' ;;
    *)       printf '%s' "$1" ;;
  esac
}

# What evidence we WOULD have accepted, named for the user so the verdict is actionable.
class_expected() {
  case "$1" in
    tests)   printf 'a test runner invocation with exit output (pytest, npm test, go test, ...)' ;;
    build)   printf 'a build command with its result (npm run build, go build, tsc, ...)' ;;
    deploy)  printf 'a deploy command (git push, vercel, fly deploy, kubectl apply, ...)' ;;
    migrate) printf 'a migration command (prisma migrate, alembic upgrade, db:migrate, ...)' ;;
    fix)     printf 'a code change (Edit/Write) or a test/build run confirming the fix' ;;
    *)       printf 'a command that was actually run' ;;
  esac
}

# has_evidence <class> -> 0 (found) / 1 (missing). Reads the prebuilt EVIDENCE_BLOB / RAW_LC.
has_evidence() {
  local class="$1"
  case "$class" in
    tests)
      printf '%s' "$EVIDENCE_BLOB" | grep -qE '\b(pytest|jest|vitest|mocha|go test|cargo test|rspec|phpunit|npm (run )?test|pnpm (run )?test|yarn test|bun test|python -m pytest|tox|gradlew? +test|mvn +test|dotnet test|ctest|rake test|make test)\b'
      return $?
      ;;
    build)
      printf '%s' "$EVIDENCE_BLOB" | grep -qE '\b(npm run build|pnpm (run )?build|yarn build|bun run build|go build|cargo build|tsc|make build|gradlew? +build|mvn +(package|install|compile)|dotnet build|webpack|vite build|next build|cmake --build)\b'
      return $?
      ;;
    deploy)
      printf '%s' "$EVIDENCE_BLOB" | grep -qE '\b(git push|vercel|netlify deploy|fly deploy|flyctl deploy|wrangler (deploy|publish)|gcloud (app|run) deploy|aws (deploy|s3 sync|cloudformation)|kubectl (apply|rollout)|docker push|sam deploy|serverless deploy|heroku (deploy|releases)|cap (production )?deploy|terraform apply)\b'
      return $?
      ;;
    migrate)
      # Require a migration COMMAND/tool token in tool activity, not the bare word
      # "migration" (which could appear in incidental output). "migrate " with a trailing
      # token, the framework runners, or a direct DB client all count.
      printf '%s' "$EVIDENCE_BLOB" | grep -qE '\b(migrate (up|run|deploy|dev|status)|db:migrate|alembic upgrade|prisma migrate|drizzle-kit|knex migrate|rails db:migrate|artisan migrate|sequelize db:migrate|flyway|goose (up|run)|atlas migrate|dbmate up|@libsql/client|psql|sqlite3|mysql )\b'
      return $?
      ;;
    fix)
      # A genuine fix should be backed by EITHER a code change (Edit/Write/MultiEdit fired
      # this session) OR a verification command (a test/build run). Either is acceptable.
      if printf '%s' "$TOOLNAMES_LC" | grep -qE '"name":"(edit|write|multiedit|notebookedit)"'; then return 0; fi
      printf '%s' "$EVIDENCE_BLOB" | grep -qE '\b(pytest|jest|vitest|go test|cargo test|npm (run )?test|pnpm (run )?test|yarn test|npm run build|go build|cargo build|tsc|make (test|build))\b'
      return $?
      ;;
    *)
      return 0  # unknown class: do not flag (fail open)
      ;;
  esac
}

# ───────────────────────── payload fields ─────────────────────────

TRANSCRIPT=$(payload_field '.transcript_path' 'transcript_path')
SESSION_ID=$(payload_field '.session_id' 'session_id')
STOP_ACTIVE=$(payload_field '.stop_hook_active' 'stop_hook_active')
HOOK_EVENT=$(payload_field '.hook_event_name' 'hook_event_name')
SUBAGENT=$(payload_field '.subagent_type' 'subagent_type')
[ -z "$HOOK_EVENT" ] && HOOK_EVENT="Stop"
[ -z "$SUBAGENT" ] && SUBAGENT="main"

# FAIL-OPEN gate: no readable transcript means we cannot judge anything. Stay silent.
if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  exit 0
fi

# Guard against runaway loops: if a prior Stop hook is already re-running the turn, do
# nothing further (matches the harness's stop_hook_active convention).
if [ "$STOP_ACTIVE" = "true" ]; then
  exit 0
fi

mkdir -p "$LOG_DIR" 2>/dev/null

# ═══════════════════════════════════════════════════════
# EXTRACT, the final assistant turn (the text under judgement)
# ═══════════════════════════════════════════════════════
# Transcripts are JSONL, one event per line. The closing assistant message carries the
# completion claim. We take the LAST assistant text block as the claim surface, and the
# WHOLE transcript as the evidence surface (a command run earlier still counts as backing).

FINAL_TURN=""
if [ "$HAVE_JQ" -eq 1 ]; then
  # Last assistant line, text blocks joined. Defensive: tolerate either {message:{content}}
  # (Claude Code transcript shape) or a flat {content} shape.
  LAST_ASSISTANT=$(grep '"role":"assistant"' "$TRANSCRIPT" 2>/dev/null | tail -1)
  if [ -n "$LAST_ASSISTANT" ]; then
    FINAL_TURN=$(printf '%s' "$LAST_ASSISTANT" \
      | jq -r '[((.message.content // .content)[]? | select(.type == "text") | .text)] | join("\n") // empty' 2>/dev/null)
  fi
fi
# Fallback without jq (or if the jq extraction came back empty): grab the tail of the
# transcript and strip JSON punctuation to a rough text blob. Coarse, but enough to match
# the high-signal verbs, and it keeps the hook working with no jq installed.
if [ -z "$FINAL_TURN" ]; then
  FINAL_TURN=$(tail -c 8000 "$TRANSCRIPT" 2>/dev/null \
    | tr ',' '\n' \
    | grep -iE '"text"|"type":"text"' 2>/dev/null \
    | sed -e 's/\\"/ /g' -e 's/\\n/ /g' -e 's/[{}"]/ /g')
fi

# Still nothing usable. Fail open, stay silent.
if [ -z "$FINAL_TURN" ]; then
  exit 0
fi

# Lowercase copy of the claim surface for case-insensitive matching.
FINAL_LC=$(printf '%s' "$FINAL_TURN" | tr '[:upper:]' '[:lower:]')

# ═══════════════════════════════════════════════════════
# DETECT, high-signal completion claims (tight verb set, low false positive)
# ═══════════════════════════════════════════════════════
# Each pattern is a present-tense RESULT claim about work just done. We deliberately
# exclude hedged / future / quoted forms ("should pass", "to deploy", "if the tests pass",
# "will fix") by requiring the asserted, completed phrasings below. A detected claim only
# becomes a verdict if its evidence class is missing (next block).

CLAIMS=""   # space-separated set of detected classes

# Drop conditional / future clauses BEFORE matching so "if the tests pass", "once it
# builds", "after we deploy", "when the migration runs", "should pass", "will deploy"
# cannot be read as completed results. This is the single biggest false-positive guard.
#
# Implemented in awk, NOT sed: BSD/macOS sed has no \b word boundary (it is a GNU
# extension), so a sed-based stripper silently no-ops on a Mac. awk's behaviour is
# consistent across BSD and GNU, so the guard works on every customer's box. We split the
# turn into clauses on . ; : ! ? (a leading connective like "and"/"but" is then stripped so
# the real first word is tested) and drop any clause that is conditional, future, a
# question, or a second-person instruction, keeping the assertive clauses intact. An
# all-conditional turn correctly reduces to (near) empty, which matches nothing, as it should.
if command -v awk >/dev/null 2>&1; then
  # We keep the boundary CHARACTER so a "?" can mark its clause as a question. A clause is
  # dropped (not a completed-work assertion) when it is:
  #   - conditional/future: starts with if/once/when/after/unless/should/would/could/will/to
  #   - a question: contains a "?" (the user is being ASKED, not told a result)
  #   - a second-person instruction: starts with "you" (telling the user to do something,
  #     not reporting what the assistant did, which reads "I.../the tests.../all...")
  ASSERTED_LC=$(printf '%s' "$FINAL_LC" | tr '\n' ' ' | awk '
  {
    gsub(/[.;:!]/, " \036 ");             # clause boundaries (keep ? and , inside the clause)
    gsub(/\?/, "? \036 ");                # ? also ends a clause, but stays attached as a marker
    m = split($0, parts, /\036/);
    out = "";
    for (i = 1; i <= m; i++) {
      clause = parts[i];
      if (index(clause, "?") > 0) continue;        # drop questions wholesale
      sub(/^[ \t]+/, "", clause);                   # trim leading whitespace
      sub(/^(and|but|so|then|,)[ \t]+/, "", clause);# strip a leading connective + retry first word
      w = clause; sub(/[ \t].*$/, "", w);           # first word of the clause
      if (w=="if"||w=="once"||w=="when"||w=="after"||w=="unless"||w=="should"||w=="would"||w=="could"||w=="will"||w=="to"||w=="you"||w=="try"||w=="trying")
        continue;                                   # drop conditional/future/instruction clause
      if (clause ~ /(^| )(might|maybe|perhaps|probably|possibly|likely|should|seems?|appears?|hopefully|may) / || clause ~ /(i think|i believe|i guess|i assume|not sure|not certain)/)
        continue;                                   # drop hedged clauses (a guess, not an asserted result)
      out = out " " clause;
    }
    print out;
  }')
else
  # No awk (vanishingly rare; it is POSIX). Skip the guard rather than crash, accepting a
  # slightly higher false-positive rate over breaking the hook. Still fail-open, still exit 0.
  ASSERTED_LC="$FINAL_LC"
fi

# TESTS, asserting the suite passed / is green. Matched against the asserted text only.
if printf '%s' "$ASSERTED_LC" | grep -qE '\b(all )?(tests?|test suite|specs?)\b[^.]{0,30}\b(pass|passed|passing|are green|green)\b'; then add_claim tests; fi
if printf '%s' "$ASSERTED_LC" | grep -qE '\ball green\b'; then add_claim tests; fi

# BUILD, asserting the build succeeded / compiles.
if printf '%s' "$ASSERTED_LC" | grep -qE '\b(build|compile|compilation)\b[^.]{0,25}\b(succeed|succeeds|succeeded|passes|passed|is green|works|clean)\b'; then add_claim build; fi
if printf '%s' "$ASSERTED_LC" | grep -qE '\b(builds|compiles) (successfully|cleanly|fine|without errors)\b'; then add_claim build; fi

# DEPLOY, asserting it was shipped to an environment.
if printf '%s' "$ASSERTED_LC" | grep -qE '\b(deployed|shipped (it|to)|pushed to (prod|production|staging)|is live|went live|rolled out)\b'; then add_claim deploy; fi

# MIGRATE, asserting a migration was applied. Allows "migration applied" and "migration is
# applied" (and the active "applied/ran the migration").
if printf '%s' "$ASSERTED_LC" | grep -qE '\b(migrated|migration (is )?(applied|ran|complete|completed)|(applied|ran) the migration)\b'; then add_claim migrate; fi

# FIX, asserting the issue is fixed / resolved / now works. Require a result-y phrasing so
# "let me fix" / "to fix" / "trying to fix" do not trip it.
if printf '%s' "$ASSERTED_LC" | grep -qE '\b(is (now )?fixed|the (bug|issue|error) is fixed|fixed the (bug|issue|error)|now works|works now|is resolved|resolved the (bug|issue))\b'; then add_claim fix; fi

# Nothing asserted. Nothing to check. Stay silent, exit clean.
CLAIMS=$(printf '%s' "$CLAIMS" | sed -e 's/^ *//' -e 's/ *$//')
if [ -z "$CLAIMS" ]; then
  exit 0
fi

# ═══════════════════════════════════════════════════════
# EVIDENCE, did the transcript actually back the claim?
# ═══════════════════════════════════════════════════════
# Evidence is TOOL ACTIVITY across the WHOLE transcript: tool_use events (a command was
# invoked) and tool_result events (its output). It must NOT include the assistant's prose,
# otherwise a claim could be its own evidence ("the migration is applied" must not satisfy
# the migrate check just by containing the word "migration"). So we build the evidence blob
# from tool lines only, and the tool-name blob (for Edit/Write detection) from tool_use
# lines only. Works with or without jq.

# Tool-name surface: only lines carrying a tool_use event. Used by the fix class to detect
# that an Edit/Write/MultiEdit actually fired this session.
TOOLNAMES_LC=$(grep '"tool_use"' "$TRANSCRIPT" 2>/dev/null | tr '[:upper:]' '[:lower:]')

# Command + output surface: tool_use inputs (commands) plus tool_result outputs (logs,
# exit lines). With jq we extract the structured command/result text; without jq we fall
# back to the raw tool lines, which still contain the command strings and output text.
EVIDENCE_BLOB=""
if [ "$HAVE_JQ" -eq 1 ]; then
  CMDS=$(grep '"tool_use"' "$TRANSCRIPT" 2>/dev/null \
    | jq -r 'try ((.message.content // .content)[]? | select(.type=="tool_use") | (.input.command // .input.cmd // .input.file_path // empty)) catch empty' 2>/dev/null)
  RESULTS=$(grep '"tool_result"' "$TRANSCRIPT" 2>/dev/null \
    | jq -r 'try ((.message.content // .content)[]? | select(.type=="tool_result") | (.content | if type=="array" then (.[]?.text // empty) else . end)) catch empty' 2>/dev/null)
  EVIDENCE_BLOB=$(printf '%s\n%s' "$CMDS" "$RESULTS" | tr '[:upper:]' '[:lower:]')
fi
# Universal fallback / supplement: the raw text of every tool line (use + result), with
# assistant-text lines excluded. Covers the no-jq path and anything jq missed.
if [ -z "$EVIDENCE_BLOB" ] || [ "$HAVE_JQ" -eq 0 ]; then
  TOOL_LINES_LC=$(grep -E '"tool_use"|"tool_result"' "$TRANSCRIPT" 2>/dev/null | tr '[:upper:]' '[:lower:]')
  EVIDENCE_BLOB=$(printf '%s\n%s' "$EVIDENCE_BLOB" "$TOOL_LINES_LC")
fi

# ── Collect the unverified classes ──
UNVERIFIED=""
for class in $CLAIMS; do
  if ! has_evidence "$class"; then
    UNVERIFIED="$UNVERIFIED $class"
  fi
done
UNVERIFIED=$(printf '%s' "$UNVERIFIED" | sed -e 's/^ *//' -e 's/ *$//')

# Every claim was backed. Log a clean "verified" row for trend analysis, stay quiet to the
# user (no news is good news), exit 0.
if [ -z "$UNVERIFIED" ]; then
  write_jsonl_row "verified" "$CLAIMS" ""
  exit 0
fi

# ═══════════════════════════════════════════════════════
# VERDICT, loud but advisory (surfaced to the user, never blocks)
# ═══════════════════════════════════════════════════════

# Build a comma-joined human list of the unverified claim labels.
LABELS=""
for class in $UNVERIFIED; do
  lbl=$(class_label "$class")
  if [ -z "$LABELS" ]; then LABELS="$lbl"; else LABELS="$LABELS, $lbl"; fi
done

# Emit the verdict so the user sees it at the turn boundary. This is advisory context, not
# a block: we surface it on stderr and exit 0 (a Stop hook cannot, and must not, block).
{
  echo ""
  echo "  UNVERIFIED CLAIM detected by claim-check"
  echo "  ----------------------------------------"
  echo "  This turn asserted: $LABELS"
  echo "  No backing evidence for that was found in this session's transcript."
  echo ""
  echo "  What would close the loop:"
  for class in $UNVERIFIED; do
    echo "    - $(class_label "$class"): $(class_expected "$class")"
  done
  echo ""
  echo "  This is advisory, not a block. claim-check reduces fabricated \"done\","
  echo "  it does not prove correctness. To actually close the loop, run /prove"
  echo "  (it hands the claim to the verifier agent for a real PASS/FAIL)."
  echo ""
} 1>&2

# ── Log + incident trail ──
write_jsonl_row "unverified" "$CLAIMS" "$UNVERIFIED"

# One human-readable incident line, matching the GUARD/VERDICT/SUBAGENT format used by the
# sibling hooks. Tagged WARN because it is advisory, never CRITICAL.
echo "- \`$TIMESTAMP\` | CLAIM-CHECK | WARN | $SUBAGENT | unverified: $LABELS" >> "$INCIDENT_LOG" 2>/dev/null

exit 0
