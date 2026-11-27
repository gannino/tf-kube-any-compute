# /research-selftune

The meta-loop proposal cycle of the Claudify Analyst engine (loops L2-L7 of the
learning lattice): base-rate updates, source-tier recalibration, prompt
refinement proposals, framework re-weighting. READINESS-GATED AND CURRENTLY OFF
BY DESIGN: the lattice runs single-tenant only, and no loop fires below its
evidence threshold. Autonomy is earned by calibration, never assumed
(.claude/skills/analyst/quality-and-calibration/SKILL.md).

```
/research-selftune [--status]
```

## The gate (checked first, every time)

1. Read `.claude/analyst/ledger/calibration_log.jsonl` and count RESOLVED
   predictions (chain must verify).
2. The readiness ladder:
   - resolved < 20: NOTHING fires. Output the status line ("resolved n=<x> of
     the 20 needed for L1-temperature; the seam is live, the maps are identity")
     and stop. This is the expected state for a long time and it is correct.
   - resolved >= 20: L1 temperature fitting may PROPOSE a map row for
     `parameters.jsonl` (never auto-apply; the proposal goes to
     knowledge-nominations with its fit evidence, guard G10: lift-justified,
     reversible).
   - resolved >= 50 with a calibrated reliability band: L2 base-rate and L3
     source-tier proposals unlock (hierarchical, bounded, exogenous ground truth
     only, guard G11: no signal grades itself).
   - L5-L7 (prompt edits, framework weights, VOI recalibration) remain
     single-tenant and human-gated regardless of n; this command only ever
     PROPOSES, and the decision loss ratio is never touched (human-only, the
     engine may not edit its own utility function).
3. Every proposal carries back-pointers to the resolved prediction ids that
   justify it, and lands as an `[ANALYST-L<n>]` nomination for the auditor and
   the operator. Nothing self-promotes (G3).

## Why the refusal is the feature

A self-improving system that tunes itself on single-digit samples whipsaws. The
gate means the engine cannot drift before it has the data to know it is
drifting. When this command says "not ready", that is the system working.

## Registration note

Not yet in command-index.md (deploy-gated). No em dashes in any output.
