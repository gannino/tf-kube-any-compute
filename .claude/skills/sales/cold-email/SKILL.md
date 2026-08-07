---
description: >
  Write a complete cold outbound email sequence, four sends with subject lines, body
  copy, and send-day offsets, personalized to a named prospect segment. Use when the
  user says "cold email", "outbound sequence", "write a cold outreach email", or
  "follow-up sequence". Not for emails to existing subscribers (use welcome-sequence
  or nurture-sequence).
user-invocable: true
version: 2.1.0
arguments:
  - name: offer
    description: the product or service being sold and to whom
---

# Cold Email Sequence

The output is the sequence itself: four complete, sendable emails. No frameworks
lectured, no "personalize here" stubs. Each email under 120 words, one idea, one CTA.

## Procedure

1. Confirm: who is the prospect, what pain does the offer remove, what is the single
   CTA (reply, call link, or trial), and one credible proof point.
2. Email 1 (day 0): open with the prospect's problem in their words, one proof point,
   soft CTA. Email 2 (day 3): new angle, a concrete before/after. Email 3 (day 7):
   short, forward a resource or one-line case result. Email 4 (day 12): polite
   breakup with an open door.
3. Write 2 subject line options per send, under 6 words, no clickbait, no ALL CAPS.
4. Personalization tokens are limited to {{first_name}} and {{company}}; every other
   word must work as written.

## Worked example (fictional)

Offer: bookkeeping cleanup for Shopify stores, sold to founders doing 1M USD/yr.

Email 1, day 0. Subject options: "your December books" / "Shopify payout mismatch".

> Hi {{first_name}}, most Shopify stores we open have payouts that do not match
> their P&L, usually 3 to 5 percent off. We fixed that for a 7-figure apparel store
> in 11 days, flat fee. Want me to run a free 15-minute mismatch check on
> {{company}}? Reply "check" and I will send the two numbers I need.

Emails 2 to 4 follow at days 3, 7, and 12 with the angles above.

## Output contract

Deliver a markdown document with four sections titled "Email 1 (day 0)" through
"Email 4 (day 12)", each containing: two subject options, full body copy under 120
words, and the CTA. Close with a send-schedule table (send, day offset, goal). Only
{{first_name}} and {{company}} tokens allowed; zero bracketed placeholders.
