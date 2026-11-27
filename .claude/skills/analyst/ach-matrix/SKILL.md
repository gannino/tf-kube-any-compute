---
name: ach-matrix
description: >
  Analysis of Competing Hypotheses in three sizes. Load when the user says
  "run an ACH", "competing hypotheses", "which hypothesis survives", "score the
  evidence against each explanation", or "build an ACH matrix". Teaches matrix
  construction, the CC/C/N/I/II consistency rubric, and ranking by inconsistency
  so the least-disconfirmed hypothesis wins, never the most-supported.
version: 1.0
user-invocable: true
---

# The ACH Matrix

The engine runs ACH automatically: `engine/ach.mjs` scores every evidence edge
against every hypothesis with a fixed rubric and recommends the least-disconfirmed
hypothesis, and the research-strategist constructs the hypothesis set that feeds
it. This skill is how you run the same discipline by hand, judge the engine's ACH
section in a Conviction Dossier, and use the method on decisions that never enter
a full engine run.

## The inversion that makes it work

Support is cheap. Most evidence is consistent with several stories at once, so
counting support rewards whichever story you collected for. Refutation is
diagnostic. The survivor is the hypothesis with the fewest weighted
inconsistencies, never the one with the most checkmarks. If you take one rule
from this skill, take that one.

## Three sizes

**Full ACH.** For decisions with real stakes. State 3 to 6 mutually exclusive,
collectively exhaustive hypotheses whose priors sum to 1. Score every evidence
item against every hypothesis with the fixed rubric: CC (strongly consistent),
C (consistent), N (neutral), I (inconsistent), II (strongly inconsistent). Weight
each row by evidence quality, total the inconsistencies per column, rank.

**Quick ACH.** Three hypotheses, one page, about 15 minutes, for decisions under
a day's stakes. Same rubric, no weighting, same ranking rule.

**Quantified ACH.** The engine-backed form: likelihood ratios per edge, priors on
the hypothesis nodes, run through `ach.mjs`, which also applies the same-origin
haircut and freshness weighting. You read that output; you never hand-edit it.
If a posterior feels wrong, say so in prose and check the inputs, do not patch
the number.

## Hypothesis-set craft

Bullish plus bearish extremes alone are not MECE. Deliberately include the
uncomfortable middle (right thing, wrong package) and the failure readings (real
demand, wrong buyer; real problem, no willingness to pay). A hypothesis set that
omits the reading you would find embarrassing is a set built to confirm.

## Zero-diagnosticity evidence

An item consistent with every hypothesis moves nothing: the generic big-TAM
finding, "no competitor found" (consistent with both blue ocean and dead zone).
Flag it in the matrix rather than letting it manufacture conviction. The engine
forces such items toward LR 1.0; do the same on paper by scoring them N across
the row.

## Worked example (fictional numbers, for illustration only)

Decision: should we build feature X for a hypothetical developer tool?

Hypotheses: H1 users want X as specced (prior 0.30), H2 users want the underlying
job but not this package (0.30), H3 the demand signal is a vocal minority (0.25),
H4 demand is real but a platform vendor will ship it natively (0.15).

| Evidence | H1 | H2 | H3 | H4 |
|---|---|---|---|---|
| E1: 40 upvotes on the request thread (hypothetical) | C | C | C | C |
| E2: 12 of 15 interviewees describe the job differently than the spec | I | CC | C | C |
| E3: churn survey names the job in 3 of 90 responses | I | I | CC | N |
| E4: two rivals shipped X and quietly deprecated it | II | C | C | N |
| E5: platform vendor roadmap mentions the area | N | N | N | CC |
| E6: our prototype's trial conversion 8 percent vs 6 percent baseline | C | C | I | C |

E1 is consistent with everything: zero diagnosticity, flagged. H1 has the most
raw support across rows yet also the most inconsistencies (E2, E3, E4). H2
carries the fewest inconsistencies and survives. The most-supported hypothesis
lost to the least-disconfirmed one, which is the method working as intended.

## Artifact-shaped output

Produce a filled markdown ACH matrix exactly like the table above (hypotheses as
columns with priors, evidence as rows, rubric cells, an inconsistency-total row)
plus a one-line survivor statement with its caveats, for example: "Survivor: H2,
least disconfirmed (2 weighted inconsistencies vs 5 for H1). Caveats: E1 flagged
zero-diagnosticity and excluded; E6 is single-origin and weakly diagnostic."
