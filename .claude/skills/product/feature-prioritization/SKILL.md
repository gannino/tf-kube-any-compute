---
description: >
  Score a feature list with a RICE table showing the arithmetic, and return a ranked
  order with the cut line argued. Use when the user says "prioritize these features",
  "RICE scoring", "what should we build next", or "rank the backlog". Not for roadmap
  presentation (use product-roadmap) or writing the requirements (use prd-writer).
user-invocable: true
version: 2.1.0
arguments:
  - name: features
    description: the candidate features and any known reach or effort data
---

# Feature Prioritization

The output is the scored table with every number visible and challengeable. RICE is
only as honest as its inputs, so each estimate carries a confidence and a one-line
rationale; scores without rationales are theater.

## Procedure

1. Collect the candidate list and whatever data exists: user counts affected,
   support ticket volumes, engineering sizings. Missing data becomes a labeled
   estimate, not a silent guess.
2. Score each feature: Reach (users affected per quarter, a number), Impact (3 =
   massive, 2 = high, 1 = medium, 0.5 = low, 0.25 = minimal), Confidence (100 /
   80 / 50 percent), Effort (person-weeks). RICE = (R x I x C) / E, arithmetic
   shown per row.
3. Rank, then argue the cut line: what ships this cycle given stated capacity,
   and the one ranking the founder should overrule if strategy demands (RICE is
   input, not verdict).
4. Note any feature whose rank is dominated by a single uncertain input; that is
   the estimate worth validating first.

## Worked example (fictional numbers)

Capacity: 6 person-weeks this cycle.

| Feature | Reach/q | Impact | Conf | Effort (pw) | RICE | Math |
|---|---|---|---|---|---|---|
| CSV export | 900 | 1 | 100% | 2 | 450 | 900x1x1.0/2 |
| Slack alerts | 400 | 2 | 80% | 2 | 320 | 400x2x0.8/2 |
| SSO | 60 | 3 | 80% | 5 | 28.8 | 60x3x0.8/5 |
| Dark mode | 1,200 | 0.5 | 100% | 3 | 200 | 1200x0.5x1.0/3 |

Cut line at 6 person-weeks: CSV export + Slack alerts (4 pw), with 2 pw held for
bugs. SSO ranks last on RICE but gates two enterprise deals; that is a strategy
overrule to make consciously, not a scoring error. All numbers fictional.

## Output contract

Deliver: the RICE table with columns Reach, Impact, Confidence, Effort, RICE, and
the arithmetic per row, a per-row one-line rationale list, the capacity-based cut
line, and a "validate first" note for the most uncertainty-dominated rank. Label
every estimated input.
