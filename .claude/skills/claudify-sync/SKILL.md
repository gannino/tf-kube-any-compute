---
name: claudify-sync
description: Refresh a Claudify project from its blueprint via three-way, edit-preserving merge. Use when updating a child from blueprint, pulling from blueprint to child, or vendor→blueprint.
---

# claudify-sync

A self-contained skill that refreshes a Claudify project (blueprint or child) from a reference via a three-way, edit-preserving merge.

## Usage

Run from any Claudify project to sync it with its blueprint:
- **Pull mode** (default): Child pulls from blueprint (cwd has `.claude/blueprint-origin.json`)
- **Push mode**: Blueprint pushes to child at `<path>` (`--to-child <path>`)
- **Vendor mode**: Blueprint pulls from vendor download (`--from-vendor <path>`)

## Mode Detection

The skill detects the mode from explicit arguments, then from context:

| Mode | Trigger | source | target | baseline | after |
|------|---------|--------|--------|----------|-------|
| **vendor → blueprint** | `--from-vendor <path>` | vendor folder | this repo (cwd) | this repo's git root commit | regenerate this repo's `UPDATE-MANIFEST.json` |
| **blueprint → child** | `--to-child <path>` | this repo (cwd) | `<path>` | child's marker, else child git root, else conservative | refresh child's marker |
| **child → blueprint** | default (cwd has `.claude/blueprint-origin.json`, or no flag) | blueprint (marker → `$CLAUDIFY_BLUEPRINT_DIR` → prompt) | cwd | child's marker, else child git root, else conservative | refresh child's marker |

## Blueprint Discovery

If the blueprint path is not specified, the skill resolves it in order:
1. Marker file: `.claude/blueprint-origin.json` → `blueprint_dir` field
2. Environment variable: `$CLAUDIFY_BLUEPRINT_DIR`
3. Prompt the user

## Procedure Variables

- `$SKILL_DIR`: This skill's folder (resolved relative to project)
- `$SCRIPTS`: `$SKILL_DIR/scripts/` (bundled scripts)
- `$SOURCE`: Blueprint directory
- `$TARGET`: Child directory
- `$BASELINE_FLAG`: `--baseline-manifest <marker.json>` or `--baseline <commit>` or empty

## Sync Procedure (13 Steps)

### 1. Detect Mode & Resolve Parameters

Determine the mode from arguments or context. Resolve `(source, target, baseline)` per the Modes table.

**Abort conditions:**
- Source directory missing
- Source manifest absent (`<source>/.claude/UPDATE-MANIFEST.json`)

**Already in sync short-circuit:**
If the target's marker exists and its `blueprint_manifest_sha` equals the blueprint manifest's current SHA-256, report "already in sync" and stop (nothing to update).

### 2. Git Checkpoint (Git Targets Only)

If the target is a git repo and has uncommitted changes, create a clean snapshot/rollback point:

```bash
git add -A && git commit -m "chore: snapshot before claudify-sync (<summary>)"
```

Where `<summary>` is auto-generated from the changed areas (e.g., "agents, 2 hooks, memory.md").

If the working tree is already clean, skip this step.

**Non-git targets** skip this step entirely.

### 3. Back Up Target

Create a backup of the target's `.claude/` directory. **If `<target>/.claude.backup` already exists, pick a fresh name** (`.claude.backup-2`, `-3`, …) so you don't nest or clobber a prior rollback — this is the primary restore path.

```bash
# choose $BK = .claude.backup (or .claude.backup-N if it exists)
mkdir -p <target>/$BK
cp -r <target>/.claude/. <target>/$BK/          # contents into the backup dir
cp <target>/CLAUDE.md <target>/$BK/
cp <target>/CLAUDE.local.md <target>/$BK/ 2>/dev/null || true
```

