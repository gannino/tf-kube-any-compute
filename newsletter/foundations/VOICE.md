# Voice Bible — Claudify Weekly

How the newsletter sounds when it's right. Read by the drafter, the auditor, and the prompt-architect on every issue. The goal: by issue 12, a subscriber should be able to identify a Claudify Weekly paragraph by voice alone, no header needed.

This file gates every sentence. If a sentence reads wrong against this bible, it doesn't ship.

---

## The voice in one sentence

**Direct, specific, personal — like a senior engineer telling you something useful at the pub, not a marketing department telling you something motivational.**

---

## Hard bans (these never appear in a Claudify Weekly issue, ever)

These are non-negotiable. The auditor blocks any of them. No exceptions.

### 1. Em dashes (—)

The writer's hard rule, system-wide. Em dashes never appear in any output. Use commas, full stops, parentheses, or restructure the sentence.

> ✗ "The fix wasn't another rule — it was making CLAUDE.md write itself."
> ✓ "The fix wasn't another rule. It was making CLAUDE.md write itself."

### 2. Filler phrases that add no meaning

| Banned | Why | What to do instead |
|---|---|---|
| "Simply" | Implies the reader is dumb if they don't get it | Just delete it. The instruction stands without it. |
| "Just" (as filler) | Same as "simply" | Delete or rephrase |
| "Obviously" | Condescending — if it were obvious, you wouldn't be writing about it | Delete |
| "As you know" | Presumptuous; alienates anyone who doesn't | Delete or rephrase as "If you've used X..." |
| "It's worth noting that" | Pure filler before the actual point | Cut the preamble; lead with the point |
| "Note that" | Same as above | Cut |
| "Of course" | Same as "obviously" | Cut |
| "Basically" | Hedging | Cut, or commit to the precise statement |
| "In conclusion" | Newsletter is not an essay | Cut |
| "Without further ado" | Lazy throwback | Cut |
| "I'd argue that" | Hedging — if you're arguing it, just state it | Drop the hedge, state the position |
| "Some would say" | Vague attribution — name names or speak yourself | Replace with concrete attribution or cut |

### 3. Internet shorthand and acronyms

Audience floor doesn't recognise these. Never use without expanding:

- TL;DR → use "The gist" or "In short"
- FWIW, IIRC, IMO, IMHO → spell out or cut
- CRUD, REST, RPC → only if defined inline or already established in the issue
- DRY, KISS, YAGNI → only with brief inline gloss

### 4. Marketing voice

These give off "the marketing team wrote this" energy and tank trust.

**Canonical marketing clichés (always banned):**

- "Game-changer"
- "Revolutionary"
- "Cutting-edge"
- "World-class" (in body text — fine in internal docs)
- "Best-in-class"
- "Unlock the power of..."
- "Take your X to the next level"
- "Supercharge your workflow"
- "Mind-blowing"

**Softer marketing clichés that slip into operational / CTA / closer copy (also banned):**

These are the ones that sneak in at the bottom of an issue when something is being promoted (referral mechanic, signup, forward CTA). They sound less obvious than the canonical list but carry the same "marketing department" energy.

| Banned | Why | What to do instead |
|---|---|---|
| "Grandfathered in" | Cliché; vague benefit | Specify exactly what carries forward ("forwards from this week count toward your first unlock") |
| "When it goes live" | Vague aspiration; the thing is already running narratively | Specify the trigger ("when the vault opens at 100 subscribers") |
| "Once we launch" | Same as above | Specify the date or threshold |
| "When we go live" | Same | Specify |
| "Lifetime access" (promotional) | Too marketing-cliché in promotional context | "Permanent" or describe what's permanent ("the prompt stays in your account forever") |
| "Early access" (promotional) | Same | Specify the actual privilege |
| "VIP access" | Same | Reframe with concrete benefit |
| "Get in early" | Same | Specify the early-mover benefit |
| "Limited time only" | Cliché; usually false | State the actual deadline or skip |
| "Don't miss out" | Manipulation language | Drop |
| "Act now" | Same | Specify the action and the reason |

The pattern: any operational copy promoting something (the godly prompt, a signup, a forward) must use **specific, concrete, action-oriented language**, not stock marketing clichés. See MISTAKE-021 in `foundations/MISTAKES-LOG.md`. The auditor's M6 check enforces this expanded list.

### 5. Vague aspirational claims

