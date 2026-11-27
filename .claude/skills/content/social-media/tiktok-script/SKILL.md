---
user-invocable: true
description: Write a TikTok video script with hook, retention beats, and delivery notes. Use when asked to "write a TikTok script", "TikTok video", "short-form video script for TikTok", or "script this for TikTok". Covers the Jul 2026 Shop LIVE AI-voice ban, the Account Health Rating, US vs global tracking, and completion-first structure.
version: 2.1.0
---

# TikTok Script

## Purpose

Script a TikTok that gets finished. Completion is the strongest available proxy for the ranker's favor (stated threshold figures like "70% completion" are third-party inference, not platform-confirmed; treat completion as directional, not a hard number). The script is written for spoken delivery, not for reading.

## Platform mechanics (dated record)

- **Shop LIVE bans AI delivery (~14-15 Jul 2026):** AI voices, AI audio, still-image slideshows, and looping footage are banned in shopping LIVEs. Violations dent the 0-1000 Account Health Rating (feature blocks at 150, freeze at 100, deactivation at 0). Any live-commerce script this skill produces assumes a HUMAN presenter, full stop. [Jul 2026]
- **US vs global run separately:** the US algorithm operates under the USDS joint venture since 22 Jan 2026. Track and baseline US performance separately from global. [Jan 2026]
- **AIGC labeling:** TikTok invisible-watermarks AI content and auto-labels realistic AI media (14 Jul 2026); self-apply the AIGC label on any realistic AI visuals or audio in regular (non-LIVE) posts, via the ai-disclosure skill. [Jul 2026]
- **First-party trend source:** the "TikTok Next" 2026 trend forecast (published 8 Jul 2026) is a legitimate research input for topic angles; branded mini-dramas are a platform-named format. [Jul 2026]

## Process

### 1. Calibrate
Read knowledge-base.md, brand memory, content-creator MEMORY. Confirm: regular post or live-commerce (different rules, above), US or global audience (different baselines).

### 2. Script structure (timed beats)
- **0-2s (hook):** the claim or visual tension, spoken in the first breath. No intros, no "hey guys". Write 2-3 hook options.
- **2-8s (commitment):** why staying pays: name the payoff and the structure ("three fixes, fastest first").
- **8s to ~80% (body):** one point per beat, each 5-15s, each ending on a mini-open-loop. Cut every sentence that does not advance; dead seconds kill completion.
- **Final 10-15% (payoff + loop):** land the promised payoff. Optionally loop the last line back into the hook (rewatches count).
- **On-screen text notes:** per beat, max 8 words per overlay, readable at arm's length.

### 3. Delivery notes
Write for the mouth: short sentences, contractions, no subclauses. Mark emphasis words. Note b-roll or demo moments per beat. For live-commerce: human presenter, live camera, no slideshows or loops (the Jul 2026 ban list).

### 4. Self-check
Hook lands inside 2s of speech (~6 words); every beat has a forward pull; script reads aloud in the target duration (test: ~150 words per minute); zero em dashes / filler / cliches; AI visuals or voice in a regular post: AIGC label step included via ai-disclosure; live-commerce: ZERO AI audio/voice/slideshow/loop elements; no AI persona giving finance/legal/health advice anywhere (cross-platform hard rule).

### 5. Audit + ship
Content-auditor fresh context. At publish: `/content-learn record` with predicted completion-proxy vs the brand's TikTok baseline for the right region (US or global).

## Worked example (hook options, topic: agent rules files)

1. "Your AI assistant ignored your rules again? I found out why."
2. "I deleted 300 lines of my AI config and it got smarter."
3. "This one file is why your coding agent keeps going rogue."

## Output format

```
TIKTOK SCRIPT, {brand}, {duration}s, {regular / live-commerce}, {US / global}

Hooks (pick one): 1) ... 2) ... 3) ...
[timed beats: timestamp, spoken line, on-screen text, b-roll note]

Read-aloud time: {N}s. Completion pulls: {N} open loops.
Live-commerce compliance: {n/a / human-delivery confirmed}
AIGC label: {not needed / self-apply, per ai-disclosure}
Self-check: PASS. Auditor: PASS/FAIL.
Prediction: {completion-proxy vs baseline} (recorded via /content-learn)
```

## After completion

Log to production log with the region tag. Hooks that beat baseline get nominated to the brand's hook bank.
