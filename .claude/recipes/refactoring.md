# Refactoring Recipes

Claude Code refactors well because it can read every call site before it changes anything, edit them all in one pass, and run the tests to prove nothing moved. Give it the target and the shape you want, and let it find the ripples.

---

### Extract a responsibility into its own module
**When to use:** A file has grown to hold two or more jobs and you want to split one out cleanly.
**Prompt:**
> Refactor [FILE] to extract [RESPONSIBILITY] into a new module at [NEW/PATH]. Find every call site across the repo, update the imports, keep the public behaviour identical, and run the test suite to confirm nothing broke. List the files you changed and why.
**Tip:** Have Claude run the tests itself as the last step, then pair with `/verify` to prove the app still behaves before you commit.

---

### Rename a symbol everywhere
**When to use:** A function, type, or variable name is misleading and you want it fixed across the whole codebase.
**Prompt:**
> Rename [OLD_NAME] to [NEW_NAME] across the entire repo. Update every definition, call site, import, and any string references in tests or config. Do not touch unrelated names that happen to contain the same substring. Show me a diff summary grouped by file before you finish, then run the build to confirm it compiles.
**Tip:** Ask Claude to grep for the substring first and report matches, so you can confirm the scope before it edits.

---

### Remove duplication across files
**When to use:** The same logic is copy-pasted in several places and you want a single source of truth.
**Prompt:**
> Find where the logic in [FILE:FUNCTION] is duplicated across the repo, extract the shared behaviour into one reusable helper in [SHARED/PATH], and replace each copy with a call to it. Preserve any small differences between the copies as parameters. Run the tests after and confirm behaviour is unchanged.
**Tip:** After the change, run `/review` so a fresh pass checks the abstraction did not accidentally merge two things that only looked alike.

---

### Split an oversized file
**When to use:** A single file is thousands of lines and hard to navigate.
**Prompt:**
> [FILE] is too large. Propose a split into cohesive modules grouped by responsibility, then carry it out: create the new files, move the code, update all imports across the repo, and keep the public entry point re-exporting the moved symbols so external callers do not break. Run the build and tests to confirm.
**Tip:** Ask for the proposed split as a plan first, approve it, then let Claude execute. Splitting on the wrong seam is expensive to undo.

---

### Modernise legacy patterns
**When to use:** The code uses an outdated idiom (callbacks, an old API, a deprecated pattern) you want brought up to date.
**Prompt:**
> Convert [FILE or DIRECTORY] from [OLD_PATTERN] to [NEW_PATTERN], for example callbacks to async/await. Apply it consistently, update the tests to match, and flag any spot where the conversion changes semantics rather than just syntax. Run the suite at the end.
**Tip:** If the library API changed too, ask Claude to check the current docs for the version in your lockfile before it rewrites, so it targets the real signature.

---

### Introduce a type or interface and thread it through
**When to use:** A shape is passed around as loose objects and you want it typed.
**Prompt:**
> Define a type/interface named [TYPE_NAME] describing the shape of [DESCRIPTION], place it in [PATH], then thread it through every function that produces or consumes this shape. Fix the type errors the change surfaces rather than suppressing them. Run the type checker and report what it found.
**Tip:** Let the type checker be the judge. Ask Claude to paste the checker output so you see the real before-and-after, not a claim.

---

### Untangle a circular dependency
**When to use:** Two modules import each other and it is causing load-order or bundling problems.
**Prompt:**
> There is a circular dependency between [MODULE_A] and [MODULE_B]. Map exactly what each imports from the other, propose the cleanest way to break the cycle (extract shared code, invert a dependency, or move an interface), then implement it and confirm the cycle is gone. Run the build to prove it resolves.
**Tip:** If you are unsure why the cycle exists, run `/unstick` first to get the root cause before choosing how to break it.

---

### Refactor safely behind a passing test net
**When to use:** You want to restructure code that has thin or no test coverage, without changing behaviour.
**Prompt:**
> Before refactoring [FILE], write characterisation tests that capture its current behaviour, including the awkward edge cases. Run them to confirm they pass against the code as it is now. Then perform the refactor and rerun the same tests unchanged to prove behaviour is preserved.
**Tip:** This is the safest order for risky refactors. Pair with `/mutation-gate` afterwards to confirm the net actually catches regressions.
