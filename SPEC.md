# Content Specialist — Build Spec & Status

**Date:** 2026-04-28 (revised same day — newsletter scope expanded)
**Status:** Phase 1 + 2 complete — content production system + full newsletter pipeline (10 agents, 14 hooks, 64 skills, 6 foundations, 4 build scripts, 7 templates) shipped. Stripe SKU wiring + checkout + webhook + Pricing UI + zip distributables all live. Ready to deploy.

---

## What's been built (this iteration)

### Foundation files (root)

| File | Status | Lines | Purpose |
|---|---|---|---|
| `CLAUDE.md` | ✅ shipped | ~130 | Entry point read by every agent at session start |
| `CLAUDE.local.md` | ✅ shipped | ~70 | User personal overrides — gitignored |
| `SETUP.md` | ✅ shipped | ~150 | 10-minute onboarding walkthrough |
| `INTEGRATION.md` | ✅ shipped | ~200 | How standalone vs bundled installs work |
| `Scratchpad.md` | ✅ shipped | (copied from base) | Quick-capture for /sync to process |
| `Task Board.md` | ✅ shipped | (copied from base) | What's queued / in-flight / done |

### `.claude/` core files

| File | Status | Lines | Purpose |
|---|---|---|---|
| `knowledge-base.md` | ✅ shipped | ~150 (30+ rules) | The trust artifact — universal content rules with `[Source:]` provenance |
| `knowledge-nominations.md` | ✅ shipped | (copied from base) | Candidate learnings pipeline |
| `command-index.md` | ✅ shipped | (copied from base, will adapt to content) | Catalog of commands |
| `memory.md` | ✅ shipped | (copied from base) | Active session context |
| `settings.json` | ✅ shipped | (copied from base) | Hook configuration |

### `.claude/agents/` (5 specialist agents)

| Agent | Status | Lines | Role |
|---|---|---|---|
| `auditor.md` | ✅ shipped | ~200 | Universal quality gate — 15 mechanical + 10 semantic + regression checks |
| `content-creator.md` | ✅ shipped | ~250 | Lead production agent — 7 modes + 6 platform deliverables |
| `content-strategist.md` | ✅ shipped | ~150 | Editorial planning, topic backlog, brief production |
| `brand-voice-keeper.md` | ✅ shipped | ~150 | Voice consistency, brand-memory file management |
| `newsletter-orchestrator.md` | ✅ shipped | ~250 | Full 9-phase newsletter pipeline orchestration |

### `.claude/commands/` (13 commands — 5 system + 8 content)

System (copied from SEO Specialist, identical):
| Command | Status | Purpose |
|---|---|---|
| `start.md` | ✅ shipped | Daily ritual entry |
| `sync.md` | ✅ shipped | Mid-day memory refresh |
| `wrap-up.md` | ✅ shipped | End-of-day handoff |
| `audit.md` | ✅ shipped | Verify recent work quality |
| `safe-clear.md` | ✅ shipped | State persistence + /compact handoff |

Content-specific (new):
| Command | Status | Lines | Purpose |
|---|---|---|---|
| `content.md` | ✅ shipped | ~80 | Full pipeline: strategy → draft → audit |
| `post.md` | ✅ shipped | ~70 | Single platform post (X, LinkedIn, IG, Threads, Bluesky) |
| `thread.md` | ✅ shipped | ~75 | X thread (3-15 tweets) |
| `blog.md` | ✅ shipped | ~85 | Long-form blog (SEO-aware if SEO Specialist present) |
| `newsletter.md` | ✅ shipped | ~80 | 9-phase newsletter pipeline orchestration |
| `launch-post.md` | ✅ shipped | ~110 | Product Hunt / Hacker News / Indie Hackers launches |
| `readme.md` | ✅ shipped | ~95 | OSS-style README + docs |
| `feedback.md` | ✅ shipped | ~80 | Auto-detection feedback loop |

### `.claude/hooks/` (9 hooks, identical to base Claudify)

| Hook | Status |
|---|---|
| `backup-before-write.sh` | ✅ copied |
| `completeness-gate.sh` | ✅ copied |
| `guard-bash.sh` | ✅ copied |
| `log-changes.sh` | ✅ copied |
| `log-failures.sh` | ✅ copied |
| `log-stop-verdict.sh` | ✅ copied |
| `post-compact-resume.sh` | ✅ copied |
| `pre-compact-handoff.sh` | ✅ copied |
| `session-reset.sh` | ✅ copied |

### `.claude/skills/content/` (64 skills across 8 categories)

