---
description: >
  Produces a pass/fail healthcare marketing compliance audit checklist covering
  authorizations, channels, website tracking, vendors, and reviews per jurisdiction. Use
  when the user says "HIPAA marketing audit", "is my clinic marketing compliant",
  "healthcare marketing checklist", "audit our patient data marketing", or "marketing
  compliance review".
user-invocable: true
version: 2.0.0
---

# Healthcare Marketing Compliance Audit Checklist

## Purpose

Outputs an actual audit checklist: grouped items, each marked PASS / FAIL / N-A, with an
evidence column and an owner column. Not a strategy memo, not a KPI table. The checklist is
the artifact.

## Step 1: Selectors (never silently default)

1. **Jurisdiction**: US (HIPAA/FTC), Spain (GDPR + LOPDGDD + regional publicidad
   sanitaria), other EU (GDPR baseline, flag national rules), UK (UK GDPR, flag CAP/ASA),
   other (emit the US skeleton and flag for local counsel). If already stated, do not re-ask.
2. **Scale**: hospital system / 1-3 practitioner clinic / dental practice / med-spa or
   aesthetic clinic.

## Step 2: Emit the checklist

Table columns: Item | PASS / FAIL / N-A | Evidence | Owner. Groups:

**Authorizations**
- Signed marketing authorization on file for every testimonial, photo, and patient story in
  use (45 CFR 164.508(a)(3) in the US; GDPR Art 9(2)(a) explicit consent in the EU).
- Each authorization names the channels actually in use.
- Remuneration statement present wherever a third party funds the content.

**Channels**
- Patient-list emails ride on documented authorization or opt-in; a patient list itself
  reveals health information, so neutral message content does not remove the requirement.
- Unsubscribe and opt-out honored and logged. US: CAN-SPAM basics. EU/Spain: prior opt-in
  under ePrivacy and LSSI arts. 21-22.

**Website**
- Tracking pixels and analytics on patient-facing pages reviewed. Flag as elevated risk:
  OCR's online-tracking bulletin treated unauthenticated-page visitor data as potentially
  PHI, and a federal court vacated part of that position in AHA v. HHS (N.D. Tex., 2024).
  This area is litigation-shaped and unsettled; confirm the current OCR position with
  counsel rather than treating any answer as settled law.
- Forms submitted over encrypted connections.
- Privacy notice current and health-specific (cross-ref the privacy-notice skill).

**Vendors**
- US: BAAs signed with every agency and tool that touches PHI.
- EU: Art 28 processor agreements in place (cross-ref legal/data-processing-agreement).

**Reviews**
- Review-response protocol never confirms patient status.
- No purchased, AI-generated, or insider reviews (16 CFR Part 465).

**Spain add-on section**
- Centro sanitario registration number (RD 1277/2003) displayed in ads.
- Regional publicidad sanitaria authorization obtained where the autonomous community
  requires it. Which communities require prior authorization versus vigilance changes over
  time; check the current regime of the community where the ad runs and display the
  authorization number where required. Confirm with counsel.
- No RD 1907/1996 prohibited claim patterns (cure promises, miracle framings).
- DPO appointed (LOPDGDD Art 34 obliges health centers).

**Scale swaps**: hospital system adds workforce-training and form-registry items; med-spa
adds before/after photo policy items (unedited beyond crop and exposure, comparable lighting
and pose, no implied typical results without substantiation).

## Hard rules

Present the artifact as counsel-review-ready, never as final. Do not claim the audit proves
compliance; a PASS on every line means the checklist found no gaps, and the checklist
supports compliance review rather than replacing counsel. No em dashes, no absolute claims.

## Worked example (excerpt)

> | Item | Status | Evidence | Owner |
> |---|---|---|---|
> | Signed authorization for the Jane S. video on the homepage | FAIL | No form on file | Practice manager |
> | Newsletter list opt-in records exportable | PASS | CRM consent log 2026-06 | Marketing lead |
> | Meta pixel on the booking page reviewed | CAUTION | Present; counsel review booked | Web vendor |

(Northside Dental, fictional clinic, US small-clinic scale.)

## Closing block (mandatory on every emitted checklist)

> TEMPLATE STATUS: This document is a starting template prepared for review by your legal
> counsel and compliance officer. It is not legal advice, and using it does not create an
> attorney-client relationship. Laws differ by jurisdiction and change; have a qualified
> professional licensed in your jurisdiction approve this document before use.
