# /content-score

**Usage:** `/content-score` then paste content | `/content-score {url}` to score a live URL

Score content on 12 SEO dimensions before publishing. Returns a PUBLISH / REVISE / BLOCK verdict.

---

## Trigger Conditions

- User runs `/content-score` explicitly
- User asks to "check this content for SEO", "is this ready to publish", "score my post"
- Before publishing any new page or post
- After a content rewrite to verify improvement

---

## Procedure

### Step 1: Gather Content

If user ran `/content-score`:
- Ask user to paste the content (title, body, target keyword, target URL if known)

If user ran `/content-score {url}`:
- Fetch the live URL via WebFetch
- Extract title tag, meta description, H1-H3 structure, body content, images, schema

### Step 2: Confirm Target Keyword

Before scoring, confirm the target keyword:
- If user provided it: use it
- If scoring a live URL: check the existing keyword map in memory for this domain
- If unknown: infer from the content's H1, title, and first paragraph — state the inferred keyword

### Step 3: Invoke seo-agent for Scoring

Spawn the `seo-agent` to run the 12-dimension content scoring.

**What to tell the seo-agent:**
```
Score this content on the 12-dimension SEO scoring rubric.
Content: [pass the full content or URL]
Target keyword: {keyword}
Target URL: {url or "not yet assigned"}
Check for cannibalization against existing pages on {domain}.
Produce the full score card with specific fixes for every dimension scoring < 6.
Apply the PUBLISH/REVISE/BLOCK threshold.
```

### Step 4: Review and Present Score

Present the full score card to the user.

If verdict is REVISE:
- Highlight the top 3 dimensions to fix (by impact on score)
- Offer: "Want me to fix these now? → I can rewrite the failing dimensions immediately"

If verdict is BLOCK:
- Explain the critical issues clearly
- Offer: "Want me to do a full content rewrite? → I can bring this to PUBLISH-ready"

If verdict is PUBLISH:
- Confirm the content is ready
- Remind: "Once published, run `/seo-audit {url} --depth content` to verify on-page signals"

### Step 5: Log Result

Add the score result to the seo-agent memory under `## Audit Output Log`.
If there are REVISE/BLOCK items, add the required fixes to the Task Board.

---

## Scoring Rubric Reference

| Dimension | Weight |
|-----------|--------|
| Target keyword clarity | 15% |
| Title tag optimization | 10% |
| Meta description | 5% |
| Header structure | 10% |
| Content depth | 15% |
| Internal linking | 10% |
| External authority links | 5% |
| Image optimization | 5% |
| Readability | 10% |
| Schema markup | 5% |
| URL structure | 5% |
| Uniqueness (no cannibalization) | 5% |

## Verdict Thresholds

| Verdict | Score | Meaning |
|---------|-------|---------|
| PUBLISH | ≥ 75 | Ready to go live |
| REVISE | 50-74 | Specific improvements needed before publishing |
| BLOCK | < 50 | Significant rework required — do not publish as-is |

---

## Output Format

```
SEO SCORE: {0-100} | Keyword: {target} | URL: {target URL}
Strong: {dimensions scoring 8+/10}
Improve: {dimensions scoring <6 with specific fix}
Verdict: {PUBLISH / REVISE / BLOCK}
```
