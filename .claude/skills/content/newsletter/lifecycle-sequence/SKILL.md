---
user-invocable: false
description: Produce a Email Lifecycle Sequence with structured process, quality checks, and system integration
version: 2.0.0
context: fork
---

# Email Lifecycle Sequence

## Purpose

Produce a comprehensive Email Lifecycle Sequence that delivers actionable, measurable, on-brand output. This skill provides a structured process with voice + format + brand-memory validation, ensuring agency-grade output every time.

**Category**: Newsletter

## Inputs

### Required
- **Brand**: which brand-memory file to read (`.claude/agent-memory/content-creator/brand-memories/{brand}.md`)
- **Topic / Brief**: the specific subject matter or strategist brief
- **Platform / Format**: target platform and any platform-specific format requirements

### Optional
- **Audience cut**: floor / middle / ceiling reader emphasis if different from brand default
- **Voice anchor**: which calibration paragraph pair to lean on most
- **Distribution plan**: derivatives expected (3-5 short-form pieces from one long-form)
- **Existing assets**: previous pieces in the same series for voice continuity

## System Context

Before starting:
- Read `.claude/knowledge-base.md` for the universal content rules (Voice & Tone, Format & Structure, Platform-Specific, Anti-Slop, Distribution, Measurement)
- Read `.claude/agent-memory/content-creator/brand-memories/{brand}.md` for voice anchors, ICP, banned phrases, signature phrases
- Read `.claude/agent-memory/content-creator/MEMORY.md` for approved patterns + watch list
- Check the most recently shipped piece for this brand for voice continuity

## Process

### Step 1: Context & Calibration
- Confirm the brand-memory file exists and has 3+ calibration paragraph pairs
- Read the calibration pairs and lock the voice anchor for this piece
- Confirm the platform's format rules from `knowledge-base.md` Platform-Specific section
- Review any active brand-specific bans + signature phrases (max 1 use per piece)

### Step 2: Structure & Outline
- Apply the format rules: hook in first N chars, body structure, closer pattern
- Outline beats (typically 3-5 for medium-form, 7-10 for long-form)
- Identify the specific moment / observation / insight that anchors the piece (no abstract preambles)
- Confirm the distribution plan: which derivatives this piece should generate

### Step 3: Draft
- Write the hook first — must establish stakes / promise / curiosity gap before truncation point
- Write the body — apply specific-over-generic rule (numbers, file paths, named tools)
- Write the closer — no padding ("And that's it!", "Hope this helps!" are banned)
- Sentence rhythm: mix short (under 10 words) with medium (15-25) with occasional long (30-40, never over 40)

### Step 4: Self-Check
- Em dashes count: must be zero
- Banned filler phrases: must be zero
- Marketing-cliché phrases (canonical + softer-cliché lists): must be zero
- AI-detector tells (delve, fast-paced world, etc.): must be zero
- Brand-specific banned phrases: must be zero
- Signature phrases: max 1 use
- Sentence length: longest under 40 words
- Paragraph length: no paragraph over 4 sentences in body

### Step 5: Hand-off to Auditor
- Produce structured handoff: draft + self-check verdict + voice anchor used + distribution plan
- The auditor runs in fresh context against the same rules + brand-memory
- If audit FAILS: apply fixes at root cause, re-self-check, re-submit
- If audit PASSES: output final + brand-memory update note

## Output Format

```
Email Lifecycle Sequence — {brand} — {platform}

Final draft:
[full content]

Voice anchor used: calibration pair {N} from {brand}
Self-check verdict: PASS
Auditor verdict: PASS

Distribution derivatives: [list if applicable]
Brand memory update: [new approved pattern logged, if any]

Next: publish OR /post {platform} for derivative
```

## Frameworks

This skill draws on:
- **Voice Calibration Pair Framework** — anchor every sentence against the brand's off-brand-vs-on-brand pairs
- **Specific-Over-Generic Rule** — numbers beat magnitudes, file paths beat "the config", named tools beat "your tool of choice"
- **Hook-Before-Truncation Principle** — establish stakes before any platform-specific truncation point
- **Distribution Multiplication** — every long-form piece generates 3-5 short-form derivatives

## Metrics

Track per piece:
- Self-check pass rate (target: 95%+ first try by piece 10)
- Auditor pass rate first try (target: 90%+ by piece 10)
- User approval rate (target: trending toward 95% by piece 10)
- Engagement signal (platform-specific: opens, clicks, forwards, saves)

## Best Practices

- **Voice is calibrated, never improvised.** Always read the brand-memory's calibration pairs before writing the first sentence.
- **The hook does the work.** A great hook with mediocre body outperforms a mediocre hook with a great body. Spend disproportionate time on the first 1-2 lines.
- **Specific beats generic, always.** If a sentence could survive find-replace from one brand to another with no edit, it's not specific enough.
- **Mobile-first.** 60%+ of email opens are mobile. 50%+ of social impressions. Render at 320px width before considering shipped.
- **Distribute or it didn't ship.** Long-form without derivatives reaches only on-platform audience. Distribution compounds reach.

## After Completion

- Update brand-memory with any new approved patterns this piece introduced (after 3 confirmations across pieces, patterns graduate)
- Log to `.claude/agent-memory/content-creator/MEMORY.md` production log with brand + platform + verdict + key voice patterns used
- If a new failure pattern was caught by the auditor: nominate it for `knowledge-base.md` promotion via `.claude/knowledge-nominations.md`
- Schedule distribution derivatives via `/post` or `/thread` for each derivative platform
