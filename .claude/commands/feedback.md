# /feedback [verdict-or-edit]

Auto-detection feedback loop. Fires automatically after the user gives a verdict on any content output. Captures learning to brand-memory + content-creator MEMORY.md.

## Auto-trigger conditions

This command fires automatically (no manual invocation needed) after ANY content production output (from `/content`, `/post`, `/thread`, `/blog`, `/newsletter`, `/launch-post`, `/readme`).

The next substantive user response is parsed for verdict intent:

- **Approve signals**: "approved", "looks good", "ship it", "go", "yes", "love it", "perfect", "post it"
- **Revise signals**: "change X", "too Y", "needs Z", "not quite", "almost", specific corrections
- **Reject signals**: "no", "scrap it", "start over", "rejected", "not right"

When detected: this command's procedure runs immediately. The user should NEVER need to think about the feedback loop existing.

## Procedure

### Step 1 — Classify verdict

Parse the user's response. Classify:
- **Approval** — content was good, ship as-is
- **Revision** — specific edits requested (extract the corrections)
- **Rejection** — content wrong, start over

### Step 2 — Update brand memory

Read `.claude/agent-memory/content-creator/brand-memories/{brand}.md`.

#### On approval:
- Identify NEW voice patterns the piece introduced (specific phrasings, structure choices, tone shifts not previously in brand-memory)
- Add to "Approved patterns (1/3 confirmations)" — needs 3 across pieces to graduate
- If pattern hits 3 confirmations: promote to "Approved patterns (graduated)"
- Append to content history: piece description + ship date + verdict + key voice patterns used

#### On revision:
- Capture user's correction VERBATIM under "User phrases / structures to reuse"
- Identify the rejected phrasing — add to "Watch list (1/2 rejections)"
- If pattern hits 2 rejections: promote to "Banned (brand-specific)"
- Append to content history: piece description + revision details + new pattern learned

#### On rejection:
- Capture user's specific reason (if given)
- Identify the rejected pattern — add to "Watch list (1/2 rejections)" or "Banned" if 2nd rejection
- Surface a question: "What angle would have worked instead?" — capture the answer for next time

### Step 3 — Update content-creator MEMORY

Read `.claude/agent-memory/content-creator/MEMORY.md`.

Append to "Production log":
```
[ISO date] {brand} — {platform} — {piece-type}
Verdict: APPROVED / REVISED / REJECTED
Pattern: {what was learned}
Source: feedback from user response "{quote}"
```

### Step 4 — Promote to knowledge-base if pattern recurs cross-brand

If a pattern is observed across 3+ brands (not just one brand): nominate it for `knowledge-base.md` promotion.

Add to `.claude/knowledge-nominations.md`:
```
- [{date}] /feedback: {pattern observation} | Evidence: {brand1, brand2, brand3 — citations}
```

The auditor reviews knowledge-nominations on its next pass and promotes valid ones to knowledge-base.md.

### Step 5 — Surface to user (silent unless asked)

Default: silent — feedback loop runs in background, user doesn't need to think about it.

If user explicitly asks "what did the system learn?" — surface:
- New approved/banned patterns this cycle
- Updated brand-memory sections
- Any knowledge-nominations queued

## Hard rules

- NEVER ask "should I log this?" — just do it. The user should never need to manage the feedback loop manually.
- NEVER skip the cycle. Even on small revisions, the pattern goes into watch list.
- NEVER promote a pattern to "approved" with fewer than 3 confirmations across pieces.
- NEVER promote a pattern to "banned" with fewer than 2 rejections across pieces.
- ALWAYS capture user phrasing verbatim. Their wording is the gold artifact, not your interpretation.
- ALWAYS cite the user response that triggered the learning, in the memory log.

## Why this exists

The system gets sharper as pieces accumulate. By piece 10 per brand, voice should hit 9/10 first try. That only works if every verdict feeds the memory architecture.

Skipping the feedback loop = the system stays static. Voice quality plateaus at piece 1.
