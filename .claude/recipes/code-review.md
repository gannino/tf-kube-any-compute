# Code Review Recipes

Claude Code can read your full diff, cross-reference it against the rest of the repo, and check the things human reviewers skim past: error paths, edge cases, and whether the change actually matches its own description. Use it before you push, and to sharpen review of other people's work.

---

### Review my diff before I push
**When to use:** You have finished a change and want a second pair of eyes before committing.
**Prompt:**
> Review the current uncommitted diff. Focus on correctness bugs, unhandled error paths, edge cases, and anything that contradicts patterns already used elsewhere in this repo. For each finding give me the file and line, why it matters, and a concrete fix. Rank findings by severity and ignore pure style.
**Tip:** This is exactly what `/review` runs. Use the command so the review goes to a fresh subagent that has not been anchored by the reasoning that wrote the code.

---

### Self-review against the requirement
**When to use:** You want to check the change actually does what it was meant to, not just that it runs.
**Prompt:**
> Here is what this change was supposed to do: [REQUIREMENT]. Read the diff and tell me honestly whether it fully satisfies that, partially satisfies it, or drifts from it. Point to the specific lines that do or do not meet each part of the requirement, and list anything the requirement asked for that is missing.
**Tip:** Follow with `/prove` to force the loop closed: if the change claims to be done, prove it by running it, not by reading it.

---

### Review someone else's pull request
**When to use:** You need to review a PR and want a thorough first pass.
**Prompt:**
> Check out and review the branch [BRANCH_NAME] against [BASE_BRANCH]. Summarise what the PR does in three lines, then review it: correctness, security, missing tests, and whether it introduces inconsistency with the surrounding code. Give me a merge recommendation (approve, approve with nits, request changes) with the reasons.
**Tip:** Ask Claude to also read the linked issue or PR description, so it can judge whether the change matches its stated intent, not just whether it is internally coherent.

---

### Security-focused review of a sensitive change
**When to use:** The diff touches auth, payments, input handling, secrets, or permissions.
**Prompt:**
> Do an adversarial security review of the current diff. Look specifically for injection, missing authorisation checks, secrets in code or logs, unsafe deserialisation, and trust placed in client-supplied input. For each issue give me the file, line, the attack it enables, and the fix. Assume a hostile caller.
**Tip:** This is what `/security-review` runs. Always use it before committing anything that touches a production security boundary.

---

### Find what the tests do not cover in this change
**When to use:** You want to know whether the new code is actually exercised.
**Prompt:**
> For the current diff, identify which new or changed branches, error paths, and edge cases are not covered by any test. List each uncovered path with the file and line, and tell me which ones actually matter versus which are trivial. Do not write the tests yet, just map the gap.
**Tip:** Once you agree the gaps that matter, hand them to `/test` to write and run focused tests for exactly those paths.

---

### Sanity-check a large or unfamiliar diff
**When to use:** A big change landed and you need to understand it fast before reviewing.
**Prompt:**
> The diff on [BRANCH_NAME] is large. Give me a map first: which files changed, grouped by concern, and the one-line purpose of each group. Then flag the three files where a bug is most likely to hide and explain why. I will decide where to dig based on your map.
**Tip:** This turns an unreviewable wall of diff into a review plan. Dig into the three flagged files with a targeted follow-up rather than reviewing everything at once.

---

### Check for accidental scope creep in a diff
**When to use:** You suspect a change grew beyond its ticket.
**Prompt:**
> This change was meant to do only [INTENDED_SCOPE]. Read the diff and list anything in it that falls outside that scope: unrelated refactors, drive-by edits, formatting churn, or new behaviour that was not asked for. For each, say whether it is harmless, worth splitting into its own commit, or a risk.
**Tip:** Splitting unrelated changes out into their own commits keeps the history reviewable and the revert clean if one part breaks.

---

### Review for consistency with repo conventions
**When to use:** You want the change to match how the rest of the codebase already does things.
**Prompt:**
> Read [CHANGED_FILES] and compare them against the established conventions in this repo: naming, error handling, file structure, and how similar features are already implemented. List every place the change diverges from the existing pattern and whether the divergence is justified or should be brought in line.
**Tip:** If the repo has a `CLAUDE.md` documenting conventions, ask Claude to check the diff against it explicitly. Conventions written down get enforced.
