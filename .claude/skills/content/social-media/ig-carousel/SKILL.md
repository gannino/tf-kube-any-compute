---
user-invocable: true
description: Design an Instagram carousel (slides + captions) for saves and sends. Use when asked to "make a carousel", "IG carousel", "multi-slide post", "slide deck for Instagram", or when a topic has 3+ distinct points. Covers the Jul 2026 watch-time feed recipe, the Jun-Jul 2026 per-slide caption rollout, and the swipe-through structure.
version: 2.1.0
---

# Instagram Carousel

## Purpose

Design a carousel that holds attention slide by slide (watch time now ranks the main feed, Jul 2026) and lands in Saved folders. Carousels are the save-and-send format: each swipe is a retention event the ranker counts.

## Platform mechanics (dated record)

- **Watch time first (Jul 2026):** the main feed now uses the Reels recipe (watch time, sends-per-reach, likes-per-reach). For a carousel, watch time = swipe-through. Every slide must earn the next swipe. [Jul 2026]
- **Per-slide captions rolling out Jun-Jul 2026:** individual captions per carousel slide are rolling out, which changes the single-caption data model. Produce a per-slide caption set alongside the main caption; flag that availability varies by account (rollout in progress, do not assume). [Jun-Jul 2026]
- **Originality enforcement (Jun 2026):** aggregator-style carousels (quote compilations, screenshot dumps of others' content) are deprioritized and the payout logic across platforms now favors original authors. Build from your own material. [Jun 2026]
- **Format:** 4:5 aspect, 3-10 slides (6-8 is the sweet spot), text on slides readable at mobile width (render check at 320px), main caption per the ig-caption skill.

## Process

### 1. Calibrate
Read knowledge-base.md, brand memory (including visual style), content-creator MEMORY.

### 2. Slide architecture
- **Slide 1 (the stop):** one claim, huge type, under 12 words. It competes in the feed alone.
- **Slide 2 (the commitment):** frame the problem or promise the payoff structure ("4 patterns, worst last"). This slide decides swipe-through.
- **Slides 3 to N-1 (one idea per slide):** each slide states its point in the headline and proves it in one supporting line or artifact. A reader who screenshots any single slide gets complete value. End each slide with a forward pull (an open loop the next slide closes).
- **Slide N (the landing):** payoff summary + save prompt ("save this for your next session") + send moment ("send to the teammate who..."). Saves ~10 likes, DM shares ~15 likes in third-party weightings of the Jul 2026 recipe.

### 3. Caption set
- **Main caption:** per the ig-caption skill (hook under 125 chars, send moment, 5-15 hashtags).
- **Per-slide captions (rollout-aware):** one line per slide extending, never restating, the slide text. Delivered as a numbered list the user applies if their account has the feature.

### 4. Self-check
Slide 1 under 12 words; one idea per slide; every slide readable at 320px; open-loop pull present between slides; save prompt + send moment on the final slide; caption set complete; zero em dashes / filler / cliches / AI-tells anywhere including slide text; AI-generated slide art: run the ai-disclosure skill (Meta detects via C2PA since 1 Jun 2026).

### 5. Audit + ship
Content-auditor fresh context (slides + captions). At publish: `/content-learn record` with predicted sends-per-reach (primary) and saves (secondary) vs the carousel baseline.

## Worked example (slides 1-3 headlines)

Topic: why agent instruction files decay.
- Slide 1: "Your agent stopped reading your rules."
- Slide 2: "4 decay patterns from 30 audited setups. The worst one is last."
- Slide 3: "Pattern 1: the 400-line file. Agents skim past line 60. Fix: cut to one screen."

## Output format

```
IG CAROUSEL, {brand}, {N} slides

Slide-by-slide: [headline + support line + visual note per slide]
Main caption: [caption + hashtags]
Per-slide captions (apply if your account has the rollout): [numbered list]

Swipe-pull check: every slide has a forward pull. 320px render: PASS.
Self-check: PASS. Auditor: PASS/FAIL.
Prediction: {sends-per-reach + saves vs baseline} (recorded via /content-learn)
```

## After completion

Log to production log. Carousels that beat the save baseline become the template for the next carousel in the series; register derivatives (e.g. the thread version) via /repurpose.