Claims with no measurable substance:

- "AI will change how we code." (so what?)
- "Claude Code is a paradigm shift." (cite the shift, with metrics)
- "This pattern is incredibly powerful." (define how powerful, in what unit)

If the claim can't be backed by a specific example, file reference, or before/after measurement, it doesn't belong.

### 6. Sentence-starters that delay the point

| Banned opener | Why |
|---|---|
| "So..." (at sentence start) | Conversational filler |
| "Well..." | Same |
| "Now..." | Same |
| "Look..." | Manipulative — implies you've earned the right to lecture |
| "Here's the thing:" | Almost always followed by something not worth the buildup |
| "Let me tell you..." | Cringe |
| "First and foremost" | Just say "first" |

### 7. Closers that pad

Padding at the end of sections:

- "And that's it!"
- "Hope this helps!"
- "Happy coding!"
- "Until next time..."
- Anything with a smiley face emoji or exclamation point that wasn't earned

The closer is the sign-off block ("Until next Tuesday"). Body sections end on the substance, not on a pleasantry.

### 8. First-person failure narratives (the writer / Claudify as the entity with the problem)

Claudify is the product. The newsletter exists to position it as the solution. If the writing frames the writer or Claudify as the entity currently hitting the failure mode the issue addresses, we (a) imply Claudify hasn't solved it yet, (b) undermine the authority the newsletter is built to establish. **The newsletter voice is the diagnostician who has seen the pattern across many users, never the practitioner currently breaking.**

Always observe problems from the outside. Use third-person observation or pattern-recognition framing. Personal voice is allowed when it positions the writer as the one who applies the solution (authority), not as the one who has the failure (vulnerability).

| Banned framing | Why it fails | What to do instead |
|---|---|---|
| "I caught Claude rediscovering X" | The writer is the one whose tool keeps failing | "Talk to anyone running Claude Code daily and the same pattern surfaces" |
| "I'd told it twice" | Admits the writer failed to make the instruction stick | "By the fourth session, Claude has rediscovered something CLAUDE.md was supposed to handle" |
| "My system breaks when X" | Implies Claudify hasn't solved X | "A pattern most Claude Code users hit by month two: X" |
| "I keep having to do Y" | Operator failure narrative | "Most Claude Code users notice they keep doing Y" |
| "I tried this and it didn't work" | Failure attribution | "The naive version of this fails because Z" |

| Allowed framing | Why it works |
|---|---|
| "I run this prompt every month" | Authority — the writer as practitioner of their own technique |
| "I've used this on dozens of CLAUDE.md files" | Authority — the writer as someone with broad usage data |
| "I noticed a pattern across our customers" | Diagnostician — the writer observing many users |
| "Talk to anyone running Claude Code daily" | Authority — the writer as the consultant who hears from many |
| "Every Claude Code user notices it eventually" | Universal observation — the writer states a categorical claim |

Acid test: if a paragraph were quoted in isolation, would a competitor agency point to it as evidence that the writer's setup keeps breaking? If yes, reframe.

> ✗ "Last Tuesday I caught Claude rediscovering, for the fourth session in a row, that this codebase uses tabs, not spaces. I'd told it twice."
> ✓ "Talk to anyone running Claude Code daily and the same pattern surfaces: by the fourth session, Claude has rediscovered something CLAUDE.md was supposed to handle."

See MISTAKE-020 in `foundations/MISTAKES-LOG.md`. The auditor's S13 check enforces this at every audit.

---

## Preferred patterns

Use these. They're the spine of the newsletter's voice.

### 1. Personal moment openers

The first sentence of the intro is a specific moment. Concrete time marker, concrete observation, concrete frustration or insight.

> ✓ "Last Tuesday I caught Claude rediscovering, for the fourth session in a row, that this codebase uses tabs, not spaces."
> ✓ "I shipped 14 commits to a side project this weekend. None of them needed a code review from a human."
> ✓ "Three weeks ago I built a hook that broke my Stop event silently for 11 sessions before I noticed."

The opener is never abstract ("AI is changing development...") and never preamble ("In this issue we'll explore..."). It's a specific thing that happened.

### 2. Numbered, specific claims

Real numbers beat vague magnitudes every time.

> ✗ "This saves a lot of time."
> ✓ "This saves about 30 minutes per session."

> ✗ "It's pretty fast."
> ✓ "Takes 2 seconds. Was taking 14."

