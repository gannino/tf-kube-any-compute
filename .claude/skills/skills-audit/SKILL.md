---
description: >
  Score every installed skill against the Claudify quality rubric and produce a
  prune / deepen report. Use when the user says "audit my skills", "score my
  skills", "which skills are worth keeping", "prune skills", or "skills report".
  Not for creating new skills (use skill-creator) or editing a single skill.
user-invocable: true
version: 1.0.0
effort: low
allowed-tools: Read, Glob, Bash(node ${CLAUDE_SKILL_DIR}/scripts/audit.mjs *)
arguments:
  - name: scope
    description: optional category or path filter, default = all installed skills
---

# Skills Audit

Latest score summary (refreshed at invocation):

!`node ${CLAUDE_SKILL_DIR}/scripts/audit.mjs --summary`

## What this does

Runs the deterministic scorer over every `SKILL.md` under `.claude/skills/` and
writes two reports to `.claude/logs/`:

- `skills-audit-{YYYY-MM-DD}.md`, the human report: tier distribution, a
  per-category table, top movers vs the last run, and recommendations.
- `skills-audit-{YYYY-MM-DD}.json`, the machine report: per-skill score,
  per-dimension breakdown, tier, and recommendations.

Scoring is 100 percent deterministic, computed from file bytes with no LLM call:
the same library always gets the same score. The rubric (100 points): frontmatter
validity 15, description quality 25 (word count, quoted trigger phrases, boundary
clause), body substance 35 (non-boilerplate word count, boilerplate shingle
fingerprint, a concrete worked example), artifact shape 15 (output block present,
low placeholder density), evals 10 (eval files exist and static checks pass).

## Tiers

| Tier | Meaning |
|---|---|
| DEEP | score >= 85 with at least one eval; the deliverable is the output |
| STANDARD | 60 to 84; solid, reachable, could go deeper |
| SHALLOW | 40 to 59; enters the deepen queue |
| BROKEN | under 40, invalid YAML, or an unreachable description |

## Procedure

1. Run the scorer:
   `node ${CLAUDE_SKILL_DIR}/scripts/audit.mjs [--scope <filter>] [--json]`
2. Read the generated report from `.claude/logs/` and narrate the headline:
   tier counts, the biggest movers, and the top 5 of the deepen queue.
3. Route the recommendations:
   - PRUNE: BROKEN skills plus near-duplicate merge candidates. Confirm with
     the user before deleting anything.
   - DEEPEN: SHALLOW skills ranked by category demand weight times score gap.
   - FIX-FRONTMATTER: good body, weak metadata; regeneration candidates.
4. Never edit skill bodies from this skill. It measures and recommends only.

## Eval modes

- `--evals static` (default): free, deterministic, runs anywhere. Checks that
  each skill with an `evals/` folder contains a passing artifact shape (its own
  worked example clears the eval's structural checks).
- `--evals live`: repo CI only. Refused unless `CLAUDIFY_LIVE_EVALS=1` is set;
  prints a cost note first, then pipes each eval input through `claude -p` and
  stores the transcript as a golden file. Costs tokens; never runs on customer
  machines by default and never runs unannounced.

## Output format

The invocation summary you report back looks like:

```
skills-audit: 1734 skills | DEEP 33 | STANDARD 4 | SHALLOW 1695 | BROKEN 2
Reports: .claude/logs/skills-audit-2026-07-27.md
Deepen queue top 5: marketing/launch-email, sales/pipeline-review, ...
```
