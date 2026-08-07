# /blog [topic-or-keyword]

Long-form blog post production, SEO-aware if Claudify SEO Specialist is also installed.

## When to use

- Long-form content (800-2000+ words)
- Topic with informational or commercial intent
- You want SEO targeting (when SEO Specialist is present, this command integrates with keyword-strategist)

## Procedure

### Step 1 — Parse arguments

```
/blog "topic here"              # informational, no specific keyword
/blog "target keyword"          # SEO-targeted (informational/commercial intent inferred)
/blog                           # no args — strategist picks based on backlog
```

### Step 2 — Strategy (if no topic OR if SEO targeting needed)

If SEO Specialist is installed:
- Invoke `seo-agent` (from SEO Specialist) for keyword research / cannibalization check
- Receive: target keyword, search intent classification, content depth recommendation, competitor coverage gaps

If SEO Specialist not installed:
- Skip SEO research
- Apply general blogging best-practices from `.claude/knowledge-base.md`

### Step 3 — Brief

If no brief from strategist: invoke `content-strategist` agent for a complete brief.

Brief includes:
- Target keyword (if applicable)
- Search intent
- Required H2 subtopics (informational depth match)
- Word count target
- Internal linking opportunities (from SEO agent if present)

### Step 4 — Draft

Invoke `content-creator` agent with mode: long-form blog.

Creator follows blog structure rules:
- H1 = target keyword variant, 50-70 chars (matches title tag if SEO)
- Intro: hook (specific moment / pattern / claim) + scope statement (what this post covers)
- Body: 4-8 H2 sections with 1-2 H3 subsections each
- Internal links: minimum 1 per 300 words, descriptive anchor text
- Code blocks (if technical): runnable as-is, no placeholders
- Conclusion: payoff / next step / CTA — NOT "in conclusion" (banned)
- Meta description: 150-160 chars, target keyword + clear CTA

### Step 5 — Audit

Invoke auditor + (if SEO Specialist) seo-agent:
- Auditor: voice / format / anti-slop checks
- SEO agent (if present): on-page SEO score, keyword density, cannibalization re-check

### Step 5b: Pre-publish gate (hard-stop)

`/blog` does not deploy, so this gate hard-stops the "ready to publish" hand-off (Step 6) instead of a deploy. Do not present the post as ready until it passes.

**Always checked (every blog, no SEO Specialist required):**
- Word count is at least 1,500.
- Zero em dashes anywhere in the post.
- Meta description is 140 to 160 characters.
- At least 2 internal links to other posts.

**Checked only when SEO Specialist is installed** (these need `seo-agent`):
- The primary keyword appears in the title, the H1, the first paragraph, at least one H2, and the meta description.
- No keyword cannibalization (the seo-agent cannibalization re-check from Step 5 returns clean).

If any required check fails, do NOT proceed to Step 6. List each failure with its fix, send the post back to the `content-creator` to correct, then re-run this gate. Only when every applicable check passes does the post reach Step 6 as ready to publish. Skip the SEO-only checks gracefully (do not fail the gate on them) when the SEO Specialist is not installed.

### Step 5c, GEO pass (AI-citation readiness)

If the GEO layer is present (Bundle or Everything, detected by the presence of a `geo-score` command or a `geo-agent`):
- Chain into `/geo-score` (or invoke `geo-agent`) so the long-form ships answer-first: the lead paragraph states the direct answer in the first ~50 words, sections are chunked into self-contained 120-180 word passages under descriptive headings, and the post is stat-dense (specific load-bearing numbers welded to their claims) for AI citation.
- If `/geo-score` returns REVISE or BLOCK, send the post back to the `content-creator` with the GEO fixes, then re-run Step 5c.

If the GEO layer is not installed (base / content-only): skip this step. The post still ships on the Step 5b gate.

### Step 6 — Output

Print:
- Final blog post (markdown or HTML per user preference)
- Audit verdict
- SEO score (if applicable)
- Distribution derivatives suggested (X thread, LinkedIn post, newsletter teaser)

## Hand-off

`/blog` produces the post; you publish to your blog platform manually. Next response triggers `/feedback`.

## Examples

```
/blog "How to set up a self-improving CLAUDE.md"
```
Drafts a long-form blog on the topic.

```
/blog "claude code workflow"
```
SEO-targeted (if SEO Specialist installed) — keyword-strategist confirms target intent + cannibalization, creator drafts.

```
/blog
```
Strategist picks topic from backlog + brand history.
