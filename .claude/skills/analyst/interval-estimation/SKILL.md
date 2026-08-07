---
name: interval-estimation
description: >
  Quantities are intervals: p10/p50/p90 elicitation and three-scenario
  reporting. Load when the user says "give me a range not a point", "p10 p50
  p90", "how confident is that estimate", "best case worst case", or "this
  point estimate feels too precise".
version: 1.0
user-invocable: true
---

# Interval Estimation

The engine treats every quantity as an interval automatically: `/market-size`
requires fractile elicitation on every input, `engine/interval.mjs` propagates
p10/p50/p90 through arithmetic with seeded Monte Carlo, and the three-scenario
tripwire blocks single flattering ratios built from wide inputs. This skill is
how you elicit and carry intervals yourself, and how you spot the false
precision in any point estimate put in front of you.

## Why points lie

A single number silently claims a precision the evidence rarely has, and
precision manufactures trust that has not been earned. "TAM: 4.2B" sounds like
knowledge; "TAM: p10 1.5B / p50 4B / p90 9B, scope stated" IS knowledge,
including knowledge of its own limits.

## The elicitation order

Bounds first, median last. Elicit p10 and p90 first, checking each with the
absurdity test: would you be genuinely surprised to see the true value outside
this bound? Only then place p50. Eliciting the middle first anchors you, and
the bounds you add afterward hug it too tightly; that ordering error is the
single most common cause of overconfident intervals.

## Scope before width

When published sources disagree by 3 to 6 times, the spread is usually scope
definitions, not measurement noise. An honest interval covers the published
range AND states the scope it measures. A narrow interval that silently adopts
one source's scope is overconfidence wearing rigor's clothes.

## The sharpness trap

The engine penalizes a wrong narrow interval far worse than a wide honest one,
and so should you. Width is not weakness; unearned narrowness is. The goal is
the tightest interval the evidence actually supports, not the tightest
interval that looks impressive.

## Compounding

Multiplying point estimates compounds hidden error: three inputs each 30
percent uncertain do not produce an output 30 percent uncertain. The engine
propagates fractiles with seeded Monte Carlo; on paper, carry pessimistic,
base, and optimistic values through the arithmetic separately and report all
three.

## The three-scenario rule

Wide inputs force pessimistic / base / optimistic reporting. The blocked
anti-pattern: a single cherry-picked ratio quietly assembled from the
flattering end of every input.

## Worked example (all numbers hypothetical, for illustration only)

An LTV:CAC estimate for a fictional SaaS. Inputs elicited as intervals: CAC
p10 200 / p50 350 / p90 600 dollars; monthly revenue per account p10 40 / p50
55 / p90 70; monthly churn p10 2% / p50 4% / p90 7%. LTV is revenue divided by
churn, so the scenarios are: pessimistic 70 / 0.07 divided by 600, roughly
1.7x; base 55 / 0.04 divided by 350, roughly 3.9x; optimistic 40 / 0.02
divided by 200, wait, the optimistic case pairs HIGH revenue with LOW churn
and LOW CAC: 70 / 0.02 divided by 200, roughly 17.5x. The honest report is
"roughly 1.7x to 17.5x with a base case near 3.9x", and the spread itself is
the finding: churn dominates, so churn is where the next research hour goes. A
deck that printed only "LTV:CAC = 17x" from these same inputs is the blocked
anti-pattern.

## Artifact-shaped output

The interval record plus the three-scenario table:

```
QUANTITY: {name}
SCOPE: {what exactly is being measured, boundary and year}
p10 / p50 / p90: {values}
SOURCE RANGE COVERED: {published low} to {published high}, {n} sources
STALENESS: inputs dated {date}; re-check by {date}

| Scenario | Inputs used | Result |
|---|---|---|
| Pessimistic | {p10-adverse combination} | {value} |
| Base | {p50s} | {value} |
| Optimistic | {p90-favorable combination} | {value} |
```
