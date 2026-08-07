---
user-invocable: true
description: Produce a one-off broadcast email (announcement, promotion, update) for Beehiiv, Substack, or Resend. Use when asked to "send a broadcast", "announcement email", "email blast", "one-off email to the list", or "promo email". Covers the Jul 2026 Beehiiv expansion (programmatic ads, Community, Copilot), the API-first send path, deliverability, and email HTML rules.
version: 2.1.0
context: fork
---

# Broadcast Email

## Purpose

Produce a single broadcast (not a recurring issue) that gets delivered, opened, and acted on. Broadcasts are higher-stakes than issues: they interrupt the cadence the reader agreed to, so the value bar is higher and the length bar is lower.

## Platform record (dated)

- **Beehiiv's 16 Jul 2026 release** (its largest expansion): programmatic ads (auto-matched advertisers), Community channels with gated paid spaces, Copilot (context-aware AI assistant over your content/audience/performance), a new visual editor, Paid Trials, Group Subscriptions. Broadcast implications: decide the programmatic-ad-slot placement explicitly (or exclude ads from high-trust broadcasts like apology or incident emails); a Community channel post can replace a low-stakes broadcast entirely; and your editorial judgment must sit above Copilot: it optimizes within existing content and audience data, it cannot decide what the brand should say or whether this broadcast should exist. That judgment is the value this system sells. [Jul 2026]
- **Send path is API-first where the tier allows.** The Beehiiv V2 write-path integration pattern was published Jun-Jul 2026; manual paste is the free-tier fallback, not the default. Resend broadcasts are API-native. See `newsletter/send.js` header docs. [Jun-Jul 2026]
- **Substack:** Reply Rules for per-publication community guidelines (3 Jun 2026); automatic post translations (30 Jun 2026); Pangram AI labels + "How I make this" disclosure statements (22-23 Jul 2026), so AI-drafted broadcasts on Substack carry the honest disclosure posture from the ai-disclosure skill. [Jun-Jul 2026]
- **Deliverability:** full authentication (SPF/DKIM/DMARC, one-click unsubscribe) plus genuine value per send; Gmail's Gemini layer filters semantically before humans see mail (early 2026), so engagement decay is a deliverability alarm, not just a content note. [2026]

## Format rules

Subject max 50 chars; preview text max 110 and completes the subject's hook. Body: ONE message, one CTA, 150-400 words (a broadcast with three announcements is three broadcasts or one digest issue). Email HTML dialect: inline styles only, no `<style>`/`<script>`, table layout, HTML entities for non-ASCII, render at 320px. All house voice rules apply.

## Process

1. **Justify the interrupt.** State in one line why this cannot wait for the next scheduled issue. If the line is weak, it is not a broadcast.
2. **Draft:** subject (3 options) + preview + body with the single CTA above the fold. Segment note: who receives it (full list vs a segment vs a Community channel instead).
3. **Ad-slot decision:** programmatic slot on / off for this send, with the reason (trust-sensitive broadcasts exclude ads).
4. **Self-check:** one message only; subject/preview budgets; HTML dialect; zero em dashes / filler / cliches; unsubscribe present; AI-disclosure posture if the platform labels (Substack) or the content contains synthetic media.
5. **Audit + send:** content-auditor fresh context, then the API path (or paste fallback), then `/content-learn record` with predicted open rate vs the list's broadcast baseline.

## Worked example (subject + preview)

Subject: "Claudify update ships Friday" (30 chars)
Preview: "What changes for you, what does not, and the one step to take before then." (75 chars)

## Output format

```
BROADCAST, {brand}, {platform}

Interrupt justification: {one line}
Subject options: 1) ... 2) ... 3) ...  Preview: ...
[body]
Segment: {all / segment / Community channel instead}. Ad slot: {on/off + reason}.
Send path: {API (tier allows) / manual paste}. Self-check: PASS. Auditor: PASS/FAIL.
Prediction: {open rate vs broadcast baseline} (recorded via /content-learn)
```

## After completion

Log to production log. Broadcast open/click grades come back through the analyst; broadcasts that underperform the issue baseline twice tighten the interrupt-justification bar in the brand memory.
