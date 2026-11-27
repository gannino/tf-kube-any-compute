#!/bin/bash
# PreToolUse Bash hook , safe-run: bash blast-radius reversibility.
#
# WHAT THIS IS, AND WHAT IT IS NOT
#   This is a SAFETY NET, not a guarantee. It snapshots the files a reversible
#   destructive bash command is about to clobber, so /undo-bash can restore them.
#   It does NOT promise to catch everything, and it is NOT a sandbox.
#
#   It complements guard-bash.sh, it does not replace or duplicate it:
#     - guard-bash.sh owns the HARD-DENY of truly catastrophic commands
#       (rm -rf /, rm -rf ~, force-push, git reset --hard, git clean -f, chmod 777).
#       safe-run NEVER denies and NEVER re-decides those , it only snapshots.
#     - safe-run owns the reversible-destructive MIDDLE GROUND: rm of specific
#       paths, mv, cp -f over an existing file, > truncation, truncate, and the
#       git history/worktree resets , taking an undo snapshot before they run.
#   If guard-bash denies a command, that command never runs; any snapshot
#   safe-run took is harmless and gets TTL/size-pruned later.
#
# FAIL-OPEN, ABSOLUTELY
#   Every error path , cannot parse stdin, no jq, path missing, disk full,
#   permission denied, target too large , results in ALLOW + silence. This hook
#   must NEVER block a legitimate command and NEVER error a session. It only
#   adds an undo net when it can do so safely and cheaply. exit 0 always.
#
# SCOPE HONESTY
#   This fires for MAIN-SESSION bash. Bash dispatched from inside a subagent may
#   not trigger the parent session's hooks, so those commands can run without a
#   snapshot. safe-run is a net for the common case, not a universal guarantee.
#
# Style matches backup-before-write.sh (snapshot + async/non-blocking + prune)
# and guard-bash.sh (single Bash PreToolUse, stdin JSON, conservative).

# ------------------------------------------------------------------
# Hard fail-open harness: any unexpected error -> allow + silent.
# No `set -e`. set -u is intentionally NOT used (we guard vars by hand and
# want a stray unset var to degrade to allow, never to abort mid-snapshot).
# ------------------------------------------------------------------
trap 'exit 0' ERR

# Tunables (conservative).
MAX_FILE_BYTES=$((50 * 1024 * 1024))      # skip snapshotting any single target > 50MB
MAX_TRASH_BYTES=$((500 * 1024 * 1024))    # cap total trash dir at ~500MB
TRASH_TTL_DAYS=7                          # prune snapshots older than 7 days
MAX_PATHS_PER_CMD=40                      # do not snapshot more than this many targets in one command

# ------------------------------------------------------------------
# Read stdin (the PreToolUse payload). Never block on it.
# ------------------------------------------------------------------
INPUT="$(cat 2>/dev/null || true)"
[ -z "$INPUT" ] && exit 0

# ------------------------------------------------------------------
# Extract the proposed command. Prefer jq; degrade gracefully if absent.
# ------------------------------------------------------------------
COMMAND=""
if command -v jq >/dev/null 2>&1; then
  COMMAND="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
fi
if [ -z "$COMMAND" ]; then
  # jq missing or returned nothing: best-effort extract "command":"..." without jq.
  # Portable across BSD (macOS) and GNU: strip everything up to and including
  # `"command":"`, then walk characters and stop at the first UNESCAPED quote
  # (so a value containing escaped quotes is captured whole). BRE alternation
  # (\|) is intentionally avoided , BSD sed does not support it. This is a
  # heuristic; if it yields nothing we simply allow with no snapshot (fail-open).
  COMMAND="$(printf '%s' "$INPUT" \
    | tr '\n' ' ' \
    | sed -E 's/.*"command"[[:space:]]*:[[:space:]]*"//' 2>/dev/null \
    | awk '{
        out=""; n=split($0,ch,"");
        for(i=1;i<=n;i++){
          c=ch[i];
          if(c=="\\"){ out=out c ch[i+1]; i++; continue }
          if(c=="\""){ break }
          out=out c
        }
        print out
      }' 2>/dev/null || true)"
  # Unescape the most common JSON escapes so paths look right. Best-effort.
  if [ -n "$COMMAND" ]; then
    COMMAND="$(printf '%s' "$COMMAND" \
      | sed -e 's/\\"/"/g' -e 's/\\\\/\\/g' -e 's/\\t/\t/g' 2>/dev/null || printf '%s' "$COMMAND")"
  fi
