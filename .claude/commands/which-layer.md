---
description: Recommend the right Claude Code layer for a goal (CLAUDE.md, skill, subagent, hook, command, or MCP) and scaffold it
argument-hint: "[what you want Claude to do]"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - Edit
---

Claude Code gives you six ways to shape behaviour: CLAUDE.md/memory, skills, subagents, hooks, slash commands, and MCP servers. Picking the wrong one is the most common cause of a setup that bloats context, ignores your rules, or blows up on multi-agent work. Describe what you want Claude to do and this command maps it to the right layer or layers, explains the trade-offs, warns you off the usual traps, and offers to scaffold the artifact in the correct location.

The task to route is in the argument: `$ARGUMENTS`. If it is empty, ask one question: "In one or two sentences, what do you want Claude to do differently?" Then continue.

## Steps

### Step 1: Read the task and the existing setup

Restate the described task in one sentence so the routing is grounded in intent, not keywords. Then survey what already exists so the recommendation fits the current project rather than duplicating it:

- Glob `.claude/skills/*/SKILL.md`, `.claude/agents/*.md`, `.claude/commands/*.md`, and `.claude/hooks/*` to see what is already installed.
- Read `CLAUDE.md` (and `.claude/memory.md` if present) to see what persistent context already exists.
- If an `.mcp.json` exists, read it to see which external integrations are already wired.

Note any existing artifact that overlaps the task. Extending or fixing an existing one is almost always better than adding a new one.

### Step 2: Classify the task against the decision framework

Run the task through the framework below in order. The first clear match is usually right, but a task can legitimately need two layers (for example: a fact in CLAUDE.md plus a hook that enforces it). Decide the primary layer, then note any secondary layer.

### Step 3: Name the recommendation and the trade-offs

State the recommendation as "You want X, so use Y, because Z." Then give the honest cost of that choice using the trade-off notes in the framework. Be specific about context budget: every line in CLAUDE.md and every always-on skill is paid for on every turn, whereas a description-matched skill or a subagent costs nothing until it is actually used.

If two layers are viable, present both with the deciding question between them (usually: "is this needed every session, or only when the task matches?" and "does this pollute the main context?").

### Step 4: Offer to scaffold

Ask: "Shall I scaffold this as a [layer] for you?" On yes, write a complete, working stub to the correct location using the scaffolds below. Fill in what you can infer from the task; leave clearly-marked prompts only where a human decision is genuinely required. Never write a stub with placeholder logic that silently does nothing.

- **Skill** to `.claude/skills/{name}/SKILL.md` with YAML frontmatter (`name`, `description`) and the procedure body. The `description` must be specific and trigger-rich, it is the only thing that decides when the skill loads.
- **Subagent** to `.claude/agents/{name}.md` with frontmatter (`name`, `description`, `tools`) and a body covering intent, mandatory reads, procedure, and the output contract it returns to the caller.
- **Hook** as a script under `.claude/hooks/` plus the wiring block for `.claude/settings.json` (matched to the correct event). Make the script exit 0 on success and print a clear message on block.
- **Slash command** to `.claude/commands/{name}.md` in this same format (frontmatter + intro + `## Steps`).
- **MCP server** as the `.mcp.json` entry plus a one-line note on which credential it needs. Do not invent tokens.
- **CLAUDE.md / memory** as a concise addition to the relevant section, not a new file.

### Step 5: Warn against the anti-patterns

Before finishing, check the recommendation against the anti-patterns list at the bottom and flag any that apply. Output a short closing summary: the layer chosen, why, where the artifact was written (if scaffolded), and the single most important trade-off to remember.

## The layer decision framework

Read every task against these six layers. The logic is "if you want X, use Y, because Z."

### CLAUDE.md / memory

Persistent project context loaded into every session automatically: facts, conventions, architecture, the things Claude should always know without being told.

- **Use it when:** the knowledge is small, stable, and needed on most turns. "Always use British English." "The API lives in `src/server`." "We never add a money-back guarantee." "Prod deploys go through `/deploy`, never bare `git push`."
- **Trade-off:** it is always on, so it is the most reliable layer and the most expensive one. Every line costs context budget on every single turn. This is the layer people abuse most: it works, so they keep adding to it, and the file grows until it crowds out the actual work. Keep it lean. If a fact is only relevant to one kind of task, it belongs in a skill, not here.

### Skill

On-demand domain knowledge or a procedure, matched by its description and loaded only when the current task is relevant.

