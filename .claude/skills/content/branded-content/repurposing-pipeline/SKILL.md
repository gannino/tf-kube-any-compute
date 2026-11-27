---
user-invocable: true
description: Turn one canonical asset into platform-native derivatives with a tracked registry. Use when asked to "repurpose this", "atomize this post", "make platform versions", "cross-post this", or via /repurpose. Covers angle extraction, the platform-fit table, the anti-republishing rule, and the Jun-Jul 2026 originality enforcement that makes untracked cross-posting a penalty.
version: 2.1.0
---

# Content Repurposing Pipeline

## Purpose

This is the procedure doc behind `/repurpose`. One canonical asset (blog post, newsletter issue, video script) becomes 3-5 platform-native derivatives, each a tracked asset with its own registry row and its own prediction_record. Repurposing is re-framing for a platform's native consumption pattern; republishing is relocation, and relocation now gets punished.

## Why tracked, why native (dated record)

- Instagram deprioritizes aggregator-style reposts, lets users remove reposts of their content (Jun 2026), and caps trial Reels at 5 duplicates per day (Jul 2026). [Jun-Jul 2026]
- X payouts are shifting to original authors away from repost accounts (rollout from late May 2026), and the Grok ranker (Jan 2026) scores originality semantically. [May 2026]
- The published agency pattern of the window is atomization WITH a derivative registry: derivatives as first-class assets, individually measured. [Jun-Jul 2026 tooling record]

## Angle extraction (the core move)

A derivative is built from ONE angle of the source, not from the source compressed. From a 1,500-word piece, extract 3-5 distinct angles: the headline finding, the surprising number, the mechanism, the contrarian implication, the how-to. Each angle maps to one derivative; no two derivatives share an angle verbatim.

## Platform-fit table

| Angle type | Best derivative | Why |
|---|---|---|
| Headline finding with a number | X single, LinkedIn post | One idea, credibility-led |
| Step-by-step mechanism | X thread, IG carousel | Sequenced formats reward structure |
| Contrarian implication | LinkedIn post, X single | Discussion-bait done honestly drives out-of-network reach (native LinkedIn KPI since Jun 2026) |
| Visual before/after | IG carousel, TikTok script | The transformation carries the visual formats |
| The full how-to | Newsletter teaser, blog cross-link | Long-form belongs where long-form lives |

Ratios per the knowledge base: every long-form piece generates 3-5 derivatives; on X keep the 3-4 singles per 1 thread rotation.

## The anti-republishing rule

Each derivative must pass: could a reader who saw the source still get value here? A thread that adds tighter framing and a new example passes; a caption that pastes the intro fails. If the derivative would survive copy-paste back into the source unchanged, it is republishing; rework or drop it.

## Process

1. Read the source in full + the brand memory. Check the registry for existing derivatives of this source (a second derivative on the same platform needs a genuinely different angle, per the duplicate caps above).
2. Extract angles, map to platforms via the table, confirm the plan with the user if targets were not specified.
3. Produce each derivative through its platform skill (x-thread, x-single, linkedin-post, ig-caption, ig-carousel, tiktok-script), each with its own self-check + audit cycle.
4. Register every derivative in `.claude/agent-memory/content-creator/derivative-registry.md` (source, platform, variant, date, prediction_record pending, status drafted).
5. At each derivative's publish: `/content-learn record` for THAT derivative; update its registry row to published. The content-analyst grades each against its own platform baseline, never against the source.

## Worked example

Source: blog post "The 80-line CLAUDE.md your agent actually reads" (finding: 24/30 audited files had ignored rules; mechanism: salience decay past one screen; number: 412 to 80 lines).
- X thread (mechanism angle): the decay pattern, post by post.
- X single (number angle): "412 lines, ignored. 80 lines, followed. Same agent."
- LinkedIn (contrarian angle): "The best config file I saw this year is the shortest."
- IG carousel (how-to angle): 6 slides, one cut rule per slide.
- Newsletter teaser (finding angle): 2 paragraphs + link to the full post.

## Output format

Use the /repurpose output block: derivative table (platform, variant, angle, audit verdict), registry rows appended, prediction plan per derivative.

## After completion

Day-7 grades per derivative accumulate in the analyst's memory; at k >= 5 per platform, patterns like "carousel derivatives outperform thread derivatives for this brand" route through knowledge-nominations.
