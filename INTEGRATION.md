# Claudify Content Specialist — Integration

How the Content Specialist files work alone, alongside the Claudify base package, and inside the all-in bundle.

---

## Two installation modes

### Mode A — Content Specialist standalone

You bought just the Content Specialist (or downloaded the bundle and only want the content piece). The package includes everything needed to operate independently:

- 9 hooks (identical to base Claudify) for safety enforcement, completeness gates, voice gates
- 5 system commands (`/start`, `/sync`, `/wrap-up`, `/audit`, `/safe-clear`) for daily rituals
- 5 specialist agents (`auditor`, `content-creator`, `content-strategist`, `brand-voice-keeper`, `newsletter-orchestrator`)
- 8 content commands (`/content`, `/post`, `/thread`, `/blog`, `/newsletter`, `/launch-post`, `/readme`, `/feedback`)
- 60+ skills across 8 categories
- Pre-seeded `knowledge-base.md` with 30+ hard rules
- Setup files (`CLAUDE.md`, `CLAUDE.local.md`, `SETUP.md`, this file)

**You run it standalone like this:**

```bash
unzip claudify-content-specialist.zip -d /path/to/your/project
cd /path/to/your/project
claude
> /start
```

That's it. The Content Specialist is self-contained.

### Mode B — Content Specialist bundled with Claudify base

You bought the bundle (Claudify + Content Specialist at $69, or the all-in at $109). The bundled zip is a pre-merged package — both layers ship together as one `.claude/` directory.

The merge logic (handled at build time, not at install time):

| Asset | Behaviour when both layers present |
|---|---|
| Hooks (`.claude/hooks/*.sh`) | Identical files. Either layer's copy is fine. Merge picks one canonical copy. |
| Settings (`.claude/settings.json`) | Merged. Hooks from both layers registered. |
| System commands (`/start`, `/sync`, etc.) | Identical. Merge picks one canonical copy. |
| Specialist commands (`/content`, `/post`, etc.) | Specialist-specific. Added to the base command set. |
| Specialist agents | Specialist-specific. Added to the base agent set. |
| Skills (`.claude/skills/`) | Merged by category. Base ships 1,727 templated skills across 31 categories. Content Specialist adds 60+ to the `content/` category. |
| Knowledge base (`.claude/knowledge-base.md`) | Merged. Base rules + Content Specialist rules combined under section headers. |
| Memory (`.claude/memory.md`) | Single merged file. Specialist-specific sections preserved. |
| `CLAUDE.md` | Bundle-specific version covering both layers. Shipped pre-merged. |

**You run the bundle the same way as standalone:**

```bash
unzip claudify-bundle.zip -d /path/to/your/project
cd /path/to/your/project
claude
> /start
```

The bundled version's `CLAUDE.md` is broader (covers both base Claudify and Content Specialist commands), and the agent set is wider, but the daily rituals (`/start`, `/sync`, `/wrap-up`) work identically.

---

## What the Content Specialist adds on top of base Claudify

If you already use base Claudify and you upgrade by adding the Content Specialist, the new capabilities are:

### New agents
- **content-creator** — full 6-mode production pipeline (motion graphics, AI video composite, IG static, ad card, X post, still-to-video, AI Reel). Reads brand memory + voice rules, drafts asset, hands off to auditor.
- **content-strategist** — editorial planning, content calendar, brief production for the creator.
- **brand-voice-keeper** — voice consistency across sessions. Manages brand-memory architecture.
- **newsletter-orchestrator** — full 9-step newsletter pipeline (strategy → draft → architect → build → audit → render-test → preview → send → analyse).

### New commands
- `/content {brand}` — full production pipeline entry
- `/post {platform} {topic}` — single platform post
- `/thread {topic}` — X / Twitter thread
- `/blog {keyword}` — long-form blog post (SEO-aware if SEO Specialist also present)
- `/newsletter {action} [N]` — newsletter pipeline
- `/launch-post {platform}` — Product Hunt / HN / IH launch
- `/readme {project}` — high-conversion README + docs
- `/feedback` — auto-detection feedback loop (fires after content verdicts)

### New knowledge base sections
The Content Specialist's `knowledge-base.md` adds 30+ hard rules across:
- Voice & Tone (em dashes banned, marketing voice banned, softer-cliché list, etc.)
- Brand Memory Architecture (calibration pairs, signature phrase rationing, etc.)
- Content Format & Structure (personal moment openers, sentence length, paragraph density)
- Headlines & Hooks (verb + what + outcome, hook-before-truncation)
- Platform-Specific (X / LinkedIn / IG / Newsletter / README format rules)
- Anti-Slop (AI-detector tells banned, mobile readability, captions add unique value)
- Content Distribution & Repurposing (3-5 derivatives per long-form, distribution rotation)
- Measurement & Iteration (every piece tracked, voice patterns confirmed/rejected)

