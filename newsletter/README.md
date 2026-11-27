# Newsletter — Starter Pack

This directory contains the complete newsletter production system used to ship Issue 001 of [Claudify Weekly](https://newsletter.claudify.tech) on April 28, 2026.

It's shipped as a **working starter pack**, not abstract templates. The foundation files (`foundations/PERSONA.md`, `VOICE.md`, etc.) are calibrated for the Claudify Weekly newsletter — they are real, used-in-production rules, not placeholders.

**Use them two ways:**

1. **As reference** — see exactly how this newsletter system was built end-to-end. The voice rules, the budget profiles, the rendering-pipeline failure modes are all documented from real production cycles.
2. **As starting templates** — adapt to your own newsletter's brand. The structure transfers; the specific rules need replacing per your audience.

---

## What's inside

### Foundation files (`foundations/`)
Read by every newsletter agent at startup. The 6 files codify the voice, audience, format, and known-failure rules of the newsletter.

| File | Purpose | Adapt? |
|---|---|---|
| `PERSONA.md` | Audience floor / middle / ceiling reader segmentation | YES — define your readers |
| `VOICE.md` | Voice bible: hard bans (em dashes, marketing voice, etc.), preferred patterns, calibration paragraphs | YES — voice is brand-specific |
| `GLOSSARY.md` | 4-bucket glossary decision tree for technical terms | PARTIAL — Bucket 4 (banned acronyms) is universal; Bucket 1-3 brand-specific |
| `BUDGETS.md` | Numerical limits (word count, sentence length, link count, visual blocks) — two profiles for with/without god-tier prompt | PARTIAL — limits are calibrated against email-rendering reality, not arbitrary |
| `PIPELINE-PERSONALITIES.md` | Email client quirks (Beehiiv mojibake, Outlook flexbox break, Gmail clip threshold) | NO — these are universal rendering pipeline facts |
| `MISTAKES-LOG.md` | Every documented failure pattern with the auditor check that prevents recurrence | NO — these are universal mistakes; ADD your own as you ship |

### Schema + rubric

| File | Purpose |
|---|---|
| `ISSUE-SCHEMA.md` | Required fields per issue, format rules |
| `GOD-PROMPT-RUBRIC.md` | 6-criterion rubric for evaluating god-tier prompts (the prompt-architect agent enforces this) |
| `COMPONENTS.html` | Reusable HTML email building blocks |
| `email-template.html` | Master HTML template with `{{PLACEHOLDERS}}` filled by `build.py` |

### Build pipeline

| File | Purpose |
|---|---|
| `build.py` | Renders an issue source markdown to HTML by filling the email-template placeholders |
| `send.js` | Sends preview email to your inbox via Resend; can also create Beehiiv broadcast drafts (manual paste recommended for non-Enterprise) |
| `render-test.sh` | Playwright-based render test at 4 viewports (320, 414, 768, 1024) |
| `test-god-prompt.py` | 3-codebase test harness for the prompt-architect agent — validates god-tier prompts empirically |

### Issue / brief / draft folders

| Folder | Purpose |
|---|---|
| `issues/` | Issue source files (`NNN.md`) + rendered HTML output (`NNN-rendered.html`) |
| `briefs/` | Strategist's briefs that the drafter consumes |
| `drafts/` | Prompt-architect's god-tier prompt drafts during validation cycles |

### Operational

| File | Purpose |
|---|---|
| `BACKLOG.md` | Planned issues pipeline (topic ideas, type rotation) |
| `SYSTEM.md` | Full operational guide — read this for the end-to-end mental model |

---

## How the agents use this directory

The `newsletter-orchestrator` agent (in `.claude/agents/`) runs the 9-phase pipeline and reads from this directory:

```
strategy → draft → architect → build → audit → render-test → preview → send → analyse
   |          |          |        |        |          |          |        |        |
strategist drafter prompt-arch  build.py auditor  stylist     send.js  manual  analyst
                              + render-test.sh
```

Each phase reads its inputs from `newsletter/` (foundations, issue source, schema). Each phase's sub-agent runs in fresh context to avoid drafter blind-spots.

---

## Customising for your newsletter

**Recommended order:**

1. **Replace `foundations/PERSONA.md`** with your audience's floor / middle / ceiling reader segmentation
2. **Replace `foundations/VOICE.md`** voice anchors (calibration paragraph pairs, banned phrases for your brand, signature phrases)
3. **Adapt `foundations/GLOSSARY.md` Buckets 1-3** with your audience's vocabulary (Bucket 4 — banned acronyms — stays universal)
4. **Adjust `foundations/BUDGETS.md`** word counts if your audience reads longer/shorter newsletters
5. **Keep `foundations/PIPELINE-PERSONALITIES.md` and `MISTAKES-LOG.md`** as-is — these are universal email-rendering reality
6. **Replace `email-template.html`** branding (colours, logo, fonts) — the structure (table-based, no flexbox, inline styles, HTML entities for special chars) stays
7. **Update `BACKLOG.md`** with your topic backlog and content rotation

After customising the foundations, trigger your first issue:
```
/newsletter strategy 001
```

The strategist reads your `BACKLOG.md`, picks a topic, writes a brief. Then `/newsletter draft 001` produces the issue. Then through the rest of the pipeline.

---

## What survives across newsletters

The Claudify Weekly system has shipped Issue 001 with these proven patterns. They generalise:

- **Voice anchors via calibration paragraph pairs** beat abstract style guides every time
- **Two-profile word-count budget** (with vs without god-tier prompt) reflects reality
- **Fresh-context auditor** catches what the drafter blind-spotted
- **3-codebase test harness for god-tier prompts** prevents shipping mediocre prompts
- **22 documented mistakes** (in `MISTAKES-LOG.md`) become permanent regression checks

These survive any newsletter. Use them.

---

## Reference newsletter

The system was used to ship [Issue 001 of Claudify Weekly](https://newsletter.claudify.tech/p/build-a-self-improving-claude-md-in-5-minutes) on April 28, 2026. Read it as a worked example — the issue source, the rendered HTML, and the audit verdicts are all in this package's reference structure.

If you want to see the system in action: take the foundations as-is, write your own `BACKLOG.md` topic, and run the full pipeline. By Issue 002 the foundations should match your brand, not the original's.
