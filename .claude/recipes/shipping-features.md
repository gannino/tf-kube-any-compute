# Shipping Features Recipes

The reliable way to ship a feature with Claude Code is: make it plan first, approve the plan, then let it build across all the files at once and prove the result. These recipes force that order so you get working software, not a hopeful draft.

---

### Plan a feature before writing any code
**When to use:** You are about to build something non-trivial and want a plan you can approve first.
**Prompt:**
> I want to add [FEATURE]. Do not write any code yet. Read the relevant parts of the codebase, then give me an implementation plan: which files you will create or change, the data flow, the edge cases you will handle, and how you will test it. Flag anything you are unsure about. I will approve or adjust the plan before you start.
**Tip:** Approving a plan is the cheapest place to catch a wrong assumption. For anything touching a production system, keep the plan and check it against the ten-step pre-ship audit before you say go.

---

### Build the feature end to end
**When to use:** The plan is agreed and you want it built and wired up completely.
**Prompt:**
> Implement [FEATURE] per the plan we agreed. Create and edit every file needed, wire it into [ENTRY_POINT], handle the edge cases we listed, and add tests. When you are done, run the tests and the build, and tell me exactly what to do to see it working.
**Tip:** End with `/verify` so Claude actually runs the app and confirms the feature behaves, rather than reporting that the code compiles.

---

### Add an endpoint or route
**When to use:** You need a new API endpoint or page route wired into the existing app.
**Prompt:**
> Add a new [HTTP_METHOD] endpoint at [ROUTE] that [DOES_WHAT]. Follow the existing pattern used by [SIMILAR_ROUTE] for validation, error handling, and response shape. Wire it into the router, add the types, and write a test that hits it with a valid and an invalid request. Run the test.
**Tip:** Pointing Claude at a similar existing route is the strongest hint you can give. It will copy your conventions instead of inventing new ones.

---

### Wire a feature behind a flag
**When to use:** You want to ship the code but keep it dark until you are ready.
**Prompt:**
> Implement [FEATURE] behind a feature flag named [FLAG_NAME], defaulting to off. Make sure every entry point checks the flag, the off state is the current behaviour exactly, and the on state is the new behaviour. Add a test for both states. Confirm the off path is untouched by running the existing tests.
**Tip:** Ask Claude to confirm the flag-off path produces byte-identical behaviour to today. A flag that subtly changes the default is worse than no flag.

---

### Integrate a third-party library
**When to use:** You are adding a dependency and want it wired in correctly the first time.
**Prompt:**
> Integrate [LIBRARY] to handle [PURPOSE]. Check its current documentation for the version compatible with my lockfile, add it as a dependency, and wire it in following its recommended setup. Isolate it behind a thin wrapper in [PATH] so the rest of the code does not depend on it directly. Add a test and run it.
**Tip:** The wrapper matters: it means swapping the library later is a one-file change. Ask Claude to keep the integration surface small on purpose.

---

### Add a database migration and the code that uses it
**When to use:** The feature needs a schema change plus the code that reads and writes it.
**Prompt:**
> Add a migration that [SCHEMA_CHANGE], following the migration pattern already in this repo. Then update the models, queries, and any types that touch the changed tables. Make the migration reversible. Do not run it against any real database. Show me the migration file and the code changes, and tell me the exact command to apply it locally.
**Tip:** Never let a migration auto-apply to a shared database. Review the SQL yourself, then run `/security-review` if the tables hold user data.

---

### Ship a small feature in parallel with subagents
**When to use:** A feature has independent parts (backend, frontend, tests) that can be worked separately.
**Prompt:**
> Break [FEATURE] into independent workstreams that do not share files, then use subagents to build them in parallel: one for the backend change, one for the UI, one for the tests. Integrate the results, resolve any interface mismatches yourself, and run the full suite to confirm the pieces fit together.
**Tip:** Only parallelise parts that touch different files. If two streams edit the same file, do them in sequence instead to avoid clobbering.

---

### Ship a risky change in an isolated worktree
**When to use:** The change is large or experimental and you do not want it touching your main working tree.
**Prompt:**
> Set up a git worktree for a branch named [BRANCH_NAME] and do all the work for [FEATURE] there, leaving my current working tree untouched. Build it, test it, and when it passes, tell me how to bring it back into my main branch. Keep the worktree self-contained.
**Tip:** Worktrees are ideal for spiking an idea you might throw away. If it does not work out, the mess is quarantined and easy to delete.

---

### Finish a half-built feature
**When to use:** Something was started, left incomplete, and you want it finished properly.
**Prompt:**
> The feature [FEATURE] in [FILES] is half-built. Read what exists, work out what is done and what is missing against the intended behaviour [DESCRIPTION], then complete it: finish the missing pieces, handle the edge cases the draft skipped, add tests, and run them. Tell me what the original author left undone.
**Tip:** Ask for the done-versus-missing breakdown before Claude writes anything. Half-built code often hides a decision the original author was stuck on.
