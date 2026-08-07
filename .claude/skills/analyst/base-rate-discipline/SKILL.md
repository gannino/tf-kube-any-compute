---
name: base-rate-discipline
description: >
  Reference-class forecasting and a growing personal base-rate library. Load
  when the user says "what's the base rate", "reference class", "outside view
  first", "how often does this usually succeed", or "what's a sensible prior".
  The outside view comes before any inside-view story, always.
version: 1.0
user-invocable: true
---

# Base Rate Discipline

The engine enforces this mechanically: the research-strategist must anchor every
claim to a `reference_class` and `base_rate`, and `engine/brief.mjs` validation
throws on any claim without one. Nothing gets scored from a standing start of
pure story. This skill is how you pick a reference class honestly yourself, and
how you judge whether the class a brief names is the right one.

## The rule

Before researching the specifics of any question ("will THIS product succeed"),
answer the class question ("how often do products LIKE this succeed"). The
outside view is the anchor; the inside view earns adjustments off it, never a
fresh start.

## Choosing the class

Pick the nearest class with a usable n. "B2B developer tools launched by solo
founders reaching 1M dollars ARR" may have no observable cohort; widen to
"bootstrapped B2B SaaS reaching 1M ARR within 2 years" until you have one. Two
honesty rules: name the class out loud so it can be challenged, and when the
rate is estimated rather than measured, label it estimated with low n. Never
dress a hunch as a cohort.

## The inside-view lockout

Write the base rate down BEFORE researching specifics. Base-rate neglect is one
of the six named biases in the red-team's sweep, and what the sweep checks is
exactly this ordering: was the inside view built first? Once you have read the
pitch, the demo, and the founder's thread, you can no longer generate an
unanchored prior; the vivid case has already moved you.

## Where rates live

- Prior runs: the strategist reuses known reference classes from agent memory
  before searching for new ones. Do the same; your past runs are your best
  library.
- Public cohort data: survival rates, adoption curves, conversion benchmarks,
  regulatory approval timelines.
- Your own resolved prediction ledger, once it has enough n to mean anything.

## Adjusting off the base

Each adjustment is a named, evidence-backed delta, and the further you move
from the base rate, the more diagnostic evidence you owe. "The base rate is 15
percent but this team feels special" is not an adjustment; it is the inside
view escaping through the window.

## Worked example (all numbers hypothetical, for illustration only)

Question: will this product reach 1M dollars ARR within 18 months?

Step 1, class: bootstrapped B2B SaaS with a launched product and some revenue.
Assume a stated comparable-cohort rate of roughly 20 percent within 18 months
(hypothetical figure, labeled estimated, modest n). Write down 0.20 before
reading anything specific.

Step 2, named adjustments: (a) the product already has 200 paying seats at 30
days retention above the cohort norm, evidence from its own analytics export:
adjust up to roughly 0.30. (b) the pricing sits 4x below the segment median
with no tested upgrade path, evidence from the published pricing page: adjust
down to roughly 0.25. Final: about 0.25, anchored, with both deltas named and
sourced. The story never touched the number except through evidence.

## Artifact-shaped output

A reference-class entry appended to a personal base-rates file the strategist
can read on its next run:

```
CLASS: bootstrapped B2B SaaS, launched, some revenue, reaching $1M ARR in 18mo
N: ~140 (estimated from cohort study, hypothetical)   RATE: ~0.20
SOURCE: {citation}   FETCHED: {date}
APPLIES-TO: pre-Series-A SaaS with launched product; NOT marketplaces
DECAY: re-verify by {date + 365d}
```
