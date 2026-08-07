# Mistakes Log — every newsletter failure with the check that would have caught it

The point of this file: every mistake the system has made, ever, becomes a check the auditor runs on every future issue. The system gets monotonically smarter — it never makes the same mistake twice.

This file is read by the auditor at the start of every issue review. It's the auditor's training data.

Each entry follows a fixed format:

```
### MISTAKE-NNN: short name
**Issue:** which issue this came from
**What happened:** a sentence
**Why it happened:** root cause (drafter blind spot, missing rule, etc.)
**Why it matters:** what the impact was on the reader/system
**Auditor check:** the specific mechanical or semantic check that prevents recurrence
**Severity:** Critical / High / Medium / Low
**Status:** Open (still possible to recur) / Closed (auditor check confirmed working)
```

---

## Pre-launch audit — patterns from Issue 001 development

These 15 entries are the foundation. Every one of them was a mistake the writer-drafter made during Issue 001 that the human writer caught and fixed. Each becomes a permanent check.

---

### MISTAKE-001: Jargon in TL;DR label
**Issue:** 001 (caught in v3 preview)
**What happened:** Used the label "TL;DR" at the top of the gist block.
**Why it happened:** Drafter defaulted to dev-internet shorthand without checking it against the audience floor.
**Why it matters:** The audience floor doesn't recognise "TL;DR". It was flagged in review. Subscribers who don't know it bounce in the first 5 seconds of opening.
**Auditor check:** Block any of these labels: `TL;DR`, `FWIW`, `IIRC`, `IMO`, `IMHO`, `AFAIK`, `YMMV`, `LGTM`, `ICYMI`, `WIP`, `TBD`. Replace with plain-English equivalents per GLOSSARY.md Bucket 4.
**Severity:** High
**Status:** Closed — auditor enforces via banned-label scan

---

### MISTAKE-002: Stack-specific reference (Bun, not npm)
**Issue:** 001 (caught in v3 preview)
**What happened:** Personal opener used "this codebase uses Bun, not npm" as the concrete preference Claude kept forgetting.
**Why it happened:** Drafter chose a real-but-niche example without checking it against audience floor. JavaScript-ecosystem readers got it; everyone else didn't.
**Why it matters:** The opener is the single most-read sentence in the issue. If 60% of readers don't recognise the example, the opener fails its hook job.
**Auditor check:** Every technical term in the issue is checked against GLOSSARY.md. Bucket 1 terms (universal) ship freely. Bucket 2 terms (need gloss) get inline-glossed on first use. Bucket 3 terms (avoidable) get replaced with universal alternatives. Bucket 4 terms (banned) are blocked.
**Severity:** High
**Status:** Closed — auditor enforces via glossary scan

---

### MISTAKE-003: Jargon NEXT_TEASE
**Issue:** 001 (caught in v3 preview)
**What happened:** Coming-Next-Tuesday tease read "piping Claude into shell with `--output-format stream-json`". Subscribers who don't already know what that flag does have no reason to want next week's issue.
**Why it happened:** Drafter copy-pasted from BACKLOG.md (internal engineering shorthand) into subscriber-facing copy without translation.
**Why it matters:** The next-Tuesday tease is the anticipation builder. If it's incomprehensible, no anticipation is built. Subscribers don't develop the habit of looking forward to Tuesdays.
**Auditor check:** Apply the floor-reader test to NEXT_TEASE specifically. Reject any tease that contains a flag name, a technical primitive, or a concept that would require prior knowledge to understand. Require benefit-led plain English.
**Severity:** High
**Status:** Closed — auditor enforces via NEXT_TEASE-specific scan

---

### MISTAKE-004: Lowercase sentence start in NEXT_TEASE
**Issue:** 001 (caught in v3 preview)
**What happened:** NEXT_TEASE shipped as "the flag that turns Claude Code...". Lowercase "the" because the drafter mentally treated it as a continuation of "Coming next Tuesday:" (with implicit colon).
**Why it happened:** The "Coming next Tuesday" eyebrow label sits as a separate block element; the tease is a standalone sentence and should be capitalised. Drafter's mental model didn't match the rendered visual hierarchy.
**Why it matters:** Lowercase sentence-start in a visually-isolated block reads as a typo. Damages perceived quality.
**Auditor check:** Every standalone block-level sentence (TIP_HEADLINE, NEXT_TEASE, Pro tip headline, Quick win headline, Deep dive title) must start with a capital letter and end with appropriate punctuation.
**Severity:** Medium
**Status:** Closed — auditor enforces via capitalisation scan on block-level sentences

