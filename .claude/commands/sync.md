---
description: Mid-day sync - review daily note, update memory, process notes
argument-hint: ""
allowed-tools:
  - Read
  - Edit
  - Write
  - Bash(date:*)
---

Mid-day context refresh. Process captured notes, update memory, health check.

## Steps

### Step 1: Read current state (parallel)

Read simultaneously:
- `.claude/memory.md`
- `Daily Notes/MMDDYY.md` (today's date)
- `Scratchpad.md`

### Step 2: Process scratchpad

For each item in Scratchpad:
- Is it a task? → Move to Task Board
- Is it a decision? → Add to Daily Note → Decisions
- Is it a learning? → Nominate to `.claude/knowledge-nominations.md`
- Is it a note? → Add to Daily Note → Notes
- Is it stale? → Delete

Clear processed items from Scratchpad.

### Step 3: Scan task board

Read `Task Board.md`:
- Move completed tasks from Today → Done
- Flag any tasks that are blocked
- Check if priorities have shifted

### Step 4: Context health check

Self-assess:
- Am I still oriented on the right problem?
- Have I been going in circles on anything?
- Is my context getting heavy? (If yes, consider `/safe-clear` after sync)

### Step 5: Orientation check (Boyd's Law)

Ask yourself:
- What has changed since this morning?
- What assumptions am I making that might be wrong?
- What's the simplest next action?

### Step 6: Update memory

Edit `.claude/memory.md`:
- Update "Now" with current focus
- Add/resolve items in "Open Threads"
- Record any new decisions in "Recent Decisions"
- Update "Blockers" if anything changed

### Step 7: Review incident log

Read `.claude/logs/incident-log.md` (if it exists). Look for:
- Repeated failures (same error 3+ times)
- Blocked commands that should be allowed (or vice versa)
- Any CRITICAL severity events

Report anything noteworthy to the user.

### Step 8: Drain knowledge nominations (auto-fire, hard trigger)

Count the pending entries in `.claude/knowledge-nominations.md` (the rows under the `## Pending Nominations` header) and find the oldest entry's date. This is a HARD AUTO-FIRE, not a yes/no prompt:

- If 5 or more nominations are pending, OR the oldest pending entry is more than 7 days old, immediately delegate to the `auditor` agent in nominations-only scope, with no confirmation gate. The auditor must finish the whole job: promote durable rules into `knowledge-base.md` (curating it under its 200-line cap), discard pattern-detector noise, close resolved items, supersede contradicted entries with a date and reason rather than silently overwriting, and rewrite `knowledge-nominations.md` with a fresh `Last drained: {date}` header so the count resets to zero.
- If under the threshold, skip the drain and note the current pending count.

A loop whose only actuator is human discipline is not closed. This trigger lives in the ritual so the backlog drains on its own; the SessionStart floor in `session-reset.sh` is the backup trigger. Report the outcome in the status report below.

### Step 9: Status report

Brief summary:
- What was accomplished this morning
- Current focus
- Any blockers or changes in priority
- Knowledge nominations: drained (N promoted, M discarded) or the pending count if under threshold
- Suggested next action
