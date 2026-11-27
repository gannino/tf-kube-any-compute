---
description: >
  Write a complete technical specification with goals, non-goals, proposed design,
  alternatives considered, and a rollout plan for a stated engineering change. Use
  when the user says "technical spec", "design doc", "write an RFC", or "spec this
  system". Not for product requirements (use prd-writer) or a single decision record
  (use architecture-decision-record).
user-invocable: true
version: 2.1.0
arguments:
  - name: change
    description: the system change or feature to specify
---

# Technical Spec

The output is the spec a reviewer can approve or block with reasons: concrete design,
named trade-offs, and a rollout that includes the failure path. Vague sections are
worse than absent ones; every claim about the current system is checked against the
code when available.

## Procedure

1. Confirm the problem, the systems touched, load or scale expectations, and any
   deadline or compliance constraint.
2. Sections in order: Summary, Background (current state, with file or service
   names), Goals (measurable), Non-goals, Proposed design (data model, API shapes,
   sequence of operations), Alternatives considered (at least two, with the reason
   each lost), Rollout plan (phases, flags, migration, rollback trigger),
   Observability (metrics and alerts added), Open questions.
3. Include at least one concrete interface artifact: an API request/response
   example, a schema DDL, or a sequence diagram in text.
4. The rollback section states the exact trigger condition and the command or flag
   that reverts.

## Worked example (fictional excerpt)

Change: move session storage from in-process memory to Redis for a 3-node API.

Proposed design excerpt:

```
POST /login  ->  SETEX session:{uuid} 86400 {json}
Session lookup: GET session:{id}, fallback = 401 (no DB fallback, by design)
Key size budget: 2 KB/session x 50k sessions = 100 MB, fits a 1 GB instance
```

Alternative rejected: sticky sessions at the load balancer; lost because deploys
drain nodes and would log out a third of users per release. Rollback trigger: p99
login latency above 400 ms for 10 minutes; revert = flip `SESSION_BACKEND=memory`.

## Output contract

Deliver a markdown spec with all nine sections, at least one fenced interface
artifact with real field names, two or more alternatives each with a losing reason,
and a rollback trigger with its revert mechanism. Numbers are estimates unless
measured, and say which.