fi

# Nothing to inspect -> allow.
[ -z "$COMMAND" ] && exit 0

# ------------------------------------------------------------------
# FAST PATH: skip the overwhelming majority of bash immediately.
# If the command contains none of the destructive tokens we care about,
# return before doing any work. Most bash is read-only; this keeps the
# common path to a couple of greps and an exit.
# ------------------------------------------------------------------
if ! printf '%s' "$COMMAND" | grep -qE '(\brm\b|\bmv\b|\bcp\b|\btruncate\b|>|git[[:space:]]+(reset|clean|checkout))'; then
  exit 0
fi

# ------------------------------------------------------------------
# Defer to guard-bash for the catastrophic set. We do NOT re-deny, but we
# also do not bother snapshotting things guard-bash will hard-block from
# ever running, EXCEPT the reversible git resets which the task asks us to
# snapshot. Cheap guard: if this is a root/home wipe, just allow (guard-bash
# owns it) and take no snapshot (we could never shadow-copy / or ~ anyway).
# ------------------------------------------------------------------
if printf '%s' "$COMMAND" | grep -qE 'rm[[:space:]]+(-[a-zA-Z]*[rf][a-zA-Z]*[[:space:]]+)*(/|~|\$HOME)[[:space:]]*($|;|&|\|)'; then
  exit 0
fi

# Resolve project dir. If unset, fall back to cwd. If even that fails, allow.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd 2>/dev/null || true)}"
[ -z "$PROJECT_DIR" ] && exit 0
[ -d "$PROJECT_DIR" ] || exit 0

LOG_DIR="$PROJECT_DIR/.claude/logs"
TRASH_ROOT="$LOG_DIR/.safe-run-trash"
MANIFEST="$LOG_DIR/safe-run-manifest.jsonl"

# Create dirs; if we cannot, allow silently (fail-open).
mkdir -p "$TRASH_ROOT" 2>/dev/null || exit 0
[ -d "$TRASH_ROOT" ] || exit 0

TS="$(date +"%Y%m%d-%H%M%S" 2>/dev/null || true)"
[ -z "$TS" ] && exit 0
# Add a short random/PID suffix so two commands in the same second never collide.
SNAP_ID="${TS}-$$"
SNAP_DIR="$TRASH_ROOT/$SNAP_ID"

# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------

# JSON-escape a string for the manifest (no jq dependency).
json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\t/\\t/g' 2>/dev/null \
    | tr '\n' ' ' 2>/dev/null || printf '%s' "$1"
}

# Portable byte-size of a single file (not dir). Echoes a number or nothing.
file_size_bytes() {
  local f="$1"
  [ -f "$f" ] || { echo ""; return; }
  # macOS stat, then GNU stat, then wc fallback.
  stat -f%z "$f" 2>/dev/null || stat -c%s "$f" 2>/dev/null || wc -c < "$f" 2>/dev/null | tr -d ' '
}

# Total bytes used by the trash root (best-effort, KB->bytes).
trash_total_bytes() {
  local kb
  kb="$(du -sk "$TRASH_ROOT" 2>/dev/null | awk '{print $1}' 2>/dev/null)"
  [ -z "$kb" ] && { echo 0; return; }
  echo $(( kb * 1024 ))
}

