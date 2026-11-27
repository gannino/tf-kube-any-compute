#!/bin/bash
# hook-proofs shared assertion library (content layer copy).
# Sourced by every test-*.sh. Provides tiny assertions plus the run_hook helper.

FAILURES=0
CASE=""

case_name() { CASE="$1"; }

fail() {
  echo "    FAIL [$CASE] $1" >&2
  FAILURES=$((FAILURES + 1))
}

run_hook() {
  local payload="$1"
  STDOUT_FILE=$(mktemp)
  STDERR_FILE=$(mktemp)
  printf '%s' "$payload" | bash "$HOOK" > "$STDOUT_FILE" 2> "$STDERR_FILE"
  EXIT_CODE=$?
}

assert_exit() {
  [ "$EXIT_CODE" -eq "$1" ] || fail "expected exit $1, got $EXIT_CODE (stderr: $(head -c 200 "$STDERR_FILE" | tr '\n' ' '))"
}

assert_stdout_empty() {
  [ ! -s "$STDOUT_FILE" ] || fail "expected empty stdout, got: $(head -c 200 "$STDOUT_FILE" | tr '\n' ' ')"
}

assert_stdout_contains() {
  grep -qF "$1" "$STDOUT_FILE" || fail "stdout missing '$1' (got: $(head -c 200 "$STDOUT_FILE" | tr '\n' ' '))"
}

assert_stderr_contains() {
  grep -qF "$1" "$STDERR_FILE" || fail "stderr missing '$1' (got: $(head -c 200 "$STDERR_FILE" | tr '\n' ' '))"
}

assert_file_exists() {
  [ -e "$1" ] || fail "expected file to exist: $1"
}

assert_file_missing() {
  [ ! -e "$1" ] || fail "expected file to be absent: $1"
}

assert_file_contains() {
  grep -qF "$2" "$1" 2>/dev/null || fail "file $1 missing '$2'"
}

finish() {
  if [ "$FAILURES" -eq 0 ]; then
    exit 0
  fi
  exit 1
}
