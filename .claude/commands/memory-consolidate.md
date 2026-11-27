---
description: Reflective consolidation pass over memory files. Merges duplicates, expires stale guesses, resolves contradictions, prunes to caps. Conservative and reversible.
argument-hint: "[--dry-run]"
allowed-tools:
  - Read
  - Edit
  - Write
  - Glob
  - Bash(date:*)
  - Bash(mkdir:*)
  - Bash(cp:*)
  - Bash(wc:*)
  - Bash(grep:*)
---

**Spawn synchronously:** every Agent/Task spawn in this procedure must pass `run_in_background: false`. Subagents default to background since Claude Code 2.1.198; this command consumes each subagent verdict before its next step, so a background spawn would race the verdict.

Append-only agent memory rots. After roughly 20 sessions the memory files fill with duplicates, stale entries, and direct contradictions. The worst failure is the confabulation loop: session N writes a guess to memory, session N+1 reads it as a confirmed fact and builds on it. This command is the periodic reflective pass that keeps memory trustworthy.

It MERGES duplicates, EXPIRES stale `[guessed]` entries, RESOLVES contradictions in favour of verified entries, and PRUNES files back under their caps. It is deliberately conservative: it backs up before it touches anything, it never deletes user-authored or customer-owned content, and it flags load-bearing items for the auditor or the user rather than deleting them itself.

**When to run:** every 15 to 20 sessions, or whenever a memory file feels noisy, contradictory, or over its line cap. It pairs with the `[verified]` / `[guessed]` provenance convention (see `.claude/skills/productivity/memory-provenance/SKILL.md`). The convention tags entries as they are written; this command acts on those tags.

**Scope (files it consolidates):**
- `.claude/memory.md` (cap: 100 lines)
- `.claude/agent-memory/*/MEMORY.md` (keep lean)
- `.claude/knowledge-nominations.md` (de-duplicate the pending queue only)

**Out of scope (read for cross-checking, never edited here):**
- `.claude/knowledge-base.md`, auditor-owned. This command may FLAG an entry for the auditor, but only the auditor writes here. Its `[Source:]` provenance and 200-line cap are enforced by `completeness-gate.sh` and are not this command's job.
- Daily Notes, Task Board, Scratchpad, any source or customer file.

**Dry run:** `/memory-consolidate --dry-run` performs Steps 0 through 4 and reports the proposed plan WITHOUT writing any change. Use it first on a large or important memory set.

---

## Steps

### Step 0: Get date, create the backup, count baselines

```bash
date +"%m%d%y %H:%M" && \
BACKUP=".claude/backups/memory-consolidate-$(date +%m%d%y-%H%M)" && \
mkdir -p "$BACKUP" && \
cp .claude/memory.md "$BACKUP/" 2>/dev/null; \
cp .claude/knowledge-nominations.md "$BACKUP/" 2>/dev/null; \
find .claude/agent-memory -name MEMORY.md -exec cp --parents {} "$BACKUP/" \; 2>/dev/null || \
find .claude/agent-memory -name MEMORY.md 2>/dev/null | while read f; do mkdir -p "$BACKUP/$(dirname "$f")"; cp "$f" "$BACKUP/$f"; done; \
echo "Backup written to $BACKUP" && \
wc -l .claude/memory.md .claude/agent-memory/*/MEMORY.md 2>/dev/null
```

Record the backup path. It goes in the final report so the change is one `cp` away from reversible. **If the backup step fails, STOP and report. Never consolidate without a backup on disk.** (In `--dry-run`, still create the backup; it is cheap and harmless.)

### Step 1: Read the memory set

Read in parallel:
- `.claude/memory.md`
- every `.claude/agent-memory/*/MEMORY.md` (use Glob to enumerate first)
- `.claude/knowledge-nominations.md`

Also read `.claude/knowledge-base.md` for cross-reference ONLY (to detect contradictions against it; you will not edit it).

### Step 2: Classify every entry

For each entry across the read files, tag it mentally as one of:

1. **Duplicate / near-duplicate**, same fact stated more than once, or two entries that say the same thing with different wording. Candidate to MERGE.
2. **Stale guess**, an entry tagged `[guessed]` whose age exceeds the threshold (see Step 3) and that has not been reconfirmed. Candidate to EXPIRE.
3. **Contradiction**, two entries that cannot both be true. Candidate to RESOLVE.
4. **Live and clean**, current, non-duplicated, not contradicted. LEAVE IT.
5. **Protected**, user-authored directive, anything under a `CUSTOMER-OWNED` / `USER-OWNED` / `DO-NOT-TOUCH` marker, or any entry whose removal would change behaviour (load-bearing). NEVER auto-delete. At most FLAG.

When classification is uncertain, default to category 4 or 5. A retained duplicate is a smaller cost than a deleted fact.

### Step 3: Apply the four operations (conservative)

**MERGE (duplicates).** Combine into a single entry. Keep the strongest provenance: if one copy is `[verified]` and the other `[guessed]`, the merged entry is `[verified]`. Keep the most specific wording and the earliest date the fact was first established. Delete the redundant copy only after the merged line is written.

