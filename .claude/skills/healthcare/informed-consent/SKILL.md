---
description: >
  Drafts a deep informed consent instrument for elective and aesthetic procedures, with
  off-label, realistic-outcomes, and financial clauses plus signature blocks. Use when the
  user says "informed consent for botox", "med spa consent form", "aesthetic procedure
  consent", "elective procedure informed consent", or "off-label consent language".
user-invocable: true
version: 2.0.0
---

# Informed Consent (elective and aesthetic procedures)

## Purpose

The deep consent variant for elective and aesthetic medicine, where consent quality is the
legal battleground. For routine treatment consent use the consent-form skill; use this one
when the procedure is elective, cosmetic, off-label, or not medically necessary. The output
is the actual signed instrument, not a memo.

## Step 1: Selectors (never silently default)

1. **Jurisdiction**: US (HIPAA/FTC), Spain (GDPR + LOPDGDD + regional publicidad sanitaria),
   other EU (GDPR baseline, flag national rules), UK (UK GDPR, flag CAP/ASA), other (emit
   the US skeleton and flag for local counsel). If the user already stated a country, do not
   re-ask.
2. **Scale**: hospital system / 1-3 practitioner clinic / dental practice / med-spa or
   aesthetic clinic.
3. **Procedure** and the product or device used.

## Step 2: Emit the form

Use the full consent-form skeleton (header with registration number, patient identification,
nature, benefits, material risks, alternatives including no treatment, questions answered,
right to withdraw, jurisdiction data clause, signature blocks), then ADD these clauses:

- **Off-label use disclosure.** US: state whether the product or device is FDA-cleared for
  this use, and if the use is off-label, say so in plain language. Spain: off-label
  medicamento use falls under prescriber responsibility; include the disclosure and flag the
  exact wording for counsel.
- **Realistic outcomes.** Results vary by individual and no specific result is promised.
  This clause also protects the clinic's marketing position under FTC substantiation rules
  and Spanish publicidad sanitaria rules.
- **Financial clause.** The procedure is elective and typically not covered by insurance
  (US) or public coverage (Spain). State the price, what it includes, and the revision or
  touch-up policy.
- **Cooling-off note.** UNCERTAIN whether a statutory cooling-off or reflection period
  applies in the user's jurisdiction; some Spanish regional consumer rules and professional
  codes recommend reflection periods for aesthetic interventions. Confirm with counsel and,
  where applicable, record the date the patient received this document and the date of
  signature separately.

**Scale swaps**: hospital system adds an IRB or ethics-committee reference for research
contexts; dental adds an anesthesia-specific risk block; med-spa keeps the
photography-during-procedure checkbox that expressly does NOT authorize marketing use
(marketing use routes to media-release-authorization).

## Hard rules

- Never bundle marketing consent, media release, or AI likeness consent into this
  instrument. Those are separate forms (media-release-authorization, ai-likeness-consent,
  marketing-communications-consent).
- Present the artifact as counsel-review-ready, never as final. Do not claim the document is
  compliant; claim it is structured for compliance review. "Legally binding", "fully
  compliant", and similar absolutes are banned from outputs. No em dashes anywhere.

## Worked example (excerpt)

Clínica Ejemplo, lip filler consent (Spain, med-spa scale):

> **Clínica Ejemplo, Calle Ficticia 5, Madrid** (clínica ficticia)
> Centro sanitario autorizado, nº de registro: CS-XXXX (RD 1277/2003)
> Paciente: María Muestra, DNI 00000000X
>
> **1. Naturaleza del procedimiento.** Infiltración de ácido hialurónico en los labios con
> fines estéticos. Duración estimada: 30 minutos.
> **Resultados realistas.** Los resultados varían según la persona. No se promete ningún
> resultado concreto. El efecto es temporal, habitualmente de 6 a 12 meses.
> **Cláusula económica.** Procedimiento electivo no cubierto por seguro. Precio: 350 EUR,
> retoque a las 4 semanas incluido.
> **Cláusula de datos (Art 13 RGPD).** Responsable: Clínica Ejemplo S.L. Contacto DPD:
> dpd@clinicaejemplo.example. Base jurídica asistencial: Art 9(2)(h). Derechos ante la AEPD.
> ...
> Firma del paciente: ______ Firma del facultativo: ______ Fecha y lugar: ______

## Closing block (mandatory on every emitted form)

> TEMPLATE STATUS: This document is a starting template prepared for review by your legal
> counsel and compliance officer. It is not legal advice, and using it does not create an
> attorney-client relationship. Laws differ by jurisdiction and change; have a qualified
> professional licensed in your jurisdiction approve this document before use.
