---
description: >
  Drafts a complete patient consent form for a named treatment or procedure, with numbered
  clauses, jurisdiction-specific data language, and signature blocks. Use when the user says
  "write a consent form", "patient consent form", "consent form for a procedure",
  "consentimiento informado", or "treatment consent template".
user-invocable: true
version: 2.0.0
---

# Patient Consent Form (treatment and procedures)

## Purpose

Produce the actual consent form a clinic can hand to counsel for review: numbered clauses, a
patient identification block, jurisdiction-correct data language, and signature blocks. This
skill never outputs a strategy memo, an executive summary, or a metrics table. The output is
the form itself.

## Step 1: Selectors (ask before drafting, never silently default)

1. **Jurisdiction**: Which jurisdiction governs? US (HIPAA/FTC), Spain (GDPR + LOPDGDD +
   regional publicidad sanitaria), other EU (GDPR baseline, flag national rules), UK
   (UK GDPR, flag CAP/ASA), other (emit the US skeleton and flag for local counsel). If the
   user already stated a country, do not re-ask.
2. **Scale**: hospital system / 1-3 practitioner clinic / dental practice / med-spa or
   aesthetic clinic.
3. **Procedure**: which treatment or service this consent covers.

## Step 2: Emit the form

Structure, in order:

- **Header**: clinic legal name and address. Spain: include the centro sanitario registration
  number issued under RD 1277/2003 by the autonomous community. Hospital-system scale:
  reference the system-wide form ID and the privacy office that owns the form registry.
- **Patient identification block**: full name, date of birth, record number. Spain adds
  DNI/NIE. Minors: parent or guardian block. Spain note: the age 14 threshold in LOPDGDD
  Art 7 applies to digital services data consent, NOT to medical consent, which follows
  patient-autonomy law and clinical judgment. Flag this distinction for counsel.
- **Clause 1. Nature of the procedure**: plain-language description of what will be done.
- **Clause 2. Expected benefits**.
- **Clause 3. Material risks and common side effects**.
- **Clause 4. Reasonable alternatives**, including the option of no treatment.
- **Clause 5. Questions answered** and the ongoing opportunity to ask more.
- **Clause 6. Right to withdraw consent** at any time before the procedure.
- **Clause 7. Data clause (jurisdiction swap)**:
  - US version: references the clinic's Notice of Privacy Practices (see the privacy-notice
    skill) for how health information is used and disclosed.
  - Spain version: the full GDPR Art 13 information block: controller identity, DPO contact,
    purposes, Art 9(2)(h) basis for care, retention per clinical-records law, data subject
    rights, and the right to complain to the AEPD.
- **Signature blocks**: patient or representative, treating clinician, date, place. Med-spa
  scale adds a photography-during-procedure checkbox that expressly does NOT authorize
  marketing use (marketing use routes to the media-release-authorization skill).

## Hard rules

- This form never bundles marketing consent, a media release, or AI consent. Those are
  separate instruments: see media-release-authorization, marketing-communications-consent,
  and ai-likeness-consent.
- Present the artifact as counsel-review-ready, never as final. Do not claim the document is
  compliant; claim it is structured for compliance review. The words "legally binding" and
  "fully compliant" are banned from outputs.
- No em dashes anywhere in the output.

## Worked example (excerpt)

Northside Dental, tooth extraction consent (US, dental practice scale):

> **Northside Dental, 12 Example Street** (fictional clinic)
> Patient: Jane Sample, DOB 04/02/1985, Record #ND-1042
>
> **1. Nature of the procedure.** Dr. Reyes will remove tooth #30 (lower right first molar)
> under local anesthesia. The visit is expected to take about 45 minutes.
> **2. Expected benefits.** Relief of pain and removal of the infection source.
> **3. Material risks.** Bleeding, swelling, dry socket, infection, temporary or in rare
> cases lasting numbness of the lip or tongue, damage to nearby teeth.
> **4. Alternatives.** Root canal treatment, or no treatment, which risks worsening
> infection.
> ...
> Patient signature: ______ Date: ______ Clinician signature: ______ Date: ______

## Closing block (mandatory on every emitted form)

> TEMPLATE STATUS: This document is a starting template prepared for review by your legal
> counsel and compliance officer. It is not legal advice, and using it does not create an
> attorney-client relationship. Laws differ by jurisdiction and change; have a qualified
> professional licensed in your jurisdiction approve this document before use.
