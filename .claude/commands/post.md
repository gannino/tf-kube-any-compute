# /post [platform] [topic]

Single platform post production. Faster than `/content` — skips strategy phase.

## When to use

- You have a specific topic in mind
- You want a single post (not a thread, not long-form)
- You know the platform (X / LinkedIn / Threads / IG / Bluesky)

## Procedure

### Step 1 — Parse arguments

```
/post X "topic here"
/post linkedin "topic here"
/post threads "topic here"
/post ig "topic here"
/post bluesky "topic here"
```

If platform not specified: use default from `CLAUDE.local.md` → "Default platform when unspecified".
If topic not specified: prompt user for it.

### Step 2 — Load brand context

Read `.claude/agent-memory/content-creator/brand-memories/{brand}.md` (active brand from `memory.md`).

If brand-memory missing: HALT — user must set up brand first via `/brand-memory create {brand}`.

### Step 3 — Draft

Invoke `content-creator` agent via Task tool with `subagent_type: content-creator`. Pass:
- Brand
- Platform (X / LinkedIn / etc.)
- Topic
- Mode: 5 (X Post — single, not thread) or platform-specific equivalent

The creator applies platform format rules (see `.claude/knowledge-base.md` Platform-Specific section):
- X: 280 char hard cap, hook in first 180 chars
- LinkedIn: 1300-2000 chars optimal, hook in first 3 lines, hashtags after body
- Threads: similar to X but longer (500 char single)
- IG: caption hook in first 125 chars, 5-15 hashtags
- Bluesky: 300 char hard cap

### Step 4 — Audit

Invoke `auditor` agent. Receive PASS / FAIL.

### Step 5 — Output

Print final post. If FAIL: print fix list.

### Step 6 — Prediction record at ship time (mandatory, contract guard G1)

When the user publishes the post (or says they will), self-execute `/content-learn record {piece-id}` immediately: predicted outcome on the platform's primary metric, by_date 7 days out, baseline from the brand's rolling mean. Without this record the content-analyst returns `INSUFFICIENT_PRECONDITION` at day-7 and the piece teaches the system nothing. Do not ask permission to write it; writing it is the default.

## Examples

```
/post X "What I learned from shipping Issue 001 of Claudify Weekly"
```
Drafts an X post (280 char cap, hook in first 180 chars).

```
/post linkedin "Why most CLAUDE.md files decay within a month"
```
Drafts a LinkedIn post (1300-2000 chars).

```
/post threads "Three patterns I see in every Claude Code session"
```
Drafts a Threads post.

## Hand-off

After PASS, you publish manually (the agent doesn't post for you — it produces the asset). After publishing, the next time you respond to this assistant, `/feedback` auto-fires to log the result.
