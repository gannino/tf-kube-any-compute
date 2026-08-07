---
description: >
  Write a sendable client proposal with scope, pricing table, timeline, and terms for
  a specific engagement. Use when the user says "write a proposal", "client proposal",
  "quote for this project", or "statement of work". Not for cold outreach (use
  cold-email) or internal project planning (use project-plan).
user-invocable: true
version: 2.1.0
arguments:
  - name: engagement
    description: the client, the work, and the intended price if known
---

# Proposal Writer

The output is the proposal document a client could sign, not a template about
proposals. It states what will be delivered, by when, for how much, and what happens
when things change.

## Procedure

1. Confirm: client name and context, the problem in the client's words, deliverables,
   price and payment structure, start date, and any known constraints.
2. Structure: Understanding (2 to 3 sentences proving you heard them), Scope of work
   (numbered deliverables with acceptance conditions), Timeline (phases with dates),
   Investment (a pricing table), Terms (payment schedule, revision limits, change
   requests, ownership), Next step (one action, one deadline).
3. The pricing table shows line items and a total; options, if any, are max three
   tiers with a recommended one marked.
4. Terms are plain language: 50 percent to start is "50 percent due on signature",
   not legalese. Include a validity date for the quote.

## Worked example (fictional excerpt)

Engagement: website rebuild for Bramble & Co, a 6-person accounting firm.

| Item | Description | Price |
|---|---|---|
| Design | 5 page templates, 2 revision rounds | 2,400 GBP |
| Build | CMS build, forms, migration of 18 pages | 3,600 GBP |
| Launch | DNS cutover, redirects, 30-day support | 800 GBP |
| **Total** | | **6,800 GBP** |

Terms excerpt: 50 percent (3,400 GBP) due on signature, balance on launch. Two
revision rounds per deliverable; further rounds at 95 GBP/hour. Quote valid until
a stated date 30 days out. All figures fictional.

## Output contract

Deliver a markdown proposal with the six sections above, a pricing table that sums
correctly, dated timeline phases, a payment schedule tied to milestones, and a
single clear next step. No bracketed placeholders; unknown client facts are asked
for, not invented.
