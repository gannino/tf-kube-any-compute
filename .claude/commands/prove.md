---
description: Force the loop closed on a completion claim - run the verifier and report real PASS/FAIL with command evidence, or say honestly what could not be verified
argument-hint: "[the claim to prove, or blank for the most recent one]"
allowed-tools:
  - Read
  - Agent
  - Glob
  - Grep
  - Bash(git diff:*, git log:*, git status:*, git show:*, tail:*, cat:*)
---

**Spawn synchronously:** every Agent/Task spawn in this procedure must pass `run_in_background: false`. Subagents default to background since Claude Code 2.1.198; this command consumes each subagent verdict before its next step, so a background spawn would race the verdict.

Turn a "done" into proof. When a turn claims work is finished ("tests pass", "deployed", "the bug is fixed", "migration applied", "all green", "build succeeds"), `/prove` makes the claim earn it: it hands the claim to the `verifier` agent, which runs the project and reports PASS or FAIL backed by real command output, or states plainly what could not be verified.

This is the active counterpart to the `claim-check` hook. The hook is advisory and passive: at a turn boundary it flags a completion claim that has no backing evidence in the transcript, but it cannot block and it does not run anything. `/prove` is what you run to actually close that loop. It reuses the same verification philosophy as `/verify` ("No evidence, no pass"), pointed specifically at the most recent claim.

**Honest framing, state it in the output:** proving a claim REDUCES fabricated "done", it does not guarantee the change is correct. A green test run proves a command ran and passed, not that the behaviour is what the user actually wanted. Report what was proven and what remains a human judgement.

## Steps

### Step 1: Identify the claim under test

Find the specific completion claim to prove, in this order:

1. **The user named one** in the argument (e.g. `/prove the auth tests`) -> prove that.
2. **The `claim-check` hook flagged one this session.** Read the tail of `.claude/logs/claim-check.jsonl` if it exists. The most recent row with `"status":"unverified"` names the claim class(es) (`tests`, `build`, `deploy`, `migrate`, `fix`). Use that as the claim.
   ```bash
   tail -5 .claude/logs/claim-check.jsonl 2>/dev/null
   ```
3. **Nothing flagged, nothing named:** take the most recent completion claim from the conversation itself (the assistant's last assertion that work is done). If there is genuinely no completion claim to prove, say so and stop. Do not invent one.

State the claim you are about to prove in one line before proceeding, and name the claim class so the verifier knows what evidence to demand:
- `tests` -> a test runner must run and pass
- `build` -> the build/compile must succeed
- `deploy` -> the deploy is NOT auto-runnable (see Step 3); confirm via artefacts/logs only
- `migrate` -> the migration is NOT auto-runnable; confirm via status/logs only
- `fix` -> the relevant test or behaviour must demonstrably pass now

### Step 2: Hand off to the verifier agent

Spawn the `verifier` subagent with:
- **The claim** from Step 1 (verbatim) and its class.
- **The scope:** the files or area the claim is about. Derive it from the current diff (`git diff` + `git diff --cached`, falling back to `git show --stat HEAD`) so the verifier runs the tests nearest the change first.
- **The expected behaviour:** what "working" means for this claim. If the user stated it, pass it through. If not, infer it from the diff and the project's tests and tell the verifier the assumption it is checking against.

The verifier owns the running. It will detect the stack from the manifests present, establish a runnable state, run the highest-value checks first (tests, then build, then typecheck, then lint), capture the real exit codes and output, and fall back honestly to build/typecheck/lint/syntax-check if no test suite exists, stating the level it reached.

### Step 3: Hold the safety boundary

The verifier runs tests, build, typecheck, and lint ONLY. It never deploys, pushes, migrates, seeds, mutates data, or hits production.

This matters most for the `deploy` and `migrate` claim classes: those cannot be re-run safely to prove them. Do NOT attempt to re-deploy or re-run a migration to "check". Instead prove them from evidence that already exists, read-only:
- **deploy:** a deploy command in the session's command history with its success output, a CI/CD run reference, the live artefact, or a git push to the deploy branch. If none exists, the claim is UNPROVEN, report that plainly.
- **migrate:** a migration-status/list command (read-only) showing the migration as applied, or the migration command's recorded success output. If the only way to check would mutate the database, stop and name the manual step a human must take.

A claim that cannot be safely auto-proven is an honest UNPROVEN outcome, not a failure to force past.

### Step 4: Demand evidence

Accept a PASS only when it is backed by real command output. Reject any "looks correct" reasoning that has no command behind it. The verifier's result must carry the exact commands run, their exit codes, and the output lines that prove the verdict.

### Step 5: Report

Present the result. On a clean pass, do not gild it.

```markdown
## Proof, [claim proven]

**Claim under test:** [the exact claim + class]
**Verdict:** PROVEN | DISPROVEN | UNPROVEN
**Stack:** [detected stack]
**Level:** [tests | build | typecheck | lint | syntax-check | read-only evidence], [why this was the bar]

### Commands Run
| Command | Exit | Result |
|---|---|---|
| `[command]` | [0/N] | [one-line outcome] |

### Evidence
[The actual output that backs the verdict, copied verbatim and trimmed to the lines that
matter, the pass/fail summary, failing test names, the build result, the deploy/migration
status line. No evidence means no PROVEN.]

### Not Proven
[What this did NOT establish: behaviour vs intent, the stack not exercised, integration/e2e
not run, "deploy confirmed only from the push log, not from hitting the live endpoint".
Always present, even on a clean pass, because proof of a passing command is not proof of
correctness.]

### Verdict Rationale
[One sentence. On DISPROVEN: the failing command + how to reproduce. On UNPROVEN: exactly
why it could not be safely verified and the one manual step that would. On PROVEN: safe to
trust this claim, with the residual human check if any.]
```

### Step 6: Offer the next move

- On **DISPROVEN**: the original "done" was fabricated or premature. Offer to hand the failing output to the `error-whisperer` agent, or fix it, then re-run `/prove`.
- On **UNPROVEN**: name the one manual step a human must take (run the migration in a safe env, hit the deployed URL) and stop.
- On **PROVEN**: state it plainly. The claim is now backed by evidence the model could not author itself.
