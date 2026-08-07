---
user-invocable: false
description: How to tag agent memory by provenance. [verified] for facts confirmed by a real check, tool output, or the user; [guessed] for unconfirmed model inference. Loaded whenever writing to or reading from memory.md, agent MEMORY.md files, or knowledge-nominations.md, so guesses never get laundered into facts.
version: 2.1.0
---

# Memory Provenance

## Why this exists

Append-only memory rots. The dangerous failure is the **confabulation loop**: session N writes a guess to memory, session N+1 reads it with no marker, treats it as a confirmed fact, and builds on it. Once a guess is laundered into a "fact" it compounds silently.

The fix is one lightweight habit: **tag every memory entry by where it came from.** A reader can then tell, at a glance, what is actually known versus what was merely inferred, and never builds on sand.

This convention is the labelling half of the system. The `/memory-consolidate` command is the cleanup half: it reads these tags to expire stale guesses and resolve contradictions.

**Category**: Personal Productivity

## The two tags

| Tag | Meaning | Use when |
|---|---|---|
| `[verified]` | Confirmed by reality | A tool/command returned it, a file or API confirmed it, a test proved it, or the user stated it directly. |
| `[guessed]` | Model inference, not yet confirmed | You reasoned it out, assumed it from context, or it is plausible but unchecked. Honest uncertainty. |

If you cannot point to the real check that confirmed a fact, it is `[guessed]`. When in doubt, tag `[guessed]`. An honest guess is safe; a guess wearing a fact's clothes is not.

## Where it applies

Tag entries in the working memory tiers:
- `.claude/memory.md`
- `.claude/agent-memory/*/MEMORY.md`
- `.claude/knowledge-nominations.md`

It does **not** replace the auditor's `[Source:]` provenance on `knowledge-base.md`. Those are complementary layers:
- `[verified]` / `[guessed]` is a **lightweight, agent-authored** marker on everyday memory, written as you go.
- `[Source:]` is the **auditor-gated** citation required on every promoted knowledge-base rule, enforced by `completeness-gate.sh`.

A `[guessed]` entry must never be promoted to `knowledge-base.md`. Only a `[verified]` entry is even eligible, and even then the auditor still attaches its own `[Source:]` on promotion. The tags feed the existing nominations to auditor flow; they do not bypass it.

## Format

Put the tag at the start of the entry, before the content:

```markdown
- [verified] Build script exits 0 even on partial failure; check stderr separately. (confirmed by running it 062926)
- [guessed] The flaky test is probably a port collision in CI. (not yet reproduced)
- [verified] User wants all dates in DD/MM/YYYY. (user directive 062926)
```

Keep the confirming detail short and in parentheses. It is what lets a later session, or `/memory-consolidate`, trust or expire the line.

## The three rules

1. **Never treat a `[guessed]` entry as fact.** When you read one, it is a lead to confirm, not a premise to build on. If a decision depends on it, verify it first, then act.
2. **Promote on confirmation: `[guessed]` to `[verified]`.** The moment a guess is confirmed by a real check, tool output, or the user, edit the entry in place: change the tag to `[verified]` and append how it was confirmed and the date. This is how a guess earns its way to fact.
3. **Stale guesses expire.** A `[guessed]` entry not reconfirmed within the threshold (default ~30 days / ~15 sessions) is expired or demoted by `/memory-consolidate`. Verified entries do not expire on a timer; they are only superseded by a newer verified entry.

## Quick reference

- Writing something you confirmed → `[verified] ... (how confirmed, date)`
- Writing something you inferred → `[guessed] ... (why unconfirmed)`
- Just confirmed an old guess → flip its tag to `[verified]`, add the confirmation
- Reading a `[guessed]` entry → confirm before relying on it; never assume
- Memory feeling noisy, stale, or contradictory → run `/memory-consolidate`

## Worked example (the loop, broken)

Session 1 hits a 500 and reasons about the cause:

```markdown
- [guessed] The 500 on /checkout is a Stripe webhook signature mismatch. (inferred from the timing, not reproduced)
```

Session 2 reads that line. Because it is tagged `[guessed]`, session 2 does **not** start editing webhook code on faith. It reproduces the error first, finds the real cause is an expired API key, and updates memory:

```markdown
- [verified] The 500 on /checkout was an expired API key, not a webhook issue. (reproduced + fixed 063026; supersedes the earlier guess)
```

Without the tag, session 2 would have trusted the guess and chased the wrong fix. The tag is the entire difference between a useful note and a confident wrong turn.

## Pairs with

- `/memory-consolidate`: the periodic reflective pass that acts on these tags (merge, expire, resolve, prune).
- The `auditor` agent: owns `knowledge-base.md` and its `[Source:]` provenance; only `[verified]` entries should ever reach it, via `knowledge-nominations.md`.
- `completeness-gate.sh`: enforces the `[Source:]` requirement and the 100/200-line caps that consolidation prunes back under.
