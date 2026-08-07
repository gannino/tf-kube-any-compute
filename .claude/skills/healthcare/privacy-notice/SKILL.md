---
description: >
  Drafts the health-specific privacy notice itself: the US Notice of Privacy Practices per
  45 CFR 164.520 or the Spanish layered RGPD web notice. Use when the user says "notice of
  privacy practices", "clinic privacy policy", "política de privacidad clínica", "HIPAA
  privacy notice", or "GDPR privacy notice for a medical practice".
user-invocable: true
version: 2.0.0
---

# Privacy Notice (NPP / RGPD web notice)

## Purpose

Outputs the actual notice document, ready for counsel review. This skill owns the
health-specific notice only; for the general site layers cross-ref legal/privacy-policy and
legal/cookie-policy.

## Step 1: Selectors (never silently default)

1. **Jurisdiction**: US (HIPAA/FTC), Spain (GDPR + LOPDGDD + regional publicidad
   sanitaria), other EU (GDPR baseline, flag national rules), UK (UK GDPR, flag CAP/ASA),
   other (emit the US skeleton and flag for local counsel). If already stated, do not re-ask.
2. **Scale**: hospital system / 1-3 practitioner clinic / dental practice / med-spa or
   aesthetic clinic. Hospital systems reference the privacy office and system-wide notice
   version; small clinics name the privacy contact person.

## Step 2: Emit the notice

### US version: Notice of Privacy Practices, 45 CFR 164.520 structure

- Required header statement, in the required tone: "THIS NOTICE DESCRIBES HOW MEDICAL
  INFORMATION ABOUT YOU MAY BE USED AND DISCLOSED AND HOW YOU CAN GET ACCESS TO THIS
  INFORMATION. PLEASE REVIEW IT CAREFULLY."
- Uses and disclosures for treatment, payment, and healthcare operations, with a
  plain-language example of each.
- Uses REQUIRING written authorization, expressly including marketing and sale of PHI, and
  most uses of psychotherapy notes.
- Individual rights: access and copies, amendment, accounting of disclosures, restriction
  requests, confidential communications, breach notification, a paper copy of the notice.
- The clinic's duties, and its right to change the notice.
- Complaints: to the practice contact AND to the HHS Office for Civil Rights, with the
  statement that no retaliation will follow a complaint.
- Effective date.

### Spain version: layered RGPD web notice

- Layer 1 (short table at the point of collection): responsable, finalidad, legitimación,
  destinatarios, derechos, and where to read the full notice.
- Layer 2 (full notice): controller identity and registration; DPO contact (mandatory for
  health centers under LOPDGDD Art 34); purposes with the legal bases SEPARATED: care under
  Art 9(2)(h), marketing only ever under explicit Art 9(2)(a) consent, never bundled;
  recipients and processors; retention referencing the clinical-records law of the
  applicable community; data subject rights and how to exercise them; the right to complain
  to the AEPD.

## Hard rules

Present the artifact as counsel-review-ready, never as final. Do not claim the document is
compliant; claim it is structured for compliance review. "Fully compliant" and similar
absolutes are banned from outputs. No em dashes anywhere.

## Worked example (excerpt)

Northside Dental NPP opening (US, fictional clinic):

> **Northside Dental Notice of Privacy Practices** (effective 01 Aug 2026)
> THIS NOTICE DESCRIBES HOW MEDICAL INFORMATION ABOUT YOU MAY BE USED AND DISCLOSED AND HOW
> YOU CAN GET ACCESS TO THIS INFORMATION. PLEASE REVIEW IT CAREFULLY.
> **For treatment.** We use your dental records to plan your care, for example sharing an
> x-ray with the oral surgeon we refer you to.
> **Uses that need your written authorization.** We will not use your information for
> marketing, and will never sell it, without your signed authorization. You may revoke an
> authorization at any time; revocation applies going forward.

## Closing block (mandatory on every emitted notice)

> TEMPLATE STATUS: This document is a starting template prepared for review by your legal
> counsel and compliance officer. It is not legal advice, and using it does not create an
> attorney-client relationship. Laws differ by jurisdiction and change; have a qualified
> professional licensed in your jurisdiction approve this document before use.