---

### MISTAKE-005: Low-contrast grey text recurring across template
**Issue:** 001 (originally caught in v3 preview; regression caught 2026-04-27 by auditor)
**What happened:** Originally the P.S. forward CTA used `color:#9a9aad` (light grey on light background, 2.6:1 contrast — well below WCAG AA's 4.5:1). The original fix replaced ONLY the P.S. line. The same `#9a9aad` value persisted in 4 other locations in `email-template.html`: byline (line 31), "Coming next Tuesday" eyebrow (line 124), footer text (line 141), unsubscribe link (line 144). All four have contrast ratios 2.52-2.65:1 — three fail even the looser 3:1 floor.
**Why it happened:** The fix was scoped to a single element rather than to the colour value template-wide. The template has a recurring "subordinate grey" need; the value `#9a9aad` was the de-facto solution and propagated wherever subordinate grey was wanted.
**Why it matters:** Accessibility violation across the template. The forward CTA failure was the visible symptom; the colour value's broader use is the systemic cause.
**Auditor check (expanded):** Every text element's foreground colour must have a contrast ratio ≥ 4.5:1 against its background (WCAG AA), regardless of the element's role. The auditor's contrast check now runs across ALL text elements in the rendered HTML, not just the P.S. CTA. Block any text under 4.5:1.
**Severity:** High
**Status:** Re-opened 2026-04-27 — auditor regression-checked the original fix and found 4 surviving instances. Fix applied: `#9a9aad` swapped to `#6a6a7a` (contrast 5.7:1) globally in `email-template.html`. Status will move to Closed-2 after Issue 001 re-audit confirms zero `#9a9aad` instances and all greys at 4.5:1+.

---

### MISTAKE-006: Mojibake on non-ASCII characters in Beehiiv paste
**Issue:** 001 (caught in initial Beehiiv preview)
**What happened:** Literal characters `↓`, `·`, `—` rendered as `‚Üì`, `¬∑`, and other garbled sequences when pasted into Beehiiv.
**Why it happened:** Beehiiv's paste pipeline re-decodes UTF-8 bytes as Mac Roman. Drafter wasn't aware of this pipeline quirk.
**Why it matters:** Mojibake makes the entire newsletter look broken. Loss of trust is immediate.
**Auditor check:** Scan rendered HTML for any non-ASCII character (codepoint > 127). Block if any are found. All non-ASCII must be HTML entities (`&darr;`, `&middot;`, `&mdash;`, etc.).
**Severity:** Critical
**Status:** Closed — auditor enforces via non-ASCII scan

---

### MISTAKE-007: Reusing email subjects across previews caused Gmail thread-trimming
**Issue:** 001 (caught when reviewing v3 preview in Gmail)
**What happened:** Multiple preview sends used identical subject ("[PREVIEW] Build a self-improving CLAUDE.md in 5 min"). Gmail threaded them and silently trimmed the "duplicate" middle content. On opening the latest preview, the entire body content appeared missing.
**Why it happened:** The send.js preview command didn't include any subject differentiator. Drafter didn't account for Gmail's threading + content-trimming behaviour.
**Why it matters:** During preview review, the reviewer couldn't see the actual content the auditor was supposed to be reviewing. The system's review loop was broken.
**Auditor check:** Preview send wraps subject with timestamp suffix (`[PREVIEW HHMMSS]`). Auditor verifies this is in send.js before approving any send pipeline change.
**Severity:** Medium
**Status:** Closed — fix shipped to send.js, auditor validates pipeline behaviour

---

### MISTAKE-008: Generic god-tier prompt with no relevance to issue topic
**Issue:** 001 (caught when the reviewer asked "is this really god-tier")
**What happened:** First god-tier prompt (Senior Engineer Review) had no thematic connection to Issue 001's main tip (self-improving CLAUDE.md). The two sections of the email felt disconnected.
**Why it happened:** Drafter treated "god-tier prompt" as a slot to fill rather than as content that should reinforce the issue's thesis.
**Why it matters:** The issue's compositional integrity matters. When the god-tier prompt extends the main tip, the whole issue feels like one coherent argument. When they're disconnected, the reader gets two unrelated ideas.
**Auditor check:** GOD-PROMPT-RUBRIC.md Criterion #6 (Relevance) must score 4 or 5 to ship. Auditor verifies the prompt-architect's rubric scoring before approval.
**Severity:** High
**Status:** Closed — auditor enforces via rubric check

---

### MISTAKE-009: Quality settling at "B+ is good enough"
**Issue:** 001 (caught when the reviewer asked "is this really the best we can do")
**What happened:** Drafter shipped a B+ quality first draft of the god-tier prompt and called it complete. Required two review passes to iterate to A+.
**Why it happened:** No internal quality gate forced iteration past "good enough."
**Why it matters:** Settling at B+ produces newsletters that are okay but not memorable. The reader's "I have to forward this" reaction never lands. Growth stalls.
**Auditor check:** Every god-tier prompt must clear the 6-criterion rubric with 4+ on at least 5 criteria, AND must be tested empirically on 3 codebases. Paper claims about quality are insufficient.
**Severity:** Critical (this is the systemic bias toward shipping mediocre content)
**Status:** Closed — auditor enforces via rubric + empirical-test requirement

---

### MISTAKE-010: Iterative degradation across turns (Deep Dive clickability)
**Issue:** 001 (flagged twice in review, in different turns)
**What happened:** The reviewer asked for the Deep Dive block to be fully clickable. The drafter started the fix, then pivoted to a larger refactor, and the original fix was lost. It had to be re-flagged.
**Why it happened:** No tracking of open items across turns. When the drafter's attention shifted, the older request fell out of working memory.
**Why it matters:** The user has to repeat themselves. Trust erodes.
**Auditor check:** At the end of each working session, auditor produces a "open items" list — anything flagged in review that wasn't explicitly resolved or closed. This list rolls forward to the next session.
**Severity:** Medium
**Status:** Open — open-items tracking pattern to be implemented in workflow

---

### MISTAKE-011: Prompt voice was the writer's voice, not the prompt's character
**Issue:** 001 (caught during god-tier prompt v2-to-v3 iteration)
**What happened:** v2 of the god-tier prompt had lines like "Be ruthless. Most CLAUDE.md files are 70% noise." This was the writer's voice telling Claude what to do. The prompt itself had no character.
**Why it happened:** Drafter conflated "voice in the marketing copy" with "voice in the prompt body." These are different jobs.
**Why it matters:** The prompt's character determines the personality of Claude's response. A prompt with strong character (clear stance, anti-patterns, calibration examples) produces sharper output. A prompt with no character produces generic output.
**Auditor check:** God-tier prompts are evaluated against rubric Criterion #3 (Novelty) and Criterion #5 (Shareability). Both lean on prompt character. If the prompt reads like procedural instructions only (no stance, no anti-patterns, no calibration), score reflects this.
**Severity:** Medium
**Status:** Closed — auditor enforces via rubric

---

### MISTAKE-012: Cumulative word-count drift
**Issue:** 001 (observed across iterations)
**What happened:** Issue word count went 408 → 555 → 662 → 868 → 1,007 across iterations. Each addition was justified individually. No one was watching the total.
**Why it happened:** No cumulative budget enforcement. Each block addition was a local optimisation; total never measured.
**Why it matters:** A 1,007-word newsletter exceeds the realistic 5-min Tuesday-morning attention budget. Skim rate spikes, engagement drops.
**Auditor check:** Every issue's total word count is checked against BUDGETS.md targets (700-900 ideal, 1,100 hard cap). Going over requires explicit justification.
**Severity:** Medium
**Status:** Closed — auditor enforces via budget scan

---

### MISTAKE-013: Schema validation gaps caught only by human review
**Issue:** 001 (multiple times)
**What happened:** Lowercase NEXT_TEASE, missing capitalisation rule, etc. — these had to be flagged in review. Schema in ISSUE-SCHEMA.md didn't enforce them.
**Why it happened:** Schema enforced "field present and non-empty" but not "field follows specific format rules" (capitalisation, sentence structure, length).
**Why it matters:** Subtle failures slip past mechanical schema checks until a human catches them.
**Auditor check:** Each schema field has format-specific validators. NEXT_TEASE must start with capital, end with full stop, max 110 chars. TIP_HEADLINE must be 5-10 words. Etc. Implemented as deeper validation in build.py and the auditor agent.
**Severity:** Medium
**Status:** Open — deeper field-level validators to be added to build.py + auditor

---

### MISTAKE-014: Encoding-pipeline-blind drafting
**Issue:** 001 (multiple symptoms — mojibake, Beehiiv border styling, Gmail trimming)
**What happened:** Drafter optimised for the source HTML file. Didn't account for what Beehiiv strips, what Gmail trims, what Outlook breaks.
**Why it happened:** Mental model was source-first, not destination-first.
**Why it matters:** Half the bugs in Issue 001 development came from the source-vs-destination gap.
**Auditor check:** Stylist agent runs PIPELINE-PERSONALITIES.md tests on every rendered HTML before approving for send. Mechanical tests for non-ASCII, HTML size, table-border-suppression, link validity, inline-style enforcement.
**Severity:** Critical
**Status:** Open — stylist agent to be built in Phase 3

---

### MISTAKE-015: "We're not on Beehiiv Enterprise" surprise
**Issue:** 001 (caught when /newsletter send hit a 403)
**What happened:** Drafter assumed `node send.js 1` (Beehiiv broadcast creation) would work. Beehiiv returned `SEND_API_NOT_ENTERPRISE_PLAN`. Manual paste was the only available send path.
**Why it happened:** Drafter didn't know which Beehiiv plan-tier the user is on, and didn't check API capability before assuming the automation would work.
**Why it matters:** Caused a false start at send time. Issue 001 ship was delayed while the manual-paste path was understood.
**Auditor check:** PIPELINE-PERSONALITIES.md documents Beehiiv API gating. Send pipeline pre-flight checks plan capability before assuming automated send. Manual-paste documentation is the canonical send path until plan changes.
**Severity:** Low (one-time discovery; well-documented now)
**Status:** Closed — documented in PIPELINE-PERSONALITIES.md

---

### MISTAKE-016: Source-rendered drift (drafter updated source, build never re-ran)
**Issue:** 001 (caught at first auditor validation cycle, 2026-04-27)
**What happened:** GOD_PROMPT_BODY in source `001.md` was iterated to v3 ("The CLAUDE.md Surgeon", 2,487 chars, structured Steps 1-5 plus edge cases plus "Begin." marker). The rendered HTML still contained the older v2 prompt at 1,377 chars. About 50% of the god-tier prompt content the drafter wrote never reached the subscriber-bound HTML. GOD_PROMPT_INTRO and GOD_PROMPT_CLOSER also drifted.
**Why it happened:** No automatic re-render trigger when source changes. Drafter assumed `001-rendered.html` is the live output of `001.md`. It was actually a stale snapshot.
**Why it matters:** The whole point of the source-of-truth model is that the source IS the issue. If the rendered file diverges silently, every audit downstream of source is auditing a fiction. The subscribers receive something the auditor never saw.
**Auditor check:** Before any voice/length checks run, verify `NNN-rendered.html` is newer than `NNN.md` AND that key field samples match between source and rendered (e.g. compare GOD_PROMPT_BODY first 200 chars). If mismatch, HALT audit and demand re-render. Ideally a `make render` step runs automatically on audit invocation.
**Severity:** Critical
**Status:** Open — auditor procedure step 3.5 (source-rendered consistency check) to be added; PostToolUse hook on `python3 build.py` should be considered to auto-rebuild on source changes.

---

### MISTAKE-017: Budget set without accounting for god-tier gift block size
**Issue:** 001 (caught when re-render after MISTAKE-016 fix exposed the actual full-content word count)
**What happened:** BUDGETS.md set a 1,100 hard cap on total word count without distinguishing between issues with and without a god-tier gift block. After MISTAKE-016 was fixed (build.py parser corrected to faithfully render the full v3 god-tier prompt), Issue 001's word count rose to 1,309, then 1,131 after substantive trims, still 31 words over a cap that was set blind to the god-tier gift's actual size (~500 words).
**Why it happened:** Budgets were drafted before any issue had been built end-to-end with all sections present, including a fully-formed god-tier prompt. The discipline value of the budget was real, but the calibration was based on incomplete data.
**Why it matters:** Forcing a strict budget through trim-discipline when the budget itself is miscalibrated either compromises content quality (over-trimming) or breeds rationalisation ("just this one exception"). Both erode the system's integrity. The right response to a miscalibrated budget is to recalibrate, not to constrain.
**Auditor check:** Two budget profiles now exist (with-god-tier vs without-god-tier). Auditor checks the issue source for non-empty GOD_PROMPT_BODY field and applies the correct profile. If word count exceeds the relevant profile's hard cap, FAIL. If word count is within the profile, PASS.
**Severity:** Medium
**Status:** Closed — BUDGETS.md updated to two-profile model; auditor's M14 check now reads the correct cap based on god-tier gift presence.

---

### MISTAKE-018: Paragraph break inside single `<p>` collapses in email clients
**Issue:** 001 (caught 2026-04-27 by auditor during full pipeline run)
**What happened:** TIP_INTRO and GOD_PROMPT_INTRO source contained two paragraphs separated by a blank line. The build wrapped each entire field value in a single `<p>` tag, which meant the blank line collapsed to a single space in the rendered HTML. Gmail web, Outlook, and Apple Mail all collapse multiple consecutive whitespace inside `<p>` to one — the intended two-beat hook rendered as one wall-of-text paragraph.
**Why it happened:** build.py was structured around HTML-bearing fields (TIP_BODY, TLDR, READ_THIS_WEEK) that bring their own paragraph structure, plus plain-text fields (TIP_INTRO, GOD_PROMPT_INTRO/CLOSER, PRO_TIP_BODY, QUICK_WIN_BODY). The plain-text fields were dropped into a single `<p>` wrapper without any paragraph-break translation. The drafter wrote multi-paragraph prose assuming it would render as separate paragraphs.
**Why it matters:** Voice rhythm is load-bearing for newsletter copy. The two-beat opener (specific moment + what this issue delivers) loses its punch when both beats merge into one paragraph. This silently degrades every issue using multi-paragraph prose in plain-text fields.
**Auditor check:** For every multi-sentence prose field (TIP_INTRO, GOD_PROMPT_INTRO, GOD_PROMPT_CLOSER, PRO_TIP_BODY, QUICK_WIN_BODY), verify source blank lines render as visual breaks in the rendered HTML. If a single `<p>` contains literal `\n\n` without `white-space:pre-wrap`, FAIL.
**Severity:** Medium
**Status:** Closed 2026-04-27 — build.py updated with `prose_paragraph_split()` helper that converts `\n\n` to `<br><br>` for plain-text prose fields. Audit pre-flight should also grep rendered HTML for `\n\n` inside `<p>` blocks.

---

### MISTAKE-022: God-tier prompt body collapses in Beehiiv (white-space:pre-wrap unreliable)
**Issue:** 001 (caught 2026-04-28 in review of the rendered Beehiiv preview)
**What happened:** GOD_PROMPT_BODY was wrapped in `<p style="...white-space:pre-wrap">{body}</p>` and the body content used raw `\n` newlines for structure (Step 1 / Step 2 / bulleted lists / BAD-WHY-GOOD calibration triples / Edge cases). When pasted into Beehiiv's HTML editor, all line breaks collapsed and the prompt rendered as one flowing block of text. Reader cannot parse the structure.
**Why it happened:** the build assumed `white-space:pre-wrap` would preserve newlines across all email-client paste pipelines. Empirically Beehiiv (and likely some other clients) strip or normalise whitespace inside `<p>` tags during paste, even when pre-wrap is set. Same root failure family as MISTAKE-018 (paragraph collapse in TIP_INTRO / GOD_PROMPT_INTRO), just affecting a different field that was assumed safe because pre-wrap was thought to handle it.
**Why it matters:** the god-tier prompt is the issue's referral reward and the longest-form content piece. If it renders unreadable, the entire issue fails its purpose. Subscribers cannot use the prompt, the referral mechanism collapses (forwarders won't earn unlocks because the recipient sees garbage), and the perceived value of the newsletter drops.
**Auditor check:** `god_prompt_body_format()` helper added to build.py. Every `\n` in GOD_PROMPT_BODY is converted to an explicit `<br>` tag at build time. The `<p>` wrapper retains `white-space:pre-wrap` as belt-and-suspenders, but `<br>` does the actual line-breaking work, surviving any platform's whitespace normalisation. Stylist agent should verify GOD_PROMPT_BODY contains `<br>` tags in rendered output and zero raw `\n` characters inside the prompt body's `<p>` element.
**Severity:** Critical (renders the prompt unusable)
**Status:** Closed 2026-04-28 — `god_prompt_body_format()` helper added; applied to GOD_PROMPT_BODY before injection into the gift block. Issue 001 rebuilt with structured `<br>` line breaks. Generalised lesson: any newsletter content that depends on whitespace preservation is fragile across email-client paste pipelines, use explicit `<br>` tags.

