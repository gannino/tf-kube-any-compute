---
name: evidence-grading
description: >
  Grading evidence strength from evidence TYPE, never from wording. Load when
  the user says "how strong is this evidence", "can I trust this number",
  "grade this source", "likelihood ratio", or "is this claim actually
  supported". Persuasion words cap credibility, they never raise it.
version: 1.0
user-invocable: true
---

# Evidence Grading

The engine grades evidence automatically: the evidence-integrator assigns
likelihood ratios from the evidence-type rubric and `engine/ingest.mjs` runs
every item through four gates before it can enter the graph. This skill is how
you grade evidence the same way in your own head, and how you sanity-check the
LR column when you read a run's evidence log.

## The rubric, with recognition cues

Grade by what the evidence IS, never by how confidently it is written:

- **Primary data / experiment / panel, LR 2.5 to 4.0.** You can see the method
  and the n. A cohort export, a controlled test, a survey with its instrument.
- **Official filing or government statistic, LR 2.0 to 3.0.** A regulator or
  statistics office attached its name to it.
- **Direct vendor artifact, LR 1.5 to 2.0.** A live pricing page you fetched
  yourself, a changelog, a docs page. The vendor speaks about itself.
- **Reputable secondary reporting, LR 1.2 to 1.6.** A named outlet with
  editorial process, reporting someone else's facts.
- **Blog or forum assertion, LR 1.0 to 1.3.** A person said a thing.
- **Absence of evidence, exactly 1.0.** It moves nothing in either direction.
  "No competitor found" supports blue ocean and dead zone equally.

## The puffery rule

"Definitive", "proven", "authoritative" never raise a grade; they CAP it (the
engine caps such items at LR 2.0) and are themselves a manipulation signal.
Confidence of tone is what fabrication wears; method is what evidence wears.

## Extraction fidelity

How the value got out of the source matters: a verbatim number carries weight
1.0, a paraphrase 0.6 to 0.8, an inference 0.4. "The report says 14M" and "the
report implies roughly 14M" are different strengths and should be recorded as
such.

## The disconfirming mirror

Disconfirming evidence grades by the same type logic, with LR below 1. One
strong primary refutation outweighs ten supportive blog posts, which is the
arithmetic of why refutation-hunting is efficient.

## The four gates as human questions

1. Is the source alive? A dead link contributes nothing.
2. Does the passage actually contain the value at the claimed scope? Right
   number about the wrong entity fails here.
3. Does the number survive sanity arithmetic (shares sum to about 100, a
   segment does not exceed its parent market)?
4. Is the provenance complete: source, date, and the exact passage?

## Worked example (fictional, for illustration only)

One claim: "the hypothetical product Acme has 50,000 paying users." Four
sources: a vendor press release stating it (direct vendor artifact, 1.5 to
2.0, but promotional wording caps it), two trade articles that cite that press
release (secondary in form, but both trace to the same origin, so together they
add almost nothing beyond the release itself), and a government procurement
filing listing seat counts for one large deployment (official statistic, 2.0 to
3.0, narrow scope). Net read: three of the four items collapse toward one vote,
the filing independently supports only a fraction of the claim, and the honest
grade is "single-origin headline number, partially corroborated at a narrower
scope". Ten minutes of grading turned "four sources confirm" into that.

## Artifact-shaped output

One evidence log row per graded item:

| Source | Type tier | LR range | Fidelity | Gates (1-4) | Origin id |
|---|---|---|---|---|---|
| acme.com press release | vendor artifact | 1.5 (capped, puffery) | verbatim 1.0 | pass/pass/pass/pass | org-acme-pr1 |
| tradeweekly article | secondary | 1.2 | paraphrase 0.7 | pass/pass/pass/pass | org-acme-pr1 |
| procurement filing | official | 2.5 | verbatim 1.0 | pass/scope-narrow/pass/pass | org-gov-fil3 |
