---
user-invocable: true
description: Produce one complete newsletter issue through the gated pipeline. Use when asked to "write the newsletter", "draft this week's issue", "newsletter issue", "produce issue N", or when the rotation date arrives. Wraps the 9-phase /newsletter pipeline with the two-profile word budget, the HTML rules, and the send gate.
version: 2.1.0
context: fork
---

# Newsletter Issue Production

## Purpose

Ship one issue that clears every gate before a subscriber sees it. This skill is the map of the production system; the heavy lifting runs through `/newsletter` and its specialist agents. Use the skill directly when producing an issue outside the full pipeline (a brand without the foundations pack), and keep the same gate order.

## The system (what runs, in order)

The 9-phase pipeline (`/newsletter all N`): strategy, draft, architect, build, audit, render-test, preview, HALT for human review, send, analyse. Each phase runs a fresh-context specialist; every Task invocation is pinned `run_in_background: false` because the phases are strictly sequential (subagents background by default since Claude Code 2.1.198, Jul 2026).

Hard gates that never move:
- **Audit gate:** 26 mechanical + 13 semantic + regression checks (newsletter-auditor). The send step reads the verdict FILE, not an agent message.
- **Render gate:** 20 structural checks + Playwright at 4 viewports (stylist). Source-level audits cannot see rendering failures.
- **Human gate:** the user reviews the preview email and says ship. Never auto-send.
- **Prediction gate:** at send, write the issue's prediction_record (predicted open rate, day-7 date, prior 3-issue mean). Without it the analyst refuses to grade (contract guard G1).

## Format rules (the ones that bite)

- **Two-profile word budget:** issues WITH a god-tier prompt block target 900-1,200 words (hard cap 1,300, HTML under 80KB); issues WITHOUT target 600-900 (cap 1,000, HTML under 40KB preferred). Past 1,300 words even motivated readers skim.
- **Email HTML is its own dialect:** no `<style>` blocks (Beehiiv strips them on paste), no `<script>`, no flexbox/grid without table fallback, no inline SVG (Outlook breaks), all styles inline, HTML entities for non-ASCII (Beehiiv mojibakes raw UTF-8).
- **Subject max 50 chars; preview text max 110 chars** and it completes the hook the subject started.
- **Mobile first:** render at 320px before considering shipped; most opens are mobile.

## Platform notes (dated record)

- **Beehiiv's 16 Jul 2026 expansion** (its largest): programmatic ads, Community channels with gated paid spaces, Copilot, Paid Trials, Group Subscriptions. Templates carry a programmatic-ad-slot placement decision; Community prompts are a legitimate issue component; your editorial value sits above the built-in Copilot (it optimizes within your content; it cannot decide what your brand should say). [Jul 2026]
- **Send path is API-first where the tier allows** (Beehiiv V2 write integration pattern, Jun-Jul 2026); manual paste is the free-tier fallback. See `newsletter/send.js` header docs.
- **Substack publications:** automatic post translations (30 Jun 2026), the 6 Jul 2026 retention bundle (polls, scheduled Chats, Subscriber Perks, podcast RSS), Pangram AI labels + "How I make this" disclosure (22-23 Jul 2026). AI-drafted text with human editorial sign-off: log the sign-off (EU AI Act Article 50 applies 2 Aug 2026; see the ai-disclosure skill). [Jun-Jul 2026]

## Process (standalone use, no foundations pack)

1. **Brief:** topic, issue type in the rotation, the one takeaway, target profile (with or without prompt block).
2. **Draft:** voice per the brand memory; personal-moment opener; specific-over-generic throughout; sign-off per the brand's microcopy rule.
3. **Build + check:** render to HTML respecting the dialect rules above; word count against the right profile.
4. **Audit:** run the mechanical checks yourself if no newsletter-auditor exists for this brand (em dashes, banned lists, subject/preview lengths, link HTTPS + 200s, HTML size), then the semantic pass in a fresh look.
5. **Preview + human gate + send + prediction record.**

## Output format

```
NEWSLETTER ISSUE, {brand}, {NNN}

Profile: {with / without god-tier prompt}. Words: {N}/{cap}. HTML: {N}KB.
Gates: audit PASS, render PASS, human {pending/ship}, prediction_record {written}
Ad-slot decision: {position / none}. Community prompt: {included / n/a}
Send path: {API (tier allows) / manual paste}
```

## After completion

Day-of-send + day-7 analysis via the analyst (`/newsletter analyse N`). Register social derivatives of the issue via /repurpose so the teaser posts are tracked assets.
