---
description: >
  Runs a red-line compliance review of clinic ad copy, reproducing the ad with
  line-referenced findings tagged BLOCK, REVISE, CAUTION, or OK plus replacement wording.
  Use when the user says "review this ad for compliance", "can my clinic say this",
  "publicidad sanitaria review", "is this health claim allowed", or "check my med spa ad".
user-invocable: true
version: 2.0.0
effort: high
---

# Clinic Ad Compliance Red-Line Review

## Purpose

Input: the actual ad copy or creative description, plus jurisdiction and scale. Output: a
red-line review artifact: the ad text reproduced with line-referenced findings, each tagged
BLOCK / REVISE / CAUTION / OK, the rule cited, and suggested replacement wording. Not a
memo about advertising; a marked-up review of THIS ad.

## Step 1: Selectors (never silently default)

1. **Jurisdiction**: US (HIPAA/FTC), Spain (GDPR + LOPDGDD + regional publicidad
   sanitaria), other EU (GDPR baseline, flag national rules), UK (UK GDPR, flag CAP/ASA),
   other (emit the US skeleton and flag for local counsel). If already stated, do not re-ask.
2. **Scale**: hospital system / 1-3 practitioner clinic / dental practice / med-spa or
   aesthetic clinic. Med-spa gets the strictest scan (elective claims); hospital systems
   add service-line claim substantiation items.
3. The ad text itself, line by line.

## Step 2: Apply the rule content

**US:**
- FTC substantiation: every efficacy claim needs competent and reliable scientific
  evidence. Anecdotes and testimonials are never substantiation.
- Atypical-results testimonials must disclose what a typical consumer can expect; "results
  not typical" alone does not cure the problem.
- Endorsement disclosure: material connections (payment, free services, discounts) must be
  clearly disclosed; the advertiser is liable for claims made through endorsers.
- Before/after imagery honesty: no edits beyond crop and exposure, comparable conditions.
- No implied cure claims.

**Spain:**
- RD 1907/1996 prohibited patterns: cure promises, slimming or miracle framings, claims
  exploiting fear.
- Law 14/1986 Art 27: health authorities control advertising of health activities.
- Display of the RD 1277/2003 centro sanitario registration number in the ad.
- Regional prior-authorization check: verify the current regime of the autonomous
  community where the ad will run, and where required obtain and display the authorization
  number. Which communities require prior authorization versus vigilance changes over
  time; confirm with counsel.
- CGCOM deontology cautions for physician-fronted ads (sensationalism, comparative
  superiority, exploiting patient gratitude). Exact article numbers of the current CGCOM
  code: confirm with counsel.

**Banned-pattern scan (verbatim strings the review always flags):** "cure", "risk-free",
"painless" (unqualified), "permanent results", "#1 clinic" (without substantiation), any
assured-results or your-money-back promise wording, and superlatives without evidence.

## Step 3: Emit the red-line artifact

Reproduce the ad with numbered lines. Under it, one finding per line flagged:
`Line N | TAG | rule | replacement wording`. Close with a verdict line: SHIP / SHIP AFTER
REVISIONS / DO NOT SHIP, and the counsel-review disclaimer.

## Hard rules

Present the review as counsel-review-ready, never as final clearance. Do not claim the
revised ad is compliant; claim it is structured for compliance review. Voice-calibrate
replacement wording via brand-voice-calibration-pairs when a voice file exists. No em
dashes, no absolute claims in replacements.

## Worked example (excerpt)

Med-spa ad (US, fictional):

> 1. "Permanent results after one session!"
> 2. "Rated the #1 med spa in the county."
>
> Line 1 | BLOCK | FTC substantiation; assured-results pattern | Replace with: "Many
> clients see results that last 6 to 12 months. Individual results vary."
> Line 2 | REVISE | Unsubstantiated superlative | Replace with: "Rated 4.9 stars by over
> 200 verified clients" (only if true and verifiable).
> Verdict: SHIP AFTER REVISIONS.

## Closing block (mandatory on every emitted review)

> TEMPLATE STATUS: This document is a starting template prepared for review by your legal
> counsel and compliance officer. It is not legal advice, and using it does not create an
> attorney-client relationship. Laws differ by jurisdiction and change; have a qualified
> professional licensed in your jurisdiction approve this document before use.
