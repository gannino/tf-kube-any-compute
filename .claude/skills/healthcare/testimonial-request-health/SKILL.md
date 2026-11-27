---
description: >
  Builds a three-part patient testimonial packet: the request message, the signed
  authorization form, and a staff compliance one-pager. Use when the user says "ask a
  patient for a testimonial", "patient review request", "testimonial consent", "use a
  patient story in marketing", or "google review request for clinic".
user-invocable: true
version: 2.0.0
---

# Patient Testimonial Request + Authorization Packet

## Purpose

A patient testimonial used promotionally is a marketing use of protected health information.
A general intake consent does NOT cover it. This skill outputs a three-part packet of real
artifacts, never a strategy memo.

## Step 1: Selectors (never silently default)

1. **Jurisdiction**: US (HIPAA/FTC), Spain (GDPR + LOPDGDD + regional publicidad
   sanitaria), other EU (GDPR baseline, flag national rules), UK (UK GDPR, flag CAP/ASA),
   other (emit the US skeleton and flag for local counsel). If already stated, do not re-ask.
2. **Scale**: hospital system / 1-3 practitioner clinic / dental practice / med-spa or
   aesthetic clinic.
3. **Channels** where the testimonial will appear (each listed individually).

## Step 2: Emit the three artifacts

### Part 1: The request message

Email, SMS, or in-person script. Voice-calibrate it with the brand-voice-calibration-pairs
skill when a voice file exists. Rules baked into the wording: never pressure, never condition
an incentive on a positive review, and disclose any incentive in the resulting content
(FTC Consumer Reviews and Testimonials Rule, 16 CFR Part 465: incentivized reviews need
disclosure and cannot be conditioned on positivity).

### Part 2: The authorization form

US version: a HIPAA marketing authorization with the full 45 CFR 164.508(c) element set:

- Description of the PHI used: name, image, the patient's words, the condition treated.
- Who may disclose, and who receives it, with the channels listed individually as
  checkboxes: website, Instagram, paid ads, print, other named channels.
- Purpose of the use, and an expiration date or event.
- Revocation clause: the patient may revoke in writing at any time, prospective effect only.
- No-conditioning statement: treatment is never conditioned on signing (45 CFR
  164.508(b)(4)).
- Remuneration statement whenever a third party pays for the marketing (45 CFR
  164.508(a)(3)).
- Signature and date blocks.

Spain version: GDPR Art 9(2)(a) explicit consent plus the Organic Law 1/1982 image cession
(image rights are a separate civil right from data protection, so both consents appear),
granular per-channel checkboxes, the withdrawal right and its prospective effect, and the
Art 13 information block.

### Part 3: The staff compliance one-pager

- Testimonials are advertiser claims: the FTC treats them as if the clinic said it, and
  atypical results need a statement of what a typical patient can expect. "Results not
  typical" alone does not cure the problem.
- Never reply to a public review in a way that confirms the reviewer is a patient. OCR has
  settled multiple cases over review-response disclosures. Respond generically.
- Never post AI-fabricated, composite, or purchased reviews (16 CFR Part 465).

## Hard rules

- Real-likeness authorization only. Any AI retouch, synthetic voice, or AI-generated element
  routes to the ai-likeness-consent skill; this packet expressly does not cover it.
- Present every artifact as counsel-review-ready, never as final. Do not claim the document
  is compliant; claim it is structured for compliance review. No em dashes, no absolute
  compliance claims.

## Worked example (excerpt)

Northside Dental request email (US, fictional clinic):

> Subject: Would you share your experience?
> Hi Jane, we are glad your treatment went well. If you are comfortable, we would love to
> share your story on our website and Instagram. Attached is a short authorization that
> explains exactly what we would use (your first name, your photo, your words), where it
> would appear, and how to withdraw at any time. Saying no changes nothing about your care.

## Closing block (mandatory on every emitted artifact)

> TEMPLATE STATUS: This document is a starting template prepared for review by your legal
> counsel and compliance officer. It is not legal advice, and using it does not create an
> attorney-client relationship. Laws differ by jurisdiction and change; have a qualified
> professional licensed in your jurisdiction approve this document before use.
