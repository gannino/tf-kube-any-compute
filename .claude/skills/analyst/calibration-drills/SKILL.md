---
name: calibration-drills
description: >
  Probability elicitation and Brier scoring practice for the human who signs the
  frames. Load when the user says "calibration practice", "am I overconfident",
  "Brier score", "probability training", or "score my forecasts". The engine
  keeps its own scoreboard; this is how you build yours.
version: 1.0
user-invocable: true
---

# Calibration Drills

The engine grades itself automatically: the research-analyst writes hash-chained
prediction records at synthesis and `engine/score.mjs` computes Brier and log
scores with the Murphy decomposition when they resolve. But the engine's loss
ratios, priors, and fractiles are elicited from YOU, and an uncalibrated human
poisons a calibrated engine at the inputs. This skill is how you train the human
half and how you read the engine's calibration report honestly.

## Elicitation drills

**The equivalent-bet test.** Before writing "80 percent", ask: would I take a
bet that pays 1 if I am right and costs 4 if I am wrong? If the bet feels bad,
the number is wrong, not the bet.

**Absurdity anchoring.** For quantities, start from bounds you would bet heavily
on ("definitely above 100, definitely below 100,000") and tighten inward. Bounds
first prevents the middle from anchoring you narrow.

**Lexicon mapping.** Say your gut word ("likely", "doubtful"), then write the
number, then check it against the fixed 7-band estimative lexicon. Where your
words and numbers disagree is exactly where your communication misleads.

## The weekly 10-question drill

Ten resolvable questions (product metrics, industry announcements, sports,
anything with a clean answer inside a month). For each: write the probability
AND freeze the resolution criterion in writing before answering; that is guard
G8 in human form, because the party that wants to look right must not pick its
referee afterward. Grade on schedule, never early, never selectively.

## Scoring by hand: worked example (hypothetical numbers)

Five forecasts with outcomes. Brier per item is (p minus outcome) squared:

| Forecast | p | Outcome | Brier |
|---|---|---|---|
| Release ships by Friday | 0.9 | 1 | 0.01 |
| Rival announces pricing change | 0.6 | 0 | 0.36 |
| Signups exceed 500 | 0.7 | 1 | 0.09 |
| Bug report reproduced | 0.8 | 1 | 0.04 |
| Conference talk accepted | 0.3 | 1 | 0.49 |

Mean Brier = (0.01 + 0.36 + 0.09 + 0.04 + 0.49) / 5 = 0.198. Then the Murphy
read in plain words: reliability asks whether your 70s came true about 70
percent of the time (calibration); resolution asks whether you separated winners
from losers at all, because a parrot that answers the base rate every time is
perfectly calibrated and perfectly useless.

## The hard-band rule

Report your [0.35, 0.65] calls first, always. An aggregate padded with
near-certainties is the flattering lie of forecasting scoreboards. The hard band
is where judgment lives; the rest is bookkeeping.

## The honesty floor

Below 20 resolved forecasts you are "n=<x>, uncalibrated" and you say so before
any score. Do not imply a track record a dozen data points cannot support.

## Artifact-shaped output

The personal calibration card plus the drill ledger:

```
CALIBRATION CARD {date}
n resolved: 23 | Brier: 0.198 | direction: overconfident above 0.7
hard band [0.35, 0.65]: 6 calls, Brier 0.24
next drill due: {date}

DRILL LEDGER (one row per question, criterion frozen before answering)
| # | Question | p | Resolution criterion (frozen) | Resolves by | Outcome | Brier |
```
