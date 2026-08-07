# /competitor-seo

**Usage:** `/competitor-seo {competitor domain}` | `/competitor-seo {competitor domain} --vs {your domain}`

Deep competitor SEO analysis: keywords, content strategy, backlink profile, SERP features, and gaps.

---

## Trigger Conditions

- User runs `/competitor-seo` explicitly
- User asks about a competitor's SEO strategy, what a competitor ranks for, or how to outrank a competitor
- As part of a T3 or T4 audit
- Quarterly competitive review

---

## Procedure

### Step 1: Pre-checks

1. Read `.claude/agent-memory/seo/MEMORY.md` — `## Competitor Registry` for any prior analysis on this competitor
2. Read the keyword map for the user's domain if a comparison domain is specified
3. Note the date of last competitor scan (avoid redundant work for recent scans)

### Step 2: Invoke seo-agent for Competitor Analysis

Spawn the `seo-agent` with the competitor domain.

**What to tell the seo-agent:**
```
Run a competitor SEO analysis on {competitor domain}.
User's domain for comparison: {domain or "not specified"}.
Analysis scope:
1. Top keyword categories (infer from SERP analysis — search for competitor site:domain to see rankings)
2. Content strategy (publishing frequency, content types, topic focus)
3. Backlink profile (via Ahrefs free checker — DR, referring domains, top anchors)
4. SERP feature ownership (featured snippets, PAA, image packs on shared keywords)
5. Technical baseline (CWV via PageSpeed, mobile score)
6. Schema types deployed
7. Keyword gaps: keywords competitor ranks for that the user's domain does not
Compare against {user's domain}'s keyword map where available.
Output in competitor analysis format.
Update competitor registry in memory.
```

### Step 3: Gap Analysis

After the raw competitor report, run a gap analysis:
1. Keywords competitor ranks for (top 20 by estimated volume) vs. keywords in user's keyword map
2. Backlink sources linking to competitor but not to user's domain
3. SERP features competitor owns vs. user's domain
4. Content types competitor produces that user's domain doesn't

### Step 4: Present Report and Opportunities

Present the competitor analysis with actionable gaps prioritised by impact.

Offer next steps:
- "Want me to add the keyword gaps to your keyword map? → I can do that now"
- "Want a content brief for any of the gap keywords? → Use `/keyword-research` or ask for a brief directly"
- "Want to pursue the backlink gaps? → Run `/backlink-scan {domain}` for the full opportunity list"

---

## Output Format

```
COMPETITOR ANALYSIS | {competitor domain} | vs. {user domain} | {date}

Profile:
Domain: {competitor} | DR/DA: {score} | Est. organic traffic: {tier}
Top content categories: {list}
Publishing cadence: {est. posts/month}

Keyword landscape:
Shared keywords (both rank): {count} | User ranks higher: {count} | Competitor ranks higher: {count}
Competitor-only keywords (your gaps): {count} — top opportunities: {top 5}

SERP features:
Features owned by competitor: {list}
Features owned by user: {list}
Unclaimed features: {list}

Backlink profile:
Referring domains: {N} | DR: {score}
Unique backlink sources (competitor only): {count} — top domains: {top 5}

Technical comparison:
CWV: Competitor {LCP/INP/CLS} vs. User {LCP/INP/CLS}
Mobile score: Competitor {score} vs. User {score}

Schema advantage: Competitor uses {types} | User uses {types} | User should add: {types}

Priority opportunities (ranked by impact):
1. {opportunity} — Est. impact: {high|medium|low}
2. {opportunity}
```

---

## Notes

- Competitor keyword data is inferred from SERP analysis, not direct access — label accordingly
- DR/DA from Ahrefs free checker is a reliable signal but may lag by 30-90 days
- Focus on topical competitors (those competing for the same keywords), not just industry peers