# Snapshot one existing path (file or dir) into SNAP_DIR preserving its
# relative-to-project location. Returns 0 if something was copied, 1 otherwise.
# Conservative: skips missing paths, oversized files, and oversized dirs.
SNAPSHOTTED=""   # space-free list is hard; we build a JSON array string instead
SNAP_JSON_ITEMS=""
snapshot_path() {
  local target="$1"
  [ -z "$target" ] && return 1

  # Expand a leading ~ to $HOME for existence checks (best-effort).
  case "$target" in
    "~"|"~/"*) target="${HOME}${target#\~}" ;;
  esac

  # Must already exist to be worth snapshotting (we are saving what will be lost).
  [ -e "$target" ] || return 1

  # Never try to snapshot the trash dir itself (no recursion).
  case "$target" in
    "$TRASH_ROOT"|"$TRASH_ROOT"/*) return 1 ;;
  esac

  # Size guard.
  if [ -f "$target" ]; then
    local sz; sz="$(file_size_bytes "$target")"
    if [ -n "$sz" ] && [ "$sz" -gt "$MAX_FILE_BYTES" ] 2>/dev/null; then
      return 1   # too big, skip (fail-open: command still runs)
    fi
  elif [ -d "$target" ]; then
    local dkb; dkb="$(du -sk "$target" 2>/dev/null | awk '{print $1}' 2>/dev/null)"
    if [ -n "$dkb" ] && [ $(( dkb * 1024 )) -gt "$MAX_FILE_BYTES" ] 2>/dev/null; then
      return 1   # tree too big, skip
    fi
  else
    return 1     # not a regular file or dir (socket, device, etc.) , skip
  fi

  # Compute a destination that preserves the path layout.
  # Absolute paths -> stored under SNAP_DIR/abs/<path>.
  # Project-relative or other relative paths -> SNAP_DIR/rel/<path>.
  local dest
  case "$target" in
    /*) dest="$SNAP_DIR/abs${target}" ;;
    *)  dest="$SNAP_DIR/rel/${target#./}" ;;
  esac

  local dest_parent; dest_parent="$(dirname "$dest" 2>/dev/null)"
  [ -z "$dest_parent" ] && return 1
  mkdir -p "$dest_parent" 2>/dev/null || return 1

  # Copy preserving attributes. -a is archive (recursive + perms + symlink-safe).
  if cp -a "$target" "$dest" 2>/dev/null; then
    local esc; esc="$(json_escape "$target")"
    if [ -z "$SNAP_JSON_ITEMS" ]; then
      SNAP_JSON_ITEMS="\"$esc\""
    else
      SNAP_JSON_ITEMS="$SNAP_JSON_ITEMS,\"$esc\""
    fi
    SNAPSHOTTED="yes"
    return 0
  fi
  return 1
}

# ------------------------------------------------------------------
# Extract candidate target paths from the command.
# Strategy: scan whitespace-separated tokens, keep ones that look like paths
# and that exist on disk. We deliberately do NOT execute or eval anything.
# Tokens that are flags (-rf), operators, or redirections are filtered.
# This is heuristic and conservative: if we miss a target, we simply do not
# snapshot it (fail-open), we never act destructively ourselves.
# ------------------------------------------------------------------
collect_existing_tokens_as_paths() {
  # Replace shell metacharacters that separate words with spaces, but keep the
  # path characters intact. Then iterate tokens.
  local cleaned
  cleaned="$(printf '%s' "$COMMAND" | tr '\t' ' ')"
  local count=0
  # shellcheck disable=SC2086
  for tok in $cleaned; do
    [ "$count" -ge "$MAX_PATHS_PER_CMD" ] && break
    case "$tok" in
      -*) continue ;;                       # flags
      "&&"|"||"|"|"|";"|">"|">>"|"<"|"2>"|"2>>") continue ;;  # operators
      "rm"|"mv"|"cp"|"truncate"|"git"|"reset"|"checkout"|"clean"|"sudo"|"--hard"|"--") continue ;;
      *=*) continue ;;                      # VAR=value assignments
    esac
    # Strip a trailing redirection-glued operator if present (rare).
    # Only consider tokens that exist on disk right now.
    local cand="$tok"
    case "$cand" in
      "~"|"~/"*) cand="${HOME}${cand#\~}" ;;
    esac
    if [ -e "$cand" ]; then
      if snapshot_path "$tok"; then
        count=$((count + 1))
      fi
    fi
  done
}

# Extract a `> file` (or `>>`-adjacent) truncation target: the word after a lone '>'.
collect_redirect_target() {
  # Only single '>' is truncation; '>>' is append (not destructive of prior content).
  # Find '> something' but not '>> something'. The leading (^|[^>]) anchor matches
  # a redirect at the very start of the command (e.g. "> file") as well as mid-command,
  # while still excluding the append operator '>>'. Use sed to isolate the target word.
  local redir
  redir="$(printf '%s' "$COMMAND" \
    | grep -oE '(^|[^>])>[[:space:]]*[^[:space:]>&|;]+' 2>/dev/null \
    | sed -E 's/^.*[^>]?>[[:space:]]*//' 2>/dev/null || true)"
  [ -z "$redir" ] && return 0
  # May be multiple; iterate lines.
  printf '%s\n' "$redir" | while IFS= read -r tgt; do
    [ -z "$tgt" ] && continue
    # Snapshot only if it already exists (truncation destroys existing content).
    snapshot_path "$tgt"
  done
}

