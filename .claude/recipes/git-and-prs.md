# Git and PRs Recipes

Claude Code can read a diff and turn it into clean commits, a clear PR description, or a resolved conflict, because it understands what the change means, not just what lines moved. These recipes cover the git work that surrounds shipping.

---

### Write a commit message from the staged diff
**When to use:** You have staged changes and want a clear, conventional commit message.
**Prompt:**
> Read the staged diff and write a commit message for it. Use a concise imperative subject line under 72 characters, then a body that explains what changed and why, not how. Match the commit style already used in this repo's history. Show me the message, do not commit until I approve it.
**Tip:** Ask Claude to read a few recent commits first so the message matches your project's tone and any conventional-commit prefixes you use.

---

### Split a messy working tree into clean commits
**When to use:** You made several unrelated changes at once and want them committed separately.
**Prompt:**
> My working tree has several unrelated changes mixed together. Group them into logical commits, one concern each, and stage and commit them in a sensible order with good messages. Tell me the plan before you start committing so I can adjust the grouping.
**Tip:** Reviewable history is worth the extra minute. Approve the grouping before Claude commits, since only you know which changes are truly related.

---

### Write a PR description from a branch
**When to use:** You are opening a pull request and want a description that reviewers can actually use.
**Prompt:**
> Write a pull request description for the branch [BRANCH_NAME] against [BASE_BRANCH]. Include: a short summary of what and why, the notable changes, how it was tested, and anything a reviewer should look at closely. Read the actual diff and the linked issue if there is one. Keep it factual, no filler.
**Tip:** A good PR description is the difference between a fast review and a slow one. Ask Claude to call out the risky files explicitly so reviewers know where to spend attention.

---

### Resolve a merge or rebase conflict
**When to use:** You hit conflicts and want them resolved correctly, not just made to compile.
**Prompt:**
> I have merge conflicts in [FILES]. For each one, work out what both sides were trying to do, then resolve it so both intents are preserved, not just one side picked. Explain each resolution. After resolving, run the build and tests to confirm nothing broke in the merge.
**Tip:** Conflicts are where silent bugs enter. Ask Claude to explain each resolution so you can confirm it kept the intent of both branches, then verify with the tests.

---

### Rebase and clean up a branch before review
**When to use:** Your branch has grown messy commits and you want it tidy before opening a PR.
**Prompt:**
> Tidy up the branch [BRANCH_NAME] before I open a PR: bring it up to date with [BASE_BRANCH], and reorganise the commits into a clean, logical sequence with clear messages. Tell me your plan for the commit structure first. Do not force-push until I confirm.
**Tip:** Always let Claude show the rebase plan before it rewrites history. Force-pushing a shared branch without agreement is how teammates lose work.

---

### Cherry-pick a fix onto another branch
**When to use:** A fix on one branch needs to go onto a release or hotfix branch too.
**Prompt:**
> The fix in commit [COMMIT_REF or DESCRIPTION] needs to go onto [TARGET_BRANCH] as well. Cherry-pick just that change, resolve any conflicts so it applies cleanly against the target, and run the tests on the target branch to confirm the fix works there. Do not bring along unrelated commits.
**Tip:** Ask Claude to confirm the fix still makes sense on the target branch. Code the fix depended on may not exist there, in which case it needs adapting, not just picking.

---

### Review your own change on a worktree before merging
**When to use:** You want to review a branch in isolation without disturbing your current work.
**Prompt:**
> Create a git worktree for [BRANCH_NAME] so I can review it without touching my current working tree. Then review the full diff against [BASE_BRANCH] for correctness, tests, and consistency, and give me a merge recommendation. Clean up the worktree when we are done.
**Tip:** Worktrees let you review or test one branch while your main tree stays on another. Handy when a review interrupts work you are not ready to stash.

---

### Draft a changelog or release notes from history
**When to use:** You are cutting a release and want notes generated from the actual commits.
**Prompt:**
> Generate release notes for the changes between [FROM_REF] and [TO_REF]. Read the actual commits and diffs, group the changes into features, fixes, and breaking changes, and write each entry so a user of this software understands the impact, not just the internal detail. Flag anything that needs a migration note.
**Tip:** This overlaps with the `/release` command, which produces technical, marketing, and executive versions. Use it when you need more than one audience served.

---

### Find and explain when and why a line changed
**When to use:** You need the history behind a specific line or block of code.
**Prompt:**
> Trace the history of [FILE:LINES or the FUNCTION named X]. Tell me when it was last meaningfully changed, by which commit, and what problem that change was solving. Read the commit messages and surrounding diff to reconstruct the reasoning, so I understand why it is the way it is before I touch it.
**Tip:** Understanding why code exists before changing it prevents you from re-breaking something an old commit deliberately fixed. This is the archaeology the `archaeologist` agent specialises in.
