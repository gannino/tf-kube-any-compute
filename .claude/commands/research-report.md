# /research-report

Thin preset over the Claudify Analyst engine: compile and render the Conviction
Dossier for an EXISTING run. `/research-report <run_id> [--investor]` runs the
deterministic builder + the synthesizer over the accumulated graph:
1. `node .claude/analyst/engine/dossier.mjs <run>/ceg.jsonl <run>/brief.json
   .claude/analyst/dossier/template.html <run>/dossier.html --now=<ISO>`
   (`--investor` swaps in `template-investor.html`),
2. the `research-synthesizer` writes the prose around the computed numbers
   (assert-only-supported discipline),
3. render via the house pattern (`npx playwright screenshot --full-page`),
4. `research-analyst` Mode A writes any new falsifiable headline claims to the
   ledger.
The verdict is whatever the coverage state honestly allows; compiling a report
never upgrades a partial run into an answer. No em dashes.
