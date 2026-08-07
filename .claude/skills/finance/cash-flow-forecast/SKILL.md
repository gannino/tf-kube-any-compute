---
description: >
  Build a 13-week cash flow forecast table with weekly inflows, outflows, closing
  balance, and the computed runway date for a specific business. Use when the user
  says "cash flow forecast", "runway forecast", "13-week cash model", or "when do we
  run out of cash". Not for monthly P&L projections (use financial-model) or
  historical statements.
user-invocable: true
version: 2.1.0
arguments:
  - name: business
    description: opening balance, known inflows and outflows, payment timings
effort: high
---

# Cash Flow Forecast

The output is the 13-week table and the runway date it implies. Cash timing beats
accounting logic here: revenue counts the week the money lands, not the week it is
invoiced.

## Procedure

1. Confirm: opening bank balance, recurring inflows with their landing week (net of
   payment terms), one-off expected receipts and their confidence, recurring
   outflows (payroll, rent, tools, tax) with their debit week, and known one-offs.
2. Build the weekly table: Opening, Inflows (itemized), Outflows (itemized), Net,
   Closing. Closing of week n is Opening of week n+1, stated explicitly.
3. Compute the runway date: the first week Closing goes negative, or "beyond the
   horizon" with the trend stated.
4. Flag timing risks: any single receipt that, if 4 weeks late, changes the runway
   date. Show that scenario as one extra line.

## Worked example (fictional, first 4 of 13 weeks)

Opening balance 18,000 GBP. Retainers 6,000 GBP landing weeks 2, 6, 10. Payroll
7,500 GBP weeks 4, 8, 12. Rent and tools 1,100 GBP every week 1 of the month.

| Week | Opening | Inflows | Outflows | Net | Closing |
|---|---|---|---|---|---|
| W1 | 18,000 | 0 | 1,100 | -1,100 | 16,900 |
| W2 | 16,900 | 6,000 | 0 | +6,000 | 22,900 |
| W3 | 22,900 | 0 | 0 | 0 | 22,900 |
| W4 | 22,900 | 0 | 7,500 | -7,500 | 15,400 |

Continued to W13, this pattern closes at 9,700 GBP with no negative week: runway
extends beyond the 13-week horizon. If the W6 retainer slips to W10, the low point
is W8 at 300 GBP, a near-miss worth flagging. All numbers fictional.

## Output contract

Deliver: the full 13-week table (Opening, itemized Inflows, itemized Outflows, Net,
Closing), the runway statement (first negative week or "beyond horizon" plus the
low-point week and amount), and one timing-risk scenario line. Arithmetic must be
internally consistent; label all assumed timings as assumptions.
