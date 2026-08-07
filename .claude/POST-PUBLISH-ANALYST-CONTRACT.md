# Post-Publish Analyst Contract

The single, shared contract that every "learn from what shipped" loop instantiates: the SEO Output to Track to Verify loop, the newsletter analyst, and any future loop. It exists so the loops compound real signal instead of producing confident noise. Each loop supplies only its parameters; the six guards are non-negotiable.

## Parameters each loop supplies
- `signal_source`: where the real outcome comes from (for example GSC rankings, Beehiiv open and click rates, the human's verdict).
- `observe_after`: how long to wait before the outcome is real (for example SEO 14 to 28 days, newsletter 7 days).
- `primary_metric`: the one number the prediction is about.
- `baseline`: the comparison value recorded at output time (may be null on a cold start).
- `judge`: who scores the outcome (must differ from the generator; see G4).
- `k`: the minimum sample before any conclusion (default 3 to 5).
- `min_effect`: the smallest change that counts as signal rather than noise.

## The six guards (non-negotiable)
- **G1 prediction-first.** No learning without a prior `prediction_record` (`predicted_outcome`, `by_date`, `baseline`) written at publish or output time. If none exists, the loop returns `INSUFFICIENT_PRECONDITION` and stops. It NEVER invents a retrospective story.
- **G2 enough signal.** No conclusion from fewer than `k` samples, or from an effect inside the noise band (smaller than `min_effect`). Below either, return `INSUFFICIENT_DATA`.
- **G3 external ground truth.** Promotion to a durable rule requires a REAL outcome (actual ranking, actual engagement, the human's verdict) AND human approval. The loop's own score never promotes anything by itself.
- **G4 judge is not the generator.** Whoever scores the outcome runs in fresh context, or is a different agent, than whoever produced the work. A producer's self-check never counts as the verification.
- **G5 evidence back-pointer.** Every canonical change (a knowledge-base entry, a rule update) carries a pointer to the `prediction_record` and the outcome that justify it. No unsourced rules.
- **G6 supersede, do not accumulate.** A learning that contradicts an existing one supersedes it with a date and reason, preserving provenance. Stale and contradicted learnings are pruned, never silently overwritten or left to pile up.

## The hard precondition
If no `prediction_record` exists for the thing being analyzed, return `INSUFFICIENT_PRECONDITION`. Do not reconstruct a prediction after the fact and grade against it. That is circular, and it is exactly the failure this contract prevents.
