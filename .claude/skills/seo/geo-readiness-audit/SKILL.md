---
user-invocable: false
description: Score a page or domain for Generative Engine Optimization (GEO) readiness, its ability to be cited by ChatGPT, Perplexity, Google AI Overviews, and Claude. Runs a 9-criterion scored checklist with cited thresholds, then returns a PUBLISH / REVISE / BLOCK verdict and a prioritised remediation list.
version: 2.1.0
effort: high
context: fork
---

# GEO Readiness Audit

## Purpose

Traditional SEO asks "will this page rank?". GEO asks a different question: "will an AI engine quote this page in its answer?". The two overlap but are not the same. An AI engine does not cite pages, it cites passages. It lifts a self-contained chunk out of context and attributes it. The job of this audit is to score how extractable and quotable a page is, then hand back the exact fixes that move the needle.

This is the checklist the GEO work loads. It is scored, every threshold carries the evidence behind it, and it ends in a verdict you can gate a publish on. Use it before publishing new content, when retrofitting existing pages for AI visibility, or when a page ranks in classic search but never appears in AI answers.

**Category**: SEO & Search, GEO / AI Search

## When to run this

- Before publishing any page intended to be an authoritative answer (definitions, how-to, comparison, data pages).
- When a page has organic rankings but zero AI citations (check via the brand-mention monitor or by prompting the engines directly).
- As a quarterly sweep across the top 20 pages by traffic.
- After a content refresh, to confirm the refresh improved extractability and did not just change the date.

## Inputs

### Required
- **Target URL** (or raw HTML / markdown of the page).
- **Primary question the page answers**, the head query, phrased as a user would type it into ChatGPT.

### Optional
- **Fan-out sub-questions**, the related questions an AI engine would decompose the head query into. If not supplied, derive them (see criterion 8).
- **Competitor pages** currently cited for the same query, to benchmark against.

## How AI engines actually select citations (read before scoring)

Grounding the scoring in the real mechanism, not folklore:

1. **Retrieval is passage-level.** The engine chunks pages and retrieves the chunks that best answer the query. A page is a bag of independently-retrievable passages, not one unit. [Source: industry standard, Princeton GEO study, Aggarwal et al., KDD 2024]
2. **The top GEO levers are editorial, not technical.** In the Princeton GEO study (10,000 queries, GEO-bench), adding **quotations** lifted visibility by up to ~41%, **citing sources** and **adding statistics** by roughly +30% each. These beat keyword stuffing, which actively hurt. [Source: industry standard, Aggarwal et al., KDD 2024]
3. **Most AI crawlers see only raw HTML.** As of mid-2026, GPTBot, OAI-SearchBot, ClaudeBot, Claude-SearchBot, and PerplexityBot execute **zero JavaScript** (analysis of 500M+ GPTBot fetches found no JS execution). If the answer is injected client-side, the engine never sees it. Google's Gemini is the only meaningful exception (it reuses Googlebot's render service). [Source: industry standard, 2025-2026 crawler analyses]
4. **Comprehensive coverage compounds.** Pages ranking for the fan-out sub-queries (not just the head term) are ~161% more likely to be cited (ALM Corp, 173,000-URL study). [Source: industry standard, ALM Corp fan-out study 2026]

The nine criteria below operationalise these four facts.

## The scored checklist (9 criteria, 100 points)

Score each criterion. Weights reflect citation impact, not effort. A criterion marked **[GATE]** is a hard fail: if it fails, the verdict is BLOCK regardless of the total score, because the page is structurally invisible to AI engines.

### 1. Answer-first opening, 15 pts

**Threshold:** The page answers its primary question directly inside the **first ~50 words / first 100 tokens**, before any preamble, history, or throat-clearing. The opening sentence should be liftable as a standalone answer.

**Why:** Information placed at the start of a page is disproportionately cited, roughly 44% of AI citations are drawn from the first ~30% of a page. Engines favour the inverted pyramid; a page that buries its answer under 300 words of context gives the extractor nothing to grab early. [Source: industry standard, AI citation placement data 2026]

