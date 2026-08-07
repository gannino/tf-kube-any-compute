# /backlink-scan

**Usage:** `/backlink-scan {domain}`

Full backlink profile audit with prospecting for new link opportunities.

---

## Trigger Conditions

- User runs `/backlink-scan` explicitly
- User asks about backlinks, link building opportunities, or domain authority
- As part of a T3 or T4 audit
- Monthly backlink monitoring routine

---

## Procedure

### Step 1: Pre-checks

1. Read `.claude/agent-memory/seo/MEMORY.md` — `## Backlink Opportunities` for open prospects
2. Check audit history for last backlink scan date — note changes since then
3. Read knowledge-base.md Hard Rules — Link Building section

### Step 2: Audit Current Backlink Profile

Invoke the `link-builder` agent to pull and analyse the current profile.

**What to tell the link-builder:**
```
Run a full backlink profile audit for {domain}.
Pull current data from Ahrefs free checker.
Compare against the last scan recorded in memory.
Check anchor text distribution — flag if any single anchor exceeds 25-30%.
Identify potential toxic links.
Output in backlink audit format.
```

### Step 3: Opportunity Discovery

After the profile audit, run the full prospecting suite:
1. **Broken link building** — find broken links on resource pages in the niche
2. **Unlinked mentions** — find sites mentioning the brand without linking
3. **Guest post prospects** — find sites accepting contributions in the niche
4. **Resource page prospects** — find curated lists the domain could be added to

All four run in parallel via the link-builder agent.

**What to tell the link-builder:**
```
Run the full 4-part prospecting suite for {domain}:
1. Broken link building: search for resource pages in {niche} with dead links
2. Unlinked mentions: search for "{brand}" -site:{domain}
3. Guest post prospects: search {niche} "write for us" / "guest post"
4. Resource page prospects: search {niche} "best resources" / "useful links"
For each prospect type, score and prioritise results.
Produce outreach templates for the top 3 prospects in each category.
```

### Step 4: Present Results

Present the backlink audit and opportunity report together.

Prioritise:
1. Unlinked mentions (lowest effort, highest conversion rate)
2. Broken link building (medium effort, high relevance signal)
3. Resource pages (medium effort, long-term value)
4. Guest posts (high effort, highest brand exposure)

Offer: "Want me to draft personalised outreach for any of these? I can produce ready-to-send templates."

### Step 5: Update Memory

Confirm the link-builder updated `## Backlink Opportunities` in memory with all new prospects.

---

## Output Format

```
BACKLINK SCAN | {domain} | {date}

Current Profile:
Referring domains: {N} | DR/DA: {score}
Change since last scan: {+N|-N} domains
Anchor distribution: {top 5 anchors with %} | Risk: {SAFE|WARN}
Potential toxic links: {count}

New/Lost Links:
New: {N} | Notable new domains: {list}
Lost: {N} | Notable lost domains: {list}

Opportunities Summary:
Unlinked mentions: {N} linkable
Broken link prospects: {N} qualified
Guest post prospects: {N} qualified
Resource page prospects: {N} qualified

Total qualified opportunities: {N}
Priority outreach targets:
1. {domain} | Type: {type} | Anchor recommendation: {anchor} | Template: ready
2. {domain} | Type: {type} | Anchor recommendation: {anchor} | Template: ready
3. {domain} | Type: {type} | Anchor recommendation: {anchor} | Template: ready
```

---

## Notes

- Backlink audits run monthly provide the best signal; quarterly is the minimum
- Always check anchor distribution before pursuing new link targets — avoid exact-match anchor over-concentration
- Unlinked mentions are the fastest wins — pursue before anything else
