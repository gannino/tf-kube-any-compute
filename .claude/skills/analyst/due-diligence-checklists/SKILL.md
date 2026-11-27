---
name: due-diligence-checklists
description: >
  Product, market, team, and financial diligence checklists where every item is
  an observable with a pass/flag criterion. Load when the user says "diligence
  checklist", "vet this company", "red flags", "verify the claimed numbers", or
  "should we do this deal". Private output only.
version: 1.0
user-invocable: true
effort: high
---

# Due Diligence Checklists

The engine runs diligence automatically: `/due-diligence` frames the decision as
write-the-check vs pass, runs the bear with independent collection by default,
and renders the investor dossier with its assumptions ledger. This skill is how
you run the same checks yourself, and how you read a diligence dossier without
being soothed by its completeness.

## The frame

The decision is write-the-check vs pass, and the loss ladder is elicited in
those terms: how much worse is a wrong check than a missed winner? Answer that
before collecting anything, because it decides how much disconfirming evidence
you owe yourself.

## The four checklists

Every item is an observable plus a criterion, never a vibe.

**PRODUCT.** Activation and retention by cohort, not vanity totals (flag: only
cumulative signups offered). Churn by cohort (flag: blended churn hiding a
decaying newest cohort). Roadmap shipped vs promised over the last year (flag:
ratio below half). Support-load signal per account (flag: rising tickets per
account while headcount is flat).

**MARKET.** Real category vs feature of someone else's platform (flag: the whole
product restates one incumbent capability). Timing evidence: what changed that
makes this work now (flag: no dated answer). Concentration of demand (flag: top
3 customers over 40 percent of revenue).

**TEAM.** Key-person dependency (flag: one person holds product, code, and the
top customer relationships). Reference triangulation across 3 independent
origins, not the founder's provided list alone. Prior-outcome base rates for the
team's category, stated before the pitch narrative is read.

**FINANCIAL.** Revenue quality: recurring vs one-time vs related-party (flag:
related-party revenue presented as organic). Claimed vs verifiable for every
headline metric. Unit economics as intervals, never a single flattering ratio.
Runway arithmetic recomputed from the bank statement, not the deck.

## The master rule

Every claimed metric that cannot be traced to a primary source is itself a
finding. And the most common diligence trap is right number, wrong entity: the
figure is real but belongs to a different scope (the parent company, the whole
platform, the pre-pivot product). That is scope-bound entailment in human form:
check that the passage containing the number is actually about the entity being
bought.

## Worked example (fictional, for illustration only)

A hypothetical target claims "4M dollars ARR" in its deck. Tracing: the deck
cites a trade-press profile; the profile cites a press release; the press
release is from the target's parent holding company and describes group-wide
recurring revenue across three products. The number is real and the entity is
wrong. Verdict: red-flag, with the ask reissued as "product-level ARR with an
accounting export as the primary source". One hour of tracing changed the
finding from "confirmed" to "unverified at the product scope".

## Artifact-shaped output

The diligence findings table, which drops directly into the investor template's
assumptions ledger:

| Checklist item | Evidence found | Source class | Verdict |
|---|---|---|---|
| Product-level ARR | Press release, parent-company scope | secondary | red-flag |
| Retention by cohort | Accounting export, month cohorts | primary | solid |
| Key-person dependency | Org review, 2 of 3 functions held by founder | internal | risky |

## Boundary

Diligence output is never published and never a public teardown of a named
third party. It is decision support, not investment advice.
