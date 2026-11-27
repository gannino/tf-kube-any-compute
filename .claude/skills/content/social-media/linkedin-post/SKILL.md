---
user-invocable: true
description: Write a LinkedIn post in first-person, specific-experience voice. Use when asked to "write a LinkedIn post", "post this on LinkedIn", "LinkedIn version of this", or "professional post". Covers the Jul 2026 suppression of generic AI-voice posts, the Jun 2026 in/out-of-network reach KPI, vertical video expansion, and the beat-the-platform-default copy bar.
version: 2.1.0
effort: low
---

# LinkedIn Post

## Purpose

Produce a LinkedIn post that escapes the follower graph. The scoreboard metric is out-of-network reach percentage (a native KPI since Jun 2026); a post that only reaches existing followers did the minimum.

## Platform mechanics (dated record)

- **Generic AI-voice is a reach penalty in itself.** LinkedIn started actively suppressing generic AI-pattern posts on 23 Jul 2026; first-person, specific-experience posts gain the distribution those lose. The house anti-slop rules are not just brand hygiene here; they are the algorithm strategy. [Jul 2026]
- **In-network vs out-of-network reach are native KPIs since Jun 2026.** Predict and grade posts on out-of-network percentage. [Jun 2026]
- **Copy must beat the platform default.** Campaign Manager generates ad copy itself since 8 Jul 2026 (with Brand Kits and variants). Any copy a human ships has to be visibly better than what the platform writes free: more specific, more experiential, more first-person. [Jul 2026]
- **Vertical video feed expanded to UK/AU/CA in Jun 2026.** For brands in those markets, offer a vertical-video derivative of any post that performs. [Jun 2026]
- **Format:** 1300-2000 chars optimal; mobile truncates after 3 lines (~210 chars) behind "see more", so the hook must be complete before that; 3-5 hashtags after the body, never inline; external link in the first comment when reach matters, not the body.

## Process

### 1. Calibrate
Read knowledge-base.md, brand memory, content-creator MEMORY. Lock the voice anchor. LinkedIn amplifies the first-person rules: "I" with a named situation, never "we at {brand} believe".

### 2. Structure (the 4-beat shape)
- **Beat 1 (lines 1-3, before truncation):** the specific moment or number that earns "see more". Concrete beats clever.
- **Beat 2:** what happened, with the artifacts (numbers, named tools, timeframes).
- **Beat 3:** the mechanism, why it happened, the transferable insight.
- **Beat 4:** the application for the reader, plus at most one question a stranger could answer from their own experience (out-of-network commenters drive out-of-network reach).

### 3. Line discipline
1-2 sentence paragraphs with white space; 1300-2000 chars total. Read the first three lines in isolation: if they work as a complete micro-post, the hook is right.

### 4. Self-check
Hook complete by ~210 chars; length in band; hashtags 3-5 after body; zero em dashes / filler / cliches / AI-tells (double weight here, per the 23 Jul 2026 suppression); no first-person failure narrative (the brand is never the entity with the problem it solves); the beat-the-default test: would Campaign Manager plausibly have written this? If yes, it is not specific enough. Synthetic media attached: run the ai-disclosure skill (LinkedIn labels via C2PA).

### 5. Audit + ship
Content-auditor fresh context. At publish: `/content-learn record` with predicted out-of-network reach percentage vs the brand baseline (guard G1).

## Worked example (hook)

Suppressible: "In today's rapidly evolving AI landscape, developer productivity has never been more important. Here are my thoughts on agentic coding."
Distribution-worthy: "A client asked me why their agent ignored the coding rules they wrote for it. I opened the rules file: 412 lines. We cut it to 80. The agent started following it the same afternoon."

## Output format

```
LINKEDIN POST, {brand}

[post]

[hashtags]

Chars: {N} (hook complete at {N}). Beats: 4/4 present.
Beat-the-default check: PASS (what makes it un-generatable: {one line})
Voice anchor: pair {N}. Self-check: PASS. Auditor: PASS/FAIL.
Prediction: {predicted out-of-network % vs baseline} (recorded via /content-learn)
Vertical-video derivative recommended: {yes (UK/AU/CA market) / no}
```

## After completion

Log to production log. If the post performs above baseline at day-7, nominate its hook shape to approved patterns and queue the vertical-video derivative where the market has the feed.
