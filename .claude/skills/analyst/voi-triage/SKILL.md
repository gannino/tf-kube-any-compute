---
name: voi-triage
description: >
  Value-of-information triage: research what can change the decision, skip what
  cannot. Load when the user says "what should I research next", "is this worth
  researching", "value of information", "when do we stop researching", or
  "where does the research budget go".
version: 1.0
user-invocable: true
---

# VOI Triage

The engine triages automatically: `engine/voi.mjs` computes exact EVPI per
claim, ranks the tier-0 frontier, and applies the stopping rule, while the
staged `/research` budget model frames cheap and researches one crux at a time.
This skill is how you run the same triage on paper for any research plan, and
how you judge whether a plan (yours or the engine's) is spending effort where
it can matter.

## EVPI in plain words

The value of perfect information on a question is what knowing the answer for
certain would be worth, measured in avoided decision loss. The test that does
most of the work: if you knew this for certain, would the action change? If
certainty would not change what you do, the question's research value is zero,
no matter how interesting it is. Interest and value are different currencies.

## The tier-0 priority proxy

You do not need the exact computation to rank questions. The engine's own
frontier proxy is three factors anyone can score on paper, 1 to 5 each:

- **Decision weight:** how much does this question bear on the decision?
- **Uncertainty:** how unsettled is it right now (maximal near 50/50)?
- **Unresolved gap:** how much of it has current evidence not yet covered?

Multiply the three, rank the open questions, fund from the top.

## The zero-VOI traps, named

- **The settled fact.** High interest, already resolved, no movement possible.
- **The everything-consistent finding.** Evidence compatible with every
  hypothesis (the generic big-TAM stat) has zero diagnosticity; researching
  more of it buys conviction without information.
- **The book report.** A question serving no decision. It earns an evidence
  map, never a budget.

## The budget rule

Roughly 80 percent of effort belongs to the 1 to 3 cruxes. Audit any plan by
asking where the hours actually go; if spending does not track the cruxes, the
plan is wrong regardless of how sensible its prose sounds.

## Stopping rules

Stop when the best action stops changing under plausible resolutions of the
open questions (the flip test), or when marginal evidence on the top crux has
stopped moving belief. And "resolved 1 of 3 cruxes, not yet a verdict" is a
valid, honest stopping state; it beats a hedged verdict manufactured to feel
finished.

## Worked example (fictional, all scores hypothetical)

A market-entry call for a hypothetical product, six open questions, scored
weight x uncertainty x gap:

| Question | W | U | G | Score | Call |
|---|---|---|---|---|---|
| Will the anchor segment pay at the modeled price? | 5 | 4 | 4 | 80 | FUND |
| Can we reach them through an existing channel? | 5 | 4 | 3 | 60 | FUND |
| Exact TAM to the nearest 100M | 2 | 3 | 2 | 12 | skip: action unchanged at any plausible value |
| Rival's founding year | 1 | 1 | 1 | 1 | skip: settled and irrelevant |
| Will the category grow? | 3 | 2 | 1 | 6 | skip: consistent with every hypothesis |
| Long-term platform risk | 4 | 4 | 4 | 64 | skip THIS stage: matters at scale, not at entry; parked as a signpost |

Two funded, four skipped with reasons on record. The skips are findings too.

## Artifact-shaped output

The research frontier table:

| Question | Decision weight | Uncertainty | Gap | Priority | Fund/Skip | Budget |
|---|---|---|---|---|---|---|
| {question} | 1-5 | 1-5 | 1-5 | product | FUND | {hours or searches} |
| {question} | ... | ... | ... | ... | SKIP: {reason} | 0 |

Close it with the stopping condition you will honor: "stop when {the flip test
passes or the top crux stops moving}".
