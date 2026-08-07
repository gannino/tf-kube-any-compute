---
description: >
  Write slide-by-slide pitch deck content, 12 named slides with headline and body copy
  for each, for a specific venture and raise. Use when the user says "pitch deck",
  "investor deck", "deck outline", or "slides for our raise". Not for the business
  model itself (use business-model-canvas) or monthly updates (use
  investor-update-template).
user-invocable: true
version: 2.1.0
arguments:
  - name: venture
    description: the company, stage, and raise amount
---

# Pitch Deck

The output is the deck content: every slide gets a name, a one-line headline an
investor reads in 3 seconds, and the supporting copy or data that belongs on it.
Design notes are minimal; words and numbers are the deliverable.

## Procedure

1. Confirm: what the company does in one sentence, stage, raise amount, traction to
   date, and the single most surprising true fact about the business.
2. Use the 12-slide spine: Title, Problem, Solution, Product, Market, Business Model,
   Traction, Go-to-Market, Competition, Team, Financials, The Ask.
3. Each slide: a headline that asserts (not labels: "Churn is the industry's open
   wound", never just "Problem"), then 2 to 4 bullets or one chart description.
4. The Ask slide states amount, instrument, runway it buys, and 3 milestones it funds.
5. Every number is either the founder's stated figure or labeled "estimate".

## Worked example (two slides, fictional)

Venture: KerbSide, kerbside EV charging for terraced streets, pre-seed, 500k GBP.

Slide 2, Problem. Headline: "9 million UK drivers have no driveway, so no home
charging." Bullets: public charging costs 3x home rates; terraced streets are 40
percent of urban housing stock; councils have no deployment playbook.

Slide 12, The Ask. Headline: "500k GBP pre-seed for 18 months of runway."
Bullets: SAFE, 3 pilot councils signed; milestones: 200 chargepoints live, 60
percent utilization, Series A data pack complete.

## Output contract

Deliver a markdown document with 12 numbered slide sections. Each section contains:
slide name, assertive headline in quotes, and 2 to 4 content bullets (or a described
chart with its axes and the point it proves). End with a one-paragraph narrative
read-through of the deck's argument. No bracketed placeholders.
