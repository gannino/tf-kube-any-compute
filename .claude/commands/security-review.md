---
description: Adversarial read-only security pass over your git diff - severity-ranked findings with file:line and a concrete fix
argument-hint: "[the change, branch, or files to review]"
allowed-tools:
  - Read
  - Agent
  - Glob
  - Grep
  - Bash(git diff:*, git log:*, git status:*, git show:*)
---

**Spawn synchronously:** every Agent/Task spawn in this procedure must pass `run_in_background: false`. Subagents default to background since Claude Code 2.1.198; this command consumes each subagent verdict before its next step, so a background spawn would race the verdict.

Read-only adversarial security review of a change set. Reads your uncommitted diff and the changed files, traces untrusted input to dangerous sinks, and reports real, exploitable findings ranked by severity, each with an exact file:line and a concrete fix. This is the security counterpart to `/review`: review judges quality, this hunts for the hole an attacker would use.

## Steps

### Step 1: Establish the change set

Identify what to review:
- If the user named files, a branch, or a PR -> review that
- If nothing is specified -> review the current uncommitted change (`git diff HEAD`), falling back to staged-only (`git diff --cached`) or the most recent commit (`git show HEAD`)
- If there is no diff and no git repo, say so and stop. There is nothing to review, do not scan the whole codebase uninvited.

### Step 2: Hand off to the security-review agent

Spawn the `security-review` subagent with the change scope from Step 1. The agent owns the actual review. It will:
1. Read the full diff and the changed files for context (a hunk out of context cannot tell you whether input is tainted or already validated).
2. Hunt by vulnerability class: injection (SQL / command / XSS / template), broken authn/authz including IDOR, secret leakage, unsafe deserialization, path traversal, SSRF, missing input validation, and weak crypto.
3. Gate every finding on the taint-chain test: a named untrusted Source, the exact dangerous Sink at a `file:line`, and the concrete Impact. No chain, no finding.

### Step 3: Enforce the read-only boundary

The agent holds no Write or Edit tool by design. It diagnoses and prescribes, it never modifies the code under review. A security pass that edits the very code it reports on cannot be trusted to report on it honestly. Confirm the verdict is a report, and that you, not the agent, apply any fix.

### Step 4: Demand a real taint chain

Reject noise. A valid finding names the untrusted input, traces it to the sink, and states what an attacker achieves. Reject any "consider security here" or "this might be unsafe" with no proven path. Equally, reject a silent pass on a diff that adds an unauthenticated route or sends user input to a shell. Every finding must carry:
- An exact `file:line` and the vulnerability class
- The Source -> Sink -> Impact chain
- A concrete, code-level fix

### Step 5: Report

Present the agent's verdict, ordered Critical -> High -> Medium -> Low:

```markdown
## Security Review: [N files, M findings]

**Scope:** `git diff HEAD` across [changed files]
**Verdict:** BLOCK | REVIEW | PASS
**Findings:** Critical: [n] · High: [n] · Medium: [n] · Low: [n]

### [SEVERITY] [Title]
**Location:** `file:line` · **Class:** [class]
**Taint chain:** Source -> Sink -> Impact
**Evidence:** [the vulnerable line(s)]
**Fix:** [concrete corrected code + one line on why it closes the hole]
```

On a clean diff, the agent returns PASS and names what it actually traced. It does not invent Low findings to look diligent. A trustworthy "no issues found" is the product.

### Step 6: Offer the next move

- On **BLOCK** (any Critical or High finding): list the must-fix findings and offer to apply the prescribed fixes one by one, then re-run `/security-review` to confirm each hole is closed.
- On **REVIEW** (Medium / Low only): summarise the judgment calls and let the developer decide what to harden before shipping.
- On **PASS**: state it plainly and stop. Note that the pass covers the diff only, not pre-existing code in untouched files.
