---
user-invocable: true
description: Write a long-form blog post built to rank and to be cited by AI answer engines. Use when asked to "write a blog post", "SEO post", "article targeting a keyword", "blog about X", or via /blog. Covers the Jun 2026 Google spam update reality, E-E-A-T experience signals, answer-first extractability, and the AI-disclosure sign-off for AI-drafted text.
version: 2.1.0
---

# SEO Blog Post

## Purpose

Produce an 800-2,000+ word post that earns rank the 2026 way: unique value per page, demonstrated first-hand experience, and passages an answer engine can lift whole. Volume plays are dead; the June 2026 spam update explicitly targets scaled content abuse, and AI Overviews mean the win condition on informational queries is being the quoted source, not just the ranked link.

## Search reality (dated record)

- **Google's Jun 24-26 2026 spam update** hit scaled content abuse, scraped pages, and AI-manipulation tactics; the target is tactics, not AI authorship. Every post must pass: "would this page exist without search traffic?" Publish velocity itself is now a spam signal; cap it. [Jun 2026]
- **"SEO for AI is still SEO"** (Google, 8 Jan 2026), with an explicit warning against chunking content into LLM-bait fragments. Extractability formatting must read naturally to a human. [Jan 2026]
- **E-E-A-T experience signals (2026 core updates):** named author with an author page, demonstrated first-hand use (original screenshots, data, numbers), and at least one piece of information gain vs the current top-10. [Mar-Jun 2026, secondary sources]
- **AI Overview economics:** AIO presence correlates with large CTR reductions on informational queries (position-1 CTR on AIO queries reported down to ~1.6% by early 2026). Plan informational posts for citation visibility; push commercial-intent pages where AIOs are rarer. [Feb 2026 studies, secondary]
- **AI-drafted text + EU:** ordinary human-reviewed marketing copy needs no AI label under Article 50 (editorial-responsibility carve-out), but LOG the human sign-off (name + date). Applies 2 Aug 2026; see the ai-disclosure skill. [Jul 2026]

## Process

### 1. Target and intent
With the SEO layer installed: take keyword, intent class, and gap notes from the seo-agent. Without it: pick the query, classify intent (informational / commercial), and read the current top 3 to find the information gain this post will add. No gain identified = no post.

### 2. Architecture (answer-first)
- **Title:** under 60 chars, keyword front-loaded naturally (headline skill rules).
- **Lead paragraph:** directly answers the title question in 2-4 sentences. This is the passage an answer engine lifts.
- **Sections:** H2s phrased as the real sub-questions (PAA-style); each section a self-contained 120-180 word passage that stands alone when quoted; specifics in every section (numbers, file paths, named tools, dated claims with sources).
- **Experience block:** at least one original artifact: your screenshot, your measurement, your before/after. This is the E-E-A-T experience signal and the part no scaled competitor can copy.
- **FAQ or summary:** only if it adds answers not already covered; never restate.

### 3. Draft
Voice per brand memory. House rules in full (no em dashes, no filler, no AI-tells, personal-moment opener if first-person, max 40-word sentences, max 4-sentence paragraphs). Internal links to the brand's related posts; external links only to primary sources.

### 4. Self-check
Unique-value test passes; lead answers the title; every H2 section self-contained; named author + experience artifact present; information gain named explicitly; zero banned patterns; human editorial sign-off logged if AI-drafted (Article 50 carve-out); publish cadence sane (this post is not part of a same-day batch dump).

### 5. Audit + ship + learn
Content-auditor fresh context (S11 checks GEO readiness). At publish: `/content-learn record` with predicted 7-day sessions or GSC clicks vs the blog baseline. Register social derivatives via /repurpose.

## Worked example (lead paragraph, query: "why does claude ignore claude.md")

"Claude ignores a CLAUDE.md for one dominant reason: the file is too long to stay salient, so instructions past the first screen lose the competition for attention. In the 30 files I audited in June, the median length was 340 lines; the rules owners complained about were at line 90 or later. Cut the file to one screen of load-bearing rules and compliance recovers the same day."

## Output format

```
SEO BLOG POST, {brand}, {target query} ({intent})

[full post, frontmatter + body]

Information gain vs top-10: {one line}. Experience artifact: {what}.
Author: {name}. AI-drafting sign-off: {logged / human-written}.
Self-check: PASS. Auditor: PASS/FAIL.
Prediction: {7-day sessions or clicks vs baseline} (recorded via /content-learn)
Derivatives queued: {list} (via /repurpose)
```

## After completion

Log to production log. With the SEO layer present, hand the URL to its indexing workflow. Day-7 and day-28 grades come back through the learning loop.
