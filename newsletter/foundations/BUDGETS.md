# Budgets — explicit limits on every issue

Every dimension of a Claudify Weekly issue has a numerical limit. These exist to prevent cumulative drift (the "each addition was justified, total ballooned" failure mode caught in the audit).

The auditor enforces every budget below. Going over requires explicit justification.

---

## Total issue budget

The total budget depends on whether the issue contains a god-tier gift block. God-tier prompts are 350-500 words by themselves, which shifts the realistic envelope. Two profiles:

### Issues WITHOUT a god-tier gift block (most weeks)

| Dimension | Target | Hard cap | What happens at cap |
|---|---|---|---|
| Total word count (rendered HTML, all sections) | 600-900 | 1,000 | Auditor flags. Drafter must cut, not add. |
| Reading time (at 200 words/min) | 3-5 min | 5 min | Same as above |
| Total HTML size (raw bytes) | < 40KB | 60KB | Approaches Gmail's 102KB clip threshold; auditor flags |

### Issues WITH a god-tier gift block (Issue 001 inaugural; future referral-unlock weeks)

| Dimension | Target | Hard cap | What happens at cap |
|---|---|---|---|
| Total word count (rendered HTML, all sections) | 900-1,200 | 1,300 | Auditor flags. Drafter must cut, not add. |
| Reading time (at 200 words/min) | 4.5-6 min | 6.5 min | Same as above |
| Total HTML size (raw bytes) | < 50KB | 80KB | Approaches Gmail's 102KB clip threshold; auditor flags |

**Why two profiles:** the god-tier prompt is a major content payload (350-500 words). Treating it as "extra" content within the same budget as a prompt-less issue forces unnecessary trimming of either the main tip or the prompt itself, both of which are load-bearing. The reader has opted in to the god-tier gift by reading that far; the extra 200-300 words are content they actively want.

**Why the absolute ceiling at 1,300:** beyond this, even motivated readers skim. Gmail's clip threshold (102KB ≈ 13,000+ words of plain text) isn't the binding constraint; reader attention is.

**Issue 001 reference:** shipped at ~1,131 words with full v3 god-tier gift. That's mid-range of the WITH-god-tier profile. Future god-tier-gift issues should aim for 950-1,100 unless content genuinely demands more.

---

## Per-section budgets

| Section | Min words | Max words | Rationale |
|---|---|---|---|
| TIP_HEADLINE | 5 | 10 | Headlines that exceed 10 words usually contain a hidden second idea — split or sharpen |
| Subject line | (no min) | 50 chars | Gmail truncates around 60 chars on mobile; 50 leaves margin |
| Preview text | (no min) | 110 chars | What Gmail shows next to the subject |
| TLDR | 25 | 60 | Three bullets, ~15 words each. Skim-reader's escape hatch |
| TIP_INTRO | 30 | 80 | The personal moment. Long enough to land, short enough to keep moving |
| TIP_BODY (full block) | 200 | 450 | The technique itself. Anything longer means the technique is too complex for one issue — split |
| TIP_BODY: numbered steps count | 2 | 4 | More than 4 steps means the technique is too complex |
| Deep dive title + description | 15 | 35 | Subordinate signal — should not compete with main tip |
| PROMPT (Copy this prompt) | 30 | 80 | Plain-English instruction, short |
| Pro tip headline | 8 | 15 | Sharper than the main headline because the audience is the ceiling reader |
| Pro tip body | 30 | 80 | Concise advanced technique |
| Quick win headline + body | 25 | 70 | Lower-effort second tip |
| What I'm reading: total | 50 | 130 | Three items, ~30-40 words each (link + 1-line description) |
| What I'm reading: number of items | 3 | 3 | Always exactly 3. Two feels thin, four feels listy |
| God-tier prompt body | 200 | 500 | The actual prompt. Above 500 it gets too dense for an email |
| God-tier prompt intro + closer | 50 | 150 | Framing copy around the prompt itself |
| NEXT_TEASE | 8 | 20 | One sentence. The "ooh, I want to read that" hook |

---

## Code block budget

| Dimension | Limit | Rationale |
|---|---|---|
| Number of code blocks per issue | Max 3 in TIP_BODY, plus 1 in PROMPT, plus 1 in god-tier prompt | More than this and the email becomes a code dump |
| Lines per code block | Max 25 | Anything longer should be a link to a gist or blog |
| Code block character width | Should fit at 600px email width with `font-size:12px` | Roughly 70 chars per line max. Long lines wrap ugly |

