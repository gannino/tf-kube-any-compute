---
description: >
  Drafts the real-likeness media release authorization form covering a patient's actual
  photos, video, name, and voice, with per-channel checkboxes and an express AI exclusion.
  Use when the user says "patient photo release", "media release form", "use patient photos
  in marketing", "before and after photo consent", or "cesión de derechos de imagen
  paciente".
user-invocable: true
version: 2.0.0
---

# Media Release (real image, name, voice)

## Purpose

The REAL-likeness half of the AI split. This authorization covers a patient's actual
photographs, video, audio, name, and story. It expressly excludes any AI-generated,
AI-retouched, or synthetic use; that requires the separate ai-likeness-consent instrument.
The two are never merged. The output is the actual authorization form.

## Step 1: Selectors (never silently default)

1. **Jurisdiction**: US (HIPAA/FTC), Spain (GDPR + LOPDGDD + regional publicidad
   sanitaria), other EU (GDPR baseline, flag national rules), UK (UK GDPR, flag CAP/ASA),
   other (emit the US skeleton and flag for local counsel). If already stated, do not re-ask.
2. **Scale**: hospital system / 1-3 practitioner clinic / dental practice / med-spa or
   aesthetic clinic.

## Step 2: Emit the form

- **Clause 1. What is covered**, each with its own checkbox: photographs, video, audio
  recordings, name, stated words, treatment details.
- **Clause 2. Channels**, each a checkbox: clinic website, each specific social platform
  named, paid ads, print, press. No blanket "any media" clause, ever.
- **Clause 3. Duration** and the expiration date or event.
- **Clause 4. Revocation**: in writing at any time, prospective effect, plus the takedown
  commitment stated as a service standard the clinic sets (for example: removal from owned
  channels within 10 business days; material already printed or distributed is excluded).
- **Clause 5. No conditioning of treatment**; no compensation, or the compensation stated;
  and a remuneration statement where a third party funds the marketing (45 CFR
  164.508(a)(3)).
- **Clause 6. Jurisdiction block**: US: the full 45 CFR 164.508(c) authorization elements
  (PHI described, who discloses, who receives, purpose, expiration, revocation right,
  no-conditioning, remuneration where applicable). Spain: the Organic Law 1/1982 image
  cession AND the GDPR Art 9(2)(a) explicit data consent, as two stated consents with both
  signature lines, because image rights and data protection are separate rights in Spain.
- **Clause 7. EXPRESS AI EXCLUSION (mandatory in every variant, verbatim):**

  > This authorization does NOT permit creation or use of AI-generated, AI-retouched, or
  > synthetic versions of my image or voice. Any such use requires the separate AI Likeness
  > and Synthetic Media Consent.

- **Before/after photo rider** (med-spa and dental scales): images unedited beyond crop and
  exposure, presented with comparable lighting and pose, and no implication of typical
  results without substantiation.
- **Signature blocks**: patient or representative, clinic representative, date, place.

## Hard rules

- Clause 7 is the hinge of this instrument and may never be removed or softened.
- If the user asks to fold AI uses into this form, refuse the merge and route to
  ai-likeness-consent, which emits both instruments separately.
- Present the artifact as counsel-review-ready, never as final. Do not claim the document
  is compliant; claim it is structured for compliance review. No em dashes, no absolute
  claims.

## Worked example (excerpt)

Northside Dental (US, fictional clinic), smile makeover photos:

> I, Jane Sample, authorize Northside Dental to use the following:
> [x] Before and after photographs of my teeth [ ] Video [ ] Audio [x] First name only
> On the following channels: [x] northsidedental.example website [x] Instagram
> [ ] Paid ads [ ] Print
> This authorization expires on 01 Aug 2028. I may revoke it in writing at any time;
> revocation applies going forward. Northside Dental will remove the images from its owned
> channels within 10 business days of a revocation.
> This authorization does NOT permit creation or use of AI-generated, AI-retouched, or
> synthetic versions of my image or voice. Any such use requires the separate AI Likeness
> and Synthetic Media Consent.

## Closing block (mandatory on every emitted form)

> TEMPLATE STATUS: This document is a starting template prepared for review by your legal
> counsel and compliance officer. It is not legal advice, and using it does not create an
> attorney-client relationship. Laws differ by jurisdiction and change; have a qualified
> professional licensed in your jurisdiction approve this document before use.
