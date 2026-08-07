---
description: >
  Produces a three-part health data breach response pack: the internal runbook with real
  deadlines, the individual notification letter, and the authority notification checklist.
  Use when the user says "patient data breach", "HIPAA breach notification letter", "notify
  AEPD of a breach", "data breach response plan clinic", or "72 hour breach notification".
user-invocable: true
version: 2.0.0
---

# Health Data Breach Response Pack

## Purpose

When patient data leaks, the clinic needs three concrete artifacts, not advice. This skill
emits all three. Cross-ref legal/breach-notification and legal/incident-response-plan for
the general-business versions; this skill owns the health-specific pack.

## Step 1: Selectors (never silently default)

1. **Jurisdiction**: US (HIPAA/FTC), Spain (GDPR + LOPDGDD + regional publicidad
   sanitaria), other EU (GDPR baseline, flag national rules), UK (UK GDPR, flag CAP/ASA),
   other (emit the US skeleton and flag for local counsel). If already stated, do not re-ask.
2. **Scale**: hospital system / 1-3 practitioner clinic / dental practice / med-spa or
   aesthetic clinic. Hospital systems route through the privacy office and legal; small
   clinics name one accountable owner per step.

## Step 2: Emit the three artifacts

### Artifact 1: Internal response runbook

A contain / assess / document / notify decision tree with the actual deadlines:

- **Contain**: isolate the affected system or account, preserve evidence, stop the leak.
- **Assess**: what data, how many individuals, risk of harm. US: apply the breach risk
  assessment factors. EU: assess risk to rights and freedoms to decide Art 34 individual
  notification.
- **Document**: timeline, scope, decisions, and the reasoning, dated as you go. Both
  regimes expect demonstrable records even when you decide not to notify.
- **Notify, with the real clocks**:
  - HIPAA: individuals without unreasonable delay and no later than 60 days from discovery;
    HHS via the breach portal (within 60 days if 500+ affected, otherwise an annual log
    submission); prominent media notice if 500+ residents of one state or jurisdiction.
  - GDPR: supervisory authority within 72 hours of awareness (Art 33), stating the reasons
    for any delay; affected individuals without undue delay when the breach is likely to
    result in high risk (Art 34). Spain: the authority is the AEPD, via its electronic
    breach form.

### Artifact 2: Individual notification letter template

Per regime, with the required content: what happened, what data was involved, what the
clinic is doing, what the individual can do, and a contact channel. US adds the
HIPAA-required elements including steps individuals should take to protect themselves.
Plain language, no minimizing, no speculation beyond what is documented.

### Artifact 3: Authority notification content checklist

- Spain (AEPD form fields): nature of the breach, categories and approximate number of
  data subjects and records, DPO contact, likely consequences, measures taken or proposed.
- US (HHS breach portal fields): covered entity details, breach dates, type and location of
  breached information, safeguards in place, notification steps taken.

## Hard rules

Present every artifact as counsel-review-ready, never as final. Breach law has short clocks
and local variation; engage counsel immediately and do not treat this pack as a substitute.
Do not claim the pack is compliant; claim it is structured for compliance review. No em
dashes, no absolute claims.

## Worked example (excerpt)

Clínica Ejemplo (Spain, fictional), stolen laptop with an unencrypted patient list:

> Day 0, 14:10: theft discovered, laptop reported, remote wipe issued. Owner: gerente.
> Day 0, 17:00: assessment: 214 patients, names + appointment types. Appointment types
> reveal health information, so risk is not low. Decision: notify AEPD within 72 hours and
> prepare Art 34 individual letters. Counsel engaged same day.

## Closing block (mandatory on every emitted artifact)

> TEMPLATE STATUS: This document is a starting template prepared for review by your legal
> counsel and compliance officer. It is not legal advice, and using it does not create an
> attorney-client relationship. Laws differ by jurisdiction and change; have a qualified
> professional licensed in your jurisdiction approve this document before use.
