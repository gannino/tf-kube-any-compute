---
description: Run mutation testing on changed files - reports the mutation SCORE and surviving mutants, PASS/FAIL on a threshold
argument-hint: "[file or path to mutate, or blank for the current change]"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash(git diff:*, git log:*, git status:*, git show:*, git merge-base:*)
  - Bash(npx stryker:*, npx @stryker-mutator/core:*, stryker:*)
  - Bash(mutmut:*, cosmic-ray:*, cr-report:*)
  - Bash(mvn:*, ./gradlew:*)
  - Bash(cargo mutants:*, cargo-mutants:*)
  - Bash(infection:*, vendor/bin/infection:*, php:*)
  - Bash(cat:*, ls:*, find:*, head:*, tail:*, grep:*, wc:*)
---

**Spawn synchronously:** every Agent/Task spawn in this procedure must pass `run_in_background: false`. Subagents default to background since Claude Code 2.1.198; this command consumes each subagent verdict before its next step, so a background spawn would race the verdict.

Mutation testing scoped to what changed. Coverage tells you a line ran; it does not tell you a test would notice if that line broke. Mutation testing settles it: it injects small bugs (mutants) into your code and reruns the tests. A mutant the tests kill is a bug they would catch. A mutant that survives is a bug they would miss, a hole in the suite even at high coverage. This command detects the project's mutation tester, runs it against the changed files only (mutation testing is slow, so scope is everything), reports the mutation SCORE, lists the surviving mutants, and gives a PASS/FAIL against a threshold.

**Why mutation score beats coverage:** coverage answers "did the test execute this line?" Mutation score answers "would the test FAIL if this line were wrong?" Those are different questions, and only the second is what you actually want from a test. The gap is large and well-documented: LLM-generated tests routinely hit high line coverage while scoring around 20% on mutation, meaning roughly four out of five injected bugs survive untouched. Tests that run the code but assert nothing meaningful (tautological or weak assertions) are exactly what a mutation score exposes and a coverage number hides.

## Steps

### Step 1: Determine the changed files to mutate

Scope tightly, mutation runs are expensive:
- If the user named a file or path → mutate exactly that.
- If nothing specified → mutate the files in the current change. Get them from git:

```bash
# Changed source files, staged and unstaged, against the working tree
git diff HEAD --name-only
git diff --cached --name-only
# If reviewing a branch before a PR, diff against the base
git merge-base HEAD main >/dev/null 2>&1 && git diff $(git merge-base HEAD main)...HEAD --name-only
```

Filter to source files for the detected stack and drop test files, config, and generated code, you mutate the code under test, not the tests. If the change touches no mutatable source, say so and stop.

### Step 2: Detect the stack and its mutation tester

Identify the stack from the manifests present (the same signal files the verifier and test-writer use), then map to the matching mutation tester:

| Signal file | Stack | Mutation tester | Detect it is installed |
|---|---|---|---|
| `package.json` | JS / TS | **Stryker** | `stryker.conf.*` present, or `@stryker-mutator/core` in deps, or `npx stryker --version` |
| `pyproject.toml` / `setup.cfg` / `pytest.ini` | Python | **mutmut** (or **cosmic-ray**) | `mutmut --version`, or `cosmic-ray --help`; a `[tool.mutmut]` / cosmic-ray config block |
| `pom.xml` / `build.gradle` | Java / Kotlin | **PITest** | the `pitest` plugin in the build file, or `mvn org.pitest:pitest-maven:mutationCoverage` resolves |
| `Cargo.toml` | Rust | **cargo-mutants** | `cargo mutants --version` |
| `composer.json` | PHP | **Infection** | `infection.json*` present, or `vendor/bin/infection --version` |

Read the manifest to confirm the language. Then probe whether the tester is actually installed (the version / help check in the right column), do not assume it is present.

### Step 3: Run the mutator on the changed files only

Run with the file scope from Step 1. Always constrain to the changed files, never mutate the whole project. Use each tool's scoping flag:

- **Stryker (JS/TS):** `npx stryker run --mutate "<changed-glob>"` (pass the changed source paths to `--mutate`).
- **mutmut (Python):** `mutmut run --paths-to-mutate <changed-files>`, then `mutmut results` for survivors. (cosmic-ray: init a session over the changed module, `exec`, then `cr-report`.)
- **PITest (Java/Kotlin):** the `mutationCoverage` goal with `-DtargetClasses=<changed classes>` (and `-DtargetTests` if you can narrow the tests).
- **cargo-mutants (Rust):** `cargo mutants --file <changed-file>` (repeat or pass each changed file).
- **Infection (PHP):** `vendor/bin/infection --filter=<changed-files>` (or `--git-diff-filter=AM` to let Infection scope to the diff itself).

Set a sensible timeout, mutation runs can be long even when scoped. Capture the real output, you need the mutation score and the surviving-mutant list from it.

### Step 4: Degrade gracefully when no mutator is installed

If Step 2 finds no mutation tester installed for the detected stack, do NOT fail and do NOT block. This command is a gate when the tool exists and a recommendation when it does not. Report the detected stack, name the right mutator, and give the one-line install and run so the user can adopt it:

| Stack | Install | First run (changed files) |
|---|---|---|
| JS / TS | `npm i -D @stryker-mutator/core` then `npx stryker init` | `npx stryker run --mutate "<changed files>"` |
| Python | `pip install mutmut` | `mutmut run --paths-to-mutate <changed files>` |
| Java / Kotlin | add the `pitest` plugin to the build file | `mvn org.pitest:pitest-maven:mutationCoverage -DtargetClasses=<changed>` |
| Rust | `cargo install cargo-mutants` | `cargo mutants --file <changed file>` |
| PHP | `composer require --dev infection/infection` | `vendor/bin/infection --git-diff-filter=AM` |

State clearly that this run is a recommendation, not a verdict, because the tooling is not present yet. That is an honest outcome, not a failure.

### Step 5: Report the score, the survivors, and the verdict

The mutation SCORE is the headline (killed mutants over total mutants), not a coverage percentage. List the surviving mutants by `file:line` with the mutation that survived, each survivor is a concrete weak spot: a test that ran the code but would not have caught that change. Give the verdict against the threshold (default 80, configurable, the user can name a different bar):

```markdown
## Mutation Gate, [files mutated]

**Verdict:** PASS | FAIL | NOT RUN (mutator not installed)
**Stack:** [detected stack, e.g. TypeScript, Stryker]
**Scope:** [the changed files mutated]
**Mutation score:** [killed]/[total] = [N]% (threshold: [T]%)

### Surviving Mutants (tests would NOT catch these)
| Location | Mutation that survived | What it means |
|---|---|---|
| `file:line` | [e.g. `>` changed to `>=`, the boundary] | [the test exercises this line but asserts nothing that pins it] |

### Killed (caught)
[killed]/[total] mutants were caught, the tests would notice these bugs.

### Verdict Rationale
[One sentence. On FAIL: which survivors matter most and that they mark tautological or
under-asserting tests to strengthen. On PASS: the suite would catch injected bugs in this
change, not merely run the lines. On NOT RUN: the mutator to install, from Step 4.]
```

### Step 6: Offer the next move

- On **FAIL** (score below threshold): point at the surviving mutants and offer to strengthen the weak tests, the fix is almost always a real assertion where the test currently runs the code but checks nothing meaningful. `/test` can write the missing cases.
- On **PASS**: state it plainly and stop. The tests do not just execute the change, they would catch it breaking.
- On **NOT RUN**: leave the install recommendation from Step 4 and do not block, the change is not gated by a tool the project has not adopted.
