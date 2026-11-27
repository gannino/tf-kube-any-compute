# /research-learn

The LEARN pass of the Claudify Analyst engine: grade every due prediction against
external ground truth and produce the calibration report. This is the command that
makes "it grades its own calls" a measured fact. Fires the research-analyst in
Mode B (fresh context, guard G4: the grader never graded its own generation).

```
/research-learn [--due-only] [--as-of=YYYY-MM-DD]
```

Default `--due-only`: only predictions whose `resolves_by` has passed. `--as-of`
overrides today for backtesting (never for real grading).

## Hard rules

1. **G1:** no record in the ledger, no learning. INSUFFICIENT_PRECONDITION verbatim.
2. **G8:** the outcome is judged against the FROZEN resolution criterion (the hash
   on the record). Outcomes that do not cleanly match are UNRESOLVED with a reason,
   counted and reported, never dropped and never charitably graded.
3. **G7:** the report leads with the HARD BAND [0.35, 0.65], never the flattering
   aggregate.
4. Chain integrity first: a broken `verifyChain` STOPS the run.
5. No em dashes in any output.

## Procedure

1. Verify both ledgers: `verifyChain` on `.claude/analyst/ledger/predictions.jsonl`
   and `calibration_log.jsonl` (engine/score.mjs). Broken chain = stop + report line.
2. `listDue` with today. Zero due = report "nothing due until <next resolves_by>"
   and stop.
3. Spawn `research-analyst` (Mode B) with the due prediction ids. It establishes
   each ACTUAL outcome from the frozen resolution_source only, scores via
   `resolveOutcome`, appends to the calibration log, and produces
   `calibrationReport`.
4. Surface the report verbatim: resolved counts, UNRESOLVED count with reasons,
   aggregate + hard-band Murphy decomposition, the reliability diagram, interval
   coverage, the temperature stage. Below 20 resolved, the honest line is
   "n=<x>, uncalibrated" and it appears first.
5. The analyst's `[ANALYST-L1]` / `[ANALYST-L4]` nominations go to
   knowledge-nominations for the auditor; nothing self-promotes (G3).

## Standing schedule

Run this command whenever predictions come due; the daily /sync surfaces due
dates whenever the ledger holds any.

## Registration note

Not yet in command-index.md (shared-file edit, deploy-gated). Invoked directly.
