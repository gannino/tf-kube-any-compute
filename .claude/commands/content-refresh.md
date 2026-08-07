# /content-refresh

**Usage:** `/content-refresh` | `/content-refresh {domain}` | `/content-refresh {url}`

Find and prioritise stale content across a site for update. Returns a prioritised refresh plan.

---

## Trigger Conditions

- User runs `/content-refresh` explicitly
- User asks about "stale content", "content updates", "refreshing old posts", or "content decay"
- Part of quarterly SEO maintenance cycle
- When organic traffic is declining across multiple pages

---

## Procedure

### Step 1: Identify Stale Content Candidates

For each tracked domain, identify content to review:

**Staleness signals (check in order of reliability):**
1. **Age**: Pages last modified > 12 months ago (check file metadata or CMS dates)
2. **Traffic decline**: Pages with declining sessions in GSC (if available)
3. **Ranking decay**: Pages that have slipped 5+ positions over 90 days
4. **Content gap**: Pages where competitors now cover more subtopics
5. **Outdated data**: Pages citing statistics, tools, or events from 2+ years ago

**Invoke the content-optimizer to identify candidates:**
```
Identify stale content candidates on {domain}.
Check:
1. WebSearch for site:{domain} — look at indexed pages and their apparent freshness
2. Read keyword map to find pages that were ranking but have slipped
3. Read audit history in memory for any flagged thin or outdated pages
4. Produce a prioritised refresh list with staleness reason for each page
```

### Step 2: Prioritise Refresh Queue

Score each candidate by refresh ROI:

| Factor | High priority | Medium priority | Low priority |
|--------|-------------|----------------|-------------|
| Traffic potential | High-volume keyword | Medium-volume keyword | Long-tail only |
| Current position | 4-15 (pushable) | 16-30 (recoverable) | 31+ (rebuild needed) |
| Backlinks to page | 5+ referring domains | 1-5 domains | None |
| Staleness degree | Severely outdated facts | Mildly stale | Just old |
| Effort to refresh | Low (data update only) | Medium (new sections) | High (full rewrite) |

### Step 3: Produce Refresh Plan

For the top 5-10 candidates, produce a specific refresh brief for each:
- What to update (specific outdated facts, new sections needed, images to replace)
- What to add (new H2 topics from SERP analysis, updated statistics)
- What to remove (deprecated advice, outdated tools, dead links)
- Estimated effort (Low / Medium / High)
- Expected ranking impact (Low / Medium / High)

### Step 4: Execute Refreshes (if requested)

If user asks to refresh immediately, invoke the `content-optimizer` for each page:
```
Refresh {url} targeting keyword {keyword}.
Staleness reason: {reason from assessment}
Current SERP top 3: {run WebSearch to find}
Specific updates needed: {from refresh brief}
Produce the full refreshed content with all changes implemented.
```

### Step 5: Schedule Remaining Refreshes

Add remaining items to the Task Board under **This Week** or **Backlog** by priority.
Log the full refresh plan in the seo-agent memory.

---

## Output Format

```
CONTENT REFRESH PLAN | {domain} | {date}
Pages assessed: {N}
Refresh candidates: {N}

Priority queue:
| # | URL | Keyword | Traffic Signal | Staleness Reason | Effort | Expected Impact |
|---|-----|---------|---------------|-----------------|--------|----------------|

Immediate action (this week):
- {URL}: {specific actions needed} | Est. time: {X} min

Scheduled (next 30 days):
- {URL}: {specific actions needed} | Est. time: {X} min

Deprioritise or prune (low ROI):
- {URL}: {reason} | Recommendation: {refresh|noindex|consolidate}
```

---

## Notes

- Content freshness is confirmed by genuine content changes — never change only the date
- Schema `dateModified` must reflect actual content changes, not cosmetic edits
- Consolidating two thin stale pages into one strong page often outperforms refreshing both individually
- Pages with zero backlinks and no organic traffic may be better candidates for noindex than refresh