# ------------------------------------------------------------------
# Decide whether this command is in the reversible-destructive set, and if so
# snapshot the relevant targets. Each branch is additive and best-effort.
# ------------------------------------------------------------------

# 1. rm of specific paths (non root/home , guard-bash owns those, handled above).
#    Covers `rm file`, `rm -f file`, `rm a b c`. (rm -rf of a project subdir is
#    soft-blocked by guard-bash, but if it ever runs we still want the snapshot.)
if printf '%s' "$COMMAND" | grep -qE '\brm\b'; then
  collect_existing_tokens_as_paths
fi

# 2. mv (source is destroyed at the old location; also clobbers an existing dest).
if printf '%s' "$COMMAND" | grep -qE '\bmv\b'; then
  collect_existing_tokens_as_paths
fi

# 3. cp -f (or cp that would overwrite): snapshot any existing destination.
#    collect_existing_tokens_as_paths snapshots every existing token, which
#    includes the destination if it already exists (the thing being overwritten).
if printf '%s' "$COMMAND" | grep -qE '\bcp\b'; then
  collect_existing_tokens_as_paths
fi

# 4. truncate (shrinks/zeroes a file).
if printf '%s' "$COMMAND" | grep -qE '\btruncate\b'; then
  collect_existing_tokens_as_paths
fi

# 5. > file truncation (single redirect over an existing file).
#    (^|[^>]) matches a redirect at command start ("> file") and mid-command alike,
#    while excluding the '>>' append operator (which does not destroy prior content).
if printf '%s' "$COMMAND" | grep -qE '(^|[^>])>[[:space:]]*[^[:space:]>&|;]'; then
  collect_redirect_target
fi

# 6. git reset --hard / git clean -fd / git checkout -- <path>.
#    guard-bash HARD-blocks reset --hard and clean -f, so they usually never run;
#    we still snapshot defensively (cheap, and a no-op if the command is denied).
#    For these, the "affected paths" are the working tree, which is too large to
#    blind-copy. We conservatively snapshot only EXPLICIT path arguments when
#    present (e.g. `git checkout -- src/app.ts`), and otherwise record the intent
#    in the manifest WITHOUT a full-tree copy (honest: no snapshot taken).
GIT_INTENT=""
if printf '%s' "$COMMAND" | grep -qE 'git[[:space:]]+reset[[:space:]]+--hard'; then
  GIT_INTENT="git-reset-hard"
elif printf '%s' "$COMMAND" | grep -qE 'git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*f'; then
  GIT_INTENT="git-clean"
elif printf '%s' "$COMMAND" | grep -qE 'git[[:space:]]+checkout[[:space:]]+(--[[:space:]]|\.)'; then
  GIT_INTENT="git-checkout-discard"
