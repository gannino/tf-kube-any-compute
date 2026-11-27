# Subscriber Persona — Claudify Weekly

The single source of truth for who we write for. Every voice, glossary, budget, and quality decision references this document. When in doubt, this wins.

This file is read at the start of every drafting, auditing, and prompt-architecting cycle. If you're an agent and you haven't read this, you're not ready to write.

---

## The audience in one sentence

A developer who codes with AI assistance and wants their Tuesday morning to be 10 minutes better than last Tuesday's.

---

## The core writing principle (read this first)

**Technical depth and language complexity are independent dimensions. The newsletter is allowed to be deeply technical. The newsletter is NOT allowed to be linguistically complex.**

The technique can be advanced. The exposition must always be plain.

This means:
- A power-user technique using Claude Code's hook system, MCP servers, custom subagents, or shell pipelines is allowed and welcomed.
- The way that technique is described must be clear enough that anyone reading along can follow what's happening, even if they wouldn't apply it themselves.

### Three ways to handle technical references

Whenever a sentence reaches for a technical term, framework, tool, or concept that's not universally known, we have three valid options. Pick the one that preserves the most meaning.

**Option 1 — Replace with a universal example.**
Use this when the specific tool isn't the point; any concrete example serves. The technique is what matters.

> *Bad:* "I caught Claude rediscovering that this codebase uses Bun, not npm."
> *Good:* "I caught Claude rediscovering that this codebase uses tabs, not spaces."

The story is identical. Tabs/spaces is universally understood. Bun/npm requires JavaScript-ecosystem knowledge that 60%+ of subscribers don't have.

**Option 2 — Plain rephrasing of the technique.**
Use this when the underlying idea matters more than the specific tool name. Drop the jargon, describe what it does.

> *Bad:* "Pipe `--output-format stream-json` into `jq` to extract tool_use blocks."
> *Good:* "Claude Code has a flag that prints its output as structured data instead of plain text. That means you can pipe it into other scripts and grab specific pieces, like the tool calls Claude made, and feed them somewhere else."

Same technical content. No assumed prior knowledge. The reader who knows what `jq` is still gets the value. The reader who doesn't gets context first.

**Option 3 — Inline gloss (preferred when authenticity matters).**
Use this when the SPECIFIC term is part of the writer's real experience and a generic substitute would feel sanitised. Keep the term, add a parenthetical that explains it in 6-12 words.

> *Bad:* "I caught Claude rediscovering that this codebase uses Bun, not npm."
> *Good:* "I caught Claude rediscovering that this codebase uses Bun (a faster alternative to Node.js for JavaScript), not the standard tooling."

Or, more compact:

> "...we use Bun (a JavaScript runtime that's faster than Node)..."

This preserves the writer's authentic voice — these were the real tools in the real moment — while making the sentence land for readers who don't recognise the term. The gloss must be:
- 12 words or fewer
- In parentheses, not a full sentence aside
- Functional, not editorial ("a faster JavaScript runtime" not "a fascinating new tool that everyone is talking about")

### When to pick which option

| Situation | Pick |
|---|---|
| The tool/term is incidental — any example serves | Option 1: replace with universal |
| The technique is the point, the tool name doesn't add | Option 2: rephrase plainly |
| The specific tool is part of the authentic story or has cultural weight | Option 3: inline gloss |
| The tool name appears repeatedly across the issue | Option 3 the first time, then use the term freely (reader has been onboarded) |

### The test

For every sentence, ask: **Can a developer who's never written a Bash pipeline, never used `jq`, and only uses Claude Code as chat follow what's happening?**

If yes: ship.
If no: rewrite. Either explain the assumed concept in one half-sentence, or rephrase to avoid needing it.

This rule applies to every section — body, deep dive, pro tip, god-tier prompt, even the Worth Your Time links' descriptions. Plain language always. The depth lives in the IDEAS, not the vocabulary.

---

## Who they are

- **Working developers.** They ship code. They've used Claude Code, Cursor, Windsurf, ChatGPT, or some combination. They're not learning to program.
- **Stack-agnostic.** Could be writing Python, TypeScript, Go, Rust, Ruby, PHP, Swift, or some polyglot mix. The newsletter must land regardless of stack.
- **Time-constrained.** They have day jobs, side projects, families, or all three. Tuesday morning has 5-15 minutes for a newsletter, not 45.
- **Skeptical of generic content.** They've subscribed to too many newsletters that drift into platitudes. They unsubscribe fast when they smell filler.
- **Curious about technique, not theory.** They want "do this, get that result." They don't want "10 things every developer should know about AI."

---

## The range — floor and ceiling, both must be served

The newsletter has a wide audience range. Every issue must land for both ends. This is the hardest part of writing it.

### The floor reader (40-50% of subscribers)