**Score:** 15 = direct answer in sentence 1-2. 8 = answer present but after a paragraph of setup. 0 = answer is buried below the fold or never stated plainly.

### 2. Citable chunk structure, 15 pts

**Threshold:** Body is broken into **self-contained chunks of 120-180 words**, one idea per chunk, each under its own descriptive heading, each understandable if lifted out of the page in isolation. Flag any answer-bearing chunk **under 50 words** as a stub.

**Why:** Pages structured into 120-180-word sections earn ~70% more citations than pages with sub-50-word sections (SE Ranking 2025 citation data). 120-180 words is long enough to carry a complete answer plus a supporting fact, short enough for the model to parse and attribute cleanly. The test for each chunk: if it were shown on its own, would a reader understand it fully? [Source: industry standard, SE Ranking 2025; "self-contained unit" research]

**Score:** 15 = every answer chunk is self-contained and in range. 8 = mixed (some long walls, some sub-50w stubs). 0 = one undifferentiated wall of text, or all stubs.

### 3. Statistic density, 12 pts

**Threshold:** Roughly **10-19 concrete, specific statistics per substantive page** (numbers, percentages, dates, quantities), each tied to its claim. Vague quantifiers ("many", "most", "significantly") do not count.

**Why:** "Statistics Addition" was one of the three highest-impact GEO interventions in the Princeton study (~+30% visibility). Engines preferentially cite passages that carry a specific, checkable number over passages that assert the same thing qualitatively. [Source: industry standard, Aggarwal et al., KDD 2024]

**Score:** 12 = 10+ specific, relevant stats. 6 = 3-9 stats. 0 = fewer than 3, or stats that are decorative rather than load-bearing.

### 4. Quotations and cited sources, 13 pts

**Threshold:** The page includes **direct quotations from named authorities** and **inline citations to primary sources** for its key claims. Each major claim is traceable to something checkable.

**Why:** Quotation Addition (~+41%) and Cite Sources (~+30%) were the two single biggest levers in the Princeton GEO study. Engines treat quotes and citations as trust signals and lift them directly into answers, often carrying the attribution with them. [Source: industry standard, Aggarwal et al., KDD 2024]

**Score:** 13 = quotations from named sources + inline citations on key claims. 7 = citations present but no quotations, or vice versa. 0 = unsourced assertions throughout.

### 5. Server-side rendering, 18 pts **[GATE]**

**Threshold:** The page's **primary answer content is present in the raw HTML** returned by the server, before any JavaScript runs. Test it: `curl -sL {url} | grep -i "{a distinctive phrase from your answer}"`. If the phrase is absent from the curl output but visible in a browser, the content is client-rendered and AI-invisible.

**Why:** The major non-Google AI crawlers run zero JavaScript. Client-side-rendered content is simply not seen by ChatGPT, Perplexity, or Claude's crawlers, you are invisible to every AI engine except Google. This is the single most common silent GEO failure for modern SPA / React / Vue sites. [Source: industry standard, 500M+ GPTBot fetch analysis; UPF / U.Chile SSR research 2025]

**Score:** 18 = answer content fully in raw HTML (SSR / SSG / hybrid). 0 and **BLOCK** = answer content only appears after JS execution.

### 6. AI crawler access, 10 pts **[GATE]**

**Threshold:** `robots.txt` **explicitly allows** the AI citation bots (OAI-SearchBot, PerplexityBot, ClaudeBot, Claude-SearchBot, Google-Extended, Bingbot), and the site is not silently blocking them at the CDN. On Cloudflare, confirm the "Block AI bots" / "Bot Fight Mode" managed rules are not set to block these agents.

**Why:** A page can be perfectly optimised and still never get cited if the crawler is turned away at the door. From **1 July 2025, Cloudflare began blocking AI crawlers by default on new domains** (opt-in model, with a Pay-Per-Crawl 402 path). Many sites are blocking the very bots they want to cite them and do not know it. [Source: industry standard, Cloudflare announcement 1 July 2025]

