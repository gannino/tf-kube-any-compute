---
description: Prove a change works by running the project, not by reading it - PASS/FAIL with real evidence
argument-hint: "[the change, branch, or feature to verify]"
allowed-tools:
  - Read
  - Agent
  - Glob
  - Grep
  - Bash(git diff:*, git log:*, git status:*, git show:*)
---

**Spawn synchronously:** every Agent/Task spawn in this procedure must pass `run_in_background: false`. Subagents default to background since Claude Code 2.1.198; this command consumes each subagent verdict before its next step, so a background spawn would race the verdict.

Run-it-and-prove-it verification. Detects the project's stack, runs the relevant tests, build, typecheck, or lint, observes the ACTUAL behaviour, and reports PASS/FAIL with the real command output as evidence. This is the counterpart to `/review`: review reads the code, verify runs it.

## Steps

### Step 1: Determine what to verify

Identify the change under test:
- If the user named a file, branch, PR, or feature → verify that
- If nothing specified → verify the current uncommitted change (`git diff` + `git diff --cached`), falling back to the most recent commit (`git show --stat HEAD`)
- Note the expected behaviour if the user gave it. If not, infer it from the diff and the project's tests, and carry that assumption forward so the verifier checks against the right thing.

### Step 2: Hand off to the verifier agent

Spawn the `verifier` subagent with:
- The change scope from Step 1 (the diff, file list, or branch)
- The expected behaviour (stated or inferred)
- Any verify command the user already knows works

The verifier owns the actual running. It will:
1. **Detect the stack** from the manifests present (package.json scripts, pyproject.toml / pytest, go.mod, Cargo.toml, Makefile, and more) rather than assuming.
2. **Establish a runnable state** (confirm deps are installed; run a cheap, non-destructive install only if clearly needed).
3. **Run and observe** the highest-value checks first (tests, then build, then typecheck, then lint), capturing the real exit code and output.
4. **Fall back honestly** if no tests exist (build → typecheck → lint → syntax-check) and state the level reached.

### Step 3: Enforce the safety boundary

The verifier runs tests, build, typecheck, and lint ONLY. Confirm nothing in the verification path deploys, pushes, migrates, seeds, mutates data, or hits production. If proving this particular change would require any of those, the verifier stops and reports that the change cannot be safely auto-verified, and names the manual step a human must take instead. A blocked verification is an honest outcome, not a failure to force past.

### Step 4: Demand evidence

A PASS is only valid if backed by real command output. Reject any "looks correct" verdict that has no command behind it. Every result the verifier returns must carry:
- The exact command(s) run and their exit codes
- The actual output lines that prove the verdict (pass/fail summary, failing test names, build result, error text)
- A scope statement of what was NOT exercised

### Step 5: Report

Present the verifier's result:

```markdown
## Verification, [change verified]

**Verdict:** PASS | FAIL | PARTIAL
**Stack:** [detected stack, e.g. Node + TypeScript (pnpm)]
**Level:** [tests | build | typecheck | lint | syntax-check], [why this level was the bar]

### Commands Run
| Command | Exit | Result |
|---|---|---|
| `[command]` | [0/N] | [one-line outcome] |

### Evidence
[The actual output that proves the verdict, copied verbatim and trimmed to the lines that
matter, failing test names, the summary line, the build result. No evidence means no PASS.]

### Not Verified
[What was out of scope: the stack not touched, runtime behaviour not observed, integration/e2e
not run, "no test suite so behaviour is unproven beyond build". Always present, even on a pass.]

### Verdict Rationale
[One sentence. On FAIL: the likely culprit + the command to reproduce. On PASS: safe to proceed,
or the one manual check a human should still do.]
```

### Step 6: Offer the next move

- On **FAIL**: ask "Want me to hand the failing output to the `error-whisperer` agent to diagnose and fix it?"
- On **PARTIAL**: name the missing coverage and ask whether to verify deeper (e.g. run the other stack, or exercise runtime behaviour).
- On **PASS**: state it plainly and stop. Do not gild a clean result.
