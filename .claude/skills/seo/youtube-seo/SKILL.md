---
user-invocable: false
description: Optimize YouTube presence for search and AI visibility. Use when the user says "YouTube SEO", "optimize my videos", "video keywords", "rank on YouTube", or when AI-visibility strategy needs the mention channel with the strongest measured correlation. Covers video metadata, the brand-mention flywheel, and how YouTube feeds AI answers.
version: 2.1.0
---

# YouTube SEO

## Purpose

Optimize a brand's YouTube presence for two compounding outcomes: ranking inside YouTube and Google
video surfaces (classic video SEO), and feeding the single strongest measured correlate of AI
visibility. The Ahrefs 75,000-brand study (26-27 May 2026) found YouTube mentions correlate with
AI-answer visibility at r=0.737, the top predictor measured, ahead of branded web mentions
(r=0.664) and far ahead of backlinks (r=0.218). Gemini's citation mix is notably
YouTube-and-Wikipedia heavy (Semrush, reported 2026). YouTube is no longer a side channel for an
SEO strategy; it is the highest-correlation mention surface available.
[Source: ahrefs.com/blog/ai-brand-visibility-correlations, 26-27 May 2026]

**Category**: SEO & Search

## Inputs

### Required
- **Channel or brand**: the channel URL, or the brand if the play is earning third-party coverage
- **Goal**: rank owned videos, earn third-party YouTube mentions, or both

### Optional
- **Keyword map**: `.claude/agent-memory/seo/keyword-maps/{domain-slug}.md` for target topics
- **Competitor channels**: for gap analysis

## Two plays (run the right one, usually both)

### Play 1: Owned-channel video SEO

1. **Keyword-map the channel.** Pull target topics from the keyword map; check which have video
   intent (a video carousel or video results in the SERP; YouTube autocomplete demand). Video-intent
   keywords get videos; the rest do not.
2. **Metadata per video:**
   - Title: target keyword up front, under ~60 visible characters, watchable-human phrasing.
   - Description: first 150 characters answer the query directly (they show in search); then
     timestamps (chapters), links to the matching site page, and 2-5 topic keywords in prose.
   - Chapters: named with sub-topic keywords; chapters are extractable passages for engines.
   - Tags are low-weight; do not invest beyond brand + topic basics.
3. **Transcript and captions.** Upload a clean transcript or corrected captions. The transcript is
   the text AI engines and Google index; an auto-caption mess is a content-quality problem.
4. **Embed and interlink.** Embed each video on the matching site page (a page that already targets
   the keyword), add VideoObject schema there (`schema-markup-generator`), and link the description
   back to that page.
5. **Say the brand name on camera and in the description.** A video that never names the brand
   produces no brand mention for engines to count.

### Play 2: Earned YouTube mentions (the AI-visibility lever)

1. **Target list**: creators and podcasts in the niche who do reviews, tool roundups, comparisons,
   and interviews. Rank by topical fit first, audience size second (mirrors the
   relevance-over-authority backlink rule).
2. **Offer**: review access, a demo, a founder interview, exclusive data worth covering
   (`digital-pr-plan` mechanics apply; the deliverable here is YouTube coverage).
3. **Brief for mentionability**: quotable one-liners and specific numbers; ensure the brand name is
   spoken and spelled correctly in the description.
4. **Track mentions, not just links**: log third-party videos naming the brand in
   `.claude/agent-memory/seo/MEMORY.md`; correlation to watch is mention volume vs `/ai-visibility`
   SoV trend over monthly runs.

## Honest limits

- r=0.737 is a correlation across 75,000 brands, not a per-brand mechanism claim. Treat it as
  prioritisation evidence and verify against your own citation trend (`/ai-visibility`,
  `ai-search-measurement`); never promise a citation outcome from any specific video.
- Video production quality and retention drive YouTube's own ranking; metadata cannot rescue a
  video nobody watches.
- Do not buy mentions or undisclosed sponsorships presented as organic reviews; disclosure rules
  apply and undisclosed placements are the mention-world equivalent of purchased links.

## Output Format

```markdown
# YouTube SEO Plan: {brand/channel} | {date}

## Play 1: Owned channel
| Video/topic | Target keyword | Video intent confirmed | Metadata fixes | Site page to embed on |
|-------------|----------------|------------------------|----------------|----------------------|

## Play 2: Earned mentions
| Target creator/show | Topical fit | Offer | Status |
|---------------------|-------------|-------|--------|

## Measurement
- Mention log location and cadence
- /ai-visibility baseline and next run date
- Expected signal: {what movement, by when} (prediction for later grading)
```

## Quality validation (before returning)

- [ ] Every recommended video maps to a confirmed video-intent keyword
- [ ] Every metadata fix is specific (the actual title/description text, not "improve the title")
- [ ] Earned-mention targets ranked by topical fit with a concrete offer each
- [ ] The r=0.737 evidence cited with its date and framed as correlation, not promise
- [ ] A measurable prediction logged for later verification

## After Completion

- Update `.claude/agent-memory/seo/MEMORY.md` (mention log, plan, prediction)
- Pair with `digital-pr-plan` (outreach mechanics), `entity-optimization` (attribution),
  `schema-markup-generator` (VideoObject on embed pages)
- Add production/outreach tasks to `Task Board.md`
