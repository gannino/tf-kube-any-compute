---
description: >
  Write a complete product requirements document with user stories, acceptance
  criteria, and explicit non-goals for a stated feature. Use when the user says "write
  a PRD", "product requirements", "spec this feature", or "requirements doc". Not for
  engineering design detail (use technical-spec) or roadmap sequencing (use
  product-roadmap).
user-invocable: true
version: 2.1.0
arguments:
  - name: feature
    description: the feature or product being specified
---

# PRD Writer

The output is the PRD itself, complete enough that a designer and an engineer could
start without a meeting. Acceptance criteria are testable statements, never vibes.

## Procedure

1. Confirm: the user problem, who has it, evidence it matters, and any hard
   constraints (platform, deadline, compliance).
2. Write the sections in order: Summary (3 sentences), Problem and evidence, Goals
   (measurable), Non-goals (explicit exclusions with reasons), User stories,
   Acceptance criteria, Edge cases, Success metrics, Open questions.
3. Each user story follows "As a [role], I want [action], so that [outcome]" with
   roles taken from the actual product, not generic personas.
4. Acceptance criteria use Given/When/Then and must be checkable by QA without
   asking anyone.
5. Non-goals get equal care: each one names what is excluded and why, so scope
   creep has to argue with a written sentence.

## Worked example (excerpt, fictional)

Feature: CSV export for a time-tracking app.

Story: As an agency owner, I want to export a date-filtered CSV of tracked hours,
so that I can attach it to client invoices.

Acceptance criteria:
- Given a workspace with 500 entries, when I export March 1 to 31, then the file
  contains only entries in that range, one row per entry, within 5 seconds.
- Given an entry with a comma in its note, when exported, then the CSV remains
  RFC 4180 valid and reimports cleanly.

Non-goal: no PDF export in this release; invoicing tools consume CSV and PDF
doubles the rendering surface for zero validated demand.

## Output contract

Deliver a markdown PRD with all nine sections above, at least 3 user stories, at
least 2 Given/When/Then criteria per story, a Non-goals section with reasons, and
numeric success metrics with a measurement source each. No bracketed placeholders;
open questions are real questions with a named decider.
