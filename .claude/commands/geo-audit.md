---
description: Audit a URL for AI-citation readiness (GEO), with optional full visibility, fan-out, and crawl analysis.
argument-hint: {url} [--depth full]
allowed-tools: Read, Write, Edit, Bash(date:*), Glob, Grep, WebSearch, WebFetch
---

# /geo-audit

**Usage:** `/geo-audit {url}` | `/geo-audit {url} --depth full`

Run a tiered GEO (Generative Engine Optimization) audit on a URL. Scores AI-citation readiness and,
at full depth, adds share-of-voice tracking, a fan-out gap map, and AI-bot crawl analysis. Returns a
PUBLISH / REVISE / BLOCK verdict. This is the flagship customer-facing GEO command.

---

## Trigger Conditions

- User runs `/geo-audit` explicitly
- User asks to "check AI readiness", "audit for AI search", "will ChatGPT cite this", "GEO check",
  or "are we visible in AI answers" on a URL
- After publishing or significantly editing any page (auto T1 readiness check)
- Alongside an SEO audit when AI-surface visibility matters for the page

---

## Procedure

### Step 1: Determine Audit Tier

| Flag | Tier | Scope |
|------|------|-------|
| (none) | T1 | Quick readiness check, 5-10 min |
| `--depth full` | T2 | Readiness + visibility + fan-out + crawl, 20-40 min |

T1 is always run first. T2 builds on T1: the readiness audit is the foundation for everything else.

### Step 2: Invoke geo-agent

Spawn the `geo-agent` with the URL and tier. Pass the full command including any flag. Spawn it
synchronously (`run_in_background: false`): Step 3 reviews the agent's output, so the result must
exist before this command continues.

**What to tell the geo-agent:**
```
Run a T{N} GEO audit on {url}.
Read your MEMORY.md first to check for any prior readiness score or SoV data on this domain,
and load the domain's geo-map if one exists.
Fetch BOTH the raw HTML (curl, pre-JS) and the rendered DOM (WebFetch), because the SSR check needs both.
Run the nine-check GEO Readiness Audit. Apply the SSR and AI-crawler gates: a FAIL on either
caps the score at 40 and forces BLOCK.
{If T2:} Then run citation/share-of-voice tracking for the domain's prompt library, the fan-out
gap finder for the page's primary topic, and AI-bot crawl monitoring if log data is available
(otherwise note the robots.txt substitute).
Label every visibility figure as an estimate with its sample size and date. Never fabricate an
engine response or a crawl statistic. Log any gap and proceed.
Output using the GEO READINESS format {and, for T2, the AI VISIBILITY / FAN-OUT / CRAWL blocks
plus the priority-action tail}. After completing, update your MEMORY.md and the domain's geo-map.
```

### Step 3: Review Output

The geo-agent returns the formatted audit. Review for:
- All nine readiness checks completed, each with PASS/WARN/FAIL and fetched evidence
- The SSR ratio reported and both gates correctly applied
- Every finding carrying a specific remediation (exact URL, passage, schema field, or robots directive)
- For T2: visibility figures labelled as estimates with sample size and date, gaps logged not invented
- Output format matches the tier specification

### Step 4: Display Results

Present the full audit output to the user.

- If the SSR or AI-crawler gate triggered a BLOCK, lead with it, because it caps every other gain until fixed.
- For T1: offer to go deeper (`--depth full`) for share-of-voice, fan-out gaps, and crawl analysis.
- For T2: offer to fill the highest-leverage fan-out gaps, or to schedule the next monthly
  visibility run.

### Step 5: Update Task Board

If the audit produced a BLOCK verdict or gate failure, add the priority fixes to `Task Board.md`
under **Today** or **This Week** based on severity. SSR and citation-crawler blocks are always Today.

---

## Output Format Reference

**T1 (readiness):**
```
GEO READINESS: {0-100} | {url} | {date}
Fetch: raw HTML {N} words | rendered DOM {N} words | SSR ratio {0.00}
1. Answer-first      {PASS|WARN|FAIL}, {evidence} → Fix: {...}
2. Passage chunking  {PASS|WARN|FAIL}, {in-band}/{total}, {N} stubs → Fix: {...}
3. Stat density      {PASS|WARN|FAIL}, {count} stats → Fix: {...}
4. Quotes + sources  {PASS|WARN|FAIL}, {Q} quotes, {C} citations → Fix: {...}
5. SSR (gate)        {PASS|WARN|FAIL}, content {present|partial|absent} pre-JS → Fix: {...}
6. AI-crawler (gate) {PASS|WARN|FAIL}, {blocked agents or "all citation bots allowed"} → Fix: {...}
7. Freshness         {PASS|WARN|FAIL}, visible {date}, schema {dateModified} → Fix: {...}
8. Entity clarity    {PASS|WARN|FAIL}, Organization schema {Y/N}, sameAs {count} → Fix: {...}
9. Heading hierarchy {PASS|WARN|FAIL}, {N} H1, skipped levels {Y/N} → Fix: {...}
Verdict: {PUBLISH | REVISE | BLOCK}
Top fix (highest citation impact): {the single highest-leverage change}
```

**T2 adds:** the AI VISIBILITY block (per-engine presence + competitor SoV), the FAN-OUT GAP MAP,
the AI-BOT CRAWL block (or its no-data note), and the GEO PRIORITY ACTIONS tail ranked by citation
impact.

## Verdict Thresholds

| Verdict | Score | Meaning |
|---------|-------|---------|
| PUBLISH | >= 75 | AI-citation-ready, ship it |
| REVISE | 50-74 | Specific structural fixes needed before it will be cited reliably |
| BLOCK | < 50 | Cannot be cited as-is, usually an SSR or crawler-access gate failure |

---

## Notes

- Always starts at T1 regardless of the depth flag, because the readiness audit is the foundation.
- The SSR check is load-bearing: a client-side-rendered page is invisible to AI crawlers (they run
  zero JS) no matter how good its content is. A BLOCK here is the most important finding in the audit.
- Visibility and share-of-voice are estimates of a non-deterministic target. Run the visibility
  layer monthly with weekly spot-checks (`/ai-visibility {domain}`), because one run is a data point,
  not a verdict.
- If exa or firecrawl MCP servers are connected, the agent uses them for richer answer-engine
  retrieval. If not, it proceeds with WebSearch/WebFetch and logs the reduced coverage.
- If the user has GSC or Bing Webmaster access, the T2 visibility layer corroborates its estimates
  with the official surfaces: the GSC generative-AI performance reports (announced 3 Jun 2026;
  impressions, pages, countries, devices; no clicks or queries; data from 18 May 2026, subset
  rollout) and Bing's Citation Share (added 16 Jun 2026). Absence of either surface is normal and
  the audit proceeds without it. See the `ai-search-measurement` skill for the full method.
- Pairs with `/seo-audit`: run both for full search visibility (ranking + AI citation).