**Score:** 10 = citation bots explicitly allowed in robots.txt and not CDN-blocked. 5 = robots.txt silent (default-allow, but unverified at CDN). 0 and **BLOCK** = citation bots disallowed or CDN-blocked.

### 7. Freshness signal, 7 pts

**Threshold:** `dateModified` is present in the Article schema and reflects a **genuine, substantive content edit** (new data, rewritten section, added answer), not a touched timestamp. AI engines weight recency, and freshness carries roughly **2x** the weight it does in classic ranking, but only for real edits.

**Why:** Engines favour recently and genuinely updated content for queries with any time sensitivity. Bumping the date without changing the content is a recognised spam signal and trains crawlers to distrust the date field. [Source: industry standard, content freshness / recency weighting 2026]

**Score:** 7 = `dateModified` accurate and backed by a real edit within the relevant window. 3 = present but the edit was cosmetic. 0 = missing, or a fake date bump.

### 8. Fan-out sub-question coverage, 7 pts

**Threshold:** The page (or its cluster) **answers the sub-questions an engine decomposes the head query into**. Google AI Mode fires 8-12 sub-queries per prompt, ChatGPT 4-20. Identify the top sub-questions and confirm each has a chunk that answers it.

**Why:** Pages ranking for fan-out sub-queries are ~161% more likely to be cited than pages that only cover the head term (ALM Corp, 173,000 URLs; Spearman 0.77 between sub-query coverage and citation likelihood). Comprehensive coverage is one of the strongest citation predictors there is. [Source: industry standard, ALM Corp fan-out study 2026]

**To derive sub-questions:** prompt an AI engine with the head query and read the "People also ask" / follow-up chips, or list the natural "what / why / how / when / vs / cost" variants of the head query.

**Score:** 7 = all major sub-questions answered with a dedicated chunk. 4 = head term plus a few sub-questions. 0 = head term only.

### 9. Entity clarity, 3 pts

**Threshold:** The publishing organisation is unambiguous to a machine: `Organization` schema present with `name`, `url`, `logo`, and `sameAs` pointing to authoritative profiles (Wikipedia/Wikidata where they exist, LinkedIn, Crunchbase, official socials).

**Why:** Engines need to resolve "who is making this claim" to decide whether to trust and attribute it. A page from a well-described entity is easier to cite with confidence. (Depth on this lives in the `entity-optimization` skill.) [Source: industry standard, entity resolution for AI engines 2026]

**Score:** 3 = Organization schema + sameAs present. 1 = partial. 0 = no entity markup.

## Scoring rubric (verdict)

Sum the nine criteria, then apply the gates.

```
GEO READINESS: {0-100} | {url} | Primary query: "{query}" | {date}
Gates: SSR {PASS/FAIL} | Crawler access {PASS/FAIL}
Per-criterion: 1:{x}/15 2:{x}/15 3:{x}/12 4:{x}/13 5:{x}/18 6:{x}/10 7:{x}/7 8:{x}/7 9:{x}/3
Strong: {criteria scoring full or near-full}
Fix now: {criteria scoring low, each with the specific remediation}
Verdict: {PUBLISH / REVISE / BLOCK}
```

**Verdict thresholds:**
- **PUBLISH**, total >= 80 AND both gates PASS. The page is genuinely citable. Ship it.
- **REVISE**, total 55-79 AND both gates PASS. Citable potential, but leaving citations on the table. Apply the Fix-now list, then re-score.
- **BLOCK**, total < 55, OR either gate (criterion 5 SSR / criterion 6 crawler access) FAILS. A gate failure means the page is structurally invisible to AI engines no matter how good the prose is. Fix the gate first, everything else is moot until then.

## Remediation library (map each low score to its fix)

