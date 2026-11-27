---
user-invocable: true
description: Set or revise a newsletter's strategy: platform choice, cadence, rotation, growth and retention systems, monetization posture. Use when asked "which newsletter platform", "newsletter strategy", "grow my newsletter", "should I use Beehiiv or Substack", or "plan my newsletter". Carries the dated Jul 2026 Beehiiv expansion and the Jun-Jul 2026 Substack retention bundle.
version: 2.1.0
context: fork
---

# Newsletter Strategy

## Purpose

Decide what the newsletter is FOR, where it lives, and which platform surfaces it uses, before any issue is produced. Strategy revisions are dated and versioned in the brand memory; the strategist agent reads this skill when planning rotations.

## Platform picture (dated record, Jun-Jul 2026)

**Beehiiv (16 Jul 2026 release, its largest expansion ever):**
- **Programmatic ads:** auto-matched advertisers. Strategy call: which sends carry the slot, which never do. Ad revenue becomes a secondary analyst metric where enabled.
- **Community channels + gated paid spaces:** a new deliverable class between issues; low-stakes updates move to a channel post instead of interrupting the inbox.
- **Copilot:** a context-aware assistant over your content, audience, and performance data. Positioning line, stated with its reasoning: your editorial value sits ABOVE the built-in Copilot, because Copilot optimizes within what exists (subject variants, resend timing) while the strategy layer decides what the brand should say, to whom, and why now. A newsletter operation whose only value is Copilot-level optimization is replaceable by the free feature.
- **Paid Trials + Group Subscriptions:** new monetization surfaces for paid tiers; trials suit high-conviction archives, group subs suit team-tool topics.
- Beehiiv V2 API write path where the tier allows it (published integration pattern, Jun-Jul 2026); manual paste is the free-tier fallback.

**Substack (June-July 2026 wave):**
- **Reply Rules** (3 Jun 2026): per-publication community guidelines; set them at launch, not after the first incident.
- **Automatic post translations** (30 Jun 2026): the localization barrier is gone; non-English audience segments become reachable without workflow changes.
- **The 6 Jul 2026 bundle:** polls, scheduled Chats, Subscriber Perks, saved Notes, richer formatting, podcast RSS distribution. Script polls and Chats into the retention playbook (a monthly poll and a scheduled Chat are cheap retention events).
- **MCP support** for publication analytics: publication data exposed to AI tools, so analytics can flow to the analyst through it where the customer has it configured (documented path; automation of the ingestion is a later step).
- **Pangram AI labels + "How I make this" disclosure** (22-23 Jul 2026): fill the disclosure statement honestly once; it covers the standing process. See the ai-disclosure skill.

**Resend:** API-native, no platform features; right when the newsletter is an owned-audience channel attached to a product and the platform features above are noise.

## Strategy decisions this skill produces

1. **Job statement:** the one sentence the newsletter does for the reader (and the business metric it feeds).
2. **Platform choice** against the record above: Beehiiv when monetization surfaces and Community matter; Substack when network discovery, translations, and the retention bundle matter; Resend when it is a product channel.
3. **Cadence + rotation:** issue types on a rotation the strategist can execute (the foundations pack pattern); cadence the operator can sustain for 6 months.
4. **Retention system:** which platform surfaces are scripted in (polls, Chats, Perks, Community posts) and on what rhythm.
5. **Monetization posture:** free / ads / paid / trials, with the trigger conditions for changing it (e.g. paid tier only after k issues and a stable open-rate baseline).
6. **Measurement:** open rate stays the primary metric (analyst contract); ad revenue and Community engagement are secondary where enabled.

## Process

1. Read the brand memory + any existing newsletter memory. State the current strategy version (or "none").
2. Work the six decisions above; every recommendation carries its dated platform fact.
3. Write the strategy block to the brand memory, versioned and dated. Revisions supersede with a reason (contract guard G6 pattern).
4. Hand the rotation to the strategist agent / `/newsletter next`.

## Output format

```
NEWSLETTER STRATEGY, {brand}, version {N} ({date})

Job: {one sentence}
Platform: {choice + the dated facts that decided it}
Cadence + rotation: {...}
Retention surfaces: {...}  Monetization: {...}
Metrics: primary open rate; secondary {ad revenue / community / none}
Supersedes: {version N-1 note, or "initial"}
```

## After completion

Log to strategist MEMORY. Revisit on a quarterly rhythm or when a platform ships a change of the Jul-2026-Beehiiv magnitude; the /intel-class ecosystem scans and the analyst's quarterly review are the triggers.
