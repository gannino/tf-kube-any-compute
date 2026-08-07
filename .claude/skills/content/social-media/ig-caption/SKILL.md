---
user-invocable: true
description: Write an Instagram caption engineered for sends and watch time. Use when asked to "write an IG caption", "Instagram caption", "caption for this post", or "caption this Reel". Covers the Jul 2026 main-feed ranking recipe (watch time, sends-per-reach, likes-per-reach), the Jun 2026 originality enforcement, and hashtag mechanics.
version: 2.1.0
---

# Instagram Caption

## Purpose

Write a caption that does two jobs the visual cannot: earns the 3-second hold, and gives someone a reason to SEND the post to a specific friend. Sends-per-reach is the metric this skill optimizes and the metric the analyst grades it on.

## Platform mechanics (dated record)

- **The Reels ranking recipe now ranks the main feed (Jul 2026):** watch time first, then sends-per-reach, then likes-per-reach. Third-party estimates weigh a DM share around 15 likes and a save around 10. Every caption engineers a send moment: a line someone forwards because it names a person they know ("send this to whoever maintains your CLAUDE.md"). [Jul 2026]
- **Originality enforcement (Jun 2026):** aggregator-style reposts deprioritized; users can remove reposts of their content. Captions on repurposed content must add original value, not relocate it. [Jun 2026]
- **Caption mechanics:** hook complete before the ~125-char truncation ("more" fold); 5-15 hashtags at the end or in the first comment; over 30 hashtags is a downranking signal.
- **Caption adds unique value, never restates the visual** (house hard rule): if the image already says it, the caption carries the story, the number, or the context the image cannot.

## Process

### 1. Calibrate
Read knowledge-base.md, brand memory, content-creator MEMORY. Confirm what the visual already communicates so the caption does not duplicate it.

### 2. Structure
- **Line 1 (pre-truncation hook):** the payoff or tension in under 125 chars. It must work standing alone in the feed.
- **Body (2-5 short paragraphs):** the story or mechanism behind the visual. Specifics: numbers, named tools, before/after.
- **Send moment:** one line that targets a person type ("send this to the teammate who...", or a claim so counterintuitive it begs to be forwarded). This is a structural element, not a nice-to-have, per the Jul 2026 recipe.
- **CTA (max one):** save, comment prompt, or follow; sends outrank likes, so prefer the send moment as the primary ask.
- **Hashtags:** 5-15, end of caption or first comment, mixed reach tiers.

### 3. Self-check
Hook under 125 chars and complete; send moment present; caption does not restate the visual; zero em dashes / filler / cliches / AI-tells; brand bans; signature phrase max once; hashtag count 5-15; if the visual is AI-generated, run the ai-disclosure skill (Meta "AI info" is C2PA-detected since 1 Jun 2026; pre-disclose rather than get flagged).

### 4. Audit + ship
Content-auditor fresh context. At publish: `/content-learn record` with predicted sends-per-reach vs the brand baseline (guard G1).

## Worked example (hook + send moment)

Weak hook: "Some thoughts on why AI coding assistants lose context over long sessions."
Strong hook: "Your AI assistant forgot your rules by lunchtime. Here is the 80-line fix."
Send moment: "Send this to whoever owns the 400-line CLAUDE.md on your team."

## Output format

```
IG CAPTION, {brand}

[caption]

[hashtags]

Hook: {N}/125 chars. Send moment: present ({quote it}).
Restate-the-visual check: PASS. Self-check: PASS. Auditor: PASS/FAIL.
AI disclosure: {not needed / disclosed via ...}
Prediction: {predicted sends-per-reach vs baseline} (recorded via /content-learn)
```

## After completion

Log to production log. If sends-per-reach beats baseline at day-7, nominate the send-moment construction to approved patterns.
