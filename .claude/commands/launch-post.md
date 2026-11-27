# /launch-post [platform] [project]

Launch post production for Product Hunt, Hacker News, or Indie Hackers.

## When to use

- You're launching a product / project / public release
- Target platform is one of: Product Hunt, Hacker News, Indie Hackers
- You want platform-native format (not generic press copy)

## Procedure

### Step 1 — Parse arguments

```
/launch-post product-hunt "Claudify"
/launch-post hacker-news "Claudify Content Specialist"
/launch-post indie-hackers "Claudify"
```

If platform not specified: surface a question — "Which launch platform: Product Hunt / Hacker News / Indie Hackers?"

### Step 2 — Load context

Read:
- Brand-memory for the project's brand (voice anchors, ICP, content history)
- The project's positioning / one-liner / hero feature (from `CLAUDE.local.md` if present, or ask user)
- Recent launches for similar products on the target platform (WebSearch, optional)

### Step 3 — Draft

Invoke `content-creator` agent with mode: launch post + platform-specific.

#### Product Hunt
- **Title** (60 chars max): hook + product name
- **Tagline** (60 chars max): one-line value prop
- **Description** (260 chars): what it is + who it's for + key differentiator
- **First comment from maker**: longer story — why I built it, what I learned, what's next, ask for feedback
- **Reply prompts**: 3-5 anticipated questions + maker reply drafts
- **Schedule**: 12:01 AM PT for full-day launch

#### Hacker News (Show HN)
- **Title**: "Show HN: [Product] — [one-line value prop]"
  - No marketing language ("revolutionary", "amazing" get flagged)
  - Descriptive, specific, what it does
- **Body**: 1-3 paragraphs — what it is, why I built it, what's interesting technically (HN cares about the *how*)
  - No "click here" / "buy now" — HN is hostile to marketing copy
  - Include the URL plainly
- **Initial replies**: ready-to-post responses to common HN comment patterns (skepticism, technical questions, comparison to alternatives)

#### Indie Hackers
- **Title**: question or claim that frames the launch as a story
- **Body**: longer-form — context, what I built, the specific problem, the build process, MRR / metrics if shareable, ask for feedback
- **Tags**: 3-5 relevant
- **CTA**: link to product, ask specific question to drive replies

### Step 4 — Audit

Invoke auditor. Platform-specific checks:
- Product Hunt: title length, tagline length, description length
- Hacker News: NO marketing language (game-changer, supercharge, etc. — auto-flag and reframe), title is descriptive not clickbait
- Indie Hackers: voice matches brand, story arc present, CTA specific

### Step 5 — Output

Print all assets ready to paste:
- Title
- Tagline / hero (per platform)
- Body
- First comment (PH only)
- Reply prompts (PH/HN)
- Suggested schedule + maker behaviour notes

## Hand-off

User publishes manually. Launch-day behaviour matters:
- **Product Hunt**: maker comment present at launch, reply to every comment in first 4 hours, share to your audience for traffic
- **Hacker News**: be present on the thread for first hour, respond to skepticism with specifics not defensiveness, never ask for upvotes
- **Indie Hackers**: respond to every comment, link to product naturally, share metrics openly

After launch, `/feedback` auto-fires on next response — log the launch + initial signal.

## Hard rules (per platform)

- **Hacker News: zero marketing language.** Auto-reject any draft containing: "revolutionary", "game-changer", "amazing", "incredible", "ultimate". HN flags these instantly.
- **Product Hunt: schedule for 12:01 AM PT** for full-day exposure. Never launch mid-day.
- **All platforms: no upvote-begging.** Asking for upvotes is a flag on PH and HN, gets you removed from leaderboard.