| Failing criterion | The fix |
|---|---|
| 1 Answer-first | Move the direct answer to sentence 1. Rewrite the opening as: claim, then the one stat that proves it. Cut the historical preamble or push it below. |
| 2 Chunk structure | Split walls of text at every distinct idea. Add a descriptive H2/H3 above each chunk. Expand sub-50w stubs to a full 120-180w self-contained answer. Apply the "Information Island" test to each chunk. |
| 3 Statistic density | Replace vague quantifiers with specific numbers. Add a stat to each major claim. Target 10+ load-bearing stats per substantive page, each tied to its assertion. |
| 4 Quotations + sources | Add 1-2 direct quotations from named authorities. Add an inline citation to a primary source for every key claim. Make every assertion traceable. |
| 5 SSR **[GATE]** | Switch the answer-bearing content to SSR / SSG / hybrid rendering so it ships in the raw HTML. For React/Next, render the content server-side, not in a client `useEffect`. Re-test with `curl`. (Full method: `ai-crawler-access` skill.) |
| 6 Crawler access **[GATE]** | Add the explicit allow block for the citation bots to `robots.txt`. On Cloudflare, exempt the citation bots from AI-bot blocking. (Copy-paste block + CDN steps: `ai-crawler-access` skill.) |
| 7 Freshness | Make a genuine content edit (new data, rewritten section), then set `dateModified` to that date. Never bump the date alone. |
| 8 Fan-out | List the head query's sub-questions, then add a dedicated, headed chunk answering each one. Or build a cluster where sibling pages cover the sub-questions and interlink. |
| 9 Entity clarity | Add `Organization` schema with `name`, `url`, `logo`, `sameAs`. Populate `sameAs` with every authoritative profile. (Full method: `entity-optimization` skill.) |

For the editorial criteria (1-4, 8), the `ai-answer-optimization` skill carries the deep how-to and before/after examples. For the technical gates (5-6, 9), the `ai-crawler-access` and `entity-optimization` skills carry the artifacts. This audit decides what is wrong; those skills carry how to fix each one.

## Worked example (abbreviated)

A React SaaS pricing page, head query "how much does {category} software cost":

```
GEO READINESS: 41/100 | /pricing | Primary query: "how much does X cost" | 2026-06-29
Gates: SSR FAIL | Crawler access PASS
Per-criterion: 1:8/15 2:8/15 3:6/12 4:0/13 5:0/18 6:10/10 7:3/7 8:4/7 9:2/3
Strong: crawler access (bots allowed)
Fix now:
  - SSR [GATE]: pricing table renders client-side, curl returns no prices. Move to SSG. THIS IS WHY IT IS NEVER CITED.
  - Quotations+sources (4): zero citations. Add a source for each pricing claim.
  - Statistic density (3): only 2 concrete numbers. Add tier prices, ranges, averages inline.
  - Answer-first (1): answer ("from $X/mo") buried under positioning copy. Lead with the number.
Verdict: BLOCK (SSR gate failed)
```

The total of 41 would BLOCK on its own, but the SSR gate is the headline: every other fix is wasted until the prices ship in the raw HTML.

## Quality validation (before returning the audit)

- [ ] Every criterion has an explicit numeric score and a one-line justification tied to the page.
- [ ] Both gates (SSR, crawler access) were tested empirically, SSR via `curl`, crawler access via `robots.txt` + CDN check, not assumed.
- [ ] The Fix-now list names the specific element/section to change, not "improve the content".
- [ ] The verdict respects the gate override (any gate FAIL forces BLOCK).
- [ ] Every threshold cited carries its source.

## After completion

- Log the score and verdict in `.claude/agent-memory/seo/MEMORY.md` so the next audit can check for regression or improvement.
- If you discover a recurring GEO failure pattern across multiple pages (e.g. "all blog pages are client-rendered"), nominate it to `.claude/knowledge-nominations.md` tagged `[SEO]`.
- If the page failed a gate, the related fix skill (`ai-crawler-access`) is the immediate next step, recommend it.
