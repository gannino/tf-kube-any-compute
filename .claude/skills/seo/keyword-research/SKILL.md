---
user-invocable: false
description: Produce a scored keyword cluster map for a topic or domain. Use when the user says "keyword research", "what should we rank for", "find keywords", "keyword opportunities", or before planning new content. Outputs a scored, prioritised cluster map saved to the domain's keyword map file, not a flat keyword list.
version: 2.1.0
---

# Keyword Research

## Purpose

Turn a topic or domain into a scored keyword cluster map: keywords grouped by the page that should
own them, each cluster scored for opportunity, mapped to intent, and checked against what the
domain already ranks for. The artifact is the cluster map written to
`.claude/agent-memory/seo/keyword-maps/{domain-slug}.md`; a flat list of keywords with volumes is
a failed output.

**Category**: SEO & Search

## Inputs

### Required
- **Topic or seed keywords**: what territory to research
- **Domain**: whose map this feeds (slug = dots to hyphens, drop www, e.g. `mysite-com`)

### Optional
- **GSC access**: unlocks the harvest pass (real impression data beats estimated volume)
- **Competitors**: 2-3 domains for gap analysis
- **Existing keyword map**: extend it, never silently overwrite history

## Process

### Step 1: Harvest before you plant (when GSC exists)
Pull queries the domain already gets impressions for in the topic area. Keywords at positions 4-20
with real impressions are pre-validated demand and outrank any estimated-volume guess. Mark these
STRIKING-DISTANCE; they head the priority queue because lifting an existing ranking is cheaper
than earning a new one.

### Step 2: Expand the seed set
- WebSearch the seeds; collect autocomplete variants, People Also Ask questions, related searches.
- Enumerate the fan-out: the 8-15 sub-questions an engine would decompose the topic into (Google
  documents query fan-out for its AI features; sub-question coverage also serves AI citation, see
  the geo pack).
- Pull competitor angles: what do the top-3 ranking pages for each seed also cover?

### Step 3: Classify intent per keyword
Informational (guide/how-to), Commercial (best/vs/review), Transactional (buy/pricing/signup),
Navigational (brand). Intent must match content format (knowledge-base hard rule); a cluster whose
keywords mix intents is two clusters.

### Step 4: Cluster to pages
Group keywords that a single page can own (same intent, same core need, overlapping SERPs). Name
each cluster by its target page (existing URL or "NEW: {working title}"). Check cannibalization:
`site:{domain} "{primary keyword}"` per cluster; if an existing page targets it, the cluster is an
UPDATE, not a new page.

### Step 5: Score each cluster (0-100)
| Factor | Weight | How to score |
|--------|--------|--------------|
| Demand evidence | 30 | GSC impressions (best) > autocomplete/PAA presence > estimated volume alone |
| Winnability | 30 | current position (striking distance scores high); SERP strength of top 3 (forums and thin pages = weak, beatable) |
| Intent value | 25 | transactional/commercial score high; informational scores by funnel relevance |
| Strategic fit | 15 | supports an existing pillar or business goal vs orphan topic |

Priority tiers from the score: P1 >= 70 (do now), P2 50-69 (this quarter), P3 < 50 (backlog or
drop). Apply via negativa: clusters with no demand evidence and no strategic fit get dropped, not
backlogged.

### Step 6: Write the map
Write/update `.claude/agent-memory/seo/keyword-maps/{domain-slug}.md` using the format below.
Append, do not destroy prior research; date-stamp the session.

## Output Format (the cluster map artifact)

```markdown
# Keyword Map: {domain} | updated {date}

## Priority queue
| Rank | Cluster (target page) | Score | Tier | Primary keyword | Intent | Current pos | Action |
|------|----------------------|-------|------|-----------------|--------|-------------|--------|

## Clusters
### {Cluster name} -> {target URL or NEW: title}
- Score: {N}/100 (demand {n}/30, winnability {n}/30, intent {n}/25, fit {n}/15)
- Intent: {type} | Format required: {guide/comparison/product page/...}
- Primary: {keyword} | Secondary: {keywords}
- Fan-out / PAA to cover: {sub-questions}
- Evidence: {GSC impressions, positions, autocomplete/PAA presence, with dates}
- Cannibalization check: {clear | conflicts with URL -> update instead}

## Dropped this session (via negativa)
| Keyword/cluster | Why dropped |
|-----------------|-------------|

## Session log
- {date}: {what was researched, what changed}
```

## Quality validation (before returning)

- [ ] Every cluster names its target page and has a cannibalization check result
- [ ] Every score shows its four factor sub-scores, not just the total
- [ ] Demand evidence cited with source and date (GSC window, or "estimated, no GSC")
- [ ] Intent classified per cluster and format stated
- [ ] Striking-distance keywords (when GSC exists) sit at the top of the queue
- [ ] The map file was actually written/updated, and prior content preserved

## After Completion

- Update `.claude/agent-memory/seo/MEMORY.md` (research session logged under the domain)
- Offer `/topical-map` to arrange the clusters into a pillar structure, and `/content-score` before
  any resulting draft publishes
- P1 clusters become Task Board entries with their target page named
