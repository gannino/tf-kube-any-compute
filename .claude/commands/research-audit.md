# /research-audit

The standalone quality gate of the Claudify Analyst engine: an adversarial,
fresh-context audit of an existing run (its graph, its dossier, its discipline)
that can return a BLOCKING FAIL. Use before shipping any dossier to a third party,
or whenever a run's output smells too clean.

```
/research-audit <run_id>
```

## What it verifies (the no-slop checklist)

1. **Mechanical integrity:** ceg.jsonl loads clean; every belief in the dossier is
   reproducible by `propagate.mjs` on the frozen graph (recompute and diff); the
   eval harness (`node .claude/analyst/eval/run.mjs`) is green.
2. **Provenance:** every headline number traces to sources with passages, dates,
   and origins; no claim asserts beyond its status (CONTESTED prose discipline).
3. **Selection honesty (G7):** the run did not pad itself with near-certainties;
   crux claims sit where the falsifiers say they should; declined or unresolved
   items are visible, not vanished.
4. **The dialectic actually ran:** disconfirming evidence exists for falsifiable
   claims (or the RAS disconfirming gap is visibly open); the bear's surviving
   points appear in the dossier; single-origin claims carry their tags.
5. **Gate discipline:** quarantined evidence is visible and inert (weight 0,
   excluded from N_eff); suspected sources never raised belief (containment rule).
6. **The two-axis rule:** likelihood shown as bands, confidence computed, no bare
   conviction decimals in customer-facing prose.

## Procedure

1. Spawn the `auditor` agent (fresh context) with the run directory and the
   checklist above. It reads the graph and the dossier; it does not read the
   conversation that produced them.
2. Verdict: PASS, or BLOCKING FAIL with a structured fix list (file, line/record,
   rule violated). A FAIL stops any send/publish of the dossier until fixed and
   re-audited.
3. The verdict is written to a dated file in the run directory
   (`audit-YYYY-MM-DD.md`), not just chat, and logged to the auditor's Audit
   Output Log.

## Registration note

Not yet in command-index.md (shared-file edit, deploy-gated). Invoked directly.
No em dashes in any output.
