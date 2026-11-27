# Claude Code Weekly — Issue Schema

Every issue follows this exact structure. Fill in each field. Nothing more, nothing less.

---

## Frontmatter (metadata)

```
issue: 001
date: Tuesday, April 1, 2026
subject: <50 chars — the email subject line. No clickbait. Make it the tip itself.
preview: <90 chars — preview text shown in inbox before opening.
type: Command | Config | Workflow | Agent | Debug
```

---

## Fields

### `TIP_HEADLINE`
The technique name. Bold, specific, outcome-focused.
- Max 60 characters — **build.py enforces this as a hard error**
- Format: `Verb + what + outcome` (e.g. "Stop wasting tokens on context you already have")
- No questions, no ellipsis, no "how to"

### `TIP_INTRO`
The hook. Why does this matter right now? 2 sentences max.
- Sentence 1: The problem or cost (concrete, relatable)
- Sentence 2: What this issue delivers

### `TIP_BODY`
The technique itself, built from components in `COMPONENTS.html`.

**Required structure:**
1. Section label: `THE SETUP` — 1 paragraph on the context
2. Prompt teaser callout — immediately after THE SETUP paragraph, before THE TECHNIQUE:
   ```html
   <div style="background:#0d0f1f;border:1px solid rgba(80,112,247,0.2);border-radius:6px;padding:10px 14px;margin:0 0 24px">
     <p style="font-family:'SF Mono',Monaco,'JetBrains Mono',monospace;font-size:12px;color:#5070f7;margin:0">↓ Ready-to-run prompt at the bottom — Claude sets this up for you in 60 seconds.</p>
   </div>
   ```
3. Section label: `THE TECHNIQUE` — 2–4 numbered steps
4. Code block (if applicable) — show the actual command/config
5. Section label: `THE RESULT` — what changes, how much

**Rules:**
- Max 4 steps. If you need more, split into two issues.
- Every code block must be runnable as-is. No `YOUR_VALUE_HERE`, no `<placeholder>`, no `...` — **build.py blocks these**
- HTML comments inside `<pre><code>` blocks MUST be HTML-encoded: `&lt;!--` and `--&gt;`. Raw `<!--` inside pre blocks is stripped by email clients.
- No "as you know", "obviously", "simply", "just" — treat the reader as expert
- If you can't explain the result in one sentence, the tip isn't focused enough

**Claudify tie-in rule (every 4th issue):**
Add one factual line at the end of the RESULT block linking the outcome to Claudify. Rotate the angle per the issue type:
- Config → "Claudify ships with this configured out of the box."
- Workflow → "This is one workflow. Claudify includes the full library."
- Agent → "Claudify's agent system handles this automatically."
- Debug → "Claudify's auditor catches this class of error by default."
- Command → "Claudify wraps this into a single slash command."
Never pitch in non-tie-in issues. Tie-in issues: 004, 008, 012, …

### `PROMPT`
**MANDATORY. build.py fails hard if this field is empty.**

A plain-English instruction a non-technical user can paste directly into Claude Code and get the result without any manual config. Rules:
- Must be a complete, self-contained instruction
- No technical jargon that requires prior knowledge
- Should produce the same outcome as following all the steps manually
- 1–3 sentences max
- Never reference file paths, flags, or commands the reader hasn't seen in the issue

### `DEEP_DIVE_TITLE`
**MANDATORY.** Title of a related Claudify blog post or external resource that goes deeper on this issue's topic. Click target for engaged readers.
- Max 70 characters
- Format: descriptive phrase, not a question

### `DEEP_DIVE_URL`
**MANDATORY.** URL to the deep-dive resource. Prefer `/blog/...` (Claudify blog, drives internal SEO) over external links.
- Must start with `http://`, `https://`, or `/`

### `DEEP_DIVE_DESCRIPTION`
**MANDATORY.** One sentence describing what the reader will get. Don't repeat the title.
- 1 sentence, max 120 characters

### `PRO_TIP_HEADLINE`
**MANDATORY.** Advanced variation or extension of the main tip. Targets power users who already know the basics.
- 1 line, max 80 characters
- Should feel like an "insider trick"

### `PRO_TIP_BODY`
**MANDATORY.** What to do + why it matters. 2 sentences max.
- Must be directly buildable on top of the main tip (not a separate technique)

