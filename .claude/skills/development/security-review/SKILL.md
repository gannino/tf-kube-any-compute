---
description: >
  Run a security review of code or a diff and emit a findings table with severity,
  file and line, exploit scenario, and a concrete fix per finding. Use when the user
  says "security review", "security audit", "check this for vulnerabilities", or "is
  this code safe". Not for dependency version scanning alone or infrastructure
  hardening outside the code under review.
user-invocable: true
version: 2.1.0
arguments:
  - name: scope
    description: the files, diff, or directory to review
effort: high
---

# Security Review

The output is a findings table, not a lecture. Every finding names the file and line,
how an attacker uses it, and the exact fix. Zero findings is a valid result and is
stated plainly with what was checked.

## Procedure

1. Read the scoped code fully before judging. Note the trust boundaries: where does
   user input enter, where do secrets live, what talks to the network or filesystem.
2. Sweep for the recurring classes: injection (SQL, command, template), missing
   authorization checks (not just authentication), secrets in code or logs, unsafe
   deserialization, path traversal, SSRF, weak crypto or randomness, and
   race-prone check-then-act sequences.
3. Grade severity: Critical (remote compromise or data theft, no auth), High
   (authenticated user crosses a boundary), Medium (hardening gap with a plausible
   chain), Low (defense in depth).
4. For each finding write the one-line exploit scenario; if you cannot write one,
   downgrade it or drop it.
5. Order the table by severity; end with what was explicitly out of scope.

## Worked example (fictional finding)

| # | Severity | Location | Finding | Exploit scenario | Fix |
|---|---|---|---|---|---|
| 1 | Critical | api/export.js:41 | User-supplied `table` interpolated into SQL string | `?table=users;--` dumps arbitrary tables | Allowlist table names; use parameterized identifiers |
| 2 | Medium | lib/token.js:12 | Session token from `Math.random()` | Tokens predictable given a few samples | Use `crypto.randomBytes(32)` |

## Output contract

Deliver: a summary line (files reviewed, findings by severity count), the findings
table with columns Severity, Location (file:line), Finding, Exploit scenario, Fix,
then an Out-of-scope list. Each fix must be specific enough to implement without a
follow-up question. If no findings: state the classes checked and the boundaries
inspected.
