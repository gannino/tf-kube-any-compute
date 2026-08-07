# Claudify Recipe Library

A curated set of battle-tested, copy-pasteable prompts for Claude Code, organised by the job you are trying to get done. These are not generic AI prompts. Every recipe is written for what Claude Code is genuinely good at: reading a whole repository at once, editing across many files in one pass, spawning subagents for parallel work, running commands to verify its own output, and driving git.

## How to use this library

1. **Find the job.** Open the category file that matches what you are doing (refactoring, shipping a feature, debugging, and so on). The table of contents below links each one.
2. **Copy a recipe.** Each recipe has a ready-to-paste prompt in a blockquote.
3. **Fill the `[BRACKETS]`.** The bracketed parts are the only bits you change: a file path, a symbol name, a behaviour to describe. Everything else is deliberate.
4. **Paste into Claude Code.** Send it as your message. Read the plan it comes back with before it starts editing.
5. **Verify.** Most recipes end by asking Claude to run tests or the app. Where a Claudify command pairs well, the **Tip** line names it (for example `/verify`, `/prove`, `/security-review`). Use it.

## Conventions

- `[BRACKETS]` mark the values you supply. Fill every one before sending.
- Recipes assume Claude can read your repo. If you have a `CLAUDE.md`, keep it current: it is the single highest-leverage thing you can do to make every recipe here work better.
- Prompts ask Claude to plan before it edits, and to prove the result at the end. Do not remove those clauses to save time. They are the difference between a change that looks done and one that is done.
- Where a recipe touches a production system (payments, auth, migrations, deploys), pair it with `/security-review` and `/verify` before you ship.

## Which layer or command pairs with a recipe?

Not sure which Claudify command fits your situation? The **Tip** line on most recipes names one. As a quick map:

- Proving a change actually works: `/verify`, `/prove`
- Writing and running focused tests: `/test`, then `/mutation-gate`
- Security pass over a diff: `/security-review`
- Deep code review before merge: `/review`
- Stuck for more than ten minutes: `/unstick`
- Learning an unfamiliar codebase: `/onboard`
- Context getting heavy or switching task domains: `/safe-clear`
- Passing work to another person or session: `/handoff`

## Table of contents

| Category | File | What it covers |
|---|---|---|
| Refactoring | [refactoring.md](refactoring.md) | Extracting modules, renaming, removing duplication, modernising, splitting large files |
| Code review | [code-review.md](code-review.md) | Reviewing diffs, self-review before push, reviewing someone else's PR, spotting risk |
| Shipping features | [shipping-features.md](shipping-features.md) | Planning then building a feature end to end, wiring, config, feature flags |
| Debugging | [debugging.md](debugging.md) | Reproducing, bisecting, root-causing, fixing intermittent and production bugs |
| Testing | [testing.md](testing.md) | Writing focused tests, filling coverage gaps, hardening the suite, mutation checks |
| Git and PRs | [git-and-prs.md](git-and-prs.md) | Commits, branches, PR descriptions, rebases, cherry-picks, worktrees, conflict resolution |
| Documentation | [documentation.md](documentation.md) | READMEs, API docs, CLAUDE.md, architecture notes, comments, changelogs |
| Planning and context | [planning-and-context.md](planning-and-context.md) | Onboarding to a codebase, planning before coding, handoffs, keeping context sharp |

Around sixty recipes across the eight files. Start with the category that matches your task, not the top of the list.
