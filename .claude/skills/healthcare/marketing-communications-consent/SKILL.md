---
description: >
  Produces the marketing communications consent pack for patient email and SMS: the opt-in
  capture block, the consent register schema, and the withdrawal footer. Use when the user
  says "patient newsletter opt-in", "can I email my patient list", "SMS marketing consent
  clinic", "healthcare email marketing consent", or "LSSI opt-in".
user-invocable: true
version: 2.0.0
---

# Marketing Communications Consent Pack (email/SMS)

## Purpose

Emailing a patient list is not neutral: the fact of being on a clinic's list reveals health
information, so patient-list marketing is regulated in both regimes even when the message
content is bland. This skill outputs three real artifacts, not advice.

## Step 1: Selectors (never silently default)

1. **Jurisdiction**: US (HIPAA/FTC), Spain (GDPR + LOPDGDD + regional publicidad
   sanitaria), other EU (GDPR baseline, flag national rules), UK (UK GDPR, flag CAP/ASA),
   other (emit the US skeleton and flag for local counsel). If already stated, do not re-ask.
2. **Scale**: hospital system / 1-3 practitioner clinic / dental practice / med-spa or
   aesthetic clinic.
3. **Channels and purposes** the clinic actually wants (newsletter, offers, event invites).

## Step 2: Emit the three artifacts

### Artifact 1: The opt-in capture block

Form or checkbox wording, granular per channel AND per purpose, every box UNTICKED, and
unbundled from care paperwork. Care reminders and recall messages are healthcare
operations, stated as such next to the marketing boxes so patients see the difference, and
never presented as opt-in marketing. The block states in plain language that ticking
nothing changes nothing about care.

### Artifact 2: The consent register schema

Both regimes require demonstrable consent. Columns: who (patient identifier) | when
(timestamp) | what wording was shown (versioned) | channel | proof (form scan, checkbox
log) | withdrawal date. State the retention rule: keep the record for as long as the
consent is relied on plus the local limitation period; confirm the exact period with
counsel.

### Artifact 3: The footer and withdrawal block

For every marketing message: who is sending, why the recipient is receiving it, a
functioning one-step unsubscribe, and the postal address where required. Withdrawal takes
effect promptly and is logged in the register.

## Clause logic per regime

- **US**: marketing communications using PHI need a signed HIPAA authorization (45 CFR
  164.508(a)(3)); every message needs a functioning opt-out (CAN-SPAM basics). Care
  reminders and recall are operations, not marketing, and are labeled as such.
- **EU/Spain**: patient-list email marketing is special-category processing riding on GDPR
  Art 9(2)(a) explicit consent, PLUS the ePrivacy/LSSI (arts. 21-22) prior opt-in for
  electronic marketing. The soft opt-in for a clinic's own similar services is narrow, and
  its scope for health services is UNCERTAIN; confirm with counsel before relying on it.
  Consent must be unbundled from treatment paperwork.

Cross-ref: patient-intake-form captures these opt-ins at intake; privacy-notice discloses
the processing.

## Hard rules

Present every artifact as counsel-review-ready, never as final. Do not claim the pack is
compliant; claim it is structured for compliance review. No pre-ticked boxes, ever. No em
dashes, no absolute claims.

## Worked example (excerpt)

Northside Dental opt-in block (US, fictional clinic):

> **Appointment reminders.** We send appointment reminders by text as part of managing
> your care. This is not marketing and no box is needed.
>
> **Optional updates (your choice, boxes unticked):**
> [ ] Email me the monthly oral health newsletter.
> [ ] Text me about occasional whitening offers.
> Leaving these blank changes nothing about your care. Unsubscribe any time using the link
> in any email or by replying STOP to any text.

## Closing block (mandatory on every emitted artifact)

> TEMPLATE STATUS: This document is a starting template prepared for review by your legal
> counsel and compliance officer. It is not legal advice, and using it does not create an
> attorney-client relationship. Laws differ by jurisdiction and change; have a qualified
> professional licensed in your jurisdiction approve this document before use.
