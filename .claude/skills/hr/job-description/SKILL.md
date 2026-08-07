---
description: >
  Write a postable job description with real responsibilities, honest requirements,
  and a salary range for a specific role. Use when the user says "job description",
  "write a JD", "job posting", or "hiring ad for this role". Not for interview
  evaluation (use interview-scorecard) or offer letters.
user-invocable: true
version: 2.1.0
arguments:
  - name: role
    description: the role, seniority, location or remote policy, and budget
---

# Job Description

The output is a JD ready to post: specific about the actual work, honest about the
company stage, with a salary range and a described process. No "rockstar" language,
no 15-item wishlists that filter out good candidates.

## Procedure

1. Confirm: title and seniority, remote policy, salary range (push for one; posts
   with ranges convert better and are legally required in several jurisdictions),
   the 4 to 6 things this person will actually do in month one, and what success
   looks like at 6 months.
2. Structure: one-paragraph company context (stage, size, funding honestly stated),
   "What you will do" (outcome-phrased bullets), "What you need" (max 6 hard
   requirements), "Nice to have" (max 3, clearly optional), compensation and
   benefits, the hiring process step by step with a total timeline.
3. Requirements test: for each item ask "would we reject an otherwise great
   candidate lacking this?" If no, move it to nice-to-have or delete it.
4. Strip biased phrasing: no age proxies ("digital native"), no gender-coded
   superlatives, no unpaid trial work.

## Worked example (excerpt, fictional)

Role: Customer Support Lead at a 9-person SaaS, remote UK, 38,000 to 45,000 GBP.

What you will do: own the support inbox end to end (about 40 tickets/day between
two of you); write and maintain the help center (currently 12 articles, needs 40);
turn ticket patterns into a weekly product feedback report; hire and train the
second support person in Q1.

Process: 30-minute screen, take-home ticket exercise (90 minutes, paid 50 GBP),
final interview with the founders. Two weeks start to offer.

## Output contract

Deliver a markdown JD with: company context paragraph, What you will do (4 to 6
outcome bullets), What you need (max 6), Nice to have (max 3), salary range and
benefits, and the hiring process with timeline. Zero bracketed placeholders and
zero superlative fluff; every bullet describes observable work.
