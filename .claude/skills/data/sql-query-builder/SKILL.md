---
description: >
  Write working SQL for a described schema and question, with the dialect stated and
  the query explained line by line. Use when the user says "write a SQL query", "query
  for this", "SQL to find", or "turn this question into SQL". Not for schema design or
  migrations, and not for query performance tuning alone (use query-optimization).
user-invocable: true
version: 2.1.0
arguments:
  - name: request
    description: the schema (tables and columns) and the question to answer
paths:
  - "**/*.sql"
---

# SQL Query Builder

The output is runnable SQL against the stated schema, not SQL-shaped pseudocode.
If the schema is not given, ask for table and column names before writing; guessed
column names produce queries that fail at the first run.

## Procedure

1. Confirm the dialect (default: PostgreSQL, stated in the answer), the exact
   tables and columns involved, and what one row of the desired result represents.
2. Write the query with CTEs over nested subqueries when logic has stages. Name
   CTEs after what they contain, not "t1".
3. Handle the classic silent bugs explicitly: NULLs in aggregations and NOT IN,
   duplicate inflation from one-to-many joins, timezone assumptions in date
   filters, and division by zero in ratios (NULLIF).
4. Explain each clause in one line, then state one verification query or check the
   user can run to confirm correctness (row count sanity, a known example row).

## Worked example (fictional schema)

Schema: orders(id, customer_id, created_at, total_cents),
customers(id, email, created_at). Question: monthly revenue and new-customer count
for the last 6 full months. Dialect: PostgreSQL.

```sql
WITH months AS (
  SELECT date_trunc('month', created_at) AS month,
         SUM(total_cents) / 100.0 AS revenue
  FROM orders
  WHERE created_at >= date_trunc('month', now()) - INTERVAL '6 months'
    AND created_at < date_trunc('month', now())
  GROUP BY 1
),
new_customers AS (
  SELECT date_trunc('month', created_at) AS month, COUNT(*) AS new_count
  FROM customers
  WHERE created_at >= date_trunc('month', now()) - INTERVAL '6 months'
    AND created_at < date_trunc('month', now())
  GROUP BY 1
)
SELECT m.month, m.revenue, COALESCE(n.new_count, 0) AS new_customers
FROM months m LEFT JOIN new_customers n USING (month)
ORDER BY m.month;
```

Check: the current partial month is excluded by the upper bound; COALESCE keeps
months with zero signups visible.

## Output contract

Deliver: the dialect statement, one fenced sql block that parses and runs against
the stated schema, a clause-by-clause explanation list, and one verification check.
Flag every assumption about the schema you had to make. No invented columns.
