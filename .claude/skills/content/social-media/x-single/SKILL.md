---
user-invocable: true
description: Write a single X (Twitter) post under 280 characters. Use when asked to "write a tweet", "X post", "single post for X", "tweet this", or for the daily-presence singles between threads. Covers the Jan 2026 Grok ranker, the late-May 2026 originality payout shift, and the Jun 2026 13x link cost.
version: 2.1.0
---

# X Single Post

## Purpose

Produce one X post that carries the brand's daily presence. Singles are the workhorse: the rotation is 3-4 singles per thread, so most of a brand's X voice lives here. One idea, fully landed, under 280 characters.

## Platform mechanics (dated record)

- **Grok-ranked feed since 20 Jan 2026** (legacy heuristics deleted): the ranker reads the post semantically and predicts dwell. A single wins on the strength of its one idea, not on formatting tricks. [Jan 2026]
- **Originality over aggregation:** payouts shifting to original authors away from repost accounts (rollout from late May 2026). A single that restates a popular take is invisible; a single with your own number or observation is the format the ranker now pays. [May 2026]
- **Links cost 13x via the API** ($0.20 vs $0.015 base, since 1 Jun 2026). A link-carrying single posted by automation states its cost; better pattern: post the idea clean, link in a reply. [Jun 2026]
- **Format:** 280 chars hard cap; the point lands in the first 180 chars (feed truncation); line breaks for rhythm; hashtags rarely (0-1, only when genuinely navigational).

## Process

### 1. Calibrate
Read knowledge-base.md, the brand memory (calibration pairs, bans, signature phrases), content-creator MEMORY (approved patterns, watch list). Lock the voice anchor.

### 2. Find the one idea
A single carries exactly one of: a specific observation ("most X do Y"), a number with context, a sharp reframe, a before/after, or a concrete tip with the artifact named. If the draft contains two ideas, save the second for tomorrow's single.

### 3. Draft three variants
Write the same idea three ways: observation-led, number-led, imperative-led. Pick the one whose first line hits hardest cold. (This is cheap at 280 chars and reliably upgrades the pick.)

### 4. Self-check
Under 280 chars; point complete by 180; zero em dashes, banned filler, cliches, AI-tells; brand bans respected; signature phrase max once; no engagement-bait ("agree?", "RT if"); link out of the primary post if automated; ai-disclosure skill if synthetic media is attached (X "Made with AI" toggle).

### 5. Audit + ship
Content-auditor in fresh context. On publish: `/content-learn record` with predicted dwell-proxy engagement vs the brand's singles baseline (guard G1).

## Worked example

Weak: "Context management is really important for AI coding agents. You should think about what's in your context window."
Strong: "Every broken agent session I have debugged this month had the same cause: a 400-line CLAUDE.md the model stopped reading at line 60. Shorter file, sharper agent."

Why: one idea, a number, a mechanism, a payoff, 160 chars to the point.

## Output format

```
X SINGLE, {brand}

[post text]

Chars: {N}/280 (point lands at {N} chars)
Variants considered: 3 (observation / number / imperative), picked: {which + why}
Voice anchor: pair {N}. Self-check: PASS. Auditor: PASS/FAIL.
Prediction: {predicted engagement vs baseline} (recorded via /content-learn)
```

## After completion

Log to production log. Track rotation position (singles since last thread); at 3-4, recommend the next thread topic from the backlog.
