---
user-invocable: false
description: Build a recurring SEO report that explains performance instead of mystifying it. Use when the user says "SEO report", "monthly report", "reporting dashboard", "show me our SEO numbers", or asks why traffic fell. Reports AI-surface impressions beside organic clicks so zero-click decline is explained, not mysterious.
version: 2.1.0
---

# SEO Reporting Dashboard

## Purpose

Produce a recurring SEO report whose numbers explain themselves. The single most common reporting
failure in 2026 is presenting an organic-click decline with no AI-surface context, which reads as
"SEO is failing" when the true picture is "visibility moved to surfaces that do not click". This
skill builds the report so clicks, impressions, AI-surface impressions, and citations sit side by
side, each labelled with what it can and cannot claim.

**Category**: SEO & Search

## The zero-click context every report must carry (dated evidence)

- AI Overviews presence cuts organic clicks 39.8 percent, with no measurable difference in the
  quality of the clicks that remain (Agarwal and Sen randomized field experiment, Search Engine
  Journal, 1 Jul 2026).
- AIOs cost top-ranking sites 58 of every 100 clicks (Ahrefs study, ~300K keywords, 18 May 2026).
- Zero-click searches reached 69 percent as of May 2025, up from 56 percent a year earlier
  (Similarweb).

Consequence for reporting: a click decline at stable average position and stable impressions is the
expected signature of AI-surface expansion. Report it as such, with the evidence above available as
footnotes, instead of letting the decline read as unexplained failure. Never use this context to
excuse an actual ranking loss: the report must distinguish the two (position moved = ranking
effect; position stable, clicks down = surface effect).

## Inputs

### Required
- **Property/domain** and reporting window (default: calendar month vs prior month)
- **Data sources available**: GSC (and whether the property has the generative-AI reports), GA4,
  Bing Webmaster Tools, rank tracker, none

### Optional
- **Audience**: operator (full detail) vs stakeholder (one-page summary first)
- **Tracked keywords**: keyword map at `.claude/agent-memory/seo/keyword-maps/{domain-slug}.md`

## Process

### Step 1: Assemble the metric set (only from sources that exist)
| Block | Metric | Source | If unavailable |
|-------|--------|--------|----------------|
| Classic search | clicks, impressions, CTR, avg position | GSC Performance | manual SERP checks, labelled approximate |
| AI surfaces | AI-surface impressions (AI Overviews / AI Mode / Discover-AI) | GSC generative-AI reports (announced 3 Jun 2026; impressions/pages/countries/devices only, no clicks or queries, data from 18 May 2026, subset rollout) | mark NOT-ROLLED-OUT or NOT-AVAILABLE |
| AI citations | Citation Share (Bing/Copilot surfaces only) | Bing Webmaster AI Performance report (Citation Share added 16 Jun 2026) | mark NOT-AVAILABLE |
| AI citations (est.) | prompt-sampled brand SoV per engine | `/ai-visibility` run | run one or mark "no run this period" |
| Conversions | organic sessions, conversions | GA4 | omit block, say so |
| Rankings | tracked-keyword movement | `/rank-check` | GSC position data only |

### Step 2: Compute deltas and classify every movement
For each block: this period vs prior, absolute and percent. Classify each notable movement as
RANKING EFFECT (position moved), SURFACE EFFECT (position stable, clicks down, AI impressions up or
AIO present on the queries), CONTENT EFFECT (pages added/removed/refreshed), or TECHNICAL EFFECT
(indexing or CWV change). Check dated drops against the 2026 update calendar in
`.claude/commands/rank-check.md`.

### Step 3: Build the report artifact
Use the output format below. Lead stakeholder versions with the one-page summary. Footnote every
dated claim with its source and date.

### Step 4: Recommend, with predictions
Each recommendation names its expected metric movement and by-when, so next period's report can
grade it (feeds the Pending Recommendations and Calibration loop in agent memory).

## Output Format

```markdown
# SEO Report: {domain} | {window}

## One-page summary
- Total search visibility: {narrative combining classic + AI surfaces}
- Organic clicks: {N} ({+/-N%}) | Classified: {ranking/surface/content/technical}
- AI-surface impressions: {N or "report not rolled out"} ({+/-N%})
- Bing Citation Share: {% or "not available"} (Bing/Copilot surfaces only)
- Prompt-sampled AI SoV (estimate, sample {N}): {per engine}
- The one thing to do next: {highest-leverage action}

## Classic search performance
{clicks/impressions/CTR/position table, by page group and by top queries, with deltas}

## AI-surface visibility
{GSC gen-AI impressions by page; Bing Citation Share trend; prompt-sampled estimates clearly
labelled as estimates. State surface scope on every figure.}

## Movement classification
| Movement | Size | Class | Evidence |
|----------|------|-------|----------|

## Recommendations (with predictions)
| # | Action | Expected movement | By when | Owner |
|---|--------|-------------------|---------|-------|

## Data caveats
{sources unavailable this period, estimate sample sizes, rollout gaps}
```

## Ecommerce note (dated)

For stores, add a product-feed health line to the report: ChatGPT ended in-chat Instant Checkout in
early Mar 2026 (in-chat checkout converted roughly 3x worse; commerce is now "discover in AI, buy
on site") and opened product feeds in ChatGPT Ads Manager on 2 Jun 2026 using the same catalog
format as Google Shopping. Google announced AI Mode ad formats at Marketing Live 2026. Product
schema and feed cleanliness now feed AI shopping surfaces directly; see `ecommerce-seo` and
`product-page-seo`.

## Quality validation (before returning)

- [ ] AI-surface impressions reported beside organic clicks (or their absence explicitly stated)
- [ ] Every movement classified (ranking / surface / content / technical), none left mysterious
- [ ] Official figures and prompt-sampled estimates in separate, labelled rows; never merged
- [ ] Every dated claim carries its date and source
- [ ] Every recommendation carries a predicted movement and a by-when
- [ ] No fabricated numbers for unavailable sources

## After Completion

- Update `.claude/agent-memory/seo/MEMORY.md` (report log, new alerts)
- Log recommendation predictions for next period's grading
- Route follow-ups: AI-surface gaps to `ai-search-measurement` and `/geo-audit`, CWV to
  `core-web-vitals-fix`, keyword moves to `/rank-check`
