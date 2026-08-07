---
user-invocable: true
description: Write an X (Twitter) thread of 3-15 posts for the Grok-ranked feed. Use when asked to "write a thread", "turn this into a thread", "X thread", "Twitter thread", "thread this blog post", or when a topic clearly needs more than 280 characters. Covers hook construction, per-post structure, the Jan 2026 Grok ranker, and the Jun 2026 API link-cost rule.
version: 2.1.0
---

# X Thread

## Purpose

Produce an X thread that earns dwell from the Grok-powered ranker and reads as one person thinking clearly in public. Threads are the heavy format on X: one thread per 3-4 singles in the rotation (pure-thread feeds exhaust followers).

## Platform mechanics (dated record)

- **The ranker reads semantically.** The Grok-powered feed is live since 20 Jan 2026 (open-sourced; the legacy heuristic ranker was deleted). It models content quality, originality, and predicted dwell. Consequence: engagement-bait scaffolding ("RT if you agree", curiosity-gap-without-payoff) is dead weight; a thread wins by being genuinely worth reading slowly. [Jan 2026]
- **Originality pays, literally.** Creator payouts are shifting to original authors, away from repost/aggregator accounts (rollout from late May 2026). Never build threads by aggregating others' points; build from your own numbers, incidents, and files. [May 2026]
- **Links cost 13x through the API.** Pay-per-use API since 1 Jun 2026: $0.015 per post, $0.20 per post containing a link. If the thread posts via automation, the link goes in the FINAL reply, never the hook, and the run states its cost. [Jun 2026]
- **Format:** 280 chars per post, 3-15 posts (engagement collapses past 15), hook establishes stakes within the first 180 chars, aggressive line breaks inside posts.

## Process

### 1. Calibrate
Read `knowledge-base.md` (Voice, Platform-Specific, Anti-Slop), the brand-memory file (calibration pairs, bans, signature phrases), and content-creator MEMORY (approved patterns, watch list). Lock one calibration pair as the voice anchor.

### 2. Structure
- **Post 1 (hook):** one specific claim with stakes, complete before 180 chars. Numbers beat adjectives. No "a thread 🧵" filler; the ranker does not need it and readers skim past it.
- **Posts 2 to N-1 (body):** ONE idea per post, each post able to survive being screenshotted alone. Sequence: claim, evidence, mechanism, application. Use a concrete artifact every 2-3 posts (a number, a file path, a before/after).
- **Final post (closer):** land the payoff the hook promised, then at most one CTA. The link (if any) lives here or in a reply below it.

### 3. Draft, then compress
Write it long, then cut each post to its load-bearing sentences. A post using 180 of its 280 chars with line breaks outreads a wall at 279.

### 4. Self-check
Zero em dashes; zero banned filler/cliches/AI-tells; signature phrase max once; hook complete at 180 chars; every post under 280; no post that only exists to bridge two real posts (delete bridges); link placement per the 13x rule; if any AI-generated media is attached, run the ai-disclosure skill (X "Made with AI" toggle for synthetic media).

### 5. Audit + ship
Hand to content-auditor (fresh context). On PASS: output final. At publish, `/content-learn record` fires with predicted dwell-proxy engagement vs the brand's thread baseline (guard G1).

## Worked example (hook + first body post)

Weak hook: "Let's talk about why CLAUDE.md files stop working over time. A thread."
Strong hook: "Audited 30 CLAUDE.md files last month. 24 had rules the owner stopped following within 6 weeks. The decay pattern is the same every time:"

Weak body post: "The first reason is that people add too many rules."
Strong body post: "Week 1: 10 rules, all followed. Week 4: 25 rules. The agent starts skimming. One rule buried at line 118 was the one that mattered."

## Output format

```
X THREAD, {brand}, {N} posts

1/ [hook]
2/ [post]
...
N/ [closer + CTA]

Voice anchor: pair {N}. Self-check: PASS. Auditor: PASS/FAIL.
Link placement: {final post / reply / none}. Automation cost note: {if API-posted}
Prediction: {predicted engagement vs baseline} (recorded via /content-learn)
```

## After completion

Log to content-creator MEMORY production log. If the thread derives from a long-form piece, register it in the derivative registry via `/repurpose` conventions. Offer the 3-4 singles that should follow it in rotation.
