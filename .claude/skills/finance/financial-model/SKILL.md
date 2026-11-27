---
description: >
  Build a financial model as an assumptions table plus a monthly P&L skeleton with the
  formulas written out, for a specific business. Use when the user says "financial
  model", "revenue model", "build our projections", or "model this business". Not for
  weekly cash timing (use cash-flow-forecast) or CAC/LTV math alone (use
  unit-economics-model).
user-invocable: true
version: 2.1.0
arguments:
  - name: business
    description: the business, pricing, and known actuals
effort: high
---

# Financial Model

The output is the model: a named assumptions table and a monthly P&L with every line
computed from those assumptions by a visible formula. A reader must be able to rebuild
it in a spreadsheet in ten minutes.

## Procedure

1. Confirm: revenue mechanics (price, billing period), acquisition assumption (new
   customers per month and its driver), churn, gross margin drivers, fixed costs,
   and the horizon (default 12 months).
2. Write the assumptions table first. Every assumption gets an id (A1, A2...), a
   value, and a one-line source or rationale. Anything unsourced is labeled "guess".
3. Build the monthly P&L: customers (opening + new minus churned), revenue, COGS,
   gross profit, opex lines, net. Each line states its formula in terms of
   assumption ids.
4. Show 3 sensitivity rows: net at churn +50 percent, at new customers minus 30
   percent, at price +20 percent.

## Worked example (fictional, first 3 months)

Business: 49 USD/mo helpdesk tool. A1 price = 49. A2 new customers/mo = 20 (guess).
A3 monthly churn = 4% (guess). A4 gross margin = 85%. A5 fixed opex = 6,000 USD.

| Month | Customers | Revenue | Gross profit | Opex | Net |
|---|---|---|---|---|---|
| M1 | 20 | 980 | 833 | 6,000 | -5,167 |
| M2 | 39 | 1,911 | 1,624 | 6,000 | -4,376 |
| M3 | 57 | 2,793 | 2,374 | 6,000 | -3,626 |

Formulas: Customers(n) = Customers(n-1) x (1 - A3) + A2. Revenue = Customers x A1.
Gross profit = Revenue x A4. Net = Gross profit minus A5. All figures are fictional
illustrations.

## Output contract

Deliver: the assumptions table (id, value, source), the monthly P&L table for the
full horizon, the formula list mapping every P&L line to assumption ids, and the
3-row sensitivity table. Label every non-user-supplied number "guess" or "estimate".
No bracketed placeholders.
