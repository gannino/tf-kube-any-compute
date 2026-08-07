---
description: >
  Write a complete five-email welcome sequence with subject lines, full body copy, and
  send-day offsets for new subscribers or trial users. Use when the user says "welcome
  sequence", "onboarding emails", "welcome email series", or "drip for new signups".
  Not for cold prospects (use cold-email) or mid-funnel education (use
  nurture-sequence).
user-invocable: true
version: 2.1.0
arguments:
  - name: product
    description: the product, who signs up, and the one activation action that matters
---

# Welcome Sequence

The output is five complete, sendable emails. Each has one job in the arc: deliver,
orient, activate, prove, convert. Under 150 words each; a welcome email nobody
finishes is a welcome email nobody acts on.

## Procedure

1. Confirm: the product, the signup context (free trial, lead magnet, purchase),
   the single activation action (the thing users who stick around all did), and
   the end-of-sequence goal (upgrade, purchase, reply).
2. The arc: Email 1 (minute 0) delivers what was promised and sets expectations.
   Email 2 (day 1) walks the activation action, one action only. Email 3 (day 3)
   removes the most common objection or mistake. Email 4 (day 5) shows one
   concrete result story. Email 5 (day 7) makes the ask plainly, with a deadline
   if one truthfully exists.
3. Two subject options per email, under 7 words. First lines never repeat the
   subject. One CTA per email, repeated at most twice.

## Worked example (fictional, email 2 of 5)

Product: a podcast editing tool; activation = uploading the first episode.

Day 1. Subject options: "your first episode, 10 minutes" / "upload one, we edit it".

> Yesterday you joined PodTrim. Today, one thing: upload any episode, even an old
> one. Our editor removes filler words and long pauses automatically, and you will
> see the before/after on your own audio, which beats any demo we could show you.
> Takes about 10 minutes end to end. Upload your episode: [single button link].
> Tomorrow I will show you the one setting most new users miss.

## Output contract

Deliver five sections titled "Email 1 (minute 0)" through "Email 5 (day 7)", each
with: two subject options, complete body copy under 150 words, and one CTA. Close
with the sequence map table (email, offset, job, CTA). Only {{first_name}} and
{{product}} tokens permitted; no other placeholders.
