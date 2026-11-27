---
user-invocable: false
description: Measure AI-search visibility with the official sources. Use when the user asks "are we in AI Overviews", "how do I measure AI visibility", mentions the Search Console generative-AI reports, Bing Citation Share, AI impressions, or wants AI-surface numbers in a report. Covers what the GSC gen-AI reports and Bing AI Performance report actually provide, their limits, and how to combine them with prompt-sampled estimates without blurring the two.
version: 2.1.0
context: fork
---

# AI Search Measurement

## Purpose

Until mid-2026, measuring AI-search visibility meant prompt-sampling: asking the engines questions
and recording who they cite. That remains necessary, but it is no longer the only source. In
June 2026 the measurement went official: Google and Bing both now report AI visibility directly.
This skill defines what each official surface actually provides, what it does not, and the method
for combining official data with prompt-sampled estimates so the two never get blurred.

**Category**: SEO & Search, GEO / AI Search

## The two official surfaces (know exactly what each provides)

### 1. Google Search Console generative-AI performance reports

Announced 3 Jun 2026 on the Google Search Central blog
(developers.google.com/search/blog/2026/06/gen-ai-performance-reports).

**What it provides:**
- Dedicated performance reporting for AI Overviews, AI Mode, and generative AI in Discover
- Metrics: impressions, pages, countries, devices

**What it does NOT provide (do not promise these to anyone):**
- No clicks, no CTR, no query data (as of the 3 Jun 2026 announcement)
- No backfill: data starts 18 May 2026
- Not on every property: rollout is subset-first (UK first). A property without the report is
  normal, not a configuration error.

**Also shipped in the same announcement:** a GSC control to block content from AI features. Know it
exists; only mention it when a user explicitly wants out of AI surfaces, and note that blocking AI
features removes the visibility this skill measures.

### 2. Bing Webmaster Tools AI Performance report

Launched 11 Feb 2026; expanded 16 Jun 2026 with Intents, Topic groupings, Citation Share, and
Compare.

**What it provides:**
- Citation Share: the first direct citation-share figure published by any major engine
- Intent and topic groupings, and comparison over time

**Scope limit:** Bing/Copilot surfaces only. Citation Share says nothing about ChatGPT (beyond its
Bing-sourced retrieval), Perplexity, Gemini, or Google AI surfaces. Always label the scope when
reporting it.

## Why prompt-sampling is still required

Official data covers Google AI surfaces (impressions only) and Bing/Copilot (citation share). It
does not cover ChatGPT, Perplexity, Claude, or Gemini answer surfaces, and Google gives no
citation-level or query-level view. Prompt-sampled tracking (the `geo-agent`'s Responsibility 2,
run via `/ai-visibility`) remains the only way to observe those engines.

Prompt-sampled figures are estimates of a non-deterministic target and are always labelled as
estimates with sample size, engine, and date. Official figures are measurements, but of a narrower
thing (impressions, not citations; one engine family, not all). Neither substitutes for the other.

**The churn rule:** 40 to 60 percent of the domains cited for a given query change monthly
(Profound citation-drift data, vendor-reported: AI Overviews 59.3%, ChatGPT 54.1%, Copilot 53.4%,
Perplexity 40.5%). Single snapshots are noise. Trends across a monthly cadence are the product.

## Process

1. **Inventory access.** Does the user have GSC for the property? Does the property show the
   generative-AI performance report yet (subset rollout)? Is Bing Webmaster Tools set up? Record
   each as AVAILABLE / NOT-AVAILABLE / NOT-ROLLED-OUT.
2. **Pull official data where available.**
   - GSC: AI-surface impressions by page, country, device, for the reporting window. Note the
     18 May 2026 data floor when comparing periods.
   - Bing: Citation Share plus its trend, labelled "Bing/Copilot surfaces only".
3. **Run or reuse the prompt-sampled layer.** Use the domain's prompt library via `/ai-visibility`
   (monthly cadence, weekly spot-checks). Do not re-run same-day if a current run exists.
4. **Combine without blurring.** Official figures and estimates sit in separate labelled columns.
   Never average them, never present an estimate as official, never scale an estimate by an
   official figure.
5. **Read the combined signal.**
   - AI impressions rising while prompt-sampled citations are flat: pages are entering AI surfaces
     but not as named citations. Check entity clarity and answer-first structure.
   - Citations present in prompt sampling but zero GSC AI impressions: check whether the property
     has the report at all before concluding anything.
   - Bing Citation Share diverging from other engines: normal. Visibility is platform-fragmented;
     optimize per engine, report per engine.
6. **Log the run.** Append to the geo-agent's Share-of-Voice History and the domain geo-map, with
   the official columns included, and set the next monthly run date.

## Output format

```
AI SEARCH MEASUREMENT | {domain} | {date}

Official surfaces:
| Surface | Status | Metric | This period | Prior period | Trend |
|---------|--------|--------|-------------|--------------|-------|
| GSC gen-AI report | {AVAILABLE/NOT-AVAILABLE/NOT-ROLLED-OUT} | AI-surface impressions | {N or n/a} | {N or n/a} | {dir} |
| Bing AI Performance | {AVAILABLE/NOT-AVAILABLE} | Citation Share (Bing/Copilot only) | {% or n/a} | {% or n/a} | {dir} |

Prompt-sampled estimates (non-deterministic target; sample {N} prompts/engine):
{the AI VISIBILITY block from /ai-visibility}

Reading: {2-4 sentences interpreting the combined signal, trend-first}
Next run due: {date, monthly cadence}
```

## Degradation ladder (never block, never fabricate)

| Situation | What to do |
|-----------|-----------|
| No GSC access | Prompt-sampled layer only; mark GSC NOT-AVAILABLE |
| GSC access but no gen-AI report on the property | Mark NOT-ROLLED-OUT (subset rollout is expected); re-check monthly |
| No Bing Webmaster | Mark NOT-AVAILABLE; note Citation Share is the cheapest official win when they set it up |
| No prompt library yet | Build one first (10-30 buyer-intent prompts); this run becomes the baseline |

## Quality validation (before returning)

- [ ] Every official figure states its surface, scope, and reporting window
- [ ] GSC figures described as impressions only; no clicks/CTR/query claims made from them
- [ ] Bing Citation Share labelled "Bing/Copilot surfaces only"
- [ ] Every prompt-sampled figure labelled an estimate with sample size, engine, and date
- [ ] No official figure fabricated for an unavailable surface
- [ ] Trend stated wherever a prior run exists; single runs framed as data points

## After completion

- Update `.claude/agent-memory/geo/MEMORY.md` (Share-of-Voice History plus the official columns)
  and the domain's geo-map.
- If AI-surface impressions exist but citations do not, recommend `/geo-audit` on the top
  impression pages: readiness is the upstream fix.
- Pair with `seo-reporting-dashboard` so AI impressions appear beside organic clicks in reporting,
  and with `google-search-console-audit` for the full GSC walk.
