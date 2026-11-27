# Documentation Recipes

Claude Code writes documentation that is actually accurate because it reads the code first. That is the whole trick: point it at the real thing, ask it to document what is there, and it will not invent an API that does not exist. These recipes cover the docs worth keeping current.

---

### Write a README for a project or module
**When to use:** A project or package has no README, or one that no longer matches reality.
**Prompt:**
> Write a README for [PROJECT or MODULE]. Read the code first, then cover: what it does, how to install and run it, the main usage examples with real snippets that would actually work, configuration, and how to run the tests. Keep it concise and accurate. Do not document features that do not exist in the code.
**Tip:** Ask Claude to derive the usage examples from actual entry points and tests, so the snippets are copy-paste correct rather than plausible-looking.

---

### Document an API from the code
**When to use:** You have endpoints or a public interface that needs reference documentation.
**Prompt:**
> Document the API defined in [FILES or DIRECTORY]. For each endpoint or public function, read the implementation and record the exact signature, parameters, return shape, error cases, and a realistic example. Do not guess at behaviour, if something is unclear from the code, flag it rather than inventing it.
**Tip:** The flag-if-unclear clause is what keeps API docs honest. Anything Claude flags is usually a spot where the code itself is ambiguous and worth a comment.

---

### Create or update the project's CLAUDE.md
**When to use:** You want future Claude Code sessions to understand this codebase without re-explaining it.
**Prompt:**
> Read this codebase and write (or update) the CLAUDE.md so a fresh Claude Code session can be productive immediately. Cover: what the project is, the stack, how to run and test it, the key directories, the naming and structure conventions, and the gotchas that are not obvious from the code. Keep it factual and skimmable.
**Tip:** A strong CLAUDE.md is the single highest-leverage doc in this whole library. Every other recipe works better when Claude can read one at the start of the session.

---

### Write an architecture overview
**When to use:** A new contributor (or you in six months) needs the big picture of how the system fits together.
**Prompt:**
> Write an architecture overview of this system. Read the code to map the major components, how data flows between them, the key external dependencies, and the important design decisions. Explain the why behind the structure where you can infer it. Include a simple text diagram of the main components and their relationships.
**Tip:** Ask for the flow described in terms of a single real request or job moving through the system. Concrete beats abstract for helping someone build a mental model.

---

### Add explanatory comments to dense code
**When to use:** A section of code is correct but hard to follow, and you want it explained in place.
**Prompt:**
> Add comments to [FILE:FUNCTION] that explain the non-obvious parts: why it does what it does, the assumptions it relies on, and any subtle edge case handling. Do not add noise comments that just restate the code. Do not change any behaviour, comments only.
**Tip:** Good comments explain why, not what. Ask Claude to skip anything a reader could get from the code itself, so the comments that remain earn their place.

---

### Write a docstring for every public symbol in a file
**When to use:** A file's public functions or classes lack docstrings and you want them documented consistently.
**Prompt:**
> Add docstrings to every public function and class in [FILE], following the docstring style already used in this repo. Read each implementation so the docstring is accurate: describe purpose, parameters, return value, and raised errors. Do not document private helpers unless they are genuinely confusing.
**Tip:** Consistency matters more than completeness here. Ask Claude to match an existing well-documented file so the style stays uniform across the codebase.

---

### Turn a hard-won fix into a knowledge-base entry
**When to use:** You solved a tricky problem and want the lesson captured so it is not re-learned.
**Prompt:**
> We just solved [PROBLEM]. Write a short, factual entry capturing the lesson: what the symptom was, the root cause, the fix, and the rule that would prevent it next time. Keep it to a few lines and make the rule actionable. This is going into the project's knowledge base.
**Tip:** Claudify's knowledge base requires each entry to carry a source and stay concise. Keep the entry tight and cite the incident, so the `auditor` can promote it cleanly.

---

### Document a runbook for an operational task
**When to use:** There is a manual procedure (deploy, recovery, data fix) that should be written down.
**Prompt:**
> Write a runbook for [TASK]. Read whatever scripts or config are involved, then lay it out as numbered steps someone could follow under pressure: preconditions, the exact commands, what success looks like at each step, and what to do if a step fails. Include how to roll back. Be precise, no hand-waving.
**Tip:** A runbook is read by a stressed person at a bad moment. Ask Claude to include the rollback and the failure branch at each step, not just the happy path.