---

## Sentence-level limits

| Dimension | Limit | Rationale |
|---|---|---|
| Longest sentence in body content | 40 words | Beyond this, comprehension drops. Split. |
| Average sentence length | 15-22 words | Mix of short and long. All-short feels choppy, all-long feels academic |
| Paragraphs longer than 4 sentences | Banned in body content | Email's not the medium for dense paragraphs. Break. |

---

## Link budgets

| Dimension | Limit | Rationale |
|---|---|---|
| Outbound links per issue (total) | Max 6 | Includes deep dive, what-I'm-reading, CTA, footer subscribe. Beyond this dilutes click signal |
| External (non-claudify.tech) links | Max 3 | Don't send subscribers away too aggressively |
| All links must resolve (no 404s) | Hard rule | Auditor verifies via HTTP HEAD request before ship |
| All links must use HTTPS | Hard rule | No plain HTTP |

---

## Visual budgets

The visual block budget follows the same two-profile model as the word count (see MISTAKE-017 + MISTAKE-019). Issues with a god-tier gift carry one extra dark card and typically one extra closer/framing element, which raises the realistic ceiling without compromising the "more feels cluttered" rule.

### Issues WITHOUT a god-tier gift block

| Dimension | Limit | Rationale |
|---|---|---|
| Number of visually distinct blocks (cards, callouts) | 8-11 | More feels cluttered |
| Number of inline code style tokens (`<code>`) | Max 30 across the issue | Inline code creates visual noise; use sparingly |
| Number of strong emphasis (`<strong>`) per section | Max 2 | Bolding everything bolds nothing |
| Image attachments (inline images, not links) | 0 by default | Images add HTML weight, get blocked by default in Gmail; only use if specifically justified |
| 320px viewport rendered height (stylist V2 check) | Under 5000px | Beyond this, mobile readers scroll past the fold too aggressively |

### Issues WITH a god-tier gift block

| Dimension | Limit | Rationale |
|---|---|---|
| Number of visually distinct blocks (cards, callouts) | 11-14 | God-tier gift adds 1 dark card + framing elements; cluttered floor raised by ~3 |
| Number of inline code style tokens (`<code>`) | Max 30 across the issue | Same as without-god-tier |
| Number of strong emphasis (`<strong>`) per section | Max 2 | Same as without-god-tier |
| Image attachments (inline images, not links) | 0 by default | Same as without-god-tier |
| 320px viewport rendered height (stylist V2 check) | Under 9000px | 1,131-word with-god-tier issue renders ~8000px at 320 width — that is structurally unavoidable without cutting copy |

**Why the visual budget needed splitting:** Issue 001 (with god-tier) renders 14 distinct blocks and ~8000px tall at 320px viewport. The single-profile cap (8-11 / 5000px) flagged this as a failure when the underlying structure is correct — the god-tier gift inherently adds visual mass. Same calibration insight as MISTAKE-017's word count split. See MISTAKE-019.

---

## What "exceeded budget" means in practice

If a draft exceeds any budget, the auditor flags it as **CUT, not justify**. The default response is removal, not exception.

Exceptions are allowed when:
1. The justification is documented in the issue's frontmatter (`budget_exception: ...`)
2. You sign off explicitly
3. The exception is single-issue, not a precedent

If 3+ issues in a row exceed the same budget, the budget itself is wrong — review and adjust this file.

---

## Why these specific numbers

The numbers above are not arbitrary. They're calibrated against:
- Issue 001's word counts as a baseline (it shipped at 1,007 — at the cap, not above)
- Common newsletter best-practices (Lenny ~1,200 words, Stratechery ~2,000-3,000, Morning Brew ~800)
- Mobile email reading research (3-5 min is the median for tech newsletters that retain)
- Gmail / Outlook email-size heuristics (clip thresholds, image-block defaults)

If a budget needs to change, this rationale must change too. Don't tweak numbers without updating the why.

---

## Updating this file

When the analyst agent identifies a budget that's miscalibrated (e.g., "issues over 950 words have 18% lower click-through than 700-word issues"), update this file with:
1. The new number
2. The data that motivated the change
3. The date

Don't silently shift limits.

---

## Changelog

- **2026-04-27** — Initial document. Numbers calibrated against Issue 001's shipped values (1,007 words at the upper bound), best-practices research from comparable newsletters, and email-rendering heuristics (Gmail 102KB clip, mobile reading time medians).
