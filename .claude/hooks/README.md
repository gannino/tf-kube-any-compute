# Hooks, Content Specialist layer

22 hook scripts. 21 are wired in `.claude/settings.json`; `validate-handoff.sh` is invoked by the `/safe-clear` procedure rather than a lifecycle event. This README is the inventory plus the July 2026 matcher audit.

## Inventory (file, event, blocking vs async, what it rejects or does)

| # | File | Event (matcher) | Mode | What it does |
|---|------|-----------------|------|--------------|
| 1 | `guard-bash.sh` | PreToolUse (Bash) | sync, can block | Rejects dangerous shell commands before they run |
| 2 | `safe-run.sh` | PreToolUse (Bash) | sync | Snapshots state before reversible-risk commands |
| 3 | `backup-before-write.sh` | PreToolUse (Write\|Edit\|NotebookEdit) | async | Copies the target file to backup before any write |
| 4 | `completeness-gate.sh` | PreToolUse (Write\|Edit\|NotebookEdit) | sync, blocks | Rejects incomplete writes to critical files: knowledge-base.md needs `[Source:]` per entry, max 200 lines, no TBD/TODO; memory.md max 100 lines; agent defs no TBD/TODO; settings.json must parse |
| 5 | `newsletter-em-dash-check.sh` | PreToolUse (Write\|Edit\|NotebookEdit) | sync, blocks | Newsletter voice gate: rejects em dashes in newsletter content files |
| 6 | `newsletter-jargon-check.sh` | PreToolUse (Write\|Edit\|NotebookEdit) | sync, blocks | Newsletter voice gate: rejects unglossed jargon per GLOSSARY.md buckets |
| 7 | `newsletter-schema-check.sh` | PreToolUse (Write\|Edit\|NotebookEdit) | sync, blocks | Rejects issue files that break ISSUE-SCHEMA.md required fields |
| 8 | `newsletter-contrast-check.sh` | PreToolUse (Write\|Edit\|NotebookEdit) | sync, blocks | Rendering gate: rejects low-contrast text/background combinations (regression anchor MISTAKE-005) |
| 9 | `newsletter-paragraph-collapse-check.sh` | PreToolUse (Write\|Edit\|NotebookEdit) | sync, blocks | Rendering gate: rejects HTML that collapses paragraph spacing in email clients (regression anchor MISTAKE-018) |
| 10 | `log-changes.sh` | PostToolUse (Write\|Edit\|NotebookEdit) | async | Appends every file change to the audit trail |
| 11 | `track-session-quality.sh` | PostToolUse (*) | async | Increments tool count, detects re-reads, weights heavy ops; feeds the context tier |
| 12 | `log-failures.sh` | PostToolUseFailure (*) | async | Logs failed tool calls to the incident log |
| 13 | `auto-load-topics.sh` | UserPromptSubmit | sync, advisory | Matches the prompt against `topic-routing.yml` keywords and surfaces relevant files to read |
| 14 | `pre-compact-handoff.sh` | PreCompact (auto AND manual) | sync | Writes the auto-handoff (memory Now + files touched + latest Session Handoff) so a compaction resumes sharp |
| 15 | `session-reset.sh` | SessionStart (user) | sync | Resets stale gate files on fresh sessions; validates topic-routing.yml paths (advisory, never blocks) |
| 16 | `post-compact-resume.sh` | SessionStart (compact) | sync | Surfaces the auto-handoff and instructs the resumed session to continue the Next action without asking |
| 17 | `inject-related-context.sh` | SessionStart (compact) | sync | Finds related Session Handoffs from the last 7 days by topic-routing keyword match and adds them to the resume context |
| 18 | `log-stop-verdict.sh` | Stop | async | Tags every turn with session ID, task type, and verdict for quality trending |
| 19 | `check-quality-gate.sh` | Stop | sync, can block | Computes the context tier; blocks only at Critical as a backstop before auto-compact |
| 20 | `claim-check.sh` | Stop AND SubagentStop | async | Cross-checks output claims against evidence in the transcript |
| 21 | `subagent-verdict.sh` | SubagentStop | async | Logs subagent verdicts to the audit trail |
| 22 | `validate-handoff.sh` | invoked by `/safe-clear` Step 6 (not wired to a lifecycle event) | sync | Verifies a Session Handoff has all required fields, its file paths exist, and Next: is specific |

## Lifecycle order

UserPromptSubmit (13) runs first each turn. PreToolUse (1-9) gate each tool call; PostToolUse (10-12) log after. Stop (18-20) runs when the turn ends; SubagentStop (20-21) when a subagent ends. PreCompact (14) fires on both auto and manual compaction; SessionStart (15-17) fires on fresh sessions and post-compaction resumes.

## Matcher audit (July 2026 Claude Code semantics, audited 24 Jul 2026)

The June-July 2026 Claude Code releases changed matcher semantics: hyphenated matchers became exact-match (2.1.195), comma-separated matcher lists began firing per element (2.1.191), and exit-2 with JSON output became the canonical blocking form. Audit result for this layer's `settings.json`:

- `Bash`, `Write|Edit|NotebookEdit`, `*`: plain tool names and pipe-alternation, unaffected by the hyphen exact-match change. Pinned as-is.
- `auto`, `manual` (PreCompact), `user`, `compact` (SessionStart): single lowercase words, no hyphens or commas. Pinned as-is.
- No matcher in this layer uses a comma list or a hyphenated name, so no rewrites were required. If you add one, re-read this section first.
- Blocking hooks (4-9, 19) exit non-zero with a reason on rejection; async loggers never block.

## Subagent backgrounding note (Claude Code 2.1.198, Jul 2026)

Subagents launched via the Task tool default to running in the background. Sequential pipelines that need a phase's result before the next phase starts must pass `run_in_background: false` per invocation. The newsletter pipeline (9 sequential phases) is pinned synchronous in `newsletter-orchestrator.md` and `.claude/commands/newsletter.md`.