---

### MISTAKE-021: Marketing-cliché framing in operational / CTA / closer copy
**Issue:** 001 (caught 2026-04-28 in preview review of GOD_PROMPT_CLOSER)
**What happened:** GOD_PROMPT_CLOSER read "Forward this email now and you're grandfathered in when it goes live." Two marketing-cliché phrases ("grandfathered in", "when it goes live") slipped through. Both were flagged as off-brand and off-tone.
**Why it happened:** VOICE.md hard ban #4 listed canonical marketing-cliché phrases (game-changer, cutting-edge, supercharge your workflow, etc.) but didn't include the **softer-marketing family** that leaks into operational/CTA copy at the end of issues — phrases like "grandfathered in", "when it goes live", "lifetime access", "early access", "VIP access", "once we launch". The auditor's M6 check matched the canonical list verbatim and missed the softer family entirely.
**Why it matters:** Operational copy at the end of issues (god-tier prompt closer, forward CTAs, signup prompts) is where marketing voice is most likely to leak in, because it's where promotion happens narratively. A marketing-cliché in this position undermines the brand-positioning rule (parallel to MISTAKE-020) and gives the same "competitor agency could quote this" failure mode.
**Auditor check:** M6 expanded with the **softer marketing-cliché list** (grandfathered in, when it goes live, once we launch, when we go live, lifetime access, early access, VIP access, get in early, limited time only, don't miss out, act now). The auditor flags HIGH severity for any match in operational/promotional fields (GOD_PROMPT_INTRO, GOD_PROMPT_CLOSER, P.S. forward CTAs, footer subscribe lines, body content where promotion happens).
**Severity:** Medium-High (brand-positioning damage, slipped past existing hard ban)
**Status:** Closed 2026-04-28 — VOICE.md hard ban #4 expanded with the softer-cliché table including banned/replacement pairs; auditor M6 check description updated to reference the expanded list; Issue 001 GOD_PROMPT_CLOSER rewritten to specific concrete language ("Starting next Tuesday, the god-tier prompt costs 2 referrals. Forwards from this week count toward your first unlock when the vault opens at 100 subscribers. Forward generously.").

---

### MISTAKE-020: Voice frames the writer or Claudify as the entity experiencing the failure
**Issue:** 001 (caught 2026-04-27 in preview review)
**What happened:** TIP_INTRO opened with "Last Tuesday I caught Claude rediscovering, for the fourth session in a row, that this codebase uses tabs, not spaces. I'd told it twice." The writer is the protagonist of a failure narrative — the implication being that the writer (and by extension Claudify, the product) keeps hitting the exact problem the issue claims to solve. From a brand-positioning perspective: a competitor agency could quote this paragraph as evidence that Claudify's expert can't even configure their own tool reliably.
**Why it happened:** VOICE.md preferred pattern #1 ("Personal moment opener — TIP_INTRO leads with a specific, concrete moment") was applied without a counterbalancing rule against framing the writer as the one with the problem. Personal-moment openers default to the writer's experience, which often means the writer's failure.
**Why it matters:** Claudify is the product. The newsletter exists to position it as the solution and the writer as the authority. Voice that positions the writer as the practitioner currently hitting the failure (a) implies Claudify hasn't solved it, (b) undermines authority, (c) gives competitors quotable evidence. This is a HIGH-severity brand-positioning failure, not a wording quibble.
**Auditor check:** S13 (new). Scan every prose field (TIP_INTRO, GOD_PROMPT_INTRO, GOD_PROMPT_CLOSER, PRO_TIP_BODY, QUICK_WIN_BODY, NEXT_TEASE) for first-person failure-narrative patterns. Block these phrases unless explicitly tagged as authority-framing: "I caught X failing", "I'd told it [twice/N times]", "I keep having to", "my system [verb of failure]", "I tried X and it didn't work", "X kept happening to me". Allow phrases that frame the writer as practitioner-of-solution: "I run this prompt", "I've used this on", "I see this across users", "I noticed a pattern".
**Severity:** High (brand-positioning damage, not just wording)
**Status:** Closed 2026-04-27 — VOICE.md hard ban #8 added with explicit allowed/banned framing tables; auditor S13 added; Issue 001 TIP_INTRO rewritten with third-person diagnostic opener ("Talk to anyone running Claude Code daily and the same pattern surfaces").

---

### MISTAKE-019: Visual block budget single-profile mismatch with god-tier-gift word-count two-profile model
**Issue:** 001 (caught 2026-04-27 by stylist during full pipeline run)
**What happened:** BUDGETS.md visual block budget was set to 8-11 distinct blocks, single-profile. Issue 001 (with god-tier gift) renders 14 distinct visual blocks. The stylist's V2 check also flagged 320px viewport height at 7982px against a 5000px threshold. Both findings are calibration mismatches — the single-profile thresholds did not account for the god-tier gift's structural visual mass (1 dark card + framing elements + closer = 3 extra blocks).
**Why it happened:** When MISTAKE-017 split the word-count budget into two profiles, the visual block budget and the stylist V2 height threshold were not updated to follow the same pattern. Each was set against the without-god-tier baseline.
**Why it matters:** Same as MISTAKE-017 — a miscalibrated budget either over-constrains correct output or breeds rationalisation. The fix is recalibration, not constraint.
**Auditor check:** Stylist's R15 (block count) and V2 (320px viewport height) now branch on god-tier-gift presence: 8-11 blocks / 5000px without god-tier; 11-14 blocks / 9000px with god-tier.
**Severity:** Medium
**Status:** Closed 2026-04-27 — BUDGETS.md visual section split into two profiles parallel to MISTAKE-017. Stylist agent V2 threshold updated.

---

## Open mistakes (still possible to recur)

- MISTAKE-010: Iterative degradation across turns (open-items tracking not yet built)
- MISTAKE-013: Schema field-level validators (deeper validators not yet built)
- MISTAKE-016: Source-rendered drift (build.py parser fixed; auditor pre-flight consistency check not yet built)

MISTAKE-014 closed 2026-04-27 (stylist agent built and validated). MISTAKE-005 reopened then re-closed 2026-04-27 with expanded scope. MISTAKE-018 + MISTAKE-019 added 2026-04-27 from full pipeline run, both closed same day with build.py + BUDGETS.md fixes.

---

## Self-learning architecture: which tier each mistake is at

Every documented mistake gets one of three protection tiers. The tier determines **how strongly** the mistake is prevented from recurring. Logging alone is not learning.

### The 3 tiers

**Tier 1 — Strongest. Hook blocks at write-time.**
The mistake cannot reach the file system. PreToolUse hooks scan content before Write/Edit lands. If the failure pattern is detected, the write is rejected with an explanation. Zero opportunity for the mistake to ship.

**Tier 2 — Strong. Auditor regression check at audit time.**
The mistake reaches the file system but is blocked from ship. The auditor (or stylist) agent reads MISTAKES-LOG.md at startup and runs a check for each documented entry. Failed checks block the audit verdict from PASS. The auditor also escalates regressions to INCIDENT (signals the original fix was scope-limited).

**Tier 3 — Weakest. Documented in MISTAKES-LOG only.**
Relies on agents reading the log and applying judgment. No automated enforcement. Acceptable for low-frequency or judgment-dependent failure modes; unacceptable for mechanical patterns.

### Current tier assignment

| Mistake | Description | Tier | Enforcement mechanism |
|---|---|---|---|
| MISTAKE-001 | TL;DR jargon | 1 | `newsletter-jargon-check.sh` (banned acronym list from GLOSSARY.md Bucket 4) |
| MISTAKE-002 | Bun jargon | 2 | auditor S7 (glossary compliance check); GLOSSARY.md Bucket 2 entry |
| MISTAKE-003 | NEXT_TEASE jargon | 1 | `newsletter-jargon-check.sh` |
| MISTAKE-004 | Lowercase NEXT_TEASE | 2 | auditor M20 (capital-letter start check) |
| MISTAKE-005 | Low-contrast grey (template-wide) | 1 | `newsletter-contrast-check.sh` (deny-list of low-contrast hex values) + auditor regression check |
| MISTAKE-006 | Em-dash mojibake | 1 | `newsletter-em-dash-check.sh` |
| MISTAKE-007 | Subject reuse, Gmail thread-trim | 2 | send.js timestamp suffix on previews + auditor subject-uniqueness check |
| MISTAKE-008 | Generic god-tier prompt | 2 | prompt-architect rubric criterion 6 (Relevance) — hard gate 4+ |
| MISTAKE-009 | Quality settling at "B+ is good enough" | 3 | architect hard gate enforces for god-tier prompts; drafter relies on auditor |
| MISTAKE-010 | Iterative degradation (open-items tracking) | 3 | not yet enforced — defer until pattern recurs across 3+ issues |
| MISTAKE-011 | God-tier prompt voice failures | 2 | architect rubric criterion 3 (Novelty) |
| MISTAKE-012 | Cumulative word drift | 2 | auditor M14 + BUDGETS two-profile |
| MISTAKE-013 | Schema field gaps | 1 | `newsletter-schema-check.sh` |
| MISTAKE-014 | Encoding-pipeline-blind drafting | 2 | stylist agent R3 / R4 / R9 (style-block strip, inline-style enforcement, non-ASCII scan) |
| MISTAKE-015 | Beehiiv Enterprise paywall | n/a | operational, manual paste — not preventable in software |
| MISTAKE-016 | Source-rendered drift | 2 | build.py parser fix + auditor consistency check |
| MISTAKE-017 | Word count single-profile | 2 | BUDGETS two-profile + auditor M14 god-tier-aware branching |
| MISTAKE-018 | `<p>` paragraph collapse in email clients | 1 | `newsletter-paragraph-collapse-check.sh` + build.py `prose_paragraph_split()` |
| MISTAKE-019 | Visual block single-profile | 2 | BUDGETS two-profile + stylist R15/V2 god-tier-aware branching |
| MISTAKE-020 | First-person failure narrative (the writer / Claudify as entity with the problem) | 2 | VOICE.md hard ban #8 + auditor S13 (failure-narrative phrase scan) |
| MISTAKE-021 | Marketing-cliché framing in operational / CTA / closer copy ("grandfathered in", "when it goes live", etc.) | 2 | VOICE.md hard ban #4 expanded softer-cliché list + auditor M6 |
| MISTAKE-022 | God-tier prompt body collapses in Beehiiv (white-space:pre-wrap unreliable) | 2 | build.py `god_prompt_body_format()` converts `\n` to `<br>` at build time; stylist verifies `<br>` presence in rendered body |

### Gaps (Tier 3 mistakes worth lifting in future)

- **MISTAKE-009 (quality settling)** — only the architect hard gate enforces. The drafter has no equivalent pre-handoff bar for body copy. Lift to Tier 2 by adding an auditor check that scores draft against a composite quality rubric before audit completes.
- **MISTAKE-010 (iterative degradation)** — no current mechanism. Worth building an "open items" tracker that flags any "follow up next time" or "TBD" pattern across consecutive issues. Defer until pattern recurs.

### How to lift a mistake to a stronger tier

**Tier 3 → Tier 2:** add an auditor (or stylist) check that mechanically verifies the failure mode. Add to that agent's check matrix (M-list, S-list, R-list, V-list). Update the MISTAKES-LOG entry's "Auditor check" field. Update this tier table.

**Tier 2 → Tier 1:** add a PreToolUse hook that scans content before Write/Edit. Hook must:
1. Run under 50ms in the common case (no perceptible latency)
2. Only block on definite matches — false positives are catastrophic because ship gets blocked for nothing
3. Provide a clear error message with the MISTAKE-NNN reference + foundation rule + fix recommendation
4. Be registered in `.claude/settings.json` PreToolUse hookSpecs
5. Be added to this tier table with the hook filename

### How the loops actually close

The auditor reads MISTAKES-LOG.md at the start of every audit. The "regression checks" step in its procedure verifies that each documented check is firing. When a documented Closed mistake is found recurring (like MISTAKE-005 was on 2026-04-27), the auditor escalates from FAIL to INCIDENT — signalling that the original fix was scope-limited and needs broadening. The fix gets propagated, the entry's status is updated, and in many cases the mechanism gets lifted a tier.

Every cycle, the system gets stronger:
1. New mistake observed
2. Logged at Tier 3 (judgment-only)
3. Auditor adds check (Tier 2) once pattern is mechanical
4. Hook added (Tier 1) once check is fast and false-positive-safe
5. If regression observed despite Tier 2, scope of check is broadened (sometimes triggering a tier lift)

The MISTAKES-LOG is not a passive record. It is the source of regression checks the auditor runs every audit. Every closed entry contributes to the audit's check matrix permanently.

---

## How to add a new entry

When the auditor catches a new failure pattern OR when something is flagged in review that wasn't already covered:

1. Pick the next available MISTAKE-NNN number
2. Fill in the format above (Issue / What happened / Why / Why it matters / Auditor check / Severity / Status)
3. Mark Status as Open if no enforcement exists yet
4. Add the auditor check to the relevant agent's check list (M / S / R / V)
5. When the check is implemented and confirmed working, mark Status as Closed
6. Update the "Self-learning architecture" tier table above with the new entry
7. If the pattern is mechanical and false-positive-safe, consider adding a PreToolUse hook (Tier 1)

The file grows monotonically. Closed entries stay (they're history). New entries accumulate. Tier upgrades happen as enforcement mechanisms strengthen.

---

## Changelog

- **2026-04-27** — Initial document. 15 entries seeded from the audit of Issue 001 development. Each entry maps a real failure to a specific auditor check that prevents recurrence.
