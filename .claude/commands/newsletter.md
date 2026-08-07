# /newsletter [action] [issue-number]

Newsletter pipeline orchestration. Invokes the `newsletter-orchestrator` agent which coordinates 9 phases (strategy → draft → architect → build → audit → render-test → preview → send → analyse).

## Actions

| Command | What it does |
|---|---|
| `/newsletter strategy [N]` | Pick the topic + write the brief for issue N |
| `/newsletter draft [N]` | Drafter writes issue body from brief |
| `/newsletter architect [N]` | Validate or produce the god-tier prompt via 3-codebase test harness |
| `/newsletter build [N]` | Render markdown to HTML (`build.py`) |
| `/newsletter audit [N]` | Quality gate — 26 mechanical + 13 semantic + regression checks |
| `/newsletter render-test [N]` | Visual gate — 20 structural + Playwright at 4 viewports |
| `/newsletter preview [N]` | Send preview email to inbox |
| `/newsletter send [N]` | Create broadcast (API-first where the tier allows; manual paste fallback) |
| `/newsletter analyse [N]` | Day-of-send + day-7 reports |
| `/newsletter all [N]` | Run phases 1-7 sequentially, halt for user review at preview |
| `/newsletter next` | Show what issue type is next in the rotation |

## Procedure

For any sub-action, invoke the `newsletter-orchestrator` agent via Task tool with `subagent_type: newsletter-orchestrator` and `run_in_background: false`. The pipeline is strictly sequential (each phase's output is the next phase's input), and subagents default to running in the background since Claude Code 2.1.198 (Jul 2026); an unpinned invocation can race the next phase against an unfinished one. Pass:
- Action (one of: strategy / draft / architect / build / audit / render-test / preview / send / analyse / all / next)
- Issue number (optional — defaults to next issue in rotation)
- Brand (optional — defaults to active brand from memory.md)

The orchestrator manages the pipeline state and routes to the right sub-agent for each phase.

## Phase order (when running `/newsletter all`)

1. **Strategy** — strategist picks topic + writes brief
2. **Draft** — drafter writes issue body
3. **Architect** — prompt-architect produces / validates god-tier prompt (3-codebase test harness)
4. **Build** — `build.py` renders HTML
5. **Audit** — newsletter-auditor runs 26 mechanical + 13 semantic + regression checks
6. **Render-test** — stylist runs 20 structural checks + Playwright at 4 viewports
7. **Preview** — `send.js --preview` to inbox
8. **HALT** — user reviews preview, says "ship" or provides corrections
9. **Send** — API-first (Beehiiv V2 write path where the customer's tier allows it, per the Jun-Jul 2026 published integration pattern; Resend/Substack API where configured), manual paste as the free-tier fallback
10. **Analyse** — analyst day-of-send (4-6 hours after send) + day-7 reports

Each phase runs in fresh context (the orchestrator invokes a new sub-agent per phase). Halts at phase 7 for user review of preview email.

## Send gate (precondition for `/newsletter send`)

`/newsletter send` is a hard gate, not a convenience. Before any broadcast or paste it refuses to ship unless BOTH are true:
1. The audit passed: `.claude/logs/verdicts/newsletter-latest.json` exists, parses, says `"verdict": "PASS"`, and its `piece_id` matches the issue being sent with a fresh `timestamp`. Missing, malformed, stale, or non-PASS all default to FAIL (do not send).
2. The render-test (phase 6) passed for this issue.

If either is not satisfied, do not send. Tell the user exactly which gate failed and what to run (`/newsletter audit N` or `/newsletter render-test N`). Read the gate from the verdict FILE, never from an agent message, which can truncate.

At send time, also write the issue's `prediction_record` for the analyst's later day-7 grading (Post-Publish Analyst Contract guard G1): record `{predicted_outcome, by_date, baseline}` (predicted open rate, the date 7 days out, the prior 3-issue mean as baseline) into the issue file frontmatter or `strategist/MEMORY.md`. Without a prediction written at send, the analyst returns `INSUFFICIENT_PRECONDITION` rather than grading the issue.

## State management

The orchestrator maintains state at `.claude/agent-memory/newsletter-orchestrator/state/{brand}-N.md` so the pipeline can resume after `/safe-clear` or context flushes.

## Examples

```
/newsletter all 002
```
Runs phases 1-7 for issue 002, halts at preview.

```
/newsletter strategy 002
```
Just runs the strategy phase — useful when you want to confirm topic before drafting.

```
/newsletter analyse 001
```
Runs day-of-send analytics on issue 001.

```
/newsletter next
```
Shows what type comes next in the rotation (e.g., "Last issue was Config (#001). Next is Command (#002).").

## Hand-off

After phase 9 (analyse), the analyst's report includes proposed updates to the brand-memory / knowledge-base. User approves before any rule changes propagate.
