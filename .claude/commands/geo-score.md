---
description: Score a draft or URL for AI-citation readiness before publishing. Returns PUBLISH / REVISE / BLOCK.
argument-hint: (paste draft) | {url}
allowed-tools: Read, Write, Edit, Bash(date:*), Glob, Grep, WebSearch, WebFetch
---

# /geo-score

**Usage:** `/geo-score` then paste a draft | `/geo-score {url}` to score a live URL

Score content for AI-citation readiness before it goes live. The GEO sibling of `/content-score`:
where `/content-score` checks whether a page will rank, this checks whether an answer engine will
cite it. Returns the readiness scorecard and a PUBLISH / REVISE / BLOCK verdict. Chains naturally
after `/blog` and `/content-score`.

---

## Trigger Conditions

- User runs `/geo-score` explicitly
- User asks "is this AI-ready", "will an engine cite this", "GEO score this", or "check this for
  AI search" before publishing
- After `/blog` or `/content-score`, the natural pre-publish GEO gate in the writing pipeline
- After a content rewrite, to verify the AI-citation structure improved

---

## Procedure

### Step 1: Gather Content

If the user ran `/geo-score`:
- Ask the user to paste the draft (title, body, target topic, and target URL if known).

If the user ran `/geo-score {url}`:
- The geo-agent will fetch the live URL. For a live URL, BOTH fetches matter: the rendered DOM via
  WebFetch and the raw HTML via curl, because the SSR check is the load-bearing readiness signal
  and only applies to a deployed page.

**Note on pasted drafts:** a pasted draft cannot be SSR-checked or robots-checked (it is not yet
deployed). For drafts, score the seven content-structure checks (answer-first, passage chunking,
stat density, quotes + sources, freshness signals, entity clarity, heading hierarchy) and mark the
two deployment gates (SSR, AI-crawler access) as DEFERRED with a reminder to re-run `/geo-score
{url}` once live. Make this explicit in the output so the user knows the gates are still pending.

### Step 2: Confirm Target Topic

Before scoring, confirm the primary topic and the buyer question the page should answer in AI
results:
- If the user provided it: use it.
- If scoring a live URL: check the domain's geo-map prompt library for the matching question.
- If unknown: infer it from the H1, title, and first paragraph, then state the inferred topic.

### Step 3: Invoke geo-agent for Scoring

Spawn the `geo-agent` to run the GEO Readiness Audit on the content.

**What to tell the geo-agent:**
```
Score this content for AI-citation readiness using the GEO Readiness Audit.
Content: [paste the full draft, or the URL to fetch]
Primary topic / target question: {topic}
Target URL: {url or "not yet assigned"}
{If a draft, not a live URL:} This is a pre-deploy draft. Score the seven content-structure checks.
Mark the SSR and AI-crawler gates DEFERRED (cannot be checked until deployed) and remind the user
to re-run /geo-score on the live URL.
{If a live URL:} Fetch BOTH raw HTML (curl, pre-JS) and rendered DOM. Run all nine checks and apply
the SSR and AI-crawler gates.
Read your MEMORY.md and the domain's geo-map first to check for prior data and the prompt library.
Produce the full readiness scorecard with a specific fix for every check scoring WARN or FAIL.
Apply the PUBLISH/REVISE/BLOCK threshold. Label any visibility reference as an estimate.
```

### Step 4: Review and Present Score

Present the full readiness scorecard to the user.

If the verdict is REVISE:
- Highlight the top 3 checks to fix, ranked by citation impact (answer-first and SSR outrank
  freshness and entity clarity).
- Offer: "Want me to fix these now? I can rewrite the failing checks immediately."

If the verdict is BLOCK:
- Explain the gate failure clearly. A BLOCK on a live URL is almost always SSR (client-side
  rendering makes the page invisible to AI crawlers) or a blocked citation crawler in robots.txt.
- Offer: "Want me to draft the structural fix? For SSR this is a build/render change, not a copy
  change. I can spell out exactly what to change."

If the verdict is PUBLISH:
- Confirm the content is AI-citation-ready.
- Remind: "Once live, run `/geo-audit {url} --depth full` to confirm the deployment gates and start
  tracking share-of-voice with `/ai-visibility {domain}`."

### Step 5: Log Result

Add the score to the geo-agent memory under `## GEO Output Log` and the domain's Readiness History.
If there are REVISE/BLOCK items, add the required fixes to the Task Board.

---

## Readiness Check Reference

| Check | Applies to draft | Applies to live URL | Notes |
|-------|------------------|---------------------|-------|
| Answer-first structure | yes | yes | direct answer in first ~50 words + each H2 |
| Passage chunking | yes | yes | 120-180-word citable band, no sub-50w stubs |
| Statistic / fact density | yes | yes | target ~10-19 specific stats on substantive pages |
| Quotations + cited sources | yes | yes | the two strongest GEO levers |
| SSR (gate) | DEFERRED | yes | content must exist pre-JS, load-bearing |
| AI-crawler access (gate) | DEFERRED | yes | robots.txt allows citation crawlers |
| Freshness signals | partial | yes | visible date + schema dateModified, no gaming |
| Entity clarity | partial | yes | Organization schema + sameAs |
| Heading hierarchy | yes | yes | one H1, no skipped levels |

## Verdict Thresholds

| Verdict | Score | Meaning |
|---------|-------|---------|
| PUBLISH | >= 75 | AI-citation-ready, ship it |
| REVISE | 50-74 | Specific structural improvements needed before publishing |
| BLOCK | < 50 | Significant rework or a deployment-gate fix required. Do not publish as-is |

---

## Output Format

```
GEO READINESS: {0-100} | {url or "draft"} | {date}
{For a live URL:} Fetch: raw HTML {N} words | rendered DOM {N} words | SSR ratio {0.00}
Strong: {checks scoring PASS}
Improve: {checks scoring WARN/FAIL with specific fix}
{For a draft:} Deferred gates (re-run on live URL): SSR, AI-crawler access
Verdict: {PUBLISH | REVISE | BLOCK}
Top fix (highest citation impact): {the single highest-leverage change}
```

---

## Notes

- A pasted draft can only be partially scored, because the two deployment gates (SSR, AI-crawler access)
  need a live URL. Always re-run `/geo-score {url}` once the page is deployed.
- This pairs with `/content-score`: run `/content-score` for ranking readiness and `/geo-score` for
  AI-citation readiness before any publish. Both should pass.
- The strongest citation levers are answer-first structure, a server-rendered page, and an open
  robots.txt for citation crawlers. Fix those first when the score is low.
