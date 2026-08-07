# /content [brand] [topic]

Full content production pipeline: strategy → draft → audit → ship-ready output.

## When to use

- You want a complete content piece with strategist's brief + creator's draft + auditor's verdict, end-to-end
- You're producing for a brand with an established brand-memory file
- You want the agent to handle topic selection (no topic argument) OR you're providing a topic explicitly

## Procedure

### Step 1 — Orient

Read `.claude/agent-memory/content-creator/brand-memories/{brand}.md` to confirm:
- Brand-memory exists
- Voice anchors are populated (3+ calibration pairs)
- ICP is defined

If brand-memory missing: HALT and instruct user to run `/brand-memory create {brand}` first.

If no brand specified: default to the most-recently-active brand from `memory.md`.

### Step 2 — Strategy (if no topic provided)

If user provided a topic in the command: skip strategy phase, go directly to draft.

If no topic: invoke the `content-strategist` agent via Task tool with `subagent_type: content-strategist`. Pass:
- Brand
- Target platform mix (default: per `CLAUDE.local.md` Platforms list)
- Target ship date (default: today)

Receive: brief at `.claude/agent-memory/content-strategist/briefs/{brand}-{date}-brief.md`.

### Step 3 — Draft

Invoke the `content-creator` agent via Task tool with `subagent_type: content-creator`. Pass:
- Brand
- Brief path (or inline topic if user provided)
- Target platform(s)

Receive: draft + self-check verdict.

### Step 4: Audit (mandatory gate)

Invoke the `content-auditor` agent via the Task tool with `subagent_type: content-auditor` (a fresh-context cold reader, NOT the content-creator; the creator's own Step 3 self-check never counts as this gate). Pass:
- Draft path
- Brand context

The auditor writes its verdict to `.claude/logs/verdicts/content-latest.json` and also prints it. Read that FILE as the gate, not the message text (a truncated message must never pass a fail). Default to FAIL unless the file exists, parses, says `PASS`, and its `piece_id` matches this draft with a fresh `timestamp`.

- **PASS**: continue to Step 5.
- **REVISE or FAIL**: pass the auditor's fix list back to the `content-creator` to apply, then re-audit (return to this step). This is a bounded loop, at most 2 retries. If it is still not PASS after the 2nd retry, stop and hand the piece plus the outstanding fix list to the user with a clear note that it did not clear the gate. Never ship a non-PASS piece silently, and never loop more than twice.

### Step 5 — Distribution (if applicable)

If the piece is long-form (blog, newsletter, video script): generate 3-5 short-form derivatives.

For each derivative: re-run Steps 3-4 (draft → audit) at smaller scope.

### Step 6 — Output

Surface to user:
- Final draft(s) ready to publish
- Auditor verdict
- Distribution derivatives generated
- Recommended next step (preview / publish / iterate)

## Hand-off

`/content` does NOT publish. After verdict PASS, user manually publishes via:
- `/post {platform}` for re-render to a specific platform
- Manual paste to platform UI
- API send (if platform integration exists)

The system tracks shipped pieces via `/feedback` — fires automatically after the user gives a verdict.

## Examples

```
/content claudify "How I shipped a self-improving CLAUDE.md"
```
Drafts a piece for the claudify brand on the specified topic.

```
/content claudify
```
No topic — strategist picks based on backlog + brand history + current trends.

```
/content @yourbrand twitter "AI agency 2026 outlook"
```
Drafts a piece for the @yourbrand brand specifically for Twitter, on the given topic.
