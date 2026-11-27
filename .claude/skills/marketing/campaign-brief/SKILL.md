---
description: >
  Write a campaign brief a contractor could execute unedited: objective, audience,
  message, channels, budget split, assets, and measurement. Use when the user says
  "campaign brief", "brief for this campaign", "ad campaign plan", or "brief the
  agency". Not for full product launches (use go-to-market-plan) or single ad copy
  requests.
user-invocable: true
version: 2.1.0
arguments:
  - name: campaign
    description: the product, objective, budget, and timeframe
---

# Campaign Brief

The output is the brief itself, complete enough that a freelancer who has never met
you could start producing tomorrow. The test for every section: could the contractor
act on it without a clarifying call?

## Procedure

1. Confirm: the single campaign objective with its number (not "awareness" but
   "600 trial signups"), budget, flight dates, and any brand constraints.
2. Sections: Objective (one metric, one target, one deadline), Audience (who,
   where they are reachable, what they currently believe), Key message (one
   sentence) with 2 supporting proof points, Channels and budget split (table),
   Deliverables list (exact assets with specs and due dates), Measurement (what
   is tracked, where, and the check-in cadence), Approvals (who signs off, how
   fast).
3. The budget table must sum to the stated budget. Deliverables carry formats and
   dimensions, not "some social assets".

## Worked example (fictional excerpt)

Campaign: launch of a meal-prep app's family plan. Objective: 1,200 plan upgrades
in 6 weeks. Budget: 15,000 USD.

| Channel | Budget | Deliverables | Due |
|---|---|---|---|
| Meta ads | 9,000 USD | 6 statics 1080x1350, 2 videos 15s 9:16 | Week 1 |
| Influencer seeding | 4,000 USD | 8 family-food creators, brief + codes | Week 2 |
| Email to free users | 0 USD (owned) | 3-send series, subject variants | Week 1 |
| Contingency | 2,000 USD | reallocated at week 3 review | Week 3 |

Key message: "One plan, four plates, ten minutes." Proof points: average prep time
from onboarding data; plan price versus one takeaway. All figures fictional.

## Output contract

Deliver a markdown brief with the seven sections above, a budget table that sums to
the stated total, deliverables with formats and due dates, and a measurement section
naming the tracking source. No bracketed placeholders; open questions go in a final
"Needs from client" list.
