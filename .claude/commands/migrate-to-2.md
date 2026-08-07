---
description: Upgrade an installed Claudify config from 1.0 to 2.0 in place, backup first, never overwrite your customizations
argument-hint: "[optional: path to install, defaults to cwd]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash(cp:*, mkdir:*, diff:*, git status:*, git diff:*, date:*, ls:*, find:*)
---

Upgrades a Claudify install from 1.0 to 2.0 in place. Safety is the first priority: this command takes a full timestamped backup before touching a single file, and it never overwrites anything you customized without leaving both the backup and a side-by-side `.2.0-new` copy for review. If any step cannot complete safely, it stops and tells you how to restore. The mechanism is version-agnostic: it classifies files by whether you modified them, not by a hardcoded list, so it keeps working as the 2.0 contents evolve. It is idempotent: re-running on an already-migrated install detects the 2.0 state and re-reports rather than repeating the work.

The three-way rule that governs every decision:
- **System-shipped, unmodified** by you: safe to update to 2.0.
- **System-shipped, modified** by you: your version is preserved, the new 2.0 version is written alongside with a `.2.0-new` suffix and flagged for manual review. Never silently overwritten.
- **User-owned** (you created it, or it is a designated user file): never touched.

---

## Steps

### Step 1: Resolve the target and pre-flight

Determine the install directory. If the user passed a path in `$ARGUMENTS`, use it. Otherwise use the current working directory.

```bash
date +"%Y%m%d-%H%M"
```

Confirm this is a Claudify install before doing anything. Require ALL of:
- `.claude/` directory exists at the target.
- `CLAUDE.md` exists at the target and contains the Claudify marker line (`This project uses Claudify` or a `# Claude Context` heading).
- `.claude/commands/` and `.claude/agents/` exist.

If any are missing, STOP and report: "This does not look like a Claudify install (missing: [list]). No changes made. Point me at the directory that contains your `.claude/` folder and `CLAUDE.md`." Do not attempt to migrate a non-Claudify directory.

Determine the **current version**. Check, in order:
- `.claude/VERSION` if present.
- A `version:` or `Claudify v` marker in `.claude/command-index.md` or `CLAUDE.md`.
- If no marker exists, treat it as 1.0 (the pre-versioning baseline).

**Idempotency check:** if the detected version is already 2.0 (a `.claude/VERSION` reading 2.0, or the 2.0 marker files are already present and match), STOP and report: "This install is already at Claudify 2.0. Nothing to migrate. If you want to re-verify, see the ROLLBACK section for how to inspect the last backup." Do NOT back up or modify anything in this case.

**Confirm before proceeding.** Show the user: target path, detected current version, target version (2.0), and the fact that a full backup will be taken first. Ask for explicit confirmation to proceed. Do not continue without it.

### Step 2: Full backup (the restore path)

Create a timestamped backup directory at the target root and copy the entire `.claude/` tree plus `CLAUDE.md` into it. Include `CLAUDE.local.md` if it exists.

```bash
BACKUP=".claude-backup-$(date +%Y%m%d-%H%M)"
mkdir -p "$BACKUP"
cp -R ".claude" "$BACKUP/.claude"
cp "CLAUDE.md" "$BACKUP/CLAUDE.md"
[ -f "CLAUDE.local.md" ] && cp "CLAUDE.local.md" "$BACKUP/CLAUDE.local.md"
ls -la "$BACKUP"
```

**Verify the backup exists and is non-empty before touching anything.** Confirm `"$BACKUP/.claude"` and `"$BACKUP/CLAUDE.md"` are present and that the `.claude` copy contains the expected subdirectories (`commands`, `agents`, `skills`, `hooks`). If the backup did not complete, STOP immediately and report the failure. Do not proceed to any write. The rest of this command assumes a good backup exists as the guaranteed restore path.

Record the backup path. It appears in the final report and the ROLLBACK section.

### Step 3: Classify every file

Build the 2.0 baseline reference and the 1.0 baseline reference so files can be classified correctly.

- **2.0 base** = the files shipped in this command's own Claudify template tree (the `cli/templates/claudify/` source that this 2.0 install is being upgraded to). This is the authoritative source of what 2.0 ships.
- **1.0 baseline** = the pristine 1.0 shipped files, if a `.claude/.baseline/` snapshot or the original 1.0 template is available. If no 1.0 baseline is available, fall back to the rule below.

Walk the install's `.claude/` tree plus `CLAUDE.md` and sort each file into exactly one category.

**(c) USER-OWNED, never touch.** Any of:
- `.claude/memory.md`
- `.claude/knowledge-base.md`
- `.claude/knowledge-nominations.md`
- `.claude/agent-memory/**` (per-agent learned state)
- `.claude/logs/**` (audit trail)
- `Daily Notes/**`, `Scratchpad.md`, `Task Board.md`
- `CLAUDE.local.md` (gitignored personal overrides)
- Any file that does NOT exist in the 2.0 base AND does NOT exist in the 1.0 baseline (you created it: a custom command, agent, skill, or note).
- The user-authored sections INSIDE `CLAUDE.md`: the content under `## This project`, `## Project conventions`, and `## Local context`. These are preserved verbatim during the CLAUDE.md merge in Step 4.

**(a) SYSTEM-SHIPPED, UNMODIFIED, safe to update.** A file that exists in the 2.0 base AND whose current content is byte-identical to the 1.0 baseline (you never edited it). Determine this with a diff against the 1.0 baseline:

```bash
diff -q ".claude/commands/start.md" ".claude/.baseline/commands/start.md"
```

