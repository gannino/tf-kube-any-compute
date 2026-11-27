---
user-invocable: true
description: Write or sharpen headlines and titles. Use when asked for "headline options", "a better title", "title this post", "subject line", or "name this piece". Enforces the verb + what + outcome structure, the 10-word cap, and surface-specific length budgets (email subject 50 chars, blog title, social headline).
version: 2.1.0
---

# Headline Production

## Purpose

Produce headlines that state a specific outcome in ten words or fewer. A headline that exceeds ten words almost always contains a hidden second idea: split it or sharpen it. The headline is a promise the piece must keep; the hook (see the hook skill) is how the body starts keeping it.

## The structure rule

**Verb + what + outcome, max 10 words.**

- Works: "Build a self-improving CLAUDE.md in 5 minutes"
- Fails: "How to think about CLAUDE.md and improve your workflow over time" (no outcome, two ideas, 12 words)

Specific beats generic at every slot: named tools beat categories, numbers beat plurals, timeframes beat "quickly". "5 ways to grow your Twitter" loses to "How I added 4,200 followers in 30 days, in 5 moves".

## Surface budgets

| Surface | Budget | Notes |
|---|---|---|
| Email subject | max 50 chars | Gmail truncates ~60 on mobile; 50 leaves drift margin. Preview text (max 110) completes the hook the subject started, never repeats it |
| Blog / SEO title | under 60 chars for the SERP | When the SEO layer is present, the target keyword appears naturally, front-loaded |
| Newsletter TIP_HEADLINE | 5-10 words | Budget rule from the foundations pack |
| YouTube title | under 60 chars visible | Pairs with the thumbnail; never repeat the thumbnail text |
| Social post first line | doubles as the hook | Use the hook skill's truncation budgets |

## Process

1. **Name the outcome.** One sentence: what does the reader have after consuming this that they did not have before? If this cannot be stated, the piece has a positioning problem the headline cannot fix.
2. **Draft 6:** two verb-led ("Build...", "Cut..."), two number-led ("5 patterns...", "80 lines..."), two outcome-led ("...in 5 minutes", "...without rewriting"). All within structure + budget.
3. **Kill the hidden second idea.** Any draft over 10 words gets split; the second idea becomes another piece's headline (log it to the backlog).
4. **Honesty pass:** the piece must fully deliver the promise. Over-promising headlines are a trust withdrawal AND a ranker problem in 2026 (dwell-based ranking on X since Jan 2026 and watch-time ranking on IG since Jul 2026 punish click-then-bounce).
5. **Self-check:** zero cliches, zero AI-tells, zero brand-banned words, budget met for the target surface.

## Worked example

Outcome: reader ends with a one-screen agent rules file that gets followed.
- "Cut your CLAUDE.md to 80 lines that get followed" (9 words, verb + what + outcome)
- "The 80-line CLAUDE.md your agent actually reads" (8 words, outcome-led)
- Rejected: "Why long CLAUDE.md files fail and what to do about it" (11 words, two ideas: split into a diagnosis piece and a fix piece)

## Output format

```
HEADLINES, {piece}, {surface} (budget: {N})

1-6. [drafts, tagged verb/number/outcome-led]

Recommended: #{N}. Structure: verb+what+outcome PASS. Words: {N}/10. Chars: {N}/{budget}.
Promise check: the piece delivers this at {section}.
Split-offs logged to backlog: {any second ideas found}
```

## After completion

Log winning headline shapes per brand to the brand memory. Subject-line grades come back through the newsletter analyst (open rate); social headline grades through the content-analyst day-7 pass.
