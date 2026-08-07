# /thread [topic] [length]

X / Twitter thread production. Multi-tweet structure with hook tweet + body tweets + closer.

## When to use

- The topic deserves more than 280 chars
- You want a thread structure (3-15 tweets)
- You're publishing to X / Twitter (or Threads, which supports thread-like sequences)

## Procedure

### Step 1 — Parse arguments

```
/thread "topic here"            # default length: 5-7 tweets
/thread "topic here" 3          # short thread
/thread "topic here" 12         # long thread (use sparingly)
```

### Step 2 — Load brand context

Read brand-memory from active brand.

### Step 3 — Draft thread

Invoke `content-creator` agent. Pass:
- Brand
- Platform: X
- Mode: 5 (X Post — thread variant)
- Topic
- Length (3-15 tweets)

Creator applies thread-specific rules (see `.claude/knowledge-base.md` Platform-Specific X):
- Hook tweet: must establish stakes within first 180 chars (truncation point on feed)
- Body tweets: each stands alone (people read individual tweets out of order)
- Pacing: short-mix-medium-long sentence rhythm; line breaks aggressive for breathing room
- Closer: payoff or CTA, NOT a "thread done!" signal (banned per knowledge-base)
- Length: max 15 tweets — beyond that engagement collapses

### Step 4 — Audit

Auditor checks:
- Each tweet under 280 chars
- Hook tweet hook-strength check
- No banned phrases across any tweet
- Voice consistency across tweets (no drift mid-thread)

### Step 5 — Output

Print thread tweet-by-tweet, numbered, with character count per tweet:

```
1/N (264 chars)
[hook tweet]

2/N (212 chars)
[body tweet 1]

...

N/N (189 chars)
[closer tweet]
```

## Hand-off

User copies the thread to X / Threads / Bluesky and publishes. After publishing, `/feedback` auto-fires on next response.

## Distribution

Threads have natural derivatives:
- 1 LinkedIn post (rephrased as flowing prose, hook in first 3 lines)
- 3-5 X singles (each tweet's body becomes a standalone single across the next 2 weeks)

Run `/post linkedin` and `/post X` to produce these from the same source thread (creator reads the thread for context).
