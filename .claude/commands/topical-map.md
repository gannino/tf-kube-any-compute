# /topical-map

**Usage:** `/topical-map {domain} {topic}`

Build a topical authority map for a domain and topic. Returns a pillar + cluster structure with gap analysis and internal link requirements.

---

## Trigger Conditions

- User runs `/topical-map` explicitly
- User asks to "map topics", "build a content strategy", "create a topical cluster", or "plan topical authority"
- When starting SEO for a new domain
- When expanding into a new content area
- As part of a T4 full strategic audit

---

## Procedure

### Step 1: Pre-checks

1. Read `memory.md` for active domain context
2. Read the keyword map at `.claude/agent-memory/seo/keyword-maps/{domain-slug}.md` if it exists
3. Note any existing content on the domain related to the topic (to avoid duplicating mapping work)

### Step 2: Invoke keyword-strategist

Spawn the `keyword-strategist` to build the full topical map.

**What to tell the keyword-strategist:**
```
Build a topical authority map for {domain} on the topic: {topic}.
Read the existing keyword map for context on current coverage.
Process:
1. Define the pillar page: single comprehensive guide for the core topic
2. Build cluster pages: specific subtopics (aim for 6-12 clusters per pillar)
3. Check existing content: which clusters already exist, which are gaps
4. Assign target keywords to each cluster (no cannibalization)
5. Note internal link requirements: pillar → all clusters, all clusters → pillar
6. Identify orphaned content: pages on the domain related to the topic but not in any cluster
7. Output the full topical map format
8. Update the keyword map with all cluster keyword assignments
```

### Step 3: Gap Analysis

After the map is built:
1. Count existing vs. gap clusters — this is the content production roadmap
2. Estimate time to build out the full cluster at the user's content cadence
3. Identify which gaps are highest priority (based on search volume + commercial relevance)

### Step 4: Internal Link Audit

Check whether existing cluster pages are properly linked:
1. Does the pillar page link to all existing cluster pages? (if pillar exists)
2. Does each cluster page link back to the pillar?
3. Do cluster pages link to each other where topically relevant?

Flag any missing links as INTERNAL-LINK-GAP with specific fix instructions.

### Step 5: Present Map and Roadmap

Present the topical map with:
- Visual cluster structure (ASCII or table format)
- Gap count and estimated time to close
- Internal link gaps requiring immediate fixes
- Recommended content production order (foundational clusters first)

Offer:
- "Want me to build a content calendar around this map? → I can schedule it out now"
- "Want to start with a keyword research session for any of the gap clusters? → `/keyword-research {cluster topic}`"
- "Want me to audit existing cluster pages for on-page alignment? → `/seo-audit {cluster url} --depth content`"

---

## Output Format

```
TOPICAL MAP | {domain} | Topic: {topic} | {date}

Pillar Page:
Title: "{pillar title}" | Keyword: {keyword} | URL: {/slug} | Status: {exists|gap}

Cluster Pages:
| # | Cluster Title | Target Keyword | Vol | Intent | Status | Priority |
|---|--------------|---------------|-----|--------|--------|---------|

Coverage summary:
Existing clusters: {N}/{total} | Gaps: {N}
Time to full coverage at {X posts/week}: {N} weeks

Internal link audit:
Pillar → clusters: {N}/{total} linked (missing: {list})
Clusters → pillar: {N}/{total} linked (missing: {list})
Cross-cluster links needed: {N}

Orphaned content (related but unlinked):
{list of URLs not yet assigned to a cluster}

Recommended production order:
1. {cluster} — reason: {foundational|high volume|low difficulty}
2. {cluster}
3. {cluster}
```

---

## Notes

- A topical map is only as good as its internal linking — the map is incomplete without the link audit
- Pillar pages should be comprehensive (2,000+ words) — cluster pages can be more focused (800-1,500 words)
- Every cluster must have a unique target keyword — if two clusters have the same target, consolidate them
- Start with the pillar if it doesn't exist — clusters without a pillar lose topical authority transfer
