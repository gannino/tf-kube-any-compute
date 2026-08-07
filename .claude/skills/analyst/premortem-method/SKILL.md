---
name: premortem-method
description: >
  The structured premortem: assume the decision failed, write the autopsy, map
  every line to something checkable. Load when the user says "run a premortem",
  "why might this fail", "write the autopsy", "what would make this wrong", or
  "stress test this plan before we commit".
version: 1.0
user-invocable: true
---

# The Premortem Method

The engine runs this automatically: the red-team agent's step 2 assumes the
recommended action was taken and failed badly by the horizon date, writes the
three most plausible autopsy lines, and maps each to a claim, an assumption, or
a new kill indicator that feeds the signposts `/market-watch` monitors. This
skill is how you run the same exercise yourself on any plan, and how you judge
whether an engine premortem actually found anything.

## The setup

Do not ask "what could go wrong?"; that invites polite hedging. Instead: it is
the horizon date, the action WAS taken, and it failed badly. Write the autopsy
from inside that future, looking back. The tense shift is the whole trick. It
converts "I have a concern" (career risk, easily suppressed) into "here is what
happened" (a story anyone can tell freely).

## The three-line discipline

Exactly the 3 most plausible autopsy lines, not a brainstorm dump. Twenty
failure modes is a way of avoiding the ranking judgment; three forces you to
say which failures you actually believe in.

## The mapping rule (this is the method)

Each autopsy line must map to one of:

1. **An existing claim**: the failure means the claim was wrong. Good; the
   analysis already covers it, and the claim's weight may deserve a look.
2. **An assumption**: the failure means something rated solid was not. Propose
   the downgrade with its falsifying indicator.
3. **A NEW kill indicator**: the failure is real but nothing in the analysis
   watches for it. Add the indicator.

A line that maps to NOTHING in the analysis is the hole, and finding holes is
the point. A premortem where all three lines map neatly onto existing claims
was probably written to be comfortable.

## Solo vs group

Solo: write the lines before re-reading your own conclusion. Group: everyone
writes lines silently before any discussion, because the first spoken line
anchors the room and the premortem collapses back into agreement.

## Feeding the watch

Each kill indicator becomes a signpost: an observable trigger plus a check
date. Those signposts are the exact inputs `/market-watch` monitors between
runs, which is what makes a premortem a standing defense instead of a one-time
ritual.

## Worked example (fictional, for illustration only)

Decision: launch an annual plan for a hypothetical SaaS at 20 percent discount.
Horizon: 12 months. The premortem, written from month 12 after a bad outcome:

1. "Annual buyers were our best monthly customers pre-paying at a discount;
   new-customer volume never moved." Maps to the existing claim that annual
   pricing attracts new demand: the claim was wrong.
2. "Refund requests spiked at month 2 because the product had not matured into
   the annual promise." Maps to the assumption "current churn predicts annual
   satisfaction", rated solid in the memo; it was unsupported.
3. "A rival launched monthly-with-price-lock and reframed annual as a trap."
   Maps to nothing in the analysis. That is the hole: competitor response was
   never a branch. It becomes a new crux and a kill indicator (rival pricing
   page changes, checked monthly).

## Artifact-shaped output

The premortem table, ready to append to a run's signposts:

| Autopsy line | Maps to | New kill indicator | Watch trigger | Check date |
|---|---|---|---|---|
| Cannibalized existing monthlies | Claim C3 (wrong) | none | new-customer share of annual sales below 40% | {date} |
| Month-2 refund spike | Assumption A2 (downgrade) | refund rate | refunds above 5% of annual cohort | {date} |
| Rival price-lock reframe | NOTHING (hole) | rival pricing move | rival pricing page changes | monthly |
