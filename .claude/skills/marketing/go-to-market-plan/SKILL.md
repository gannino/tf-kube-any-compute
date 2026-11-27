---
description: >
  Produce a dated, channel-by-channel go-to-market plan with budget math for a specific
  product launch. Use when the user says "go-to-market plan", "GTM plan", "launch plan",
  or "how do we launch this". Not for ongoing campaign planning (use campaign-brief) or
  positioning work alone (use brand-voice-guide).
user-invocable: true
version: 2.1.0
arguments:
  - name: product
    description: the product or offer being launched
---

# Go-to-Market Plan

Build a launch plan a solo founder or small team can execute. The output is the plan
itself, not advice about planning. Every channel gets a budget line, an owner, a start
date, and a success metric. Every number ties back to the stated budget.

## Procedure

1. Confirm the four inputs: product and price, target buyer, total launch budget, launch
   window. If any is missing, ask before writing.
2. Write a one-paragraph positioning statement: who it is for, the problem, why this over
   alternatives.
3. Select 3 to 5 channels the buyer actually uses. For each: tactic, cost, expected
   output, and the date it starts.
4. Allocate the full budget across channels. Show the arithmetic. Unallocated budget goes
   to a named contingency line, never silently dropped.
5. Define the first 90 days in three 30-day phases with one primary metric per phase.
6. List the top 3 risks with a mitigation each.

## Worked example (fictional numbers)

Product: InvoiceNudge, a 29 USD/mo tool that chases unpaid invoices for freelance
designers. Budget: 2,000 USD. Window: 6 weeks.

| Channel | Tactic | Cost | Expected output | Starts |
|---|---|---|---|---|
| Designer communities | 10 value posts + AMA | 0 USD (time) | 300 site visits | Week 1 |
| Cold email | 400 personalized sends to studios | 200 USD (tools) | 20 demos | Week 2 |
| Directory launches | Product Hunt + 4 niche directories | 100 USD | 800 visits | Week 3 |
| Paid social test | 2 creatives, designer lookalikes | 1,400 USD | CAC read under 70 USD | Week 4 |
| Contingency | Double down on best CAC channel | 300 USD | reallocated Week 6 | Week 6 |

Total allocated: 2,000 USD. Phase metrics: days 1 to 30 = 50 trials, days 31 to 60 =
CAC under 70 USD on one channel, days 61 to 90 = 40 paying customers.

## Output contract

Deliver a markdown document titled with the product and date containing, in order:
Positioning (one paragraph), Launch channels (table with Cost, Expected output, Starts),
Budget allocation (arithmetic shown, sums to the stated budget), Pricing, First 90 days
(three phases, one metric each), Risks (3 rows with mitigations). No bracketed
placeholders anywhere. All numbers labeled as estimates unless the user supplied them.
