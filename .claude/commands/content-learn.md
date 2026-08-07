# /content-learn [action] [piece-id]

The social post-publish learning loop. Writes the prediction at publish time, collects real platform outcomes when due, grades predictions, and routes confirmed learnings into the system. Second instantiation of the Post-Publish Analyst Contract (`.claude/POST-PUBLISH-ANALYST-CONTRACT.md`); the newsletter `/newsletter analyse` loop is the first.

Why this exists (Jun-Jul 2026 record): the closed feedback loop is the #1 capability gap in content tooling, with fewer than 30% of teams routing performance data back into production [vendor-reported, Jul 2026]. This command closes it for social output.

## Actions

| Command | What it does | When |
|---|---|---|
| `/content-learn record {piece-id}` | Writes the prediction_record for a piece at publish time | The moment a piece is published (auto-offered by `/post`, `/content`, `/repurpose` ship steps) |
| `/content-learn collect [piece-id]` | Pulls or requests platform metrics for due pieces (72h and day-7) | 72h and 7 days after publish |
| `/content-learn grade [piece-id]` | Spawns content-analyst to grade due predictions and route learnings | Day-7, after collect |
| `/content-learn status` | Lists open predictions and what is due | Any time; `/sync` surfaces due items |

## Procedure

### `record {piece-id}` (guard G1: no learning without this)

1. Confirm the piece: brand, platform, format, publish timestamp, and the URL if available.
2. Compute the baseline: the brand's rolling mean of the platform's primary metric over the last 5+ comparable posts (from content-analyst MEMORY or the brand memory's content history). On a cold start (fewer than 5), record `baseline: null` and note that grading starts once a baseline exists.
3. Write `.claude/agent-memory/content-analyst/predictions/{piece-id}.md`:

```yaml
piece_id: {brand}-{platform}-{YYYYMMDD}-{slug}
brand: {brand}
platform: {platform}
format: {single / thread / carousel / reel / post / blog}
published_at: {ISO timestamp}
primary_metric: {per-platform metric from content-analyst.md}
predicted_outcome: {a number or explicit range, not a vibe}
by_date: {publish date + 7 days}
baseline: {rolling mean or null}
hypothesis: {the one-line reason this piece should hit the prediction}
status: open
```

4. If the piece is a derivative, add the prediction_record id to its row in `.claude/agent-memory/content-creator/derivative-registry.md` and set the row status to `published`.

Self-execute. This step is deliberately cheap (2-3 minutes); skipping it forfeits the learning loop for that piece, because the analyst refuses retroactive predictions (G1).

### `collect [piece-id]`

1. Read `.claude/agent-memory/content-analyst/predictions/` for records where now >= published_at + 72h (preliminary) or + 7 days (final), status `open`.
2. For each due piece: pull metrics via available MCP; else print the exact platform analytics view to paste (same fallback pattern the newsletter analyst uses with Beehiiv).
3. Append collected numbers to the prediction file under `observations:` with a timestamp.

### `grade [piece-id]`

Invoke the `content-analyst` agent via the Task tool with `subagent_type: content-analyst` and `run_in_background: false` (the grade must land before learnings route). Pass the piece id(s) with day-7 observations. The analyst grades, reports, and routes confirmed learnings to `.claude/knowledge-nominations.md`. You approve promotions; nothing changes rules automatically.

### `status`

List open predictions with due dates. Flag any published piece found in the derivative registry or brand content history that has NO prediction_record: those are forfeited learnings; name them so the ship-step habit sticks.

## Hand-off

Confirmed, promoted learnings land in `knowledge-base.md` (via auditor + user approval) and in the brand memory's approved patterns. The strategist and creator read both at the start of every piece, which is what makes the loop compound.
