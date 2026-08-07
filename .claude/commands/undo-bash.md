---
description: List recent safe-run bash snapshots and restore one (or the latest) to its original location
argument-hint: "[snapshot-id | latest | list]"
allowed-tools:
  - Read
  - Bash(cat:*, ls:*, find:*, stat:*, date:*, grep:*, head:*, tail:*, wc:*, cp:*, mkdir:*, dirname:*, basename:*, sort:*, awk:*, sed:*, cut:*, test:*)
---

Restore files that a destructive bash command clobbered, using the snapshots the
`safe-run.sh` PreToolUse hook took just before the command ran.

This is the undo half of safe-run. The hook snapshots reversible-destructive bash
(rm of specific paths, mv, cp -f over an existing file, `>` truncation, truncate,
and the git history/worktree resets) into `.claude/logs/.safe-run-trash/{id}/` and
records one line per snapshot in `.claude/logs/safe-run-manifest.jsonl`. This command
reads that manifest, shows the recent snapshots, and copies a chosen one back.

**Honest scope.** safe-run is a best-effort net, not a guarantee. A snapshot only
exists if the hook fired and could safely copy the target (it fires for main-session
bash, skips oversized targets, and does not snapshot full working trees for
`git reset --hard` / `git clean`). If there is no matching snapshot, say so plainly
rather than implying the data is recoverable. This command only ever COPIES files
back, it never deletes, and it always confirms before writing.

## Argument

- (none) or `list` , list recent snapshots, newest first, and stop.
- `latest` , restore the most recent snapshot (still shows it and confirms first).
- `<snapshot-id>` , restore that specific snapshot id (e.g. `20260629-143501-12345`).

## Steps

### Step 1: Locate the manifest and confirm there is anything to undo

```bash
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
MANIFEST="$PROJECT_DIR/.claude/logs/safe-run-manifest.jsonl"
TRASH_ROOT="$PROJECT_DIR/.claude/logs/.safe-run-trash"
if [ ! -f "$MANIFEST" ]; then
  echo "No safe-run manifest found. Nothing has been snapshotted yet (or the hook has not fired in this project)."
else
  echo "Manifest: $MANIFEST"
  echo "Snapshots on disk:"
  ls -1 "$TRASH_ROOT" 2>/dev/null || echo "  (trash dir empty)"
fi
```

If the manifest is missing or empty, tell the user there is nothing to undo and stop.

### Step 2: List recent snapshots (newest first)

Read the last entries of the manifest and present them as a numbered table. Each
manifest line is one JSON object with fields: `ts`, `id`, `intent`, `command`,
`snapshot_dir`, `paths` (and some lines have `snapshot_dir: null` with a `note`,
those are history/worktree commands that were seen but could not be file-snapshotted).

```bash
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
MANIFEST="$PROJECT_DIR/.claude/logs/safe-run-manifest.jsonl"
tail -n 20 "$MANIFEST" 2>/dev/null
```

Render to the user as:

```
Recent safe-run snapshots (newest first):

  #  | time                | id                      | command (trimmed)        | files
  ---+---------------------+-------------------------+--------------------------+------
  1  | 2026-06-29T14:35:01 | 20260629-143501-12345   | rm config.old.json       | 1
  2  | 2026-06-29T14:31:10 | 20260629-143110-12290   | > server.log             | 1
```

For lines where `snapshot_dir` is `null`, show them but mark `files: 0 (no snapshot , see note)`
so the user understands those cannot be restored.

If the argument was `list` or empty, stop here. Otherwise continue.

### Step 3: Resolve which snapshot to restore

- `latest` , the newest manifest line that has a non-null `snapshot_dir`.
- `<snapshot-id>` , the line whose `id` matches exactly. If no match, report the id
  was not found and re-show the list. Do not guess.

Read the resolved line's `snapshot_dir` and `paths`. Confirm the snapshot dir still
exists on disk (it may have been TTL/size-pruned):

```bash
SNAP_DIR="<snapshot_dir from the chosen line>"
if [ -d "$SNAP_DIR" ]; then
  echo "Snapshot present. Contents:"
  find "$SNAP_DIR" -type f 2>/dev/null | head -50
else
  echo "Snapshot directory no longer exists (it was pruned). Cannot restore this one."
fi
```

If the snapshot dir is gone, tell the user it was pruned and stop. Do not fabricate a restore.

### Step 4: Show the restore plan and CONFIRM

Map each snapshotted file back to its original location. The hook stores files under
the snapshot dir mirroring their path:
- `"$SNAP_DIR/abs/<absolute-path>"` restores to `/<absolute-path>`
- `"$SNAP_DIR/rel/<relative-path>"` restores to `<relative-path>` under the project dir

Present the exact plan and a clear warning that restoring OVERWRITES whatever is at the
destination now (the post-command state):

```
Restore plan for snapshot 20260629-143501-12345 (rm config.old.json):

  FROM: .claude/logs/.safe-run-trash/20260629-143501-12345/rel/config.old.json
  TO:   config.old.json   [will overwrite if a file exists there now]

This copies the snapshot back. It will OVERWRITE the current contents at each
destination. Proceed? (yes / no)
```

**Wait for an explicit `yes` before writing anything.** If the user says no, stop and
change nothing. This confirm step is mandatory, never auto-restore.

### Step 5: Restore

On confirmation, copy each file from the snapshot back to its original location,
creating parent directories as needed, preserving attributes:

```bash
# For each file in the snapshot, recreate its destination dir then copy it back.
# (Run one cp per file so a single failure does not abort the rest.)
SNAP_DIR="<snapshot_dir>"
# Example for a relative-path entry:
#   DEST="$PROJECT_DIR/<relative-path>"
#   mkdir -p "$(dirname "$DEST")" && cp -a "$SNAP_DIR/rel/<relative-path>" "$DEST"
# Example for an absolute-path entry:
#   DEST="/<absolute-path>"
#   mkdir -p "$(dirname "$DEST")" && cp -a "$SNAP_DIR/abs/<absolute-path>" "$DEST"
```

Report what was restored, one line per file, with the destination path. If any single
copy failed (permission, missing parent), say which one and why, and continue with the rest.

### Step 6: Confirm result

State plainly:
- which files were restored and to where,
- that the snapshot is left in place in the trash dir (so the user can restore again if
  needed; it will be TTL/size-pruned automatically by the hook later),
- and, if the original command was a `git reset --hard` / `git clean` line with no file
  snapshot, that git's own tools (`git reflog`, `git fsck --lost-found`) are the real
  recovery path for those, since safe-run does not snapshot full working trees.

Do not over-claim. If only some files were recoverable, say exactly which.
