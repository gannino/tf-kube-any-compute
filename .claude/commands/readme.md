# /readme [project]

High-conversion README + docs production. For OSS projects, indie SaaS, or any product with a GitHub repo.

## When to use

- New project launching with a GitHub repo
- Existing README is broken / generic / dev-marketing-team voice
- You want a README that converts repo visitors to users (or stars / contributors)

## Procedure

### Step 1 — Load project context

If user provides project name: read the project's repo (use Glob + Read on a local checkout if available).

If no local checkout: ask user for:
- Project one-liner (what it is, in one sentence)
- Hero feature (the single most important thing it does)
- Install command (npm i, pip install, brew install, etc.)
- Quickstart (3-5 lines that get the user from zero to working)
- Target audience (who is this for)

### Step 2 — Draft

Invoke `content-creator` agent with mode: README + docs.

Apply README format rules from `.claude/knowledge-base.md` Platform-Specific section:

```
# {Product Name}

> {One-line value prop — concrete, specific, no marketing voice}

[badges row — version / build / license / downloads]

## What it is

{2-3 sentences. Specific. Names the problem, names the solution.}

## Quick start

```{language}
{install command}
{usage in 3-5 lines max}
```

That's it. {What the user just got — the payoff in one sentence.}

## How it works

{One paragraph. Brief technical explanation. NOT marketing copy.}

## Examples

{2-3 concrete usage examples covering the most common cases.}

## Configuration

{If applicable — flags, env vars, config file structure. Otherwise skip.}

## API reference

{Link to full docs if separate. Otherwise inline the most-used methods.}

## Roadmap / Status

{Current stability — alpha / beta / stable. What's coming next.}

## Contributing

{One paragraph + link to CONTRIBUTING.md. Specific about what kinds of PRs are wanted.}

## License

{License + link to LICENSE file.}
```

### Step 3 — Critical placement check

Per `knowledge-base.md` README rules:
- **H1 = product name** (NOT a tagline like "The Ultimate X tool")
- **Sentence-case throughout** (not title-case in headings)
- **Usage block within first 100 lines** — GitHub renders first 100 lines on the repo homepage, so install + usage MUST be above the fold

The auditor checks this placement explicitly. If install/usage is below line 100: FAIL.

### Step 4 — Audit

Invoke auditor. README-specific checks:
- H1 is product name (not marketing tagline)
- One-line value prop is specific (no "revolutionary AI tool")
- Usage block within first 100 lines
- All code blocks runnable as-is (no `<placeholder>` strings)
- License + repo link present

### Step 5 — Output

Print:
- Final README.md ready to commit
- Audit verdict
- Suggested CONTRIBUTING.md outline (separate file)
- Suggested badges + their URLs

## Hard rules

- **H1 = product name, not a tagline.** "Claudify" not "The Ultimate Claude Code Operating System".
- **Sentence-case in headings.** "Quick start" not "Quick Start".
- **Install + usage above line 100.** Drive-by GitHub visitors leave if they don't see how to use it on the visible homepage.
- **No marketing voice in the value prop.** "Ranks better in search" beats "Supercharge your SEO". (The HN audience overlaps heavily with OSS / dev audience — same rejection patterns.)
- **All code blocks runnable as-is.** No `<your-key-here>` — comment it inside the code block instead: `# ANTHROPIC_API_KEY=your-key-here`

## Hand-off

User commits the README to their repo. Next response triggers `/feedback` — log any user edits / feedback to brand memory.
