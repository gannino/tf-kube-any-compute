---
description: >
  Drafts a standalone AI likeness and synthetic media consent instrument with definitions,
  a specific-use table, labeling and training clauses, and its own signature. Use when the
  user says "AI consent form", "synthetic voice consent", "AI retouched photo consent",
  "digital replica consent", "consent for AI generated patient image", or "deepfake
  disclosure healthcare".
user-invocable: true
version: 2.0.0
---

# AI Likeness and Synthetic Media Consent

## Purpose

A separate instrument from the media release, with its own signature. Authorization to use
a patient's REAL image or voice is one document (media-release-authorization); consent
covering AI-generated, AI-retouched, or synthetic versions is THIS document. They are never
merged. In the EU this instrument becomes legally load-bearing on 2 August 2026, when the
AI Act Article 50(4) deepfake disclosure duty applies.

## Step 1: Selectors (never silently default)

1. **Jurisdiction**: US (HIPAA/FTC), Spain (GDPR + LOPDGDD + regional publicidad
   sanitaria), other EU (GDPR baseline, flag national rules), UK (UK GDPR, flag CAP/ASA),
   other (emit the US skeleton and flag for local counsel). If already stated, do not re-ask.
2. **Scale**: hospital system / 1-3 practitioner clinic / dental practice / med-spa or
   aesthetic clinic.

## Step 2: Emit the instrument

- **Definitions clause**, plain language, one sentence each: AI-retouched (edits beyond
  crop and exposure); AI-generated likeness (a synthetic image resembling the person);
  synthetic voice (a generated voice resembling the person's); avatar or digital replica
  (an animated or interactive synthetic version of the person).
- **Clause 1. Specific permitted uses**: a table the clinic fills, one row per use, with
  columns asset type | channel | campaign | duration. Drafted to the "reasonably specific"
  standard of California AB 2602 as the strictest common denominator, so one form travels
  across states. No blanket rows.
- **Clause 2. Labeling commitment**: any AI-generated or manipulated content resembling
  the patient will be visibly disclosed as AI-generated. EU: a legal duty from 2 August
  2026 (AI Act Art 50(4)). US: the FTC-safe posture, and passing synthetic content off as
  a real patient testimonial violates 16 CFR Part 465 regardless of consent.
- **Clause 3. Training exclusion**: the patient's images and voice will not be used to
  train AI models. If the clinic intends training use, a separate explicit opt-in line for
  exactly that, unticked by default.
- **Clause 4. Voice clause**: a separate consent line for synthetic voice. The Tennessee
  ELVIS Act (2024) protects voice specifically; treat voice as the direction of travel and
  consent it separately.
- **Clause 5. Revocation and destruction**: on withdrawal, generated assets are removed
  from owned channels and the source material used for generation is deleted; state the
  clinic's timeline as a service standard.
- **Clause 6. No conditioning of treatment; expiration; jurisdiction data block.** Spain:
  GDPR Art 9(2)(a) explicit consent plus the LO 1/1982 image cession. UNCERTAIN whether
  voice-cloning source data counts as biometric data under GDPR Art 9(1) in a given
  deployment; confirm with counsel before relying on any answer.
- **Signature blocks**, separate from any media release signature.

## Refusal rule (structural, non-negotiable)

If the user asks for ONE form covering both real-likeness use and AI use, this skill
refuses the merge and emits BOTH instruments, with this two-sentence explanation: the
revocation scope, disclosure duties, and legal bases differ between real and synthetic use.
Merging them makes both consents weaker and harder to defend.

## Other rules

- US state applicability note: whether performer-focused statutes such as AB 2602 or the
  ELVIS Act reach a patient (not a performer) varies. UNCERTAIN; confirm with counsel. The
  form drafts to the strictest common denominator regardless. The federal NO FAKES Act was
  a bill, not law, at drafting time; confirm current status with counsel before asserting
  anything federal beyond the FTC rules.
- Present the artifact as counsel-review-ready, never as final. Do not claim the document
  is compliant; claim it is structured for compliance review. No em dashes, no absolute
  claims.

## Worked example (excerpt)

Clínica Ejemplo (Spain, fictional), AI-retouched campaign image:

> **Usos permitidos específicos**
> | Tipo de activo | Canal | Campaña | Duración |
> |---|---|---|---|
> | Imagen retocada con IA (piel unificada) | Instagram @clinicaejemplo | Otoño 2026 | 6 meses |
>
> **Compromiso de etiquetado.** Todo contenido generado o manipulado con IA que se parezca
> a mi persona se publicará con la indicación visible "imagen generada con IA" (Art 50(4)
> del Reglamento de IA, aplicable desde el 2 de agosto de 2026).
> **Exclusión de entrenamiento.** Mis imágenes y mi voz no se usarán para entrenar modelos
> de IA.
> Firma del paciente: ______ Fecha: ______

## Closing block (mandatory on every emitted instrument)

> TEMPLATE STATUS: This document is a starting template prepared for review by your legal
> counsel and compliance officer. It is not legal advice, and using it does not create an
> attorney-client relationship. Laws differ by jurisdiction and change; have a qualified
> professional licensed in your jurisdiction approve this document before use.
