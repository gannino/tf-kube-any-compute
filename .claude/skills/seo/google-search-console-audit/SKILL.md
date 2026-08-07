---
user-invocable: false
description: Walk the actual Google Search Console reports in a fixed order and turn each into findings. Use when the user says "check Search Console", "GSC audit", "why did clicks drop", "indexing problems", "coverage errors", or wants performance, indexing, experience, or the new generative-AI reports read properly. Requires the user to have GSC access; degrades to an access-setup checklist without it.
version: 2.1.0
effort: high
---

# Google Search Console Audit

## Purpose

Read a property's Search Console the way an experienced SEO reads it: report by report, in a fixed
order, each report producing either a finding with a fix or an explicit "healthy" verdict. This is
not a generic analysis framework; it is a walk of the actual GSC surfaces, including the
generative-AI performance reports Google announced 3 Jun 2026.

**Category**: SEO & Search

## Inputs

### Required
- **Property**: the GSC property (domain or URL-prefix) and confirmation the user can access it
- **Window**: comparison window (default: last 28 days vs prior 28 days)

### Optional
- **Focus**: a specific symptom to chase (traffic drop, indexing stall, CWV regression)
- **Tracked keywords**: from `.claude/agent-memory/seo/keyword-maps/{domain-slug}.md` if present

**No GSC access:** do not simulate the audit. Output the access-setup path (verify ownership via
DNS or HTML file, submit sitemap, wait for data) and run what is possible without GSC: `/seo-audit`
T1 plus a `site:` index check. Never fabricate GSC numbers.

## Process (walk the reports in this order)

### Step 1: Performance, Search results
- Pull clicks, impressions, CTR, average position for the window vs the prior window.
- Segment by query, page, country, device. Flag: queries losing clicks at stable position (CTR
  leak, often a SERP-feature or AI Overview change), pages losing impressions (ranking or indexing
  loss), and new queries entering the top 20 (harvest candidates).
- Cross-check dated drops against the confirmed 2026 update calendar in
  `.claude/commands/rank-check.md` before blaming the site.
- Zero-click context for interpretation (do not skip this): under AI Overviews, organic clicks fall
  39.8 percent with no measurable click-quality difference (Agarwal and Sen randomized field
  experiment, Search Engine Journal, 1 Jul 2026), and AIO presence costs top-ranking sites 58 of
  every 100 clicks (Ahrefs, ~300K keywords, 18 May 2026). A click decline at stable position and
  stable impressions is consistent with AI-surface expansion, not necessarily a ranking problem.

### Step 2: Performance, generative-AI reports (new, announced 3 Jun 2026)
- Check whether the property has the generative-AI performance reports (AI Overviews, AI Mode,
  generative AI in Discover). Rollout is subset-first (UK first), so absence is normal; record
  NOT-ROLLED-OUT and move on.
- Where present, read: impressions, pages, countries, devices. That is the complete metric set;
  Google provides no clicks, CTR, or query data on these reports (as of the 3 Jun 2026
  announcement), and data starts 18 May 2026 with no backfill.
- Use it to answer one question: which pages are earning AI-surface impressions, and does that set
  match the pages you want cited? Feed mismatches to `/geo-audit`.
- The same announcement added a control to block content from AI features. Only surface it if the
  user asks to opt out, and note the visibility trade.

### Step 3: Indexing, Pages (coverage)
- Read indexed vs not-indexed counts and every exclusion reason with its URL count.
- Triage the reasons that are almost always real problems: "Crawled, currently not indexed"
  (quality or internal-linking signal), "Discovered, currently not indexed" (crawl budget),
  soft 404s, redirect errors, duplicate-without-canonical, blocked by robots.txt.
- Crawl errors get a 7-day resolution clock (knowledge-base hard rule).

### Step 4: Sitemaps
- Confirm the sitemap is submitted, fetchable, and its "discovered URLs" roughly matches the
  expected page count. lastmod must reflect real content changes, not deploy timestamps.

### Step 5: Experience, Core Web Vitals
- Read mobile first (mobile-first indexing). Thresholds unchanged in 2026: LCP under 2.5s, INP
  under 200ms, CLS under 0.1 (no threshold changes found as of 24 Jul 2026). Route failing URL
  groups to the `core-web-vitals-fix` skill.

### Step 6: Enhancements and shopping (as applicable)
- Read whatever enhancement reports the property has (structured data types, breadcrumbs, product
  snippets). Note: FAQ rich results were removed from SERPs on 7 May 2026 and GSC removed FAQ
  reporting in Jun 2026 (API removal Aug 2026), so a vanished FAQ report or a FAQ traffic drop
  around those dates is the platform change, not a site regression.

### Step 7: Security and manual actions
- Check both panels. A manual action rewrites the whole diagnosis; check this before deep-diving
  anything else if the symptom is a sudden sitewide drop.

### Step 8: Links
- Top linked pages and top linking sites, mostly for anomaly detection (a spam-link spike or the
  loss of a major referring domain).

## Output Format

```markdown
# GSC Audit: {property} | {window} vs prior

## Verdict: {HEALTHY | ISSUES ({N} findings) | CRITICAL ({reason})}

## Findings (ordered by impact)
| # | Report | Finding | Evidence (metric, segment, dates) | Fix | Priority |
|---|--------|---------|-----------------------------------|-----|----------|

## Report-by-report status
| Report | Status | Key numbers |
|--------|--------|-------------|
| Performance (search) | {OK/FLAG} | clicks {N} ({+/-N%}), impressions {N}, CTR {N%}, pos {N} |
| Generative-AI reports | {OK/FLAG/NOT-ROLLED-OUT} | AI impressions {N or n/a}, top AI pages |
| Indexing (pages) | {OK/FLAG} | indexed {N}, excluded {N}, top reason |
| Sitemaps | {OK/FLAG} | discovered {N} vs expected {N} |
| Core Web Vitals | {OK/FLAG} | good/needs-improvement/poor URL counts (mobile) |
| Enhancements | {OK/FLAG} | valid vs error items per type |
| Manual actions / security | {CLEAN/ACTION} | {detail} |
| Links | {OK/FLAG} | {anomaly or "no anomaly"} |

## Interpretation
{3-6 sentences: what the combined picture means, explicitly separating ranking effects,
indexing effects, and AI-surface effects on clicks}
```

## Quality validation (before returning)

- [ ] Every report in the walk has a status; nothing skipped silently
- [ ] Every FLAG carries evidence (metric, segment, dates) and a specific fix
- [ ] No GSC number fabricated; missing access or missing reports stated as such
- [ ] Gen-AI report described accurately: impressions/pages/countries/devices only, no
      clicks/CTR/queries, data from 18 May 2026, subset rollout
- [ ] Click declines interpreted against the zero-click evidence before blaming rankings
- [ ] Dated drops checked against the 2026 update calendar

## After Completion

- Update `.claude/agent-memory/seo/MEMORY.md` (Audit History; new Ranking Alerts if found)
- Add follow-up fixes to `Task Board.md` by severity
- Route: CWV failures to `core-web-vitals-fix`, AI-surface gaps to `/geo-audit` and
  `ai-search-measurement`, reporting needs to `seo-reporting-dashboard`
- Nominate recurring patterns to `.claude/knowledge-nominations.md`
