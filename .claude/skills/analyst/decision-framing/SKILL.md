---
name: decision-framing
description: >
  Framing a decision so research can serve it: the loss ladder, the signed
  frame, and the flip condition. Load when the user says "frame this decision",
  "GO or NO-GO", "what would change my mind", "loss ladder", or "set up the
  research question properly". Research that cannot name what would change as a
  result of its answer is entertainment.
version: 1.0
user-invocable: true
---

# Decision Framing

The engine enforces framing mechanically: the research-strategist encodes your
framing card into the decision node of `brief.json`, `engine/voi.mjs` computes
bestAction only from a human-signed loss, and invariant 5 says the loss is the
human's, so the machine may never choose, nudge, or default it. This skill is
how you produce that framing card well, because every downstream number is only
as honest as the frame it serves.

## Name the decision first

State the decision and its real options before any research. A question with
no decision behind it ("what's happening in this market?") gets an evidence
map, not a verdict, and that refusal is correct behavior for the engine and
for you. Verdicts are earned by frames.

## The loss ladder

The central elicitation: how much worse is the wrong commit than the wrong
walk-away? Answer on the ordinal ladder: about equal (1.5), worse (3), much
worse (6), catastrophic (12). This ratio is your risk appetite. It is not a
fact to research; it is a value to own, and nobody, human analyst or engine,
may choose it for you. The engine clamps the ratio to [1, 20] and refuses
ratios outside it as probably mis-elicited.

## Signing

An unsigned frame means evidence-map mode: the engine will refuse to emit a
GO/NOGO, and a human analyst should refuse the same way. Signing is not a
formality; it is the moment the risk appetite becomes yours on the record,
which is what makes the eventual verdict yours too.

## Reversibility and horizon

A reversible decision tolerates a thinner verdict; an irreversible one earns
the full treatment. The horizon date is load-bearing: it is what the premortem
writes its autopsy against and what the prediction records resolve against.
"Eventually" is not a horizon.

## Reading the flip point

The dossier prints a flip-point sweep: at what loss ratio does the best action
change? If your honest ladder answer sits near the flip point, the decision is
loss-dominated: more evidence may matter less than the framing itself, and the
right conversation is about risk appetite, not about another research pass.
The sweep exists so the elicited loss is audited, not laundered.

## Worked example (fictional, for illustration only)

Framing a hire-vs-contract decision for a hypothetical two-person studio.
Options: hire a full-time engineer, or contract the work for six months.
Ladder: a wrong hire (salary committed, morale cost, slow unwind) is judged
"much worse" than a wrong contract, so the ratio is 6, and the human signs it.
GO threshold: hire only if P(the workload sustains a full role) clears the
level implied by that asymmetry. Reversibility: the contract is reversible in
weeks, the hire is not; horizon: 9 months, the date the workload question
resolves. Flip-point read: the sweep shows the best action flips from
contract to hire at a ratio near 5. The signed answer of 6 sits close to that
flip, so the finding is that this decision is loss-dominated: firming up the
ladder answer matters more than a third week of workload research.

## Artifact-shaped output

The completed decision-framing card, the exact object the strategist encodes
into `brief.json`:

```
DECISION: {one line}
OPTIONS: {option A} | {option B}
LOSS RATIO (wrong-commit : wrong-walk): {1.5 | 3 | 6 | 12}   SIGNED: yes/no
GO THRESHOLD: {the belief level that justifies commit}
REVERSIBILITY: {reversible in {time} | effectively irreversible}
HORIZON: {date the outcome is judged against}
FLIP-POINT NOTE: {where the sweep says the action changes, and how close the
signed ratio sits to it}
```
