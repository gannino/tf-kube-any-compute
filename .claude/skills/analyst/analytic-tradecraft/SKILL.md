---
name: analytic-tradecraft
description: >
  The reasoning discipline of the Claudify Analyst engine: Structured Analytic
  Techniques (ACH, Key Assumptions Check, premortem, the named bias sweep), MECE
  decomposition, the bull/bear/red-team dialectic, and the estimative language
  standard. Load when framing a research question, scoring evidence against
  hypotheses, writing or judging a Conviction Dossier, or any time a conclusion is
  about to be asserted from evidence. This is the skill that stops template-filling
  from masquerading as analysis.
version: 2.1.0
---

# Analytic Tradecraft

The failure this skill exists to prevent: gathering evidence into buckets and
hoping a conclusion emerges at synthesis. That is a research assistant. An analyst
starts from competing hypotheses and asks which evidence DISCRIMINATES between
them. Everything below is that inversion, made procedural.

## 1. The question is a decision, or it is a book report

Before any research: name the decision the work serves, its options, and the
asymmetric cost of each wrong option (the loss ladder). Research that cannot name
what would change as a result of its answer is entertainment. The engine enforces
this (unsigned framing = evidence-map mode, no verdict); your job is to elicit the
frame honestly, never to default it. The loss ratio is the human's risk appetite.
You may never choose, nudge, or launder it.

## 2. MECE decomposition and the crux

Decompose into branches that are Mutually Exclusive and Collectively Exhaustive.
The venture shape: is the problem real / will they pay enough / can we reach them /
can we defend it / what kills it. Then tag the 1-3 branches that can actually FLIP
the decision as cruxes. Hard rules:
- If everything is a crux, you have not decomposed. The engine rejects 4+.
- A pricing question and a diligence question produce DIFFERENT trees. Reusing a
  tree across question types is template-filling.
- 80% of the research budget belongs to the cruxes. A settled fact with high
  interestingness and zero decision relevance earns nothing (its EVPI is zero).

## 3. ACH: the least-disconfirmed hypothesis wins

State 3-6 mutually exclusive hypotheses whose priors sum to 1. Deliberately include
the uncomfortable middle (right-thing-wrong-package) and the failure readings; the
bullish and bearish extremes alone are not MECE. Score every evidence item for
consistency with EACH hypothesis using the fixed rubric (CC / C / N / I / II),
then rank by INCONSISTENCY:

- **The survivor is the hypothesis with the fewest weighted inconsistencies, never
  the one with the most support.** Support is cheap (most evidence is consistent
  with several stories); refutation is diagnostic.
- Evidence consistent with EVERY hypothesis (the generic big-TAM finding) has zero
  diagnosticity and moves nothing. Flag it; do not let it manufacture conviction.
- "No competitor found" is scored consistent with BOTH the blue-ocean hypothesis
  AND the dead-zone hypothesis. It therefore moves nothing on its own. The engine
  forces its LR to 1.0; your job is to never argue around that.

## 4. The Key Assumptions Check

Before synthesis, enumerate the load-bearing assumptions the conclusion rests on.
Rate each: solid / risky / unsupported. Every assumption gets a falsifying
indicator (the observable that would prove it wrong). An UNSUPPORTED load-bearing
assumption caps the conclusion at coin-flip regardless of how the evidence sums.
The most expensive research failures are never wrong facts; they are unexamined
assumptions ("customers who say they will pay actually will", "the incumbent will
not respond", "the base is representative of the market").

## 5. The premortem and the named bias sweep

Premortem: assume the recommended action was taken and failed badly by the horizon
date. Write the three most plausible autopsy lines. Each maps to a claim (it was
wrong), an assumption (it was unsupported), or a new kill indicator. The autopsy
lines that map to NOTHING in the analysis are the holes.

The bias sweep is run against NAMED biases with locations, never as a vibe:
- **Anchoring:** did the first number found become the estimate?
- **Confirmation:** did collection follow the thesis (check: does disconfirming
  search evidence exist for every falsifiable claim)?
- **Survivorship:** were only the winners studied (failed comparables die silently;
  their absence from search results is not their absence from reality)?
- **Availability:** did one vivid recent case outweigh the base rate?
- **Base-rate neglect:** was the inside view built before the outside view? The
  reference class comes FIRST; the engine refuses to score a claim without one.
- **Scope creep:** was a number imported across scopes (the platform-total vs
  product-line conflation is the single most common real citation error)?

## 6. The dialectic is architectural, not editorial

Bull, bear, and red-team run in fresh, isolated contexts. The bear never reads the
bull; the red-team reads ONLY the frame (its power is the crux-omission veto, and
it cannot find the omission if it has been anchored by everyone else's work).
Dissent is PRESERVED in the deliverable: the dossier shows the strongest case both
ways and what the bear got right that survives. Resolving disagreement silently is
the anti-pattern; a sophisticated reader pays precisely for the preserved dissent.

## 7. Estimative language (the fixed lexicon)

Probabilities are communicated in the fixed 7-band lexicon, never ad-hoc words and
never bare decimals in customer-facing prose: ALMOST NO CHANCE (1-5), VERY UNLIKELY
(5-20), UNLIKELY (20-45), ROUGHLY EVEN (45-55), LIKELY (55-80), VERY LIKELY
(80-95), ALMOST CERTAIN (95-99). Two axes, always: the band (likelihood) AND the
computed confidence (evidence structure). "LIKELY, low confidence, single origin"
and "LIKELY, high confidence, three independent origins" are different statements;
collapsing them is the pre-2003 failure the two-axis rule exists to prevent.

## 8. What honest output sounds like

- "Resolved 1 of 3 cruxes; not yet a verdict" beats a hedged verdict.
- "We expected a primary filing and did not find one" beats silence about the gap.
- "The evidence is thin; here is why the claim could still be right" is a valid
  bull case. "The data clearly shows" plus an adjective is not.
- Every sentence asserting a claim cites the claim id; contested claims carry the
  word CONTESTED in the prose that mentions them.
- No em dashes, ever (house hard rule).
