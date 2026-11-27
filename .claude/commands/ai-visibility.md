---
description: Track brand citations and share-of-voice across AI answer engines, with trend vs last run.
argument-hint: {domain}
allowed-tools: Read, Write, Edit, Bash(date:*), Glob, Grep, WebSearch, WebFetch
---

# /ai-visibility

**Usage:** `/ai-visibility {domain}`

Run the citation and share-of-voice tracker for a domain across the available AI answer engines.
Returns per-engine presence (mentioned, cited, position), competitor share-of-voice, and the trend
versus the last run. These are estimates of a non-deterministic target. The value is the trend over
time, not any single number.

---

## Trigger Conditions

- User runs `/ai-visibility` explicitly
- User asks "are we showing up in AI answers", "share of voice in ChatGPT/Perplexity", "do engines
  cite us", or "how visible are we in AI search"
- On a monthly cadence per tracked domain (the recommended tracking rhythm)
- As a weekly spot-check on a key prompt subset between full monthly runs

---

## Procedure

### Step 1: Pre-checks

1. Read `.claude/agent-memory/geo/MEMORY.md`, the `## Share-of-Voice History` and `## Citation
   Baselines` for this domain, to compute the trend and avoid a redundant same-day run.
2. Load the domain's geo-map (`.claude/agent-memory/geo/geo-maps/{domain-slug}.md`) for the prompt
   library. The slug convention matches the SEO maps: replace dots with hyphens, drop www (for
   example `mysite.com` becomes `mysite-com`).
3. If no prompt library exists yet, the agent will build one (10-30 buyer-intent prompts) as the
   first step and record it, and this becomes the baseline.

### Step 2: Confirm Engine Coverage

Confirm which engines are reachable this run:
- `WebSearch` and `WebFetch` cover Google AI Overview text (when present in results) and
  Perplexity-style answer pages.
- If `mcp__exa__*` or `mcp__firecrawl__*` MCP servers are connected, they extend coverage to richer
  answer retrieval. If they are not connected, the run proceeds with WebSearch/WebFetch and logs the
  reduced coverage, and it does not block.
- Any engine not reachable this run is recorded as a GAP, never guessed.

**Official surfaces (check availability, do not assume):**
- **GSC generative-AI performance reports** (announced 3 Jun 2026): AI Overviews / AI Mode /
  Discover-AI impressions, pages, countries, and devices. No clicks, CTR, or query data. Data
  starts 18 May 2026, subset-first rollout (UK first), so absence on a property is normal. If the
  user has GSC access AND the property shows the report, its AI-surface impressions become the
  official corroboration column in the output.
- **Bing Webmaster Tools AI Performance report** (launched 11 Feb 2026, Citation Share added
  16 Jun 2026): the first direct citation-share figure from a major engine, scoped to Bing/Copilot
  surfaces. Use it when the user has Bing Webmaster set up.
- If neither is available, the run proceeds on prompt-sampled estimates alone and marks both
  surfaces NOT-AVAILABLE. Never fabricate official figures.

### Step 3: Invoke geo-agent for Tracking

Spawn the `geo-agent` to run citation and share-of-voice tracking. Spawn it synchronously
(`run_in_background: false`): Step 4 reviews the agent's report, so the result must exist before
this command continues.

**What to tell the geo-agent:**
```
Run citation and share-of-voice tracking for {domain}.
Read your MEMORY.md and the domain's geo-map first to load the prompt library and the prior SoV run
for trend comparison. If no prompt library exists, build one (10-30 buyer-intent prompts) first.
For each prompt x reachable engine, record: mentioned (Y/N), cited-with-link (Y/N), brand position,
and which competitors appeared. Aggregate into a brand share-of-voice estimate per engine and
per-competitor SoV across the prompt set.
Run the corroborating-official-data step: if the user has GSC access and the property carries the
generative-AI performance report (rolling out since 3 Jun 2026), read AI-surface impressions per
page; if Bing Webmaster is set up, read Citation Share (added 16 Jun 2026). Log either surface as
NOT-AVAILABLE when absent; never invent official figures, and never blur official impressions into
the prompt-sampled estimates.
Use WebSearch/WebFetch, plus exa/firecrawl MCP if present. Log any unreachable engine as a GAP.
Label EVERY figure as an estimate with its sample size and date, because a single observation is one
sample of a non-deterministic target, not a position. Never fabricate an engine response.
Append this run to Share-of-Voice History and report the movement vs the last run.
Output in the AI VISIBILITY format.
```

### Step 4: Review and Present

Present the AI VISIBILITY report. Review for:
- Every figure labelled an estimate with its sample size and date
- Per-engine presence and competitor SoV both included
- Trend versus the last run computed (or "baseline set" if this is the first run)
- Any unreachable engines logged as gaps, not invented

Lead with the trend, not the absolute number: "Brand SoV in Perplexity is an estimated 22%, up from
an estimated 15% last month (sample 20 prompts)" carries far more meaning than the single figure.

### Step 5: Set Next Run and Log

Confirm the run was appended to `## Share-of-Voice History`. Set the next monthly run date and note
it. If a key competitor's SoV moved sharply, offer a fan-out gap analysis (`/geo-audit {url}
--depth full`) on the topics where they gained.

---

## Output Format

```
AI VISIBILITY (estimate) | {domain} | prompts: {N} | engines: {list} | {date}
NOTE: figures are estimates of a non-deterministic target. Sample = {N} prompts/engine, single run.

Per-engine presence:
| Engine | Reachable | Mentioned | Cited (link) | Avg position | Brand SoV (est.) |
|--------|-----------|-----------|--------------|--------------|------------------|

Competitor share-of-voice (est., this prompt set):
| Entity | Mentions | SoV (est.) | Trend vs last run |
|--------|----------|-----------|-------------------|

Official corroboration (when available):
| Surface | Available | What it reports | Value this run |
|---------|-----------|-----------------|----------------|
| GSC gen-AI report (impressions only, data from 18 May 2026) | {Y/N/NOT-ROLLED-OUT} | AI-surface impressions per page | {figures or "n/a"} |
| Bing Citation Share (Bing/Copilot surfaces) | {Y/N} | direct citation share | {figure or "n/a"} |

Coverage gaps (engines/tools not reachable this run): {list or "none"}
Movement vs last run ({prior date}): {brand SoV delta per engine, or "no prior run, baseline set"}
Next run due: {date, monthly cadence}
```

---

## Notes

- This is the one GEO surface that is inherently an estimate. Treat the cadence as the product: run
  monthly, spot-check weekly, and read the trend across runs. One run is a data point, not a verdict.
- A jump or drop in a single run is often sampling noise. Only call a change real when it exceeds the
  run-to-run noise band for that domain and holds across at least two runs (the analyst contract's
  min_effect and k guards).
- Share-of-voice is computed against the brand-plus-competitor mention set for the prompt library, so
  it moves when competitors move too, so always read brand SoV alongside competitor SoV.
- If visibility is low, the fix is usually upstream: run `/geo-audit {url}` on the pages that should
  be cited. AI-citation readiness (SSR, answer-first structure, open crawler access) is what makes a
  page eligible to appear here at all.
- exa or firecrawl MCP servers, when connected, materially widen engine coverage. Connect them for a
  fuller picture; the command still runs without them.