### `QUICK_WIN_HEADLINE`
A second tip, unrelated to the main. 1 line. Pure value — never a sales reference.

### `QUICK_WIN_BODY`
2 sentences. What to do + what it gets you. No steps needed — just do it.

### `READ_THIS_WEEK`
**MANDATORY.** Curated reading list — 3 short links. Mix of Anthropic official, Claudify blog, and community/external. HTML inline blocks.

Format each link as:
```html
<p style="margin:0 0 12px;font-size:13px;line-height:1.55">
  <a href="URL" style="color:#5070f7;text-decoration:none;font-weight:600">Title here &rarr;</a><br>
  <span style="color:#6a6a7a">One-line description.</span>
</p>
```
Last item: same format but `margin:0` instead of `margin:0 0 12px`.

Rules:
- Exactly 3 items
- Mix sources: 1 Anthropic-official, 1 Claudify blog (drives internal traffic), 1 external/community
- Each description max 90 characters
- All URLs must be evergreen (no time-sensitive Reddit threads that may get deleted)

### `NEXT_TEASE`
**MANDATORY.** One-line preview of next Tuesday's issue. **Plain English, benefit-led.** Subscribers see this without context — they should understand the value in 5 seconds, even if they don't know any flags or commands.
- Max 110 characters
- **Bad:** "piping Claude into shell with `--output-format stream-json`" (jargon, requires prior knowledge)
- **Good:** "The flag that turns Claude Code into a programmable tool you can plug into your own scripts."
- **Capitalisation:** start with a capital letter, end with a full stop. The eyebrow label sits above the sentence as a separate row, so the tease itself is a complete sentence.
- Lead with the OUTCOME or PROMISE. Mention the technical bit only if it's the hook (e.g., "/compact" is OK, but "--output-format stream-json" is not).
- Pulled from `BACKLOG.md` and rewritten for subscriber readability.

---

## Design tokens (do not deviate)

These are the exact colour values used across all issues. Copy from here:

| Element | Value |
|---|---|
| Section labels (THE SETUP / THE TECHNIQUE / THE RESULT) | `color:#18b4cc` `font-size:11px` `font-weight:700` `letter-spacing:0.18em` `text-transform:uppercase` |
| Code block file labels (.claude/settings.json etc.) | `color:#52526a` `font-size:11px` `font-weight:600` `letter-spacing:0.1em` `text-transform:uppercase` |
| Inline code | `color:#5070f7` `background:#0d0d1a` `border:1px solid #1e1e35` |
| RESULT block label | `color:#28c840` |
| Footer brand text + date | `color:#5070f7` |
| Footer links (Unsubscribe / View in browser) | `color:#3a3a5a` |
| Body text | `color:#8080a0` |
| Step headlines | `color:#e0e0e8` |
| Step body | `color:#72728a` |
| Background | `#0a0a12` |
| Code block background | `#0d0d1a` |

---

## Issue types (rotate weekly)

| Type | Pattern |
|---|---|
| **Command** | A specific `/command` or `--flag` most people haven't tried |
| **Config** | A `CLAUDE.md` rule, hook, or memory pattern that changes behaviour |
| **Workflow** | A multi-step sequence that automates a recurring task |
| **Agent** | How to set up or use a specialist subagent for a specific job |
| **Debug** | A technique for diagnosing and fixing a specific class of Claude problem |

Rotate through all 5 types before repeating. Check `BACKLOG.md` for the planned rotation.

---

## Quality bar

build.py enforces hard errors on: empty PROMPT, unfilled `{{PLACEHOLDERS}}`, subject > 50 chars, headline > 60 chars, placeholder strings in code blocks.

Manual checks before sending:
- [ ] Can a developer apply this in under 10 minutes?
- [ ] Is there a concrete before/after or measurable outcome?
- [ ] Does the code block run without modification?
- [ ] Is the quick win genuinely different from the main tip?
- [ ] Does the prompt teaser callout appear after THE SETUP?
- [ ] Is every HTML comment inside `<pre>` blocks encoded as `&lt;!--`?
- [ ] No filler words in intro or body?
- [ ] If this is a tie-in issue (004, 008, 012…), does RESULT have a Claudify line?
