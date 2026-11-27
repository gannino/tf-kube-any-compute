# Claude Code Weekly — Issue Backlog

Pre-planned pipeline. Issues are drafted from this list in order.
Update `status` when an issue moves to drafted or sent.

---

## Rotation reference

Config → Command → Workflow → Agent → Debug → Command → Config → Workflow → …

Issue 001 was **Config**. Rotation continues from there.

---

## Issue 002 — Command

**Title:** `--output-format stream-json` pipes Claude output into shell pipelines

**Core technique:** Pass `--output-format stream-json` to get structured JSON event stream from Claude's stdout — each token, tool call, and result arrives as a parseable line. Lets you `grep`, `jq`, pipe to files, or build custom UIs without screen-scraping.

**Why it's valuable:** Most developers treat Claude Code as interactive-only. This flag unlocks Claude as a programmable component in shell pipelines — e.g., feeding Claude output directly into a logger, a CI step, or a downstream process without polling or manual copy-paste.

**Research needed:**
- Confirm exact flag name and output schema (event types: `content_block_delta`, `message_stop`, etc.)
- Find real shell pipeline examples from Anthropic docs or GitHub issues
- Check if flag works with `--print` / non-interactive mode

**Status:** planned

---

## Issue 003 — Workflow

**Title:** Run Claude Code as a CI step — headless, non-interactive, exit-code aware

**Core technique:** Use `claude --print --no-interactive "task description"` inside a GitHub Actions or shell script. Claude runs, completes the task, writes output, exits with a meaningful code. Pair with `--output-format json` to parse results downstream.

**Why it's valuable:** Most teams don't know Claude Code can run non-interactively. Once you know, you can trigger it from CI to do code review, generate changelogs, run security scans, or update docs — without a human in the loop.

**Research needed:**
- Exact flags for fully headless execution (no TTY prompts)
- How exit codes map to success/failure/error states
- GitHub Actions YAML example that calls claude and gates on result
- Any caveats with `--dangerously-skip-permissions` in CI

**Status:** planned

---

## Issue 004 — Agent

**Title:** Give Claude a specialist subagent with its own memory file and scope

**Core technique:** Create `.claude/agents/my-agent.md` with a targeted system prompt, a dedicated memory file path, and explicit tool allowlist. Claude Code will use this agent for matching tasks automatically. The agent accumulates its own learnings separately from the main session.

**Why it's valuable:** Without scoped agents, every Claude Code session shares one context and one instruction set. Specialist agents let you have a "database migration expert" or "copy reviewer" that knows its domain deeply without polluting the main session or bleeding context between unrelated tasks.

**Research needed:**
- Exact agent definition format (fields Claude Code reads from .claude/agents/*.md)
- How Claude Code decides which agent to invoke vs main session
- Whether agents can have their own settings.json overrides
- Real-world example of a useful specialist agent setup

**Status:** planned

---

## Issue 005 — Debug

**Title:** Fix context drift with `/compact` — when to use it vs `/clear`

**Core technique:** Use `/compact [instructions]` to compress the conversation history into a summary before Claude starts losing track of earlier decisions. The optional argument scopes what to preserve ("keep the API design decisions"). `/clear` wipes everything; `/compact` is the surgical tool.

**Why it's valuable:** The most common Claude Code failure mode — giving inconsistent answers, re-asking things it already decided, reverting earlier changes — is almost always context drift, not a model problem. Developers reach for `/clear` and lose their thread. `/compact` solves it without starting over.

**Research needed:**
- Confirm `/compact` accepts an argument in current Claude Code version
- What exactly gets preserved in the summary (tool calls? decisions? file contents?)
- When compression happens automatically vs manually triggered
- Any difference between `/compact` and the auto-compaction threshold

**Status:** planned

---

## Issue 006 — Command

**Title:** `--resume` picks up any previous session by ID — no context loss between restarts

**Core technique:** Every Claude Code session gets a unique ID printed at start. Pass `--resume <session-id>` to restore the full conversation state including tool calls and decisions. Combine with a session log to make any past conversation retrievable.

**Why it's valuable:** Developers habitually lose work when they close a terminal and reopen Claude. The `--resume` flag means a session is never permanently gone — you can come back hours later, restore context, and continue exactly where you left off. This changes how you structure long-running tasks.

**Research needed:**
- Where Claude Code stores session data (local file path)
- Whether `--resume` restores tool call results or just messages
- How long sessions persist before being pruned
- Any flag to list recent session IDs

**Status:** planned

---

## Issue 007 — Config

**Title:** The `allowedTools` allowlist in settings.json — lock what Claude can touch per project

**Core technique:** Add `"allowedTools": ["Read", "Write", "Bash"]` to `.claude/settings.json` to restrict which tools Claude can invoke in that project. Useful for read-only review sessions, preventing accidental file writes, or scoping a project to specific operations.

**Why it's valuable:** The default tool set is broad. In sensitive codebases, audit tasks, or client work where you want Claude to read but never write, the allowlist is the correct control — not hoping Claude doesn't reach for the wrong tool. Most developers don't know this exists.

**Research needed:**
- Exact tool names to use in the allowlist (match internal names: Read, Write, Edit, Bash, etc.)
- Whether `deniedTools` is also supported (blocklist approach)
- Whether the allowlist applies to subagents or just the main session
- How the setting interacts with `--dangerously-skip-permissions`

**Status:** planned

---

## Issue 008 — Workflow

**Title:** Chain Claude Code tasks with `&&` — sequential multi-step jobs from one command

**Core technique:** Run multiple `claude --print` calls chained with `&&` in a shell script. Each call does one focused task and hands off via file output or stdout. Lets you build reliable multi-step pipelines (e.g., analyse → plan → implement → test) where each step is independently inspectable and re-runnable.

**Why it's valuable:** Long single-prompt tasks are brittle — if Claude goes off-track at step 3, you restart from scratch. Chained short tasks let you checkpoint, inspect each output, and resume from any point. It's the difference between a monolith and a pipeline.

**Research needed:**
- How to pass output from one `claude --print` call into the next (stdin piping vs temp files)
- Whether `--print` mode supports reading from stdin
- Examples of shell scripts that chain Claude Code calls effectively
- Any built-in sequencing support (e.g., task queues, plans)

**Status:** planned

---

## Notes

- Topics must be about Claude Code (the free CLI tool) — not Claudify features
- Every topic needs a concrete command, config block, or shell example — no vague tips
- Check `issues/` directory for already-drafted issues before picking from this list
- Mark `status: drafted` once an issue file exists, `status: sent` once live
