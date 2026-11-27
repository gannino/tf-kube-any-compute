---
name: quality-and-calibration
description: >
  The honesty discipline of the Claudify Analyst engine: computed belief, source
  independence, proper scoring, the anti-gaming guards (G1-G13), and what may
  never be claimed. Load when assigning likelihood ratios, judging evidence
  quality, writing or grading predictions, reporting calibration, or any time a
  number is about to be shown to a human. This is the skill that keeps the
  scoreboard honest when the scoreboard is ours.
version: 2.1.0
---

# Quality and Calibration

The failure this skill exists to prevent: false authority. A precise number
computed from fabricated inputs is WORSE than an honest hedge, because precision
manufactures trust the evidence has not earned. Every rule below traces to a
documented failure mode.

## 1. Belief is computed, never typed

No agent writes a belief, a posterior, or a conviction number. Agents populate
typed records (sources, passages, LRs from the evidence-type rubric); the
deterministic engine computes. If a computed number feels wrong, say so in your
reply; never patch it. Reproducibility claim, stated honestly: deterministic on a
frozen graph. That is not a validity claim; validity comes from the gates and the
grading.

## 2. Likelihood ratios come from evidence TYPE, never wording

The fixed rubric: primary data/experiment/panel 2.5-4.0; official filing or
government statistic 2.0-3.0; direct vendor artifact 1.5-2.0; reputable secondary
1.2-1.6; blog or forum assertion 1.0-1.3; absence-of-evidence exactly 1.0.
Disconfirming evidence takes LR below 1 by the same type logic. Persuasion words
("definitive", "authoritative", "proven") never raise an LR; they CAP it at 2.0
and are themselves a manipulation signal. The engine clamps everything to
[0.1, 10]; a single source can never dominate.

## 3. Independence is counted over ORIGINS

N sources tracing to one origin are approximately ONE vote. Same registrable
domain, same underlying report or press release, or one page citing another =
the same origin; when unsure, cluster TOGETHER (pessimism: N_eff errs toward
under-confidence). The documented failure this kills: five citations laundering
one press release read as five votes. Corollary for judging: a claim's headline
strength is its N_eff, not its citation count, and a single-origin claim is
hard-capped at LOW confidence no matter how good the origin.

## 4. Decay is a property of the fact

Fast-growing-company metrics have a half-life around 90 days (the documented
5.6x staleness error: an ARR figure that was true became 5.6x wrong within a
year). Competitor pricing about 180; established market sizes about 365;
regulation about 730. An old number is not wrong; it is weak, continuously, by
`0.5^(age/half_life)`, and a stale fast-mover must also be FLAGGED visibly, not
just silently down-weighted.

## 5. Quantities are intervals

Elicit p10/p50/p90, never points. The 3-6x disagreements between market-size
sources are SCOPE definitions, not measurement noise: an honest interval covers
the published range and states the scope; a narrow interval that picks one
source's scope is overconfidence (the sharpness gate fails it with a penalty far
worse than width). Wide ranges force three-scenario reporting: a single LTV:CAC
ratio cherry-picked from wide inputs is blocked by tripwire; report pessimistic /
base / optimistic.

## 6. Predictions and grading (the contract, ninth loop)

- **G1:** no learning without a prior prediction record. Grading without one
  returns INSUFFICIENT_PRECONDITION, verbatim, always.
- **G8:** the resolution criterion (source, threshold, date) is frozen and
  content-hashed at prediction time. Outcomes that do not cleanly match are
  UNRESOLVED with a reason: counted, reported, never dropped and never
  charitably graded. Dropping ambiguous resolutions is how every self-graded
  forecast inflates itself.
- **The ledger is hash-chained.** Each row commits the prior row's hash; a
  silent post-hoc edit breaks the chain detectably. Never append to a broken
  chain; report the break.
- **Proper scores only:** Brier and log score, Murphy-decomposed. Reliability
  (calibration error) is driven toward zero; Resolution (does it separate
  winners from losers) is maximised AND floored. A base-rate parrot is
  perfectly calibrated and perfectly useless; it FAILS.
- **G7, the headline rule:** report the HARD BAND [0.35, 0.65] first, always.
  An aggregate padded with near-certainties is the flattering lie of
  forecasting scoreboards. Silence on a crux costs; abstention is scored.

## 7. The buyer-honesty statements (never soften these)

- Below 20 resolved predictions: "n=<x>, uncalibrated" appears BEFORE any score.
- Below 30: the calibration map is identity or temperature-only (the cold-start
  contract); never imply a fitted curve exists.
- Retrieval adequacy is reported with the verdict, and a weak retrieval CAPS the
  verdict ("CONDITIONAL, retrieval-capped"). "We may not have looked hard
  enough" is a feature statement, not an apology.
- The "sources we expected but did not find" ledger ships in every dossier. A
  research tool that tells you what it could not find is doing what no commodity
  tool does; deleting that section deletes the differentiation.

## 8. The anti-metric registry (never reward these)

More predictions. Higher confidence for its own sake. Faster resolution.
Narrower scope. Fewer declared cruxes. Agreement between sub-agents.
Persuasiveness to a judge. Cross-run stability bought by prompt narrowing.
Every one of these makes a scoreboard look better while making the research
worse; treat movement on any of them as a warning, not a win.

## 9. What may never be claimed

- Never "provably calibrated" or coverage guarantees on tens of bespoke,
  non-exchangeable questions (a statistician dismantles it in one paragraph).
- Never a public negative named-entity teardown (the defamation surface; house
  hard rule). Public registry calls are short-horizon, entity-safe, mechanically
  gradeable, and graded with NO model in the resolution loop.
- Never "the engine is un-poisonable". The honest containment claim: hijack of
  the authority stage is structurally prevented, exfiltration is closed
  deterministically, and poison cannot manufacture conviction (a suspected
  source can never RAISE belief). The residual (a plausible false number no
  independent source contradicts) ships flagged single-origin and is caught by
  the grading loop over time.
- No em dashes, ever (house hard rule).
