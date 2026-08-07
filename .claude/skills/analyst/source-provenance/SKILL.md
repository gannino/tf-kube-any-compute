---
name: source-provenance
description: >
  Source liveness, origin tracing, and citation laundering detection. Load when
  the user says "is this source still live", "who actually said this first",
  "are these independent sources", "citation laundering", or "check the
  provenance of this number". N sources tracing to one origin are one vote.
version: 1.0
user-invocable: true
---

# Source Provenance

The engine polices provenance automatically: the research-sensor pulls once and
provenance-tags everything, `engine/independence.mjs` clusters sources by origin
and applies the correlation haircut, `engine/ras.mjs` scores coverage against
the expected-source-class checklist, and ingest gates 1 and 4 enforce liveness
and provenance completeness. This skill is how you run the same checks by hand
on any claim, and how you read a run's source ledger.

## Liveness first

A dead or unreachable source contributes nothing, whatever it once said. Check
that the URL resolves and the passage is still there before citing, and record
the fetch date; a source that is alive today is only known to be alive today.

## Origin tracing

Two sources are the SAME origin when any of these hold: same registrable
domain, same underlying report or press release or number-set, or one page
citing the other. When unsure, cluster together; the pessimistic error is
under-confidence, which is the safe direction. What counts toward a claim's
strength is its independent-origin count, never its citation count.

## The laundering pattern

The failure that motivated the rule: one press release wearing five URLs read
as five votes. Trade coverage, aggregators, and reblogs multiply a single
origin into an apparent consensus. A single-origin claim stays LOW confidence
however reputable the origin, because there is nothing in the pool that could
have contradicted it.

## Decay is a property of the fact

Facts age at different speeds, and the half-life belongs to the fact type:
fast-mover company metrics about 90 days (the documented case: an ARR figure
that was true drifted 5.6x wrong within a year), competitor pricing about 180,
established market sizes about 365, regulation about 730. An old number is not
wrong, it is weak, and a stale fast-mover gets flagged visibly, never just
silently discounted.

## Provenance completeness

No naked numbers. Every value carries its source, its fetch date, and the
exact passage that contains it. A number you cannot point back into a passage
is a rumor with formatting.

## The expected-sources checklist

Before judging a claim, list the source classes a claim of this type SHOULD
have: an official filing, primary data, a direct vendor artifact. Then report
the ones you expected but did not find. That missing-sources ledger is a
feature, not an apology; it is the difference between "confirmed" and
"confirmed by everything we could reach".

## Worked example (fictional, for illustration only)

A funding figure for a hypothetical startup appears in five URLs: the
company's own press release, two trade articles citing that release, an
aggregator scraping one of the articles, and a national registry filing.
Tracing collapses the first four into one origin (the release); the filing is
a second, independent origin, but it is 14 months old against a fast-mover
half-life. Honest read: two independent origins, one stale and flagged, so the
claim stands at moderate confidence at best, not the "five sources confirm"
its citation count suggested.

## Artifact-shaped output

The source ledger plus the missing-expected-sources list:

| Source | Origin id | Class | Fetch date | Age vs half-life | Live? |
|---|---|---|---|---|---|
| company press release | org-pr-1 | vendor artifact | {date} | fresh | live |
| trade article A | org-pr-1 | secondary | {date} | fresh | live |
| trade article B | org-pr-1 | secondary | {date} | fresh | live |
| aggregator page | org-pr-1 | weak secondary | {date} | fresh | live |
| registry filing | org-fil-2 | official filing | {date} | 14mo vs 90d: STALE, flagged | live |

MISSING EXPECTED SOURCES: current-period filing; any primary data independent
of the company's own announcement.