### New skills
60+ skills across 8 sub-categories under `.claude/skills/content/`:
- `blogging/` — long-form structure, SEO-aware writing, content briefs
- `social-media/` — X threads, LinkedIn posts, IG captions, TikTok hooks
- `newsletter/` — Beehiiv / Resend / Substack workflows, render pitfalls, voice continuity
- `launches/` — Product Hunt anatomy, Hacker News submissions, Indie Hackers post structure
- `branded-content/` — agency-grade per-client production
- `scriptwriting/` — video scripts, podcast outlines, demo flow
- `copywriting/` — headlines, hooks, CTAs, sales pages
- `audience-development/` — newsletter growth, follower compounding, repurposing maths

---

## How the layers compose

Think of it as a layered architecture:

```
┌────────────────────────────────────────────────────────────┐
│ Content Specialist layer (this product)                    │
│ - 5 specialist agents                                      │
│ - 8 content commands                                       │
│ - 60+ content skills                                       │
│ - 30+ content rules in knowledge-base                      │
│ - Brand memory architecture                                │
└────────────────────────────────────────────────────────────┘
                          ▲
                          │ adds capabilities to
                          │
┌────────────────────────────────────────────────────────────┐
│ Claudify base layer (sold separately at $49)               │
│ - 9 base agents (auditor, error-whisperer, archaeologist…) │
│ - 21 base commands                                         │
│ - 1,727 skills across 31 categories                        │
│ - 9 hooks                                                  │
│ - Memory architecture, daily rituals, completeness gates   │
└────────────────────────────────────────────────────────────┘
                          ▲
                          │ runs on
                          │
┌────────────────────────────────────────────────────────────┐
│ Claude Code (Anthropic CLI)                                │
└────────────────────────────────────────────────────────────┘
```

The Content Specialist layer **extends** the base — it does not replace anything. Daily rituals (`/start`, `/sync`, `/wrap-up`) work the same. New commands (`/content`, `/newsletter`, etc.) appear alongside the base ones. The knowledge base merges. Brand memories layer cleanly into the existing memory architecture.

---

## Compatibility with other specialists

If you also have Claudify SEO Specialist (sold separately at $58, bundled at $69, or in the all-in $109 bundle):

- `/blog` command becomes SEO-aware (uses both content-creator AND seo-agent for keyword targeting + content scoring)
- Newsletter issues get auto-checked against SEO best practices for the web version
- Content calendar (content-strategist) integrates with topical-map (keyword-strategist) for editorial planning

If you have Claudify Paid Ads Specialist (when shipped):
- `/content` ad-card mode integrates with ads-strategist for creative briefs
- Content distribution can include paid amplification recommendations

The specialists are designed to compose cleanly. Adding more specialists adds capabilities; it never breaks the existing ones.

---

## Updating

The Content Specialist is shipped as a versioned download. When updates ship (new skills, refined knowledge-base rules, new platform support), you'll receive an email with the latest zip.

To update:

```bash
# Back up your customisations first
cp .claude/knowledge-base.md .claude/knowledge-base.backup.md
cp -r .claude/agent-memory .claude/agent-memory.backup

# Unpack the new version (overwrites template files, preserves your project state)
unzip -o claudify-content-specialist-vX.Y.zip -d .

# Manually merge any updates to knowledge-base.md (the new version may add rules)
diff .claude/knowledge-base.md .claude/knowledge-base.backup.md
```

Memory files (`.claude/memory.md`, brand memories, agent memories) are gitignored and never overwritten. Your customisations survive updates.

---

## File reference

In the standalone Content Specialist download, everything below sits inside a `content-specialist/` folder, open that first. In the bundle and everything downloads, these same files are already merged in at the zip root (there is no `content-specialist/` wrapper), alongside the base system's `.claude/`.

```
content-specialist/          # standalone download only; in a bundle these sit at the zip root
├── .claude/
│   ├── agents/              # 5 specialist agents
│   ├── agent-memory/        # per-agent persistent memory
│   │   └── content-creator/brand-memories/   # per-brand voice + history
│   ├── backups/             # auto-populated by hooks
│   ├── commands/            # 13 commands (5 system + 8 content)
│   ├── hooks/               # 9 deterministic safety hooks
│   ├── logs/                # audit trail, incident log
│   ├── skills/content/      # 60+ skills across 8 categories
│   ├── command-index.md     # full catalog of commands
│   ├── knowledge-base.md    # 30+ hard rules with provenance
│   ├── knowledge-nominations.md   # candidate learnings pipeline
│   ├── memory.md            # active session context
│   └── settings.json        # hook configuration
├── Daily Notes/             # auto-populated by /start
├── CLAUDE.md                # entry point — read this first
├── CLAUDE.local.md          # personal overrides — fill once
├── INTEGRATION.md           # this file
├── SETUP.md                 # 10-minute setup walkthrough
├── Scratchpad.md            # quick-capture for /sync to process
└── Task Board.md            # what's queued / in-flight / done
```

For full file-level documentation, see `CLAUDE.md` (the entry point read by every agent at session start).