Verify the backup is non-empty before continuing (abort if it isn't).

### 4. Dry-Run Triage

Classify all files to see what will change:

```bash
python3 "$SCRIPTS/claudify-update-triage.py" \
  --source "$SOURCE" \
  --target "$TARGET" \
  $BASELINE_FLAG
```

Show the NEW / IMPROVED / CONFLICT summary. Pause on CONFLICTs (default: keep target's, park `.blueprint-new`).

### 5. Apply Changes

Apply the safe changes:

```bash
python3 "$SCRIPTS/claudify-update-apply.py" \
  --apply \
  --park-new \
  --source "$SOURCE" \
  --target "$TARGET" \
  $BASELINE_FLAG
```

This copies NEW and IMPROVED files, preserves CONFLICT files, and parks conflicting versions as `<file>.blueprint-new`.

### 6. Adopt Held-Back Review Files

The apply step (5) prints a **REVIEW** list — integration-sensitive files it deliberately did NOT write: `.claude/command-index.md`, `newsletter/send.js`, `INTEGRATION.md`, `SPEC.md`, and any unclear diff outside the safe dirs. Each of these has its blueprint version parked as `<file>.blueprint-new`. (**Hooks are NOT in this list** — they always force-sync to the blueprint's version in step 5, because hooks are infrastructure, not customizations; only a hook the child *created* that the blueprint doesn't ship is left untouched.)

Adopt the ones the child never edited, using the **triage output from step 4** as the authority:

1. Re-read the triage classification (the `--json` written in step 4, or the printed summary).
2. For each file in the apply's REVIEW list:
   - **If it is NOT a CONFLICT** in the triage (i.e. the child never edited it — classified IMPROVED, NEW, or absent from the manifest entirely) → the blueprint version is the intended update. **Copy the blueprint version over the child's file in place** (overwrite `<target>/<file>` with `<source>/<file>`), then delete the now-redundant `<file>.blueprint-new`. This is what makes command-index (and the other review files) advance on a child sync.
   - **If it IS a CONFLICT** in the triage (child edited it, or no baseline so it is treated as edited) → **leave the child's version untouched** and **keep** its parked `<file>.blueprint-new` for manual review. Do not overwrite; the child's edit wins.
3. Report which REVIEW files were adopted (auto-updated) vs left for manual review.

Concretely, adopting looks like:
```bash
# For each REVIEW file classified non-CONFLICT (e.g. .claude/hooks/log-stop-verdict.sh):
cp "$SOURCE/<file>" "$TARGET/<file>"          # adopt blueprint version in place
rm -f "$TARGET/<file>.blueprint-new"          # drop the now-redundant parked copy
```

This step only touches files the apply already flagged as REVIEW; it never re-evaluates copy/keep/skip items.

## Merge Pattern (all merges)

Every merge (CLAUDE.md, settings.json, .gitignore, .mcp.json, settings.local.json) follows an explicit **ANALYZE → RESULT → ACTIONS** flow. A merge is never a silent auto-overwrite; it is an agent action in three phases:

1. **ANALYZE** — read source and target. Classify all differences into three buckets:
   - **clean adds** — things the target lacks and the source has, with no clash (e.g. a brand-new MCP server key; a gitignore line not present; a settings hook event the target doesn't have; a CLAUDE.md system section that advanced while the target's project sections are untouched).
   - **identical / no-op** — already match.
   - **duplicates & conflicts** — anything that can't cleanly union: the *same thing under different keys/forms* (e.g. MCP server `memory` vs `github.com/.../memory`), the *same key with different values* (e.g. a hook entry whose `command` differs; a settings env key with a different value), *near-duplicate lines* (gitignore patterns that match the same intent in different forms), or *CLAUDE.md sections that diverged* and can't be cleanly spliced.

2. **RESULT** — present the analysis to the human: list the clean adds (to be applied), give a short summary/preview of the merged result, and **explicitly enumerate every duplicate/conflict** with the concrete specifics (the two keys/values and why they clash). Do not bury conflicts.

3. **ACTIONS** — apply the clean (non-conflicting) parts. For **each** duplicate/conflict, **STOP and ask the human** how to resolve (use sensible options for that case: keep target's / use source's / merge-fields / keep-both / skip). Apply each decision only after the human chooses. **Never auto-resolve a genuine conflict.** If there are zero conflicts, state the result and apply it (no question needed).

### 7. Merge CLAUDE.md (Agent)

Follow the **Merge Pattern** (analyze → result → actions; ask on any conflict).

**Read both files, then produce the merged CLAUDE.md:**

1. **Read source frame:** `<source>/CLAUDE.md`
2. **Read target:** `<target>/CLAUDE.md`
3. **Produce merged file** by taking the source frame as the base and preserving VERBATIM every target `##` section whose content is not already present verbatim in the source frame:
   - Common preserved sections: `## This project`, `## Project conventions`, `## Local context`
   - Any custom `##` section the target added (user-specific content)
4. **Splice preserved sections** under their closest-matching heading in the source frame
5. **If unreconcilable:** DO NOT overwrite the target's CLAUDE.md — leave it unchanged and write the source frame to `<target>/CLAUDE.md.blueprint-new` for manual review

**Conflicts to surface:** a target `##` section whose content diverged from the source frame's section of the same name (not a clean preserve-or-replace).

**Example:**
```markdown
## This project
[Project-specific content from target - not in blueprint]

## Project conventions
[Local conventions from target - not in blueprint]
```

### 8. Merge settings.json (Agent)

Follow the **Merge Pattern** (analyze → result → actions; ask on any conflict).

**Read both files, then produce the merged settings.json:**

1. **Read source:** `<source>/.claude/settings.json`
2. **Read target:** `<target>/.claude/settings.json`
3. **Merge ADDITIVELY per top-level key:**

**Top-level key rules:**
- **Preserve every key** the target has (never delete any key)

**For `hooks` key:**
- Add any event the target lacks
- For events present in both, append any hook entry whose `command` string is not already in the target's array
- Never remove target entries

**For `env` key:**
- Add keys the target lacks
- Never overwrite existing keys

**For all other keys:** Preserve target's value (do not overwrite)

4. **Write the merged JSON** back to `<target>/.claude/settings.json` (2-space indent)
5. **Validate JSON** before writing — if the result doesn't parse as valid JSON, abort without writing and report the error

**Conflicts to surface:** a hook entry with the same event but a different `command`/config; an `env` key present in both with different values.

**Example additive behavior:**
```json
{
  "hooks": {
    "PreToolUse": [target entries] + [source entries not in target by command],
    "PostToolUse": [source entries if target lacks this event]
  },
  "env": {
    "existing_key": "target value",  // never overwrites
    "new_key": "source value"  // adds if target lacks
  }
}
```

### 9. Merge .gitignore (Agent)

Follow the **Merge Pattern** (analyze → result → actions; ask on any conflict).

Additive **line union** — never remove a target line.

1. **Read source:** `<source>/.gitignore`
2. **Read target:** `<target>/.gitignore` (if absent, the union is just the source — write it and stop)
3. **Build the union:** start from ALL of the target's lines (preserved verbatim, in order). For each line in the source, append it to the result **only if** it is not already present, where "present" means an **exact-string match after stripping trailing whitespace** on both sides (so a trailing-space variant still counts as a duplicate). Blank lines and comments are subject to the same dedup.
4. **Write** the union back to `<target>/.gitignore` (preserve the target's existing line endings; if unsure, use LF).
5. **Never remove** a target line — even one the source no longer ships.

**Example:** target has `node_modules/` and `.env`; source has `node_modules/`, `.env`, `dist/`, `.DS_Store` → result is target's two lines followed by `dist/` and `.DS_Store`.

**Conflicts to surface:** near-duplicate patterns (e.g. `node_modules/` vs `node_modules`); a target line that semantically clashes with a source line.

### 10. Merge .mcp.json (Agent)

Follow the **Merge Pattern** (analyze → result → actions; ask on any conflict).

Additive **server union** — preserve every target server; add only what the target lacks.

1. **Read source:** `<source>/.mcp.json`. **Read target:** `<target>/.mcp.json`.
2. **Locate the servers map** in each: prefer the `{"mcpServers": { ... }}` wrapper; if there is no `mcpServers` key, fall back to treating the top-level dict as the servers map. If the target file is absent or unparseable, abort this step and report (do not guess).
3. **For each server key in the source** that the target **lacks** → add it (the whole server object) to the target's servers map.
4. **Preserve every target server** — never overwrite or remove an existing key, even if the source has a different object under the same key.
5. **Resolve near-duplicates by taking the SOURCE (blueprint) version.** If a source server and a target server look like the **same tool under different keys** — e.g. both serve "memory", or share the same `command`/`args`/package — the blueprint's is canonical (it carries the richer/standard config, e.g. `autoApprove`/`timeout`). So: **remove the target's duplicate-key server and add the source's** (the whole source object under the source key). Do not keep both. Print a note of the replacement (`removed <target-key>; added <source-key>`). (Concrete case: target key `memory` vs source key `github.com/modelcontextprotocol/servers/tree/main/src/memory` → drop `memory`, add the long-keyed source entry.) Also update `<target>/.claude/settings.local.json`'s `enabledMcpjsonServers` if it listed the removed key: replace it with the source key so the server stays enabled.
6. **Validate JSON before writing** — parse the merged result; if it is not valid JSON, **abort without writing** and report the error.
7. **Write** the merged JSON back to `<target>/.mcp.json` with **2-space indent** and a trailing newline.

**Example:** target has `{"mcpServers": {"memory": {...}, "filesystem": {...}}}`; source adds `git` and `time` (target lacks both) plus a long-keyed `memory`-equivalent → result keeps target's `filesystem`, adds `git` and `time`, and **replaces** target's `memory` with the source's long-keyed `github.com/.../memory` (printing the replacement note).

**Conflicts to surface:** same key with a different config object (the near-duplicate case is now auto-resolved to the source — step 5).

### 11. Merge .claude/settings.local.json (Agent)

Follow the **Merge Pattern** (analyze → result → actions; ask on any conflict).

Same additive rules as settings.json (step 8), but for the **per-developer** local settings file. This file is gitignored / personal, so it is **NOT tracked by the manifest** (it stays in the generator's never-synced exclude set) — the merge reads both files directly and never produces manifest churn.

1. **Read source:** `<source>/.claude/settings.local.json` — only if it exists. **If the source has no `settings.local.json`, skip this step silently** (nothing to merge from).
2. **Read target:** `<target>/.claude/settings.local.json` — if the target has none, the merge is just the source written through (after validation).
3. **Merge additively per top-level key** — preserve every key the target has (never delete):

   **For `permissions` key:**
   - Add any `allow`/`deny`/`ask` entry the target lacks (exact-string match).
   - Never remove target entries.

   **For `hooks` key:**
   - Add any event the target lacks.
   - For events present in both, append any hook entry whose `command` string is not already in the target's array.
   - Never remove target entries.

   **For `env` key:**
   - Add keys the target lacks; never overwrite existing keys.

   **For all other keys:** Preserve the target's value (do not overwrite).

4. **Write the merged JSON** back to `<target>/.claude/settings.local.json` (2-space indent, trailing newline).
5. **Validate JSON before writing** — if the result doesn't parse as valid JSON, **abort without writing** and report the error.

**Conflicts to surface:** same as settings.json — a hook entry with the same event but a different `command`/config; an `env` key present in both with different values.

### 12. Cleanup Parked Files

After the adopts and merges, drop any `.blueprint-new` parked copy that is now redundant (byte-identical to its adopted real file), and surface any genuine diffs left for review:

```bash
python3 "$SCRIPTS/cleanup-parked.py" --target "$TARGET"
```

For each `<file>.blueprint-new` under `<target>`: if the real file (the path without the suffix) exists and is **byte-identical** to the parked copy, the parked copy is deleted (it was adopted). Otherwise the parked copy is kept (genuine diff — needs manual review). The script prints `<n> removed (adopted), <m> kept (genuine diffs)` and lists the kept ones. Exits 0.

### 13. Post-Sync Bookkeeping

**Vendor mode** (pulling from Claudify vendor download into blueprint):
```bash
# Regenerate the blueprint's manifest
python3 "$SCRIPTS/claudify-generate-manifest.py" --root <this-repo>

# Commit the refreshed manifest
git add .claude/UPDATE-MANIFEST.json
git commit -m "chore: regenerate blueprint manifest after vendor sync"
```

**Push/Pull mode** (blueprint ↔ child):
Refresh the target's `.claude/blueprint-origin.json` marker:
```json
{
  "blueprint_dir": "/path/to/blueprint",
  "blueprint_manifest_sha": "<sha of blueprint's current UPDATE-MANIFEST.json>",
  "synced_at": "<iso timestamp>",
  "files": { "...": "<the BLUEPRINT's manifest files map, copied verbatim from <source>/.claude/UPDATE-MANIFEST.json>" }
}
```

**The `files` map MUST be the blueprint's manifest `files` at sync time** — copy `<source>/.claude/UPDATE-MANIFEST.json`'s `files` map verbatim into the marker. Do **NOT** snapshot the child's own state. This is the offered-reference baseline (`S`): it lets the next sync detect any file the child *diverged* from the blueprint line (a kept customization or a stale version) as `C != S` → CONFLICT → preserved. Snapshotting the child's merged state instead would bake customizations into the baseline, making them read as unedited (`C == S`) and get silently overwritten on the next sync. (Side benefit: no need to run the generator on the child — just copy the blueprint manifest's `files` map.)

## Init Action

Establishes tracking for a child project and installs the skill folder locally.

**Behavior:**
- Writes `.claude/blueprint-origin.json` marker in the child
- Copies this skill folder to the child's `.claude/skills/claudify-sync/`
- Does **not** touch any of the child's existing config files

**Baseline (`S`) selection:**

**Git child:**
- Prefer the child's git root commit as baseline
- Pass `--baseline <commit>` to triage/apply scripts
- Marker records that commit SHA
- Result: Precise immediately — pre-existing edits show as `C != S`

**Non-git child:**
- No way to reconstruct edits made before tracking began
- `init` records `S` = the blueprint's current manifest
- First update is **conservative**: every `C != N` is `C != S` → CONFLICT
- Nothing auto-overwritten; user reviews parked `.blueprint-new` files
- Precision arrives from next sync onward (marker refreshed to post-sync state)
- This is the deliberate "lean CONFLICT when unsure" default

## Conflict Detection Rules

Per-file classification (uniform for git / non-git children):

- `S` = the blueprint's hash for the file **at the child's last sync** (the offered reference — stored in the marker's `files` map; see step 13), or — on a git child's first tracked run with no marker — the file's hash at the child's git root commit. **Not** the child's current state.
- `N` = blueprint's current hash
- `C` = child's current hash

**Rules:**
- `C == N` → **UNCHANGED** (skip)
- Child absent, `S` exists → **CONFLICT("child-deleted")** (default: leave deleted, park `.blueprint-new`)
- Child absent, no `S` → **NEW** (blueprint added it since last sync) → copy
- `C != N` and `C == S` → **IMPROVED** (child accepted the blueprint's offered version at last sync; blueprint has since advanced) → update
- `C != N` and `C != S` → **CONFLICT** (child diverged from the blueprint line — a kept customization or a stale version) → keep child's, park `.blueprint-new`. (Exception: hooks always force-sync to N regardless — see step 5.)
- No baseline + `C != N` → **CONFLICT** (conservative) → keep child's, park `.blueprint-new`

**Protected files** (forced to keep-mine regardless of hashes):
- `.claude/memory.md`
- `.claude/knowledge-base.md`
- `.claude/knowledge-nominations.md`
- `.claude/settings.json`
- `.claude/settings.local.json`
- `CLAUDE.md`
- `CLAUDE.local.md`
- `Scratchpad.md`
- `Task Board.md`
- `.mcp.json`
- `.claude/agent-memory/`
- `.claude/logs/`
- `.claude/backups/`
- `Daily Notes/`

## Edge Cases

**Blueprint manifest missing/stale:**
- Abort update, instruct to run `claudify-generate-manifest.py` in the blueprint

**Blueprint path moved/unreachable:**
- Prompt for the new path
- Offer to update the marker's `blueprint_dir` field

**Child deleted a blueprint file:**
- Deletion is an edit → CONFLICT
- Ask before restoring (default: leave deleted)

**Marker absent + not git:**
- First run is conservative (all diffs conflict)
- Marker written for precision next time

## Files

**Blueprint:**
```
.claude/skills/claudify-sync/
  SKILL.md                          # This file
  scripts/
    claudify-generate-manifest.py   # Manifest generator
    claudify-update-triage.py       # File classifier
    claudify-update-apply.py        # Safe applier
    cleanup-parked.py               # Drop adopted .blueprint-new files
    test_claudify_sync.py            # Test suite
.claude/UPDATE-MANIFEST.json         # Generated manifest (committed)
```

**Child:**
```
.claude/blueprint-origin.json        # Marker file (committed, data)
.claude/skills/claudify-sync/        # Skill folder (syncs like any manifest file)
```

## Testing

Run the test suite:
```bash
python3 .claude/skills/claudify-sync/scripts/test_claudify_sync.py
```

Expected output: All tests pass (6 passed, 0 failed).
