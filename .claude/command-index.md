# Command Index, Content Specialist

All available commands, their trigger conditions, required tools, and invocation mode.

Every agent reads this file to understand the full command catalog.

**Invocation modes:**
- **Self-execute**: Agent has the required tools and reads the command file directly
- **Recommend**: Agent lacks the required tools, or the command spawns other agents. Output `RECOMMEND: /command [args] + reason` for the orchestrator to act on.

---

## Content Commands

| Command | Trigger Conditions | Required Tools | Mode |
|---------|-------------------|---------------|------|
| `/content {brand} [topic]` | Full pipeline wanted: strategy, draft, audit, ship-ready output | Read, Task, Write | Recommend (spawns content-strategist, content-creator, content-auditor) |
| `/post {platform} {topic}` | Single post for X / LinkedIn / Threads / IG / Bluesky; topic already known | Read, Task, Write | Recommend (spawns content-creator, content-auditor) |
| `/thread {topic} [length]` | Topic deserves more than 280 chars; X or Threads sequence (3-15 posts) | Read, Task, Write | Recommend (spawns content-creator, content-auditor) |
| `/blog {topic-or-keyword}` | Long-form 800-2000+ words; SEO targeting when SEO Specialist installed | Read, Task, Write, WebSearch | Recommend (spawns content-creator; seo-agent if present) |
| `/newsletter {action} [N]` | Any newsletter phase; see the 11 sub-actions below | Read, Task, Bash, Write | Recommend (spawns newsletter-orchestrator) |
| `/launch-post {platform} {project}` | Product Hunt / Hacker News / Indie Hackers launch | Read, Task, Write | Recommend (spawns content-creator) |
| `/readme {project}` | New repo, broken README, or README that reads like marketing-team voice | Read, Glob, Write | Self-execute |
| `/feedback [verdict]` | AUTO-FIRES after any content verdict; never run manually | Read, Edit, Write | Self-execute |
| `/content-learn [record\|collect\|grade] [piece-id]` | At publish time (write the prediction_record); 72h and day-7 after publish (collect + grade) | Read, Write, Edit, Task | Recommend (grading spawns content-analyst) |
| `/repurpose {source} {targets}` | A long-form piece is approved; derivatives wanted as tracked assets | Read, Task, Write, Edit | Recommend (spawns content-creator per derivative) |

### /newsletter sub-actions (11)

`strategy`, `draft`, `architect`, `build`, `audit`, `render-test`, `preview`, `send`, `analyse`, `all` (phases 1-7, halt at preview for human review), `next` (show the rotation slot). The pipeline is strictly sequential; the orchestrator pins every phase Task invocation synchronous with `run_in_background: false` (subagents default to background since Claude Code 2.1.198, Jul 2026).

---

## System Commands

| Command | What it does | Trigger Conditions | Mode |
|---------|-------------|-------------------|------|
| `/start` | Begin session: load memory, open task board, create daily note | Start of every working session | Self-execute |
| `/sync` | Mid-session refresh: update memory, prune stale items, process scratchpad | Mid-day; after heavy work; context feels stale | Self-execute |
| `/wrap-up` | End of session: persist state, prep daily-note handoff, prune memory | End of every session | Self-execute |
| `/audit [scope]` | Quality review by content-auditor in fresh context; `/audit voice {brand}` runs the brand-voice drift report | After completing a major piece; weekly; monthly for voice drift | Recommend (spawns content-auditor or brand-voice-keeper) |
| `/safe-clear` | Distill session state to disk, then the user runs `/compact` to flush | Only when the USER asks for an explicit flush. Never recommend it for quality reasons: native auto-compact performs the flush and the warm handoff makes the resume sharp. | Self-execute |

---

## Proactive Invocation Rules

Agents should invoke commands automatically when these conditions are detected:

| Condition | Auto-invoke |
|-----------|------------|
| Content shipped from any production command | Watch the user's next substantive response as a verdict; self-execute `/feedback` on approve / revise / reject signals |
| User says a piece was published (or a publish step completes) | `/content-learn record {piece-id}` so the prediction_record exists at publish time (contract guard G1) |
| 72h or 7 days have passed since a recorded publish | `/content-learn collect` then `/content-learn grade` (content-analyst) |
| Newsletter rotation date reached (Tuesday cadence or the brand's cadence) | `/newsletter next`, then offer `/newsletter all N` |
| Long-form piece approved (blog, newsletter issue, video script) | Offer `/repurpose {piece} {platform targets}` with the derivative plan |
| A month has passed since the brand's last voice drift report | `/audit voice {brand}` (brand-voice-keeper monthly drift report) |
| User mentions launching a product | `/launch-post` with the platform question |

---

## Command to Agent Routing

| Command | Primary Agent | Supporting Agent |
|---------|-------------|-----------------|
| `/content` | `content-strategist` (brief) then `content-creator` (draft) | `content-auditor` (gate), `brand-voice-keeper` (voice gate) |
| `/post` | `content-creator` | `content-auditor` |
| `/thread` | `content-creator` | `content-auditor` |
| `/blog` | `content-creator` | `content-auditor`; `seo-agent` if SEO Specialist installed |
| `/newsletter` | `newsletter-orchestrator` | `drafter`, `prompt-architect`, `newsletter-auditor`, `stylist`, `analyst` (one per phase) |
| `/launch-post` | `content-creator` | `content-auditor` |
| `/readme` | `content-creator` | `content-auditor` |
| `/feedback` | main session (self-execute) | `brand-voice-keeper` (memory updates) |
| `/content-learn` | `content-analyst` | `content-auditor` (promotes confirmed learnings via nominations) |
| `/repurpose` | `content-creator` (per derivative) | `content-auditor`, `content-analyst` (registry feeds the learning loop) |
| `/audit` | `content-auditor` | `brand-voice-keeper` (for `/audit voice {brand}`) |
| `/start`, `/sync`, `/wrap-up`, `/safe-clear` | main session (self-execute) | none |

Full agent roster (11): content-creator, content-strategist, content-auditor, brand-voice-keeper, content-analyst, newsletter-orchestrator, drafter, prompt-architect, newsletter-auditor, stylist, analyst.

---

## Commands and skills are one invocation model (July 2026)

Since the July 2026 Claude Code releases, custom slash commands and skills share a single invocation model: a file in `.claude/commands/` and a skill with `user-invocable: true` both surface in the same slash menu, and both load a procedure into context when invoked. Practical consequence: if this layer later migrates `commands/` into `skills/`, every entry in this index keeps its `/name` invocation, its triggers, and its routing; only the file-path column below changes. This index stays the authoritative catalog either way.

---

## Command File Locations

All command procedures live at `.claude/commands/{command-name}.md`.

| Command | File |
|---------|------|
| `/content` | `.claude/commands/content.md` |
| `/post` | `.claude/commands/post.md` |
| `/thread` | `.claude/commands/thread.md` |
| `/blog` | `.claude/commands/blog.md` |
| `/newsletter` | `.claude/commands/newsletter.md` |
| `/launch-post` | `.claude/commands/launch-post.md` |
| `/readme` | `.claude/commands/readme.md` |
| `/feedback` | `.claude/commands/feedback.md` |
| `/content-learn` | `.claude/commands/content-learn.md` |
| `/repurpose` | `.claude/commands/repurpose.md` |
| `/start` | `.claude/commands/start.md` |
| `/sync` | `.claude/commands/sync.md` |
| `/wrap-up` | `.claude/commands/wrap-up.md` |
| `/audit` | `.claude/commands/audit.md` |
| `/safe-clear` | `.claude/commands/safe-clear.md` |