**EXPIRE (stale guesses).** Threshold: a `[guessed]` entry not reconfirmed in **30 days** (or, if your project counts sessions, ~15 sessions). For each stale guess:
- If it is clearly trivial and non-load-bearing → remove it, and list it in the report.
- If it is load-bearing or you are unsure → do NOT delete. Demote it in place by appending ` [stale, unconfirmed since MMDDYY, flag for auditor]` and leave the entry. Add a one-line nomination to `.claude/knowledge-nominations.md` so the auditor decides its fate.
- A `[verified]` entry is NEVER expired by age. Verified facts do not rot on a timer; they are only removed when superseded by a newer verified entry (handled under RESOLVE).

**RESOLVE (contradictions).** When two entries conflict:
- One `[verified]`, one `[guessed]` → keep the `[verified]` one. Remove the guess (or demote it if load-bearing, as above).
- Both `[verified]` but with different dates → keep the newer; mark the older `[superseded MMDDYY: <one-line reason>]` rather than silently deleting, preserving the audit trail. This mirrors the auditor's knowledge-base supersession rule.
- Both `[guessed]`, or a genuine tie → resolve NOTHING yourself. FLAG both for the user/auditor: add a nomination line describing the conflict, and leave both entries in place. Guessing which guess wins would just relaunch the confabulation loop.

**PRUNE (caps).** After merging and expiring:
- `.claude/memory.md` must end under **100 lines** (the cap `completeness-gate.sh` enforces on Write). If still over, prune in this order: resolved Open Threads, then completed Now items, then the oldest Recent Decisions. Never prune Blockers or anything Protected to hit the number.
- Agent `MEMORY.md` files: keep lean. If one exceeds ~150 lines, merge similar entries and move resolved/archival items to a sibling `resolved-archive.md` in the same agent folder. Do not invent new structure beyond what the file already uses.

### Step 4: Write the changes (SKIP ENTIRELY IN --dry-run)

Apply the edits with `Edit` (targeted) wherever possible; use `Write` only when a file is substantially restructured. Respect the existing section headers and formatting of each file, preserving its shape and just removing the rot.

For every nomination raised in Step 3, append one line to `.claude/knowledge-nominations.md` under `## Pending Nominations`:

```markdown
- [MMDDYY] /memory-consolidate: [the conflict or stale item] | Evidence: [the two entries / the staleness] | Proposed: [keep verified X / auditor to decide]
```

If running `--dry-run`: write NOTHING. Output the plan only (what WOULD be merged / expired / flagged) and stop after Step 5.

### Step 5: Report (the honesty section)

Output a concise, scannable summary:

```
Memory consolidation, MMDDYY HH:MM   [mode: live | dry-run]
Backup: .claude/backups/memory-consolidate-MMDDYY-HHMM

Merged:    N duplicate entries  (files: ...)
Expired:   N stale [guessed] entries removed; M demoted-and-flagged
Resolved:  N contradictions  (kept the [verified] side)
Flagged:   N items raised to knowledge-nominations.md for the auditor/user
Pruned:    memory.md  120 -> 96 lines; agent X  168 -> 140 lines

NOT TOUCHED (deliberately):
- [protected/user-authored/customer-owned items left exactly as found]
- [load-bearing guesses demoted in place, never deleted]
- knowledge-base.md (auditor-owned; only flagged, never edited)

To revert: cp -r <backup path>/* back over the originals.
```

The **NOT TOUCHED** block is mandatory, even when empty. The value of a consolidation pass is as much in what it conservatively left alone as in what it cleaned. If nothing was protected or flagged, say so explicitly.

---

## Safety guarantees

- **Backup first, always.** Every run writes the touched files to `.claude/backups/` before the first edit. No backup, no consolidation.
- **Never destroy user data.** User-authored directives and anything under a CUSTOMER-OWNED / USER-OWNED / DO-NOT-TOUCH marker are read-only to this command.
- **Flag, do not delete, load-bearing items.** Anything whose removal could change behaviour is demoted in place and raised to the auditor, never silently dropped.
- **Verified beats guessed.** Contradictions resolve toward the entry confirmed by a real check; ties between two guesses are escalated, never auto-decided.
- **Auditor boundary respected.** This command never writes to `knowledge-base.md`; it routes durable findings through `knowledge-nominations.md`, the same pipeline the auditor already drains.

## Why this design

Memory grows append-only because every session is locally right to write down what it learned. The rot is emergent, not any one session's fault, so the fix is a periodic pass, not a per-write rule. This command does the consolidation half; the `[verified]` / `[guessed]` convention does the labelling half. Together they break the confabulation loop: guesses are visibly marked, stale guesses get expired before a later session can launder them into facts, and the only things ever deleted outright are confirmed duplicates and trivial expired guesses, each recoverable from the backup.

## DO NOT

- DO NOT delete any entry tagged `[verified]` on the basis of age.
- DO NOT delete user-authored, customer-owned, or load-bearing content. Demote and flag it instead.
- DO NOT resolve a contradiction between two `[guessed]` entries by picking one. Flag both.
- DO NOT edit `knowledge-base.md`. Flag for the auditor through nominations.
- DO NOT run the destructive write path in `--dry-run`.
- DO NOT skip the backup, and DO NOT skip the NOT TOUCHED report block.

**Target:** 6 to 10 tool calls, under 30 seconds on a normal memory set. Dry run: 4 to 6 calls. This is a light reflective pass, not a rewrite. If it is taking many edits, the memory set is genuinely large; report that and consolidate the worst file first rather than forcing everything in one run.
