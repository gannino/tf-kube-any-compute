---
user-invocable: true
description: Craft or fix the opening hook of any piece. Use when asked to "write a hook", "better hook", "fix my opening", "make this opening stronger", "hook options", or when a draft opens with abstract preamble. Covers per-platform truncation points, the five hook families, and the 2026 ranker reality that hooks must pay off, not just tease.
version: 2.1.0
---

# Hook Crafting

## Purpose

The hook decides whether the rest of the piece exists for the reader. This skill produces hooks that stop the scroll AND get paid off by the body, because the 2026 rankers punish unresolved curiosity gaps: X's Grok ranker models predicted dwell (Jan 2026), Instagram ranks watch time and sends on the main feed (Jul 2026), and LinkedIn suppresses generic AI-voice openers (23 Jul 2026). Bait without payoff now costs distribution.

## Truncation points (the hook must be complete before these)

| Surface | Hook budget |
|---|---|
| X feed | first 180 chars |
| LinkedIn mobile | 3 lines, ~210 chars |
| Instagram caption | ~125 chars |
| Email subject / preview | 50 / 110 chars |
| TikTok / Reels | first 2 seconds of speech (~6 words) |
| Blog | title + first sentence |

## The five hook families

1. **Specific number:** "Audited 30 CLAUDE.md files. 24 had rules the owner stopped following." Numbers create instant credibility and concreteness.
2. **Counterintuitive claim:** "I deleted 300 lines of my AI config and it got smarter." Must be true and paid off with the mechanism.
3. **Named moment:** "A client asked me why their agent ignored the rules they wrote for it." Personal-moment openers are the house rule for first-person prose; abstract preambles are banned.
4. **Cost of inaction:** "Your agent forgot your rules by lunchtime." Names the reader's live problem in their own terms.
5. **Before/after:** "412 lines to 80. The agent started listening the same afternoon." The transformation IS the hook.

Banned hook patterns: abstract preamble ("AI is changing development..."), scope statements ("In this post we'll explore..."), engagement bait ("You won't believe..."), question-stacks, and anything the marketing-cliche or AI-tell ban lists catch.

## Process

1. **Extract the strongest asset** from the piece: the best number, moment, reversal, or artifact. The hook is made of the piece's best material, never bolted on.
2. **Write 5 hooks, one per family.** Force all five even when one seems obvious; family-forcing reliably surfaces a better angle.
3. **Cut to the truncation budget** for the target surface. Every word earns its place.
4. **Payoff check:** does the body deliver exactly what the hook promises, in the reader's first 20% of the piece? If not, fix the body or soften the hook. Unpaid hooks train audiences to skip you and rankers to bury you.
5. **Self-check:** zero em dashes / cliches / AI-tells; brand bans; the hook survives standing alone (screenshot test).

## Worked example

Piece asset: a config-file audit with the finding "24 of 30 had stale rules".
- Number: "24 of the 30 CLAUDE.md files I audited had rules nobody followed anymore."
- Counterintuitive: "The best CLAUDE.md I have seen this year is also the shortest."
- Moment: "Opened a client's CLAUDE.md yesterday. Line 118 was the rule that mattered. The agent never got there."
- Cost: "Your agent reads your rules the way you read terms of service."
- Before/after: "400 lines, ignored. 80 lines, followed. Same agent."

## Output format

```
HOOKS, {piece}, {surface} (budget: {N} chars)

1. [number] ...
2. [counterintuitive] ...
3. [moment] ...
4. [cost] ...
5. [before/after] ...

Recommended: #{N} because {one line}. Payoff check: PASS (body delivers at {location}).
```

## After completion

Log winning hook families per brand + platform to the brand's hook bank; the content-analyst's day-7 grades confirm which families actually lift the platform's primary metric.
