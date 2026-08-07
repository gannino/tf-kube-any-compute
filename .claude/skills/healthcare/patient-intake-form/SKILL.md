---
description: >
  Drafts the actual new-patient intake form with demographics, coverage, history pointers,
  and unbundled per-purpose marketing checkboxes. Use when the user says "patient intake
  form", "new patient form", "intake paperwork", or "formulario de admisión de pacientes",
  for any clinic scale and jurisdiction.
user-invocable: true
version: 2.0.0
---

# Patient Intake Form (with unbundled marketing consent)

## Purpose

Outputs the actual intake form a front desk hands to a new patient. The teaching core of
this skill is DATA MINIMIZATION and UNBUNDLING: collect only what care requires, and keep
every marketing opt-in separate from care paperwork.

## Step 1: Selectors (never silently default)

1. **Jurisdiction**: US (HIPAA/FTC), Spain (GDPR + LOPDGDD + regional publicidad
   sanitaria), other EU (GDPR baseline, flag national rules), UK (UK GDPR, flag CAP/ASA),
   other (emit the US skeleton and flag for local counsel). If already stated, do not re-ask.
2. **Scale**: hospital system / 1-3 practitioner clinic / dental practice / med-spa or
   aesthetic clinic.

## Step 2: Emit the form

Sections, in order:

- **Demographics**: name, date of birth, address, preferred language. Spain adds DNI/NIE
  with a one-line justification of why it is collected (identification for the clinical
  record). Collect nothing "nice to have".
- **Contact and emergency contact**.
- **Coverage**: US: insurance carrier, member ID, subscriber. Spain: mutua privada or
  public coverage indicator.
- **Medical history pointer**: reference the separate medical-history-form skill rather
  than duplicating history questions here.
- **Communication preferences for CARE**: appointment reminders and recall messages are
  healthcare operations, stated as such on the form. They are not opt-in marketing and are
  not bundled with it.
- **Marketing opt-ins, unbundled**: separate, UNTICKED checkboxes, one per purpose and
  channel (for example: monthly newsletter by email; offers by SMS). Never a precondition
  of care, and the form says so in plain language. Cross-ref the
  marketing-communications-consent skill for the full opt-in pack and consent register.
- **Jurisdiction data block**: US: pointer to the Notice of Privacy Practices and an
  acknowledgment-of-receipt signature line. Spain: the GDPR Art 13 information block
  (controller, DPO contact which LOPDGDD Art 34 makes mandatory for health centers,
  purposes with separated legal bases, retention per clinical-records law, rights, AEPD),
  plus the LOPDGDD Art 7 note that digital services consent from age 14 applies to data,
  not to medical consent.
- **Signature and date**.

**Scale swaps**: dental adds a dental-history section; med-spa adds an aesthetic-goals
section with an explicit note that aesthetic goals are still health data under GDPR Art 9;
hospital system references the system form registry and privacy office.

## Hard rules

- No marketing consent, media release, or AI consent bundled into intake. Separate
  instruments only (marketing-communications-consent, media-release-authorization,
  ai-likeness-consent).
- Present the artifact as counsel-review-ready, never as final. Do not claim the document
  is compliant; claim it is structured for compliance review. No em dashes, no absolute
  claims.

## Worked example (excerpt)

Clínica Ejemplo (Spain, small clinic, fictional):

> **Preferencias de comunicación asistencial.** Le enviaremos recordatorios de cita por SMS.
> Esto forma parte de la gestión de su asistencia.
>
> **Comunicaciones comerciales (opcional, casillas sin marcar).**
> [ ] Deseo recibir el boletín mensual de salud por correo electrónico.
> [ ] Deseo recibir información sobre nuevos servicios por SMS.
> Marcar o no estas casillas no afecta en nada a su atención. Puede retirar su
> consentimiento en cualquier momento escribiendo a bajas@clinicaejemplo.example.

## Closing block (mandatory on every emitted form)

> TEMPLATE STATUS: This document is a starting template prepared for review by your legal
> counsel and compliance officer. It is not legal advice, and using it does not create an
> attorney-client relationship. Laws differ by jurisdiction and change; have a qualified
> professional licensed in your jurisdiction approve this document before use.