fi
if [ -n "$GIT_INTENT" ]; then
  # Snapshot explicit path operands if any exist (e.g. checkout -- <path>).
  collect_existing_tokens_as_paths
fi

# ------------------------------------------------------------------
# If we snapshotted nothing, clean up the empty snapshot dir and allow.
# (We still record a git-intent line below if relevant, so the manifest shows
# that a history-rewriting command was seen even when no file copy was possible.)
# ------------------------------------------------------------------
if [ -z "$SNAPSHOTTED" ]; then
  rmdir "$SNAP_DIR" 2>/dev/null || true
  # Record git-intent-without-snapshot honestly so /undo-bash can show context.
  if [ -n "$GIT_INTENT" ]; then
    CMD_ESC="$(json_escape "$COMMAND")"
    NOW_ISO="$(date +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || true)"
    printf '{"ts":"%s","id":"%s","intent":"%s","snapshot_dir":null,"paths":[],"note":"history/worktree command seen; no file snapshot taken (guard-bash may block it, or no explicit path operands)"}\n' \
      "$NOW_ISO" "$SNAP_ID" "$GIT_INTENT" >> "$MANIFEST" 2>/dev/null || true
  fi
  exit 0
fi

# ------------------------------------------------------------------
# Record a manifest line for the snapshot we took.
# One JSON object per line (jsonl). No jq dependency.
# ------------------------------------------------------------------
CMD_ESC="$(json_escape "$COMMAND")"
NOW_ISO="$(date +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || true)"
INTENT_FIELD="${GIT_INTENT:-bash-destructive}"
printf '{"ts":"%s","id":"%s","intent":"%s","command":"%s","snapshot_dir":"%s","paths":[%s]}\n' \
  "$NOW_ISO" "$SNAP_ID" "$INTENT_FIELD" "$CMD_ESC" "$SNAP_DIR" "$SNAP_JSON_ITEMS" \
  >> "$MANIFEST" 2>/dev/null || true

# ------------------------------------------------------------------
# Trash hygiene (best-effort, never blocks). Runs AFTER we have safely stored
# this snapshot so a prune failure cannot cost us the current undo point.
#   a) TTL prune: drop snapshot dirs older than TRASH_TTL_DAYS.
#   b) Size cap: while total trash exceeds MAX_TRASH_BYTES, delete the OLDEST
#      snapshot dirs until under the cap (keeps the most recent undo points).
# ------------------------------------------------------------------
prune_trash() {
  # a) TTL prune.
  find "$TRASH_ROOT" -mindepth 1 -maxdepth 1 -type d -mtime +"$TRASH_TTL_DAYS" -exec rm -rf {} \; 2>/dev/null

  # b) Size cap. Loop a bounded number of times to avoid any pathological spin.
  local guard=0
  while [ "$(trash_total_bytes)" -gt "$MAX_TRASH_BYTES" ] 2>/dev/null; do
    guard=$((guard + 1))
    [ "$guard" -gt 100 ] && break
    # Oldest dir by mtime. Portable-ish: list dirs with epoch mtime, sort, take first.
    local oldest
    oldest="$(find "$TRASH_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null \
      | while IFS= read -r d; do
          m="$(stat -f '%m' "$d" 2>/dev/null || stat -c '%Y' "$d" 2>/dev/null || echo 0)"
          printf '%s %s\n' "$m" "$d"
        done \
      | sort -n 2>/dev/null | head -1 | cut -d' ' -f2- 2>/dev/null)"
    [ -z "$oldest" ] && break
    # Never delete the snapshot we just created in this run.
    [ "$oldest" = "$SNAP_DIR" ] && break
    rm -rf "$oldest" 2>/dev/null || break
  done
}
prune_trash 2>/dev/null || true

# ------------------------------------------------------------------
# ALWAYS allow. No decision object = allow. This hook only adds an undo net.
# ------------------------------------------------------------------
exit 0