> ✗ "Most CLAUDE.md files are bloated."
> ✓ "Most CLAUDE.md files are 70% noise."

If a number is genuinely unknown, say "I don't know how much" rather than make one up. Honesty about uncertainty beats false precision.

### 3. Active voice and direct instruction

> ✗ "It is recommended that the hook be added to the settings file."
> ✓ "Add this hook to settings.json."

> ✗ "The flag should be passed when invoking the command."
> ✓ "Pass the flag when you run the command."

> ✗ "This pattern can be used to..."
> ✓ "Use this pattern to..."

Imperative mood for instructions. Indicative mood for explanations. Never passive unless the actor is genuinely irrelevant.

### 4. Specific over generic, always

| Generic | Specific |
|---|---|
| "Edit your config file" | "Edit `.claude/settings.json`" |
| "Use a faster tool" | "Use `ripgrep` instead of `grep`" |
| "There's a flag for this" | "Pass `--output-format json`" |
| "Modern editors handle this" | "VS Code, Cursor, and Windsurf handle this" |
| "Some developers prefer..." | "I've seen most teams default to..." |

The cost of specificity is mild brittleness (named tools change, versions update). The cost of vagueness is total signal loss. Specificity wins.

### 5. Short sentences for emphasis

Mix sentence lengths. Long sentences carry nuance and explanation. Short sentences land the point.

> ✓ "Claude Code reads CLAUDE.md at the start of every session, parses your project setup, and silently shapes every response that follows. That makes the file load-bearing. Most people treat it as an afterthought."

The "Most people treat it as an afterthought" punches because the previous sentence was long. Same content, all-medium-length, would feel flat.

### 6. Honest acknowledgement when something's a trade-off

> ✓ "This adds 200ms to your session start. For most people, worth it. If your sessions are already slow, skip this."

The newsletter doesn't pretend every technique is universally good. Real engineers respect "here's the trade-off."

### 7. Lead with the surprising / counter-intuitive

If a tip is unsurprising, the issue probably isn't worth shipping. When the tip IS surprising, lead with the surprise.

> ✓ "Stop hooks are usually used for safety checks. The most useful thing they actually do is teach Claude to remember things between sessions."

> ✓ "Most CLAUDE.md improvements come from cutting, not adding."

The reader's "huh, that's not what I expected" reaction is the click that earns the rest of the issue.

---

## Calibration paragraphs

Read these side-by-side to internalise the difference.

### Calibration 1 — The intro paragraph

**Off-brand (marketing voice):**
> *In today's fast-moving AI landscape, getting the most out of tools like Claude Code can feel overwhelming. There are countless tips and tricks to learn, and it can be hard to know which ones will actually move the needle. That's why we're excited to share this week's tip — a simple but powerful technique that will revolutionize how you work with Claude.*

**Why it fails:** generic preamble, vague aspiration, "excited to share" filler, "revolutionize" + "powerful" without backing, "countless tips" is meaningless.

**On-brand:**
> *Last Tuesday I caught Claude rediscovering, for the fourth session in a row, that this codebase uses tabs, not spaces. I'd told it twice. The fix wasn't another rule. It was making CLAUDE.md write itself.*

**Why it works:** specific time marker, specific observation, specific frustration, ends on the technique. 36 words vs 67. More information.

### Calibration 2 — The instruction

**Off-brand:**
> *Now, in order to implement this technique, what you'll want to do is navigate to your `.claude/settings.json` file and carefully add the following configuration. It's worth noting that this should be done with care, as malformed JSON can cause issues.*

**Why it fails:** "Now... what you'll want to do is" delays the point, "carefully" is unnecessary, "it's worth noting" is filler, "with care" is redundant.

**On-brand:**
> *Open `.claude/settings.json` and add this. JSON is whitespace-tolerant but punctuation-strict; if it breaks, you missed a comma.*

**Why it works:** direct instruction, real warning about the failure mode, no padding.

### Calibration 3 — The trade-off

**Off-brand:**
> *This pattern is amazing and you should definitely use it on every project!*

**Why it fails:** unbacked claim, false universal recommendation, exclamation point.

**On-brand:**
> *Use this pattern when your sessions span multiple files and you keep forgetting where things are. Skip it on small one-off scripts where the overhead isn't worth it.*

**Why it works:** named the use case, named the non-use case, no hype.