Exit 0 (identical) means category (a). If no 1.0 baseline file exists to compare against but the file exists in both 1.0 conceptually and the 2.0 base, and you cannot prove it was modified, be conservative: treat it as category (b), not (a). Never assume unmodified without evidence.

**(b) SYSTEM-SHIPPED, MODIFIED by you, needs care.** A file that exists in both the 2.0 base and the 1.0 baseline, but whose current content differs from the 1.0 baseline (you edited it). These get the preserve-plus-`.2.0-new` treatment in Step 4.

**Classification safety rule:** when a file cannot be confidently placed, default to the most protective category. Unknown provenance defaults to (c) user-owned. Known-shipped but uncertain-whether-modified defaults to (b) modified. The only files that get overwritten are those PROVEN to be category (a).

Produce three explicit lists (a), (b), (c) before writing anything. This is the plan; the next step executes it.

### Step 4: Apply 2.0

Work strictly from the three lists. Take the backup as given (Step 2 verified it).

**Category (a), unmodified shipped files:** overlay the 2.0 base version directly. Copy or write the new content over the existing file. Also copy any brand-new 2.0 files (present in the 2.0 base, absent from the install) into place, these are pure additions and cannot clobber anything.

**Category (b), modified shipped files:** do NOT overwrite. Keep the user's file exactly as-is. Write the new 2.0 version alongside it with a `.2.0-new` suffix (for example `start.md` stays, `start.md.2.0-new` is created). Add each one to the "needs manual review" list in the report so the user can diff and merge deliberately.

```bash
cp "<2.0-base>/commands/start.md" ".claude/commands/start.md.2.0-new"
diff ".claude/commands/start.md" ".claude/commands/start.md.2.0-new"
```

**Category (c), user-owned files:** never touched. Skip entirely.

**CLAUDE.md merge (special case, it is part shipped, part user-owned):** CLAUDE.md carries both system-shipped documentation sections and three user-authored sections. Merge it, do not blanket-overwrite:
- Take the 2.0 base CLAUDE.md as the new frame (updated system sections).
- Preserve the user's existing `## This project`, `## Project conventions`, and `## Local context` content verbatim, splicing it into the corresponding sections of the 2.0 frame.
- If the 2.0 frame renames or restructures those sections, keep the user's content under the closest matching heading and note the mapping in the report.
- If you cannot cleanly reconcile the two (structure diverged too far), do NOT overwrite CLAUDE.md. Leave the user's CLAUDE.md in place, write the new frame as `CLAUDE.md.2.0-new`, and flag it for manual review like a category (b) file.

Never edit files in the backup directory. It is the immutable restore point.

### Step 5: Write the version marker and the migration report

Write `.claude/VERSION` with `2.0` so future runs detect the migrated state (idempotency).

Compose a migration summary and write it to `MIGRATION-2.0.md` at the install root, then output it to the user. The summary contains:

```markdown
# Claudify 2.0 Migration Report, [date]

## Result
Migrated [target path] from [previous version] to 2.0.
Backup: [.claude-backup-YYYYMMDD-HHMM]

## What is new in 2.0
- [Brief list of the notable additions/changes shipped in this 2.0 base]

## Updated automatically (unmodified shipped files)
- [file], [file], ...  (or "none")

## Added (new 2.0 files)
- [file], [file], ...  (or "none")

## Preserved untouched (your customizations)
- [file], [file], ...  (memory, knowledge base, custom commands/agents/skills, daily notes)

## Needs your manual review (you had edited these, 2.0 has a newer version)
For each: your version is unchanged; the 2.0 version is alongside as `<file>.2.0-new`.
- [file] -> [file].2.0-new
Review with:  diff <file> <file>.2.0-new
Merge deliberately, then delete the `.2.0-new` copy.

## CLAUDE.md
[Merged: user sections preserved. | Or: could not auto-merge, new frame written as CLAUDE.md.2.0-new for review.]

## Rollback
See the ROLLBACK section below or in the command file.
```

Keep the report factual. No hype. Every file that changed, was added, was preserved, or needs review must be accounted for in exactly one section.

### Step 6: Final confirmation

Output a short closing summary to the user: previous version, now 2.0, backup path, count of files updated / added / preserved / flagged for review, and a one-line pointer to `MIGRATION-2.0.md` and the ROLLBACK instructions. Do not claim success for anything not actually written.

---

## Rollback

The migration never destroys your original state. To restore the install exactly as it was before migration:

1. Identify the backup created by this run: `.claude-backup-YYYYMMDD-HHMM` at the install root (also named in `MIGRATION-2.0.md`).
2. Restore the two things that were touched:

```bash
BACKUP=".claude-backup-YYYYMMDD-HHMM"   # use the actual timestamp from the report
rm -rf ".claude"
cp -R "$BACKUP/.claude" ".claude"
cp "$BACKUP/CLAUDE.md" "CLAUDE.md"
[ -f "$BACKUP/CLAUDE.local.md" ] && cp "$BACKUP/CLAUDE.local.md" "CLAUDE.local.md"
```

3. Remove the migration artefacts if you want a clean pre-2.0 state: delete any `*.2.0-new` files, `MIGRATION-2.0.md`, and the `.claude/VERSION` marker (or set it back to 1.0).

The `rm -rf ".claude"` step is safe only because the backup holds a full copy. Verify the backup exists (`ls "$BACKUP/.claude"`) before running it. If you are unsure, copy the backup aside first.

## Idempotency and re-running

Re-running this command is safe. On an install already at 2.0 (detected via `.claude/VERSION` or the present-and-matching 2.0 markers), it makes no changes and re-reports the last migration state. A partially-completed run can be re-run after restoring from the backup: restore first (ROLLBACK), then run the command again from a clean pre-2.0 state.
