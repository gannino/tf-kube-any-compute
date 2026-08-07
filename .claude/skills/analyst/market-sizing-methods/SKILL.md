---
name: market-sizing-methods
description: >
  Top-down, bottom-up, and value-theory market sizing with scope discipline.
  Load when the user says "size this market", "TAM SAM SOM", "how big is the
  market", "top-down or bottom-up", or "is this market worth entering". Every
  size is an interval with a named scope, never a point.
version: 1.0
user-invocable: true
---

# Market Sizing Methods

The engine sizes markets automatically: `/market-size` directs the strategist to
make scope the first crux, the market-size-agent collects the anchors, and
`engine/interval.mjs` propagates fractile intervals through the arithmetic. This
skill is how you size a market yourself with the same discipline, and how you
judge a sizing the engine (or an analyst report) hands you.

## Scope is the first crux

Write the scope statement before touching any number: product boundary,
geography, buyer, year. The recorded failure pattern behind this rule: published
market sizes for the same category routinely disagree by 3 to 6 times, and those
gaps are scope definitions, not measurement noise. A number without a scope is
not yet a finding.

## The three methods, each with its failure mode

**Top-down.** Start from an analyst-report category figure and divide toward your
segment. Fast, but it inherits the report's scope, and scope creep rides in
silently: the platform total gets read as the product-line size.

**Bottom-up.** Units x price x adoption, built from primary anchors (user counts,
observed pricing, cohort adoption). The most defensible method, but adoption is
where optimism hides; elicit it as a fractile interval, not a hope.

**Value-theory.** Value created for the buyer x a plausible capture rate. Useful
for new categories with no analyst coverage; fails on capture-rate fantasy, so
anchor the capture rate to observed comparables.

## Triangulate, then reconcile

Run at least two methods independently, then compare. A gap between methods is a
scope finding to explain, not an error to average away. State which scope each
method actually measured and reconcile explicitly.

## Intervals, then SOM

Elicit p10/p50/p90 for every input. An honest interval covers the published
range and states the scope; a narrow interval that silently picks one source's
scope is overconfidence. SOM comes last, derived from SAM through named
assumptions (channel reach, sales capacity, win rate), each written down.

## Worked example (all numbers hypothetical, for illustration only)

Sizing a fictional "API mocking tools" niche.

Bottom-up: addressable developers p10 400k / p50 700k / p90 1.1M, times seat
price p10 8 / p50 12 / p90 18 dollars per month, times adoption p10 2% / p50 5%
/ p90 9%. Carrying pessimistic, base, and optimistic cases through the
arithmetic gives roughly 0.8M / 5M / 21M dollars per year.

Top-down: a hypothetical analyst report says "developer testing tools, 2.1B
dollars". Dividing by the mocking sub-segment share (assumed 1 to 3 percent)
gives 21M to 63M. That is up to 4x above the bottom-up base case. Investigating
the gap shows the report's scope includes enterprise test-management suites, a
different product boundary. The reconciliation keeps the bottom-up interval as
the SAM estimate and records the report figure with its wider scope, resolving
the 4x gap as a scope difference rather than averaging it away.

## Artifact-shaped output

The sizing one-pager:

```
SCOPE: {product boundary} | {geography} | {buyer} | {year}
| Method       | p10 | p50 | p90 | Scope measured |
|--------------|-----|-----|-----|----------------|
| Bottom-up    | ... | ... | ... | ...            |
| Top-down     | ... | ... | ... | ...            |
| Value-theory | ... | ... | ... | ...            |
RECONCILIATION: {why the methods differ, stated as scope findings}
SOM: {value} via {named assumptions}
STALENESS: inputs dated {date}; re-check by {date}
```