---

## Microcopy rules (small text, big impact)

The labels, button text, and small connectors carry voice too. These are the most-overlooked surfaces and the easiest places to drift.

### Section labels

| Banned | Use instead |
|---|---|
| "TL;DR" | "The gist" |
| "Disclaimer" | (don't use disclaimers in body content) |
| "Pro tip" (only when actually advanced) | Keep "Pro tip" but RESERVE for genuine advanced techniques |
| "Hot take" | (don't use; reserve for X/Twitter) |
| "FYI" | Replace with the actual information |

### Buttons and CTAs

| Banned | Use instead |
|---|---|
| "Click here" | A description of what's there, made into a link |
| "Learn more" | "Read the deep dive →" or specific descriptor |
| "Get started" | "Open the system", "Run /start", or specific action |

### Closers and connectors

| Banned | Use instead |
|---|---|
| "And that's it!" | (just end on the substance) |
| "I hope this helps!" | (just end on the substance) |
| "Happy coding!" | (just end on the substance) |
| "Until next time" | "Until next Tuesday" |

### Sign-off

The newsletter sign-off is fixed: **"Until next Tuesday"** on a single line. No variations week to week. Consistency builds the ritual.

---

## Tone calibration scale

Where each part of the newsletter sits on the casual ↔ precise spectrum:

| Section | Tone | Why |
|---|---|---|
| Subject line | Direct, no-frills | Inbox is competitive; survival depends on clarity |
| Headline (TIP_HEADLINE) | Specific, outcome-focused, occasional voice flourish | The reader's "is this for me?" decision happens here |
| The gist (TLDR) | Stripped to essentials | The skim reader's escape route |
| TIP_INTRO | Personal, warm, specific moment | The hook |
| TIP_BODY (THE SETUP / TECHNIQUE / RESULT) | Procedural, instructional | The reader is following along; clarity > personality |
| Deep dive | Functional, link-led | Subordinate signal — point them to depth |
| Pro tip | Confident, slightly more advanced vocabulary | Ceiling reader's reward |
| Quick win | Compressed, sharp | Low-effort high-value beat |
| What I'm reading | Personal, opinionated, light | The writer's aside; this is where personality lives |
| Reply ask + sign-off | Direct, sincere | The relationship moment |
| Coming next Tuesday | Curiosity-led, plain | Anticipation builder |
| Footer | Functional, ignored by most | Compliance layer |

The newsletter has range. The middle (procedural sections) is more buttoned-up. The edges (intro, sign-off, what I'm reading) are warmer. This rhythm is intentional.

---

## Voice consistency rules (every issue)

These are checks the auditor runs on every issue:

1. **First-person consistency.** The newsletter is written in a single first-person voice. Use "I", not "we", except in places where "we" genuinely refers to the team or community.
2. **No corporate "us".** "Reach out to us" → "Reply to me". "Our system" → "Claudify" or "the system".
3. **Don't break the fourth wall in the body.** The reader is the reader. Don't address them as "subscribers" or "readers". Use "you" or skip.
4. **Tense consistency.** Personal anecdotes in past tense. Instructions in imperative present. Technical explanations in indicative present. Don't mix mid-paragraph.
5. **One voice per issue.** If the body sounds like the writer and the god-tier prompt sounds like a corporate manual, the issue feels schizophrenic. The prompt's voice can be different from the body's voice (e.g., the prompt addresses Claude, not the reader), but it should still feel like it was written by the same person.
6. **No emoji unless the writer specifically allows it for that issue.** Newsletters are professional context. Emoji creep destroys this fast.
7. **No exclamation points in body content.** Ever. They feel like marketing.

---

## Updating this file

Every catch the auditor makes that isn't already covered here gets added. The voice bible compounds. Mistakes-log entries with voice causes get reflected back here.

Updates require explicit changelog entry below. Don't silently add or remove rules.

---

## Changelog

- **2026-04-27** — Initial document. Hard bans seeded from: the writer's standing rules (em dashes), patterns caught in Issue 001 development (TL;DR, jargon teases, weak feedback ask, weak P.S. visibility, lowercase sentence start, missing capitalization). Preferred patterns extracted from the writer's actual writing in the existing newsletter materials and their feedback during Issue 001 iteration. Calibration paragraphs constructed by writing each pair side-by-side from real Issue 001 content vs hypothetical off-brand alternatives.
