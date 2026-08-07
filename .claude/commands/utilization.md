---
description: Map what is installed against what has actually been used, then suggest the 3 highest-value unlocks for how this specific user works
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - Bash(ls:*)
  - Bash(find:*)
  - Bash(grep:*)
  - Bash(wc:*)
  - Bash(head:*)
  - Bash(date:*)
  - Bash(jq:*)
---

**Spawn synchronously:** every Agent/Task spawn in this procedure must pass `run_in_background: false`. Subagents default to background since Claude Code 2.1.198; this command consumes each subagent verdict before its next step, so a background spawn would race the verdict.

Most installs use a fraction of what they own. This command maps the installed
inventory (agents, commands, skills) against actual usage signals, shows what
has never been touched, and suggests the 3 highest-value unlocks for how this
specific user works.

Posture: read-only. You may optionally write ONE dated report to
`.claude/logs/utilization-{date}.md`; you never edit config, memory, or
templates. Honest measurement throughout: every number in the output states
its window and its source, and anything unreadable is reported as unreadable,
never estimated.

## Steps

### Step 1: Build the installed inventory

- **Agents:** every `.claude/agents/**/*.md`, name taken from the frontmatter
  `name:` field.
- **Commands:** every `.claude/commands/*.md`, PLUS every skill whose
  frontmatter has `user-invocable: true` (commands and skills are the same
  primitive on current Claude Code; count each invocable name once, so a name
  present in both forms is one entry).
- **Skills:** every `.claude/skills/**/SKILL.md`.
- **Layer attribution**, in this order: (a) if a machine-readable layer map
  from the generated-counts mechanism is present, prefer it; (b) otherwise the
  shipped `UPDATE-MANIFEST` file lists, which name each layer's files; (c)
  otherwise path convention (`skills/analyst/` = analyst, `skills/seo/` = seo,
  and so on); (d) when none of these decides it, label the item
  `unattributed` rather than misfiling it.

### Step 2: Gather usage signals (each optional; degrade gracefully in this order)

1. **Session transcripts:** `~/.claude/projects/{project-slug}/*.jsonl` when
   readable. Never load transcript content into context; use `grep -c` and
   `grep -l` patterns only:
   - slash invocations: lines containing `"/{command-name}` and
     `<command-name>` blocks
   - subagent launches: `"subagent_type":"{agent}"`
   - skill invocations: `"skill":"{name}"`
   Cap the scan at the most recent 50 files by mtime, and record the window
   (the oldest scanned session's date).
2. **The system's own logs** where the hook suite shipped: `.claude/logs/`
   (audit trail, change log, stop verdicts) grepped for command and agent
   names.
3. **Artifact signals**, proof of use even when history is unreadable:
   analyst run directories under `.claude/analyst/runs/`, ledger line counts
   in `.claude/analyst/ledger/*.jsonl`, `agent-memory/*/MEMORY.md`
   modification dates, dated report files.
4. **If none of the above is readable:** output the inventory map only, state
   plainly that usage could not be measured and which paths were unreadable,
   and pick the unlocks from inventory structure alone with that caveat
   printed above them.

### Step 3: Compute the map

Per layer and per primitive type: installed count, invoked count (invoked = at
least one signal in the window), last-seen date where known, and the
never-invoked list grouped by category (the category is the agent or
command's pipeline or folder grouping).

## Output format (exact)

```
# Utilization report, {YYYY-MM-DD}
Window: {oldest-scanned} to today. Sources read: {list}. Unreadable: {list or none}.

## Coverage map
| Layer   | Agents      | Commands    | Skills      |
|---------|-------------|-------------|-------------|
| base    | 7/12 used   | 11/31 used  | ...         |
| analyst | 4/20 used   | 3/18 used   | 2/15 used   |
(used = at least one recorded invocation or artifact in the window)

## What you use most
{top 5: name, count, last seen}

## Installed but never touched
{grouped by category; each entry: name + one line of what it does, pulled
from its own frontmatter description, never invented}

## Your 3 highest-value unlocks
1. {name}: you already {observed behavior with evidence}; this adds {what}.
   Try now: `{exact literal invocation}`
2. ...
3. ...
```

## Unlock selection heuristic (deterministic order)

1. **Close an open loop first.** If a production command is used but its
   matching learn/audit counterpart never is (`/research` without
   `/research-learn`, `/blog` without `/seo-learn`, content production without
   `/audit`), that pairing is unlock #1: the learning loops are the product's
   stated differentiator and an unclosed loop is the highest-value miss.
2. **Adjacency second.** The highest-leverage never-used capability in the
   same layer or category as the user's most-used capability; they already
   have the context, so activation cost is lowest.
3. **Bridge third.** For multi-layer installs, one cross-layer bridge, for
   example `/market-size` output feeding the content strategist, or the
   analyst dossier informing an SEO topic call.

Ties break by lower setup cost, then by evidence of the matching pain in the
logs. Always exactly 3, each with a literal paste-ready invocation. If usage
was unmeasurable, unlocks come from inventory structure with the caveat line
printed above them.

## Closing line

End with: for a pure inventory question ("what do I have installed and which
layer should a new behavior live in"), `/which-layer` remains the direct
answer; this command adds the used-vs-installed diff and the unlocks on top.