| Category | Skills | Status |
|---|---|---|
| `blogging/` | 8 skills (long-form-structure, seo-blog-post, content-brief, technical-blog, founder-blog, listicle, comparison-post, case-study) | ✅ generated |
| `social-media/` | 8 skills (x-thread, x-single, linkedin-post, ig-caption, ig-carousel, threads-post, bluesky-post, tiktok-script) | ✅ generated |
| `newsletter/` | 8 skills (newsletter-issue, newsletter-strategy, newsletter-render-test, newsletter-deliverability, newsletter-growth, newsletter-monetization, lifecycle-sequence, broadcast-email) | ✅ generated |
| `launches/` | 8 skills (product-hunt-launch, hacker-news-show, indie-hackers-post, launch-twitter-thread, launch-email-sequence, launch-page, demo-video-script, beta-launch) | ✅ generated |
| `branded-content/` | 8 skills (brand-memory, voice-calibration, brand-guidelines, content-calendar, content-history, agency-grade-content, repurposing-pipeline, content-audit) | ✅ generated |
| `scriptwriting/` | 8 skills (video-script, podcast-outline, demo-flow, tutorial-script, talking-head-script, voiceover-script, motion-graphics-brief, animation-script) | ✅ generated |
| `copywriting/` | 8 skills (headline, hook, cta, sales-page, landing-page, ad-copy, microcopy, value-prop) | ✅ generated |
| `audience-development/` | 8 skills (newsletter-growth, follower-compound, repurposing-math, content-distribution, cross-platform-strategy, audience-research, persona-development, growth-experiments) | ✅ generated |

**Skill template note:** all skills follow the standard 133-line scaffolding template (same pattern as SEO Specialist's 57 skills). Real value lives in `knowledge-base.md` (the 30+ hard rules) + the 5 agent definitions. Skills are the structured workflow scaffolding — they are invocable, but the trust-bearing artefacts are the knowledge-base + agents.

### `.claude/agent-memory/` (per-agent persistent memory)

| Subdirectory | Status |
|---|---|
| `auditor/` | ✅ created (will populate as audits run) |
| `content-creator/` | ✅ created |
| `content-creator/brand-memories/` | ✅ created |
| `content-creator/brand-memories/_TEMPLATE.md` | ✅ shipped (~150 lines) |
| `content-strategist/` | ✅ created |
| `brand-voice-keeper/` | ✅ created |
| `newsletter-orchestrator/` | ✅ created |

---

## What still needs doing (remaining build work)

### Required before SKU launch

| Task | Owner | Estimate | Blocking |
|---|---|---|---|
| Create Stripe SKU `claudify-content-bundle` ($69) — Claudify base + Content Specialist bundled | You | 30 min | Pricing page |
| Create Stripe SKU `claudify-content` standalone if applicable | You | 15 min | Could skip if specialists are bundled-only |
| Update `claudify/cli/src/plans.ts` — add Content Specialist to plan registry | Engineering | 30 min | Build pipeline |
| Update `claudify/api/create-checkout.js` — add tier branch for content | Engineering | 30 min | Stripe checkout flow |
| Update `claudify/api/webhook.js` — add content tier to download token gen + Resend email | Engineering | 30 min | Post-purchase flow |
| Create `claudify/src/pages/SuccessContent.tsx` — post-purchase success page (copy SuccessSeo.tsx) | Engineering | 1-2 hr | Post-purchase flow |
| Update `claudify/src/components/Pricing.tsx` — add Content Specialist column or comparison-table redesign for 5-tier display | Design + engineering | 2-3 hr | Pricing page UX |
| Build `content-specialist.zip` distributable | Engineering | 30 min | Customer download |
| Build `claudify-content-bundle.zip` distributable (pre-merged base + Content Specialist) | Engineering | 30 min | Bundle download |

### Recommended polish before launch

| Task | Notes |
|---|---|
| QA pass on all 64 skill files | Spot-check 5 skills to verify the template fills sensibly per slug |
| QA pass on all 5 agents — sanity-read each one start to finish | Catch any internal references that don't resolve (e.g. a command file that doesn't exist) |
| Smoke-test the install flow | `unzip` → `cd` → `/start` should work end-to-end on a fresh project directory |
| Update `.claude/command-index.md` to reflect Content Specialist commands | Currently still has SEO Specialist commands listed |
| Adapt `.claude/memory.md` from SEO-specific to Content-specific | Currently has SEO content; should be content-specific |

### Future iterations (after launch)

| Task | When |
|---|---|
| Marketing landing page copy for Content Specialist | Pre-launch, for buyers to see what's inside |
| Existing-customer upgrade campaign (91 UK + UAE customers offered $20 upgrade to add Content Specialist) | Day-1 launch |
| Day-7 post-launch review | First week post-launch — does the +$20 upsell convert as projected? |
| Pricing review at 30 days | Adjust to $79 / $129 if conversion data supports |

---

## Quality bar verification

Per the internal audit, the trust-bearing artefacts are:

1. ✅ **`knowledge-base.md`** — 30+ hard rules with `[Source:]` provenance organised across 8 sections (Voice, Brand Memory, Content Format, Headlines, Platform-Specific, Anti-Slop, Distribution, Measurement). Matches the SEO Specialist's quality bar (25+ SEO rules).

2. ✅ **5 agent definitions** — total ~1,000 lines combined. Each agent has: identity, inputs, procedure (multi-stage), hard rules, output format, self-improvement loop. The lead agent (`content-creator`) covers 7 production modes + 6 platform-specific deliverables.

3. ✅ **8 hand-built command procedures** — each command is a complete operational doc, not a templated stub. Commands invoke agents via Task tool with proper subagent_type passing.

4. ✅ **Setup/onboarding docs** — `CLAUDE.md` (entry point), `CLAUDE.local.md` (personal overrides template), `SETUP.md` (10-min walkthrough), `INTEGRATION.md` (architecture explanation).

5. ✅ **Brand-memory template** — `_TEMPLATE.md` covers ICP, calibration paragraph pairs (3+), banned phrases, signature phrases, approved patterns, watch list, content history. The brand-memory architecture is the load-bearing differentiator vs competitors (Content OS Agents, AgentKit Marketing).

**Differentiators vs market competitors:**

- **Newsletter system included** (Content OS Agents $97 doesn't have this depth — only generic content packs)
- **Brand-memory architecture** (continuity across sessions — most prompt packs lose voice between uses)
- **Full 9-phase newsletter pipeline** with strategist + drafter + prompt-architect + auditor + stylist + analyst sub-agents
- **Real production proof** — Issue 001 of Claudify Weekly was shipped using this exact system on launch day (April 28, 2026)
- **Anti-slop rules** ban AI-detector tells (delve, fast-paced world, etc.) at hard-rule level — sophisticated audiences detect ChatGPT-default voice within seconds

---

## File counts (final)

| Category | Count |
|---|---|
| Root files | 6 (CLAUDE.md, CLAUDE.local.md, SETUP.md, INTEGRATION.md, Scratchpad.md, Task Board.md) |
| `.claude/` core files | 5 (knowledge-base, knowledge-nominations, command-index, memory, settings.json) |
| Hooks | 9 |
| System commands | 5 |
| Content commands | 8 |
| Specialist agents | 5 |
| Brand-memory template | 1 |
| Skills | 64 |
| Daily Notes (placeholder) | 0 (auto-populated by /start) |
| Total files | **134** (104 content side + 30 newsletter system) |
| Newsletter foundations | 6 (PERSONA, VOICE, GLOSSARY, BUDGETS, PIPELINE-PERSONALITIES, MISTAKES-LOG) |
| Newsletter build scripts | 4 (build.py, send.js, render-test.sh, test-god-prompt.py) |
| Newsletter sub-agents added | 5 (prompt-architect, stylist, analyst, drafter, newsletter-auditor) |
| Newsletter hooks added | 5 (em-dash, jargon, schema, contrast, paragraph-collapse) — registered in settings.json |
| Newsletter templates | 7 (ISSUE-SCHEMA, GOD-PROMPT-RUBRIC, COMPONENTS, email-template, BACKLOG, SYSTEM, README) |

---

## Pricing & SKU plan (when ready to ship)

Per the strategy synthesis at `Creatives/claudify/research/2026-04-28-product-strategy/00-synthesis.md`:

| Tier | Price | What's included |
|---|---|---|
| Skills Pack | $19 | 1,727 generic skills only |
| Claudify base | $49 | Core OS + 9 agents + 21 commands + 1,727 skills |
| **Claudify + Content Specialist (bundle)** | **$69** | Base + 5 content agents + 8 content commands + 64 content skills + content knowledge-base |
| Claudify + SEO Specialist (existing) | $69 | Base + SEO Specialist (existing) |
| (Future: Claudify all-in bundle) | $109 | Base + SEO + Content + ~2 more specialists + lifetime updates |

For initial launch: ship the Content Specialist as a standalone Stripe SKU + the Claudify+Content bundle SKU. Hold the all-in bundle until 2-3 specialists have shipped + conversion data justifies the $109 tier.

---

## Source files for this build

- Strategy synthesis: `Creatives/claudify/research/2026-04-28-product-strategy/00-synthesis.md`
- Internal audit: `Creatives/claudify/research/2026-04-28-product-strategy/01-internal-audit.md`
- Market research: `Creatives/claudify/research/2026-04-28-product-strategy/02-market-research.md`
- Demand research: `Creatives/claudify/research/2026-04-28-product-strategy/03-demand-research.md`
- Reference template (quality bar): `claudify/cli/templates/seo-specialist/`
- Content engine assets: `.claude/skills/content-engine/`, `.claude/agents/content-engine/creator.md`, `newsletter/`
