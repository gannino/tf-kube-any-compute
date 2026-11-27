---
name: red-team-questioning
description: >
  The red-team question battery: attack the reasoning, never the conclusion.
  Load when the user says "red team this", "poke holes in this", "challenge my
  thinking", "what am I missing", or "play devil's advocate properly".
  Isolation is the mechanism: attack before reading anyone's conclusion.
version: 1.0
user-invocable: true
---

# Red-Team Questioning

The engine red-teams automatically: the red-team agent runs the bias sweep, the
assumption attack, and holds the crux-omission veto, reading ONLY the issue tree
and the question so it cannot be anchored by anyone else's work. This skill is
how you red-team a piece of reasoning yourself, and how to do it so you are a
genuine red team rather than a contrarian.

## The target discipline

Attack the frame, the assumptions, and the omissions, never the verdict. A red
team that argues the opposite conclusion is just a second bull with a different
portfolio. If the reasoning survives your attack, the conclusion stands
stronger; if it does not, the conclusion falls on its own.

## The crux-omission question comes first

Ask: what branch, objective, or claim is MISSING that could flip this decision?
Omission is the one failure an analysis cannot detect from inside, because it
researches what it enumerated and grades what it selected. This is exactly why
the engine grants its red-team an injection veto: the right to ADD a missing
crux the engine cannot down-select. Spend your best minutes here, before any
line-by-line critique.

## The six named biases, as questions

Answer each HIT or CLEAR, and a HIT requires a specific location:

1. **Anchoring:** did the first number found become the estimate?
2. **Confirmation:** did collection follow the thesis? Is there a disconfirming
   search on record for every falsifiable claim?
3. **Survivorship:** were only winners studied? Failed comparables die silently.
4. **Availability:** did one vivid recent case outweigh the base rate?
5. **Base-rate neglect:** was the inside view built before the outside view?
6. **Scope creep:** was a number imported across scopes (platform total read as
   product line)?

A sweep answered "all clear" with no locations examined is a vibe, not a sweep.

## The assumption attack

For every assumption rated solid: is it? Name the observable that would
downgrade it. The expensive failures are never wrong facts; they are unexamined
assumptions that everyone rated solid because no one asked.

## The caps

At most 2 injected considerations, each genuinely able to flip the decision.
More is completeness theater, and it buries the one objection that matters
under eight that do not.

## Isolation practice for humans

Red-team from the question and the issue tree only, BEFORE reading the draft
conclusion. Once you have read a fluent recommendation, you are anchored; your
critique will orbit its structure. Fresh eyes are a mechanism, not a mood.

## Worked example (fictional, for illustration only)

A hypothetical build-vs-buy memo recommends building an in-house billing
system. The sweep: ANCHORING, HIT, the vendor quote of 90k dollars per year
(hypothetical) obtained first became the comparison bar for every later
estimate. SURVIVORSHIP, HIT, the memo studies three companies that built
billing successfully and none that abandoned the attempt; the comparison set
is in section 2. Other four: CLEAR, with locations checked. Injected missing
crux: the memo never prices the ongoing compliance burden of card-data
handling, a cost that lands entirely on the build option and could flip the
decision on its own. Assumption downgrade: "two engineers can maintain it"
rated solid, downgraded to risky; the falsifying observable is either engineer
leaving within a year.

## Artifact-shaped output

The red-team report:

```
BIAS SWEEP
| Bias | HIT/CLEAR | Location |
|---|---|---|
| Anchoring | HIT | s3: vendor quote became the bar |
| Survivorship | HIT | s2: only successful builds studied |
| (four more rows, CLEAR, with locations checked) |

INJECTED CONSIDERATIONS (max 2)
1. Compliance burden of card-data handling, unpriced. Could flip: yes.

ASSUMPTION DOWNGRADES
| Assumption | Was | Now | Falsifying observable |
|---|---|---|---|
| 2 engineers can maintain | solid | risky | either engineer departs within 12mo |
```
