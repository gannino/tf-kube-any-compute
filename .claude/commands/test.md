---
description: Write focused tests for a change, then run them to prove they pass - PASS/FAIL with real evidence
argument-hint: "[file or path to test, or blank for the current change]"
allowed-tools:
  - Read
  - Agent
  - Glob
  - Grep
  - Bash(git diff:*, git log:*, git status:*, git show:*)
---

**Spawn synchronously:** every Agent/Task spawn in this procedure must pass `run_in_background: false`. Subagents default to background since Claude Code 2.1.198; this command consumes each subagent verdict before its next step, so a background spawn would race the verdict.

Write-and-prove testing. Hands the current change (or a named file) to the test-writer agent, which detects the stack, matches the project's existing test conventions, and writes happy-path, edge-case, and error-case tests for what changed, then routes to the verifier to run them and report PASS/FAIL with the real command output. This is the write-side counterpart to `/verify`: verify runs what exists, test creates the coverage first and then proves it.

## Steps

### Step 1: Determine what to test

Identify the change to cover:
- If the user named a file or path → write tests for that
- If nothing specified → test the current uncommitted change (`git diff` + `git diff --cached`), falling back to the most recent commit (`git show --stat HEAD`)
- Note the expected behaviour if the user gave it. If not, the test-writer infers it from the change and the surrounding code and carries that assumption forward, so the tests pin the right behaviour.

### Step 2: Hand off to the test-writer agent

Spawn the `test-writer` subagent with:
- The change scope from Step 1 (the diff, file list, or path)
- The expected behaviour (stated or inferred)
- Any specific path the user wants covered

The test-writer owns the actual writing. It will:
1. **Detect the stack and test framework** from the manifests present (package.json scripts and deps, pyproject.toml / pytest, go.mod, Cargo.toml, Makefile, and more) rather than assuming, and never introduce a new framework.
2. **Read the neighbouring existing tests first** and mirror them: same layout, naming, assertion style, and fixture/mock patterns, so the new tests look native to the suite.
3. **Write tests across three angles**: happy path, edge cases (empty / null / boundary / max), and error / failure cases (bad or hostile input is rejected the way it should be).
4. **Confirm the new tests run** with the one-shot / CI form of the runner, scoped to the new tests for a fast signal.

### Step 3: Enforce the boundaries

Two hard lines the test-writer holds, confirm both in the result:
- **It never weakens the safety net.** No existing test is deleted, skipped, loosened, or commented out to make a suite go green. If an existing test conflicts with the change, it is flagged, not neutered.
- **It never edits the code under test to force a pass.** If a correct new test fails, the code is broken, that is a finding to surface, not a test to bend.

A test that can never fail is not a test. Reject any test whose assertion holds no matter what the code does, it buys false confidence and is worse than no test.

### Step 4: Route to the verifier for the PASS/FAIL

The test-writer confirms the new tests execute, the `verifier` agent proves the change passes. The test-writer hands off to the verifier with the new test files, the detected run command, and the expected behaviour. The verifier runs the project's tests (falling back to build / typecheck / lint honestly if needed) and returns the verdict backed by real output. A PASS is only valid with the command and its output behind it, reject any "looks covered" with no run.

### Step 5: Report

Present the combined result:

```markdown
## Tests, [change covered]

**Verdict:** PASS | FAIL | PARTIAL
**Stack:** [detected stack + framework, e.g. Node + TypeScript (pnpm), Vitest]
**Convention matched:** [the existing test file mirrored, or "no existing tests, framework idiom"]

### Tests Added
| File | New / Updated | Cases |
|---|---|---|
| `[path]` | [new/updated] | [n happy, n edge, n error] |

### Coverage of This Change
[What the new tests pin down about the change, by angle, tied back to what changed.]

### Commands Run
| Command | Exit | Result |
|---|---|---|
| `[command]` | [0/N] | [one-line outcome] |

### Evidence
[The actual test output that proves the verdict, trimmed to the lines that matter: the new
tests collected, the pass/fail summary, any failing test name. No evidence means no PASS.]

### Not Covered
[Honest scope: angles that did not apply, behaviour needing integration/e2e, the other stack
not touched, paths not exercisable without destructive operations. Always present, even on a pass.]

### Verdict Rationale
[One sentence. On FAIL: whether a test caught a real defect or a test itself needs fixing, plus
the command to reproduce. On PASS: the change is covered and green, or the one manual check left.]
```

### Step 6: Offer the next move

- On **FAIL** where a test caught a real defect: name the broken behaviour and ask "Want me to hand the failing output to the `error-whisperer` agent to diagnose and fix the code?"
- On **PARTIAL**: name the missing coverage (the angle skipped, the integration path) and ask whether to widen it.
- On **PASS**: state it plainly and stop. Optionally suggest `/mutation-gate` to prove the new tests would actually catch injected bugs, not just run green.
