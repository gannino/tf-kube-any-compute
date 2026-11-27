---
description: >
  Produce a filled competitor comparison matrix plus positioning takeaways for a
  stated product and its named rivals. Use when the user says "competitor analysis",
  "compare us to competitors", "competitive landscape", or "how do we position against
  X". Not for one-page sales enablement (use competitor-battlecard).
user-invocable: true
version: 2.1.0
arguments:
  - name: product
    description: your product and the competitors to compare (or ask to identify them)
effort: high
---

# Competitor Analysis

The output is the filled matrix and the "so what": where to position, which segment
to win first, and which fights to avoid. Unknown cells say "unknown", never a guess
dressed as a fact.

## Procedure

1. Confirm the product, 3 to 5 competitors (research candidates if unnamed), and
   the buyer whose choice the matrix must explain.
2. Pick 6 to 9 comparison dimensions the buyer actually weighs: price, core
   capability depth, onboarding time, integrations, support, and category-specific
   ones. Reject vanity dimensions.
3. Fill the matrix. Every non-obvious cell carries a source (site, pricing page,
   review platform) or the label "unknown". Mark your own product honestly.
4. Write positioning takeaways: the segment where you win today, the gap a rival
   owns that you should not attack head-on, and the one message that exploits the
   biggest differential.

## Worked example (fictional excerpt)

Product: FormFox (form builder for agencies) vs two fictional rivals.

| Dimension | FormFox | QuickForms | MegaSurvey |
|---|---|---|---|
| Entry price | 19 USD/mo | Free tier, 39 USD/mo paid | 99 USD/mo |
| White-label | Yes, all tiers | Paid tier only | No |
| Logic branching | Basic | Deep | Deep |
| Agency multi-client | Yes | No | Partial |

Takeaway: win agencies on white-label plus multi-client at a mid price; avoid
competing on logic depth this year, that is MegaSurvey's moat; lead message: "one
account, every client, your brand."

## Output contract

Deliver: the comparison matrix (rows = dimensions, columns = products, sources or
"unknown" per cell), a 3-bullet positioning takeaways section (win-now segment, fight
to avoid, lead message), and a short list of data gaps worth researching. All example
figures labeled fictional unless sourced.
