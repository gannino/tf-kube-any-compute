# Claudify Analyst engine (`.claude/analyst/`)

The epistemic engine behind the Claudify Analyst product: a claim-evidence graph with
COMPUTED (never typed) belief, VOI-directed research, ACH reasoning, a rendered
Conviction Dossier, and a hash-chained prediction ledger. Doctrine lives in the two discipline skills: `.claude/skills/analyst/analytic-tradecraft/SKILL.md` and `.claude/skills/analyst/quality-and-calibration/SKILL.md`. No em dashes anywhere (hard rule).

## The invariants (every file obeys them)

1. **Belief is computed, never typed.** Agents populate records; only the engine
   produces a number. Deterministic: same frozen graph in, same numbers out (the
   clock and every seed are inputs, never ambient).
2. **Independence over origins, not sources.** N sources tracing to one origin are
   ~one vote (the correlation haircut). Laundering cannot vote twice.
3. **Outside view first.** No claim is scored without a reference-class base rate.
4. **Gates never raise belief.** They quarantine, zero, or flag, visibly.
5. **The loss is the human's.** Unsigned framing = EVIDENCE-MAP mode, no GO/NOGO.
6. **The verdict is emergent.** Insufficient crux coverage = a coverage state, never
   a partial answer dressed as the answer.
7. **Two-axis output.** Likelihood as a fixed estimative band; confidence computed
   from evidence structure; single-origin hard-capped at LOW.
8. **The ledger is tamper-evident.** Hash-chained; the resolution criterion is frozen
   at prediction time; due-but-unresolved is counted, never dropped.

## Layout

```
engine/            pure deterministic modules (no LLM, no ambient network)
  ceg.mjs          graph load/append/query + record validation
  independence.mjs origin clustering + the correlation haircut (N_eff)
  propagate.mjs    the belief propagator (prior + LR + decay + RAS + weakest link)
  interval.mjs     seeded Monte-Carlo fractile propagation
  ingest.mjs       gates 0a-4 + numeric tripwires + puffery/injection caps
  ach.mjs          Analysis of Competing Hypotheses (least-disconfirmed wins)
  voi.mjs          decision model + exact EVPI + the tier-0 frontier + stopping
  brief.mjs        brief validation + the zero-network dry-run planner
  dossier.mjs      the Conviction Dossier builder (two-axis, traceable) + renderer
  score.mjs        hash-chained ledger + Brier/log/Murphy + temperature + report
  sanitize.mjs     exfiltration scrub + egress guard + the puffery lexicon (Gate 5)
  spotlight.mjs    nonce delimiting + datamark + encode (the instruction boundary)
  classify_injection.mjs  the local graded injection heuristic (accept/cap/quarantine)
  recalibrate.mjs  the L0 input-calibration seam (identity + temperature, bounded)
  ras.mjs          retrieval adequacy: 6 dimensions, repair gaps, the verdict cap
  saturation.mjs   capture-recapture unseen-evidence estimation
  spamscore.mjs    the deterministic SERP-slop rubric
config/            expected-source-classes.json (the RAS checklist; data, not code)
schema/            the typed contracts (JSON Schema) for every record kind
dossier/           template.html + template-investor.html (Playwright-rendered)
hooks/             ceg-gate.sh (standalone, UNWIRED until deploy is approved)
ledger/            predictions.jsonl + calibration_log.jsonl (created at first use)
runs/<run_id>/     per-run brief.json + ceg.jsonl + dossier artifacts
eval/              the harness: node eval/run.mjs (7 suites, ~100 checks, seconds)
```

## The agents and the commands

- `/research` (`.claude/commands/research.md`): the staged orchestrator
  (frame, then per-crux, then verdict; depth is opt-in, discipline is not).
- Thin presets over the same engine: `/research-brief`, `/market-size`,
  `/competitor-teardown`, `/customer-research`, `/pricing-research`,
  `/due-diligence`, `/trend-radar`, `/research-report`; plus `/research-learn`
  (grade due predictions) and `/research-audit` (the blocking quality gate).
- Core roles: `research-strategist` frames; `research-sensor` pulls once and
  feeds many (pass-tagged for saturation); `evidence-integrator` types and gates;
  `bull` / `bear` / `red-team` argue (fresh contexts, the red-team holds the
  crux-omission veto and the bear referees resolution criteria);
  `research-synthesizer` writes prose around computed numbers;
  `research-analyst` writes and grades predictions (the contract's ninth loop).
- Specialists (evidence collectors, staffed onto branches): the 8 originals
  byte-for-byte unedited, plus customer-demand, pricing-strategy,
  distribution-channel, and regulatory-compliance.

## Running the checks

`node ".claude/analyst/eval/run.mjs"` runs everything. Any change to `engine/`
requires a green harness before it lands. New failure patterns become new eval
cases (the adversarial suite grows; it never shrinks).
