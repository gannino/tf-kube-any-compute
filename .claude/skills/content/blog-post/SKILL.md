---
description: >
  Write a complete, publishable blog post with title options, meta description, and
  structured headings for a stated topic and audience. Use when the user says "write a
  blog post", "draft an article", "blog about", or "turn this into a post". Not for
  outlines only (use content-brief) or customer stories (use case-study).
user-invocable: true
version: 2.1.0
arguments:
  - name: topic
    description: the topic, audience, and target keyword if known
---

# Blog Post

The output is the post itself, ready to paste into a CMS. No outline handed back as if
it were an article, no lorem-style filler, no "in conclusion" padding.

## Procedure

1. Confirm topic, audience, target keyword (if SEO matters), desired length, and the
   one action a reader should take after reading.
2. Draft 3 title options: one direct, one number-led, one question-form. Pick the
   strongest and say why in one line.
3. Write a meta description of 140 to 155 characters containing the keyword naturally.
4. Structure: a hook opening that names the reader's problem in 2 sentences, H2
   sections that each advance one idea, at least one concrete example or worked number
   per major section, and a closing CTA.
5. Voice: active, second person where natural, no hype adjectives, claims either
   sourced or framed as opinion.

## Worked example (excerpt, fictional)

Topic: "how long should a cold shower be" for a fitness newsletter.

Title chosen: "Cold Showers: The 2-Minute Rule Backed by Actual Studies". Meta:
"How long should a cold shower be? What controlled trials actually measured, why 2
to 3 minutes is the working range, and how to build up to it." (154 chars)

Opening: "You do not need a 10-minute ice bath. In the trials people cite, the
exposure that moved any measured outcome was 30 seconds to 3 minutes. Here is what
the data says, and a 2-week ramp that gets you there."

## Output contract

Deliver: 3 title options with the pick justified, the meta description with its
character count shown, the full post in markdown (H2/H3 headings, minimum length as
requested or 800 words by default), and a closing CTA line. Zero bracketed
placeholders; every example uses concrete, clearly fictional or sourced details.
