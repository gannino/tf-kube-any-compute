---
user-invocable: true
description: Create or repair a brand's voice calibration pairs so voice locks across sessions. Use when asked to "calibrate my voice", "set up brand voice", "the voice feels off", "make it sound like me", or when a brand memory lacks its 3+ calibration pairs. Covers pair construction, the four scoring dimensions, versioning, and the monthly drift report handshake.
version: 2.1.0
---

# Voice Calibration

## Purpose

Lock a brand's voice across sessions using calibration paragraph pairs: the same paragraph written off-brand and on-brand. The contrast does what abstract style guides cannot; "be conversational but professional" fails, wrong-vs-right examples anchor. Every brand needs 3+ pairs before any production runs (the creator HALTs without them), and since Jul 2026 voice discipline is also distribution strategy: LinkedIn actively suppresses generic AI-pattern voice (23 Jul 2026), and X's Grok ranker scores semantic originality (Jan 2026).

## What a good pair looks like

Each pair holds the SAME content in two voices, and the off-brand version must be plausible: the thing a competent generic writer would produce, not a strawman.

Pair (specificity dimension):
- Off-brand: "Our tool helps developers work more efficiently with AI assistants by managing configuration effectively."
- On-brand: "Your agent stopped reading your rules file at line 60. Cut it to 80 lines and it started listening the same day."

The three canonical pair types (from CLAUDE.local.md setup): the marketing-department pair (corporate voice vs the real voice), the hedging pair (qualified mush vs direct claims), the framing pair (brand-as-problem-haver vs outside-observer authority).

## The four scoring dimensions

Every review scores drafts against the pairs on: **tone** (hedged vs direct, generic vs specific), **rhythm** (sentence-length mix; short-punch vs long-flow), **vocabulary** (brand words vs generic words; the ban lists), **consistency** (no drift mid-piece). These are the same four dimensions brand-voice-keeper scores in the monthly drift report, so calibration and drift measurement stay commensurable.

## Process

### Creating calibration (new brand)
1. Collect raw material: 3-5 pieces the user considers most "them" (posts, emails, anything), plus 1-2 they hated.
2. Extract the signature moves: recurring sentence shapes, characteristic openings, vocabulary, what they never do.
3. Build 3-5 pairs: take real paragraphs from the loved pieces as the on-brand half; write the plausible generic version as the off-brand half. One pair per dimension weakness the raw material reveals.
4. Write to the brand memory (via the _TEMPLATE structure): pairs, ICP (floor/middle/ceiling reader), brand-specific bans, signature phrases (rationed, max once per piece). Stamp `Voice spec version: 1 ({date})`.
5. User reviews and edits the pairs; their edits are the highest-signal calibration data of all, captured verbatim.

### Repairing calibration (voice "feels off")
1. Diagnose which dimension drifts: quote 2-3 recent sentences and name the drift (hedging returned, vocabulary went generic, rhythm flattened).
2. Add ONE new pair built from the drifted sentence (as off-brand) and its fixed version (as on-brand). Targeted pairs beat rewriting the set.
3. Bump the voice spec version with a dated note of what changed and why.

### Maintenance handshake
The monthly drift report (`/audit voice {brand}`, run by brand-voice-keeper) scores shipped pieces against these pairs; two DRIFTING months trigger a recalibration proposal, which lands back in this skill's repair procedure. Patterns need 3 confirmations to graduate to approved, 2 rejections to hit the watch list; the pairs themselves change only with user approval.

## Self-check

3+ pairs present; each pair same-content-two-voices (not different content); off-brand halves plausible; all four dimensions covered across the set; version stamped; ICP + bans + signature phrases populated; zero em dashes anywhere including inside on-brand examples.

## Output format

```
VOICE CALIBRATION, {brand}, spec version {N}

Pairs: {N} (dimensions covered: tone / rhythm / vocabulary / consistency)
[the pairs]
ICP: floor / middle / ceiling defined. Bans: {N}. Signature phrases: {N}.
Written to: brand-memories/{brand}.md
Next: production unblocked; first drift report due {date + 1 month}
```

## After completion

Log creation/repair to brand-voice-keeper MEMORY. The pairs are now the reference for every draft's Stage 2 calibration and every audit's S4 voice-consistency check.
