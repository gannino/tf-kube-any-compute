# /research

The Claudify Analyst spine orchestrator. Runs a research question through the epistemic
engine in STAGES so depth is opt-in and a normal run never threatens the user's token
allowance. Fractionalise the depth, never the discipline (.claude/skills/analyst/analytic-tradecraft/SKILL.md).

```
/research "<question>" [--preset=venture|market|competitor|pricing|diligence]
                       [--stage=1|2|3] [--crux=<claim-id>] [--run=<run_id>] [--dry-run]
```

Defaults: preset venture, stage 1. `--run` resumes an existing run directory (stages of
the same decision accumulate into ONE persistent claim-evidence graph). The venture preset is the default.

## Hard rules (non-negotiable, every stage)

1. **Depth is opt-in; discipline is not.** Guards (gates, reference-class priors, the
   coherence of computed belief, honest bands) are NEVER skipped to save tokens. Lean
   mode turns the depth dial down; it never turns a guard off.
2. **The loss is the human's.** The decision-framing card is elicited from the user and
   signed by them, or the run degrades to EVIDENCE-MAP mode and NO GO/NOGO conviction is
   emitted. Never default it, never nudge it, never proceed past a declined card as if
   it were signed.
3. **The verdict is emergent.** Before crux coverage is sufficient, output the honest
   evidence map + coverage state ("resolved 1 of 3 cruxes, not yet a verdict"). A cheap
   partial run must never be mistakable for the answer.
4. **Show the cost before spending it.** Before stage 2 or 3, print the per-run estimate
   ("this will use roughly X agent calls / ~$Y on your key, continue?") and wait.
5. **Belief is computed, never typed.** Agents populate records; only `propagate.mjs`
   produces a belief number. Any agent output containing a self-assigned belief is
   rejected.
6. **No em dashes in any output** (hard rule).

## Run state

`.claude/analyst/runs/<run_id>/` holds `brief.json` (the strategist's frame) and
`ceg.jsonl` (the accumulating graph). `run_id` = `YYYY-MM-DD-<slug>`; on `--run`, reuse
the existing directory and graph.

## Stage 1: FRAME (cheap, well under one dollar; a complete standalone output)

1. **Preflight.** `date +%Y-%m-%d`; create the run directory; confirm
   `.claude/analyst/engine/` exists.
2. **The decision-framing card** (AskUserQuestion, ONE card, four fields):
   - Options (default GO / NOGO, editable)
   - The ordinal loss ladder: "how bad is a wrong COMMIT vs a wrong WALK-AWAY?"
     (rungs: about-equal 1.5 / worse 3 / much worse 6 / catastrophic 12; ratio clamped [1, 20])
   - The GO threshold if they have one, and reversibility/horizon
   - Explicit sign-off: "sign this framing?" If DECLINED: proceed in EVIDENCE-MAP mode
     (`loss_signed: false`) and say plainly that no GO/NOGO will be emitted.
3. **Spawn `research-strategist`** (Task tool) with the question, preset, run_id, card
   result, and stage budget. It writes `brief.json` and self-validates.
   Spawn synchronously: pass `run_in_background: false`. Subagents default to background
   since Claude Code 2.1.198, and step 4 validates the brief.json this spawn writes; a
   background spawn makes the validator race the strategist.
4. **Validate independently:**
   `node ".claude/analyst/engine/brief.mjs" "<run>/brief.json" --print`
   Non-zero exit = send the errors back to the strategist once; a second failure stops
   the run with the errors shown.
5. **Present the plan** (the validator's printed output IS the deliverable): decision
   frame, MECE tree with crux markers, hypotheses with priors, the ranked frontier, the
   stage-2 cost estimate per crux.
6. **`--dry-run` STOPS HERE**, always, having made zero evidence-collection calls and
   zero network fetches beyond the strategist's optional base-rate lookups.

## Stage 2: RESEARCH ONE CRUX (per-crux spend; repeatable)

0. Requires a validated `brief.json`. Target = `--crux=<claim-id>` or the top of the
   frontier. Confirm the cost estimate (hard rule 4).
1. **Route the claim to specialists** by ctype/branch: market-size, competitor, trend,
   tool-ecosystem, unit-economics, moat, risk-assessment (the existing 8, unedited).
   One to two specialists per claim, never the whole roster (VOI directed, not fan-out).
   Specialists MAY fan out in parallel (background spawns acceptable here), but collect
   every specialist's output before step 2 begins.
2. **Pipe each specialist's prose to `evidence-integrator`**, spawned with
   `run_in_background: false` (its report feeds step 3 directly), which types, origin-tags,
   gates, appends to `ceg.jsonl`, recomputes belief, and reports quarantines +
   contradictions. Push any emitted resolution claims onto the frontier.
3. **Re-rank the frontier** (tier-0) and evaluate the stopping rule
   (`voi.mjs shouldStop`): stop on budget, on `max EVPI < cost of next action`, or when
   the crux claim leaves `open`.
4. **Report the crux state honestly:** new belief + N_eff + what was quarantined + the
   coverage line ("resolved X of Y cruxes"). If evidence is thin, say thin.

## Stage 3: VERDICT (opt-in; assembles only when coverage is sufficient)

Every agent spawned in this stage (`research-synthesizer`, `research-analyst`) is spawned
with `run_in_background: false`: each step consumes the previous agent's output.

1. Requires >= the crux branches resolved (claims out of `open`). Otherwise print the
   coverage state and stop; that IS the honest output.
2. ACH + P(success): `engine/ach.mjs` posteriors over the accumulated graph;
   `engine/voi.mjs` bestAction + flipPointSweep against the signed loss.
3. Synthesis + the Conviction Dossier: `research-synthesizer` + the render pipeline
   (lands in step 5 of the build; until then output the evidence-map summary: per-claim
   belief bands, N_eff, quarantine list, ACH ranking, and the flip-point sweep).
4. Prediction records + the ledger: `research-analyst` (lands in step 6 of the build).

## Failure modes

| Failure | Detection | Recovery |
|---|---|---|
| Card declined but a verdict demanded | mode = EVIDENCE_MAP at stage 3 | explain the refusal; offer to re-elicit the card |
| Invalid brief twice | brief.mjs exit 1 | stop; show errors; do not improvise a frame |
| Budget exhausted mid-crux | shouldStop | return best-effort graph + open questions, explicitly listed |
| Specialist returns self-assigned beliefs | integrator report | reject the numbers; keep the typed evidence only |
| All evidence for a crux quarantined | integrator report | say so plainly; the claim stays open; suggest a different evidence route |

## Registration note

This command is listed in `.claude/command-index.md` alongside every other Analyst
layer command.