- Knows: how to use Claude Code as an interactive chat. Has installed it. Has a paid plan.
- Doesn't know: hooks, slash commands, MCP servers, agentic patterns, advanced flags.
- May not know: Bun, pnpm, ruff, specific JS frameworks, recent Anthropic announcements.
- Their question every issue: "Will I learn one concrete technique I can apply this afternoon?"
- Their frustration: dev-internet jargon thrown at them as if it's universal vocabulary.

**Implications for writing:**
- Never assume specific stack knowledge. Examples must use universal preferences (tabs vs spaces, naming conventions, file structure) rather than stack-specific tools (Bun vs npm).
- Never use jargon labels (TL;DR, IIRC, FWIW). Plain English.
- When a technique requires specific tooling (e.g., a JSON config block), explain what it is in one sentence before showing the block.
- The first sentence of every issue must be understandable by the floor reader.

### The ceiling reader (15-20% of subscribers)

- Knows: most of what the floor reader doesn't. Power user. Has shipped workflows with Claude Code. Has written their own hooks and slash commands.
- Their question every issue: "Will this issue have one technique I haven't seen before?"
- Their frustration: surface-level tips they've already mastered. Newsletters that explain things they already know.

**Implications for writing:**
- Every issue must contain at least one element pitched at the ceiling reader. The Pro Tip section is usually where this lives. Sometimes the God-tier Prompt.
- If the entire issue is floor-level, ceiling readers churn within 4-6 issues.
- The "I'd never have asked this in this way" moment is the ceiling reader's reason to stay subscribed.

### The middle (30-40% of subscribers)

- Knows: enough to be productive. Comfortable with hooks if they had to write one but haven't done much. Knows their main stack well, vague awareness of others.
- Their question: "Is this issue applicable to my workflow this week?"
- Their frustration: issues that are all theory, no concrete output.

**Implications for writing:**
- Every issue must include a working code block, paste-ready prompt, or specific command. The Copy This Prompt section serves this directly.
- "I tried this and it worked" should be possible within 15 minutes of reading.

---

## What they're paying attention to (and what they're not)

### Pay attention to
- Specific commands, flags, config blocks they can copy
- Before/after measurable claims ("saves 30 minutes per session")
- Personal moments from the writer ("Last Tuesday I caught Claude...")
- Insider techniques that aren't on the docs site
- Tools or workflows that compound (each issue makes the next session better)

### Tune out
- Generic advice ("use AI to be more productive")
- Vague aspirational claims ("AI will change how we code")
- Long preamble before the technique
- Marketing pitches dressed as content
- Anything that requires watching a video, joining a Discord, or signing up for something else

---

## What they buy and why

These subscribers may eventually become customers. The newsletter's job is to demonstrate competence over weeks until they decide to upgrade. Possible products:

- **Skills Pack ($19)** — entry tier; works in any tool
- **Claudify ($49)** — full operating system for Claude Code
- **Claudify + SEO ($69)** — Claudify plus the SEO specialist layer

The newsletter should never directly pitch these in body content. The CTA section pitches. Body content is pure value.

The implicit pitch is: "if these weekly tips are useful, the full system is the same quality, just bigger." If the newsletter quality drops, the implicit pitch breaks.

---

## What they're NOT

This audience is NOT:

- **Beginner programmers.** We don't explain what a function is, what a JSON file is, what a terminal is.
- **Non-technical readers.** No simplification of code for non-coders. The audience can read a settings.json block.
- **Researchers/academics.** No citations, no academic framing.
- **Casual AI users.** ChatGPT-only users without dev work aren't the target. They're welcome but not optimised for.
- **Enterprise procurement.** No B2B framing, no "schedule a demo" pitches.

---

## How to test if a sentence works for this persona

Before any sentence ships, ask:

1. **Floor test:** Would a developer who only uses Claude Code for chat and doesn't know Bun understand this?
2. **Ceiling test:** Does this sentence contain a hint of insider knowledge or specific technique?
3. **Time test:** Could this sentence be cut without losing meaning?

If a sentence fails the floor test: simplify or explain.
If a sentence is purely floor-friendly with zero ceiling-reader signal: this issue needs a different sentence somewhere that has insider depth.
If a sentence fails the time test: cut it.

---

## How this persona evolves

This document updates when:

- Analyst agent identifies a pattern in subscriber behavior (e.g., "open rate drops 12% on issues with stack-specific examples")
- A subscriber replies with feedback that reveals a misunderstanding of the floor/ceiling
- A new failure mode appears in the MISTAKES-LOG that traces back to a persona misalignment

Updates require explicit changelog entry at the bottom of this file. Don't silently shift assumptions.

---

## Changelog

- **2026-04-27** — Initial document. Persona derived from: 50 subscribers (early), the "I don't know what Bun is" feedback (signals broad floor), the existing newsletter philosophy (specific techniques, not generic advice), and the Claudify product line target audience (Claude Code users, $19-$69 price range).
