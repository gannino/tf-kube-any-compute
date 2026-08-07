---
description: >
  Builds a healthcare client brand voice memory file from calibration pairs of generic
  drafts and approved copy, with derived rules every copy skill reads first. Use when the
  user says "match our clinic's voice", "learn our brand voice", "calibrate tone from our
  approved copy", "write like our website", or "brand voice memory for client".
user-invocable: true
version: 2.0.0
---

# Brand Voice from Calibration Pairs (healthcare)

## Purpose

Voice is best taught by deltas, not descriptions. A PAIR of (generic draft, approved client
version) shows exactly what the client changes, and that delta IS the voice. This skill
turns 5-10 samples into a persistent brand voice memory file that every healthcare copy
skill reads before writing.

## Procedure

1. **Ask for 5-10 approved copy samples.** The strongest form is pairs: a generic draft
   next to the client-approved final. Accept singles (approved copy alone) as second best.
2. **Fallback when no samples exist**: fetch 3-5 pages of the live site (a services page,
   the about page, one blog post) and extract voice from published copy. State explicitly
   in the output that the profile is site-derived and weaker than approved-pair
   calibration, and should be upgraded when pairs become available.
3. **Emit the actual artifact**: a brand voice memory file named `{client}-voice.md`
   containing:
   - The pairs themselves (or the site excerpts), quoted.
   - 8-12 derived rules stated as EDITS, not adjectives. Good rule: "they cut adjectives".
     Good rule: "they say 'your clinician', never 'our doctors'". Bad rule: "warm and
     professional".
   - Banned words actually observed being removed by the client.
   - Register: formality level, grammatical person, typical sentence length.
   - A 3-line sample paragraph written in-voice as the concrete target.
4. **Standing instruction, written into the artifact itself**: every healthcare copy skill
   (testimonial-request-health request messages, clinic-ad-compliance-review replacement
   wording, follow-up messages) reads this file first when it exists. New approved copy is
   appended as fresh pairs; the rules section is re-derived once 3 or more new pairs
   accumulate.

## Compliance guard (non-negotiable)

Voice calibration never overrides compliance rules. If approved historical copy contains a
non-compliant claim (a cure promise, an unsubstantiated superlative, an assured-results
pattern), the skill FLAGS it in the voice file instead of learning it, and notes that the
clinic's counsel should review the historical copy. Compliance beats voice every time.

## Worked example (excerpt)

`northside-dental-voice.md` (fictional clinic):

> **Pair 1**
> Generic draft: "Our world-class team delivers exceptional dental care experiences."
> Approved: "You will see the same dentist every visit. Most appointments run on time."
>
> **Derived rules (excerpt)**
> 1. They replace claims about the clinic with facts the patient can verify.
> 2. They cut every intensifier: "world-class", "exceptional" never survive review.
> 3. Second person always; the patient is the subject of the sentence.
> 4. Sentences under 15 words.
>
> **Sample paragraph (target register)**
> You will meet Dr. Reyes before anything happens. She will explain the options, the
> prices, and what she would choose. Then you decide.

## Notes

- Present derived voice rules as observations from the samples, not as facts about the
  client's intent. When a rule rests on a single example, mark it provisional.
- No em dashes in any output. Do not carry absolute compliance claims from old copy into
  new copy.
- This skill produces a working file, not a legal document, but when it touches claim
  wording the boxed template applies:

> TEMPLATE STATUS: This document is a starting template prepared for review by your legal
> counsel and compliance officer. It is not legal advice, and using it does not create an
> attorney-client relationship. Laws differ by jurisdiction and change; have a qualified
> professional licensed in your jurisdiction approve this document before use.
