# Glossary — terms to gloss, terms to assume, terms banned

A living list of every technical term, framework, tool, or piece of jargon that's appeared (or could appear) in a Claudify Weekly issue, with the decision about how to handle each.

This file is read by the drafter (decides whether to gloss) and the auditor (catches ungloosed terms before ship). Updated every issue when a new term comes up.

---

## How decisions are made

Every term falls into one of four buckets. The decision tree below is mechanical — no vibe calls.

### Bucket 1: Universal — assume known, never gloss

Terms that 99%+ of any audience-floor reader knows. Using them adds zero comprehension friction.

- File path syntax (`src/`, `.json`, `.md`)
- Common Unix commands (`cd`, `ls`, `mv`, `rm`)
- HTTP basics (`GET`, `POST`, status codes)
- Database basics (`SQL`, `query`, `row`, `column`)
- Basic web tech (`HTML`, `CSS`, `JavaScript`)
- General coding concepts (`function`, `variable`, `class`, `loop`, `array`)
- Common general tools (`git`, `npm`, `Node`, `Python`)
- Claude Code itself, including `/start`, `/compact`, `/clear`
- Anthropic, Claude, Sonnet, Haiku, Opus

### Bucket 2: Inline gloss on first use, then free

Terms that some of the audience floor doesn't know but are central enough to the technique that we can't avoid them. Gloss in parentheses on first use within an issue, then use freely.

Format: `term (a brief description, max 12 words)`

| Term | Gloss |
|---|---|
| Bun | a faster JavaScript runtime alternative to Node |
| pnpm | a faster, disk-efficient alternative to npm |
| ruff | a fast Python linter and formatter |
| Biome | a fast JavaScript/TypeScript formatter and linter |
| MCP server | a small program that gives Claude extra tools |
| Stop hook | a command Claude Code runs when a session ends |
| SessionStart hook | a command Claude Code runs at the start of every session |
| stream-json | Claude Code's machine-readable output format |
| frontmatter | the metadata block at the top of a markdown file |
| YAML frontmatter | metadata in YAML format at the top of a file |
| `jq` | a command-line tool for filtering JSON output |
| `ripgrep` (or `rg`) | a faster alternative to `grep` for searching code |
| Mermaid diagrams | text-based syntax for generating flowcharts |
| ADR (architecture decision record) | a short doc explaining why a technical choice was made |
| Turso | a hosted SQLite database service |
| Resend | an email-sending API, alternative to SendGrid |
| Beehiiv | a newsletter platform |
| GSC (Google Search Console) | Google's free SEO data dashboard |
| stdout | a program's text output stream that the terminal reads |
| flag (CLI) | a command-line option you append to a command, like `--resume` or `--verbose` |
| switch (CLI) | another word for a CLI flag |

### Bucket 3: Avoid entirely, replace with universal example

Terms that aren't worth glossing because there's a universal alternative that carries the same meaning.

| Avoid | Replace with |
|---|---|
| "uses Bun, not npm" (when the choice is incidental) | "uses tabs, not spaces" or "uses kebab-case, not camelCase" |
| "fixes a flaky CI step" (when CI is incidental) | "fixes a flaky test that breaks twice a week" |
| "imports from a workspace package" (when monorepo isn't the point) | "imports from a shared library file" |

The principle: if the term is incidental to the technique, swap for something universal. If the term IS the technique, gloss in Bucket 2.

### Bucket 4: Banned

Internet shorthand and acronyms that exclude the floor reader and aren't worth glossing.

| Banned | What to do |
|---|---|
| TL;DR | Use "The gist" |
| FWIW | Spell out: "for what it's worth" or cut |
| IIRC | Spell out: "if I recall correctly" or cut |
| IMO / IMHO | Cut (just state the opinion) |
| AFAIK | Cut |
| YMMV | "Your situation may differ" |
| LGTM | "Looks good" |
| ICYMI | "If you missed it" |
| WIP | Spell out: "still in progress" |
| TBD | "Still working out the details" |
| CRUD | Only use with inline gloss |
| ORM | Only use with inline gloss (a layer between code and database) |
| DRY / KISS / YAGNI | Use with inline gloss only if the principle is the topic |
| 1L (1-liner), 1HKO, etc. | Cut entirely |

---

## When in doubt, gloss

If the writer can't decide whether a term needs glossing, gloss it. The cost of glossing a term that some readers already know is 6-12 words. The cost of NOT glossing a term some readers don't know is they bounce or skim past the technique entirely.

The cost asymmetry is one-sided. Default to glossing.

---

## Updating this file

Every issue:
1. Drafter scans the issue for technical terms
2. Each term is checked against this glossary
3. If the term isn't in the glossary, drafter decides which bucket it belongs in and adds it
4. Auditor verifies the decision before ship

If a term is genuinely new (never been used in a newsletter issue before), the drafter is responsible for the bucket decision and the gloss text. The auditor reviews. The term is added to this file.

---

## Changelog

- **2026-04-27** — Initial document. Bucket 1 seeded from common dev knowledge. Bucket 2 seeded from terms that came up during Issue 001 development (Bun, Stop hook, stream-json, etc.). Bucket 3 seeded from "Bun, not npm" → "tabs, not spaces" swap during Issue 001 review. Bucket 4 seeded from internet shorthand caught during Issue 001 (TL;DR specifically) plus standard developer-internet acronyms.
