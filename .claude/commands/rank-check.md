# /rank-check

**Usage:** `/rank-check` | `/rank-check {domain}` | `/rank-check {keyword}`

Review ranking movements across tracked keywords. Flag drops, correlate with site changes, and surface opportunities.

---

## Trigger Conditions

- User runs `/rank-check` explicitly
- User asks about "rankings", "ranking changes", "keyword positions", "how are we ranking"
- Weekly routine (suggested: every Monday to review the prior week)
- After a major site update, technical change, or algorithm update announcement

---

## Procedure

### Step 1: Read Current State

1. Read `.claude/agent-memory/seo/MEMORY.md` — `## Ranking Alerts` and `## Audit History`
2. Read the relevant keyword map at `.claude/agent-memory/seo/keyword-maps/{domain-slug}.md`
3. Note any RANKING-ALERT items that are unresolved from prior sessions

### Step 2: Pull Current Data

Use available tools to check current positions:

**With GSC access (preferred):**
- Query GSC Performance report for the last 7 and 28 days
- Extract position data for tracked keywords
- Compare against prior period

**Without GSC (fallback):**
- WebSearch for each priority keyword and note the target domain's position
- Label all positions as "manual SERP check — approximate" in the output
- Prioritise checking the top 10 tracked keywords only

### Step 3: Compare Against Last Check

Compare current positions against the last recorded data in the keyword map:
- Position improved by 5+ places → flag as POSITIVE-MOVE
- Position dropped by 5+ places → flag as RANKING-ALERT (requires investigation)
- Position dropped by 10+ places → flag as RANKING-INCIDENT (immediate investigation)
- Dropped out of top 100 → flag as DEINDEX-RISK

### Step 4: Investigate Alerts

For any RANKING-ALERT or RANKING-INCIDENT:
1. Check recent content changes (daily notes, Task Board history)
2. Check for technical regressions: run T1 audit on the affected page
3. Check for algorithm updates: WebSearch `Google algorithm update {month year}`
4. Check competitor activity: did a competitor publish or improve content on the keyword?
5. Document investigation findings in memory

### Step 5: Surface Opportunities

Beyond alerts, look for:
- Keywords ranking 4-10 that could be pushed to position 1-3 with a content update
- Keywords with improving CTR despite stable position (opportunity for snippet optimisation)
- New keywords the domain has started ranking for that aren't yet in the keyword map

### Step 6: Present Report

Output the ranking report and update memory with current positions and any new alerts.

---

## Output Format

```
RANK CHECK | {domain} | {date}
Period: {date range checked}
Data source: {GSC|manual SERP check}

Alerts (requires action):
| Keyword | Previous | Current | Change | Page | Suspected Cause |
|---------|---------|---------|--------|------|----------------|

Positive moves:
| Keyword | Previous | Current | Change | Page |
|---------|---------|---------|--------|------|

Stable / monitored:
| Keyword | Position | Page | Last Changed |

Opportunities (position 4-10, push to top 3):
| Keyword | Position | Page | Recommended action |

New keywords detected:
| Keyword | Position | Page | Volume est. |
```

---

## Investigation Protocol (for RANKING-ALERT)

When a keyword drops 5+ positions:
1. **Content check**: Was the target page recently modified? Did it lose key sections?
2. **Technical check**: T1 audit the specific page — CWV, indexability, canonical
3. **Algorithm check**: correlate the drop date against the confirmed update calendar below, then
   WebSearch for anything newer than this file's calendar
4. **Competitor check**: Check if a competitor improved their page for the same keyword
5. **Manual review**: Is the SERP layout different now? (More features, different intent match?)

### Confirmed 2026 Google update calendar (as of 24 Jul 2026; sources: Google Search Status
Dashboard via Search Engine Land / Search Engine Roundtable)

| Update | Rollout | Notes |
|--------|---------|-------|
| March 2026 core | 27 Mar - 8 Apr 2026 | Announced core update |
| March 2026 spam | Mar 2026 | First spam update of the year |
| May 2026 core | 21 May - 2 Jun 2026 | Announced core update |
| June 2026 spam | 24 - 26 Jun 2026 | SpamBrain improvement, global, all languages. NOT a link-spam update and NOT site-reputation-abuse related |
| June / July 2026 core | none | No core update in June or July as of 24 Jul 2026; next core expected Q3 |

Rules for using the calendar:
- A drop that starts inside a rollout window is a correlation, not a diagnosis. Complete all five
  checks before attributing the drop to the update.
- Unconfirmed tracker volatility (weekend chatter, aggregator claims of unannounced updates) is not
  evidence. Only attribute to updates Google has announced.
- This calendar is dated 24 Jul 2026. For anything after that date, WebSearch the Google Search
  Status Dashboard and extend the table.

Document findings in memory. If cause is unknown after investigation, mark as UNDER-INVESTIGATION.

---

## Notes

- Without GSC, position data is approximate — always note the data source
- Rankings fluctuate day-to-day — a 1-2 position change is noise; 5+ is a signal
- A ranking drop is not always the domain's fault — algorithm changes and competitor improvements both move rankings