- **Use it when:** you have a body of expertise, a checklist, or a procedure that Claude should pull in only when the work calls for it. "Our deployment runbook." "How we write ad copy." "The schema and query patterns for our database." Anything you would otherwise be tempted to paste into CLAUDE.md but that only applies to a subset of tasks.
- **Trade-off:** it keeps the main context lean because it loads only when matched, but that matching depends entirely on the description. A vague description means the skill never fires when you need it, or fires when you do not. Write the description around the words and situations that should trigger it. A skill that is genuinely needed every session is really a CLAUDE.md fact wearing a skill costume, put it in CLAUDE.md instead.

### Subagent

A separate, isolated context that does one scoped job and returns a result to the main session.

- **Use it when:** the work is delegatable and well scoped, when it is heavy enough to pollute your main context (a large research sweep, reading across many files, a long log), when you want a fresh pair of eyes that has not seen the main thread (a reviewer or auditor), or when you want to fan out N independent jobs in parallel. "Search the whole codebase for every caller of this function." "Review this diff cold." "Research these five competitors at once."
- **Trade-off:** this is the layer that protects your main context, the subagent reads the noise and returns only the conclusion. That isolation is also its limit: a subagent starts fresh with none of your conversation, so it needs a self-contained brief, and it cannot ask you a follow-up mid-task. Use it for work you can hand off with a clear instruction and a clear expected output. This is the direct fix for multi-agent setups blowing up context: move the heavy and the parallel work into subagents instead of doing it inline.

### Hook

A deterministic script that fires on a lifecycle event: PreToolUse, PostToolUse, Stop, SessionStart, or PreCompact.

- **Use it when:** you want something to happen every time X happens, with no model judgement involved. Guardrails ("block any write to this protected file"), logging ("record every bash command"), gates ("reject a commit message that lacks a ticket ref"), formatting ("run the formatter after every edit"), context safety ("save a handoff before compaction"). If the rule is "always, deterministically, on this event," it is a hook.
- **Trade-off:** hooks are reliable precisely because they are code, not judgement, they run the same way every time and cannot be reasoned around. That is also their ceiling: they cannot make a nuanced call. Use a hook to enforce a bright-line rule; use a skill or CLAUDE.md when the right action depends on context. A rule you want followed but that needs judgement is a CLAUDE.md convention, not a hook.

### Slash command

A saved prompt or procedure that a human invokes on demand.

- **Use it when:** there is a repeatable ritual or workflow that a person triggers deliberately. "Start my day." "Run the release checklist." "Set up a new client." "Audit recent work." If you find yourself typing the same multi-step instruction repeatedly, it is a command.
- **Trade-off:** it is explicit and predictable because a human chooses to run it, which also means it only runs when someone remembers to run it. Use a command for human-initiated rituals; use a hook when the same procedure should fire automatically on an event without anyone invoking it. Command for "when I ask," hook for "every time X."

### MCP server

An external tool or data integration that connects Claude to a system, API, or dataset.

- **Use it when:** the task needs Claude to reach outside the local project: query a live database, read or write a SaaS API, pull from an external dataset, drive a browser. "Read our production analytics." "Create records in our CRM." "Search the web for current docs."
- **Trade-off:** it unlocks real external capability, but every enabled server adds its tool definitions to the context on every turn, so a pile of rarely-used servers is a standing tax. Enable what you use, disable what you do not. If the need is knowledge rather than a live system, a skill is cheaper than a server.

## Common anti-patterns to warn against

- **Stuffing everything into CLAUDE.md.** It works, so it grows without limit, and eventually the always-on context crowds out the task. Move task-specific knowledge into skills; keep CLAUDE.md to the small stable core needed on most turns.
- **Too many always-on skills, or skills with vague descriptions.** A skill earns its place by loading only when matched. A dozen loosely-described skills either never fire or fire at the wrong time. Fewer skills, sharper descriptions.
- **Not using subagents for heavy or parallel work.** Doing a large research sweep, a many-file read, or N independent jobs inline is what makes multi-agent context blow up. Delegate the heavy and the parallel work to subagents that return only the conclusion.
- **Using a hook where judgement is needed, or a convention where a hard rule is needed.** Deterministic enforcement belongs in a hook; a nuanced "usually do this" belongs in CLAUDE.md or a skill. Do not force a judgement call into a script, and do not leave a bright-line rule to be remembered.
- **Reaching for an MCP server when a skill would do.** If the need is knowledge Claude can carry, a skill is cheaper than a standing external server on every turn. Reserve MCP for genuine live-system access.
