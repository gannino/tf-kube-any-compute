# Debugging Recipes

Claude Code is strong at debugging because it can reproduce the problem by running commands, read across the whole call chain to find the real cause, and prove the fix by rerunning the failing case. Give it the symptom and let it work backwards to the cause rather than guessing forwards.

---

### Reproduce and root-cause a bug
**When to use:** Something is broken and you want the actual cause, not a patch over the symptom.
**Prompt:**
> Here is the bug: [SYMPTOM], which happens when [STEPS]. First reproduce it by running the relevant code or a small test. Then trace the failure to its root cause, reading the full call chain rather than guessing. Explain the cause before you fix anything, then fix it and prove the fix by rerunning the reproduction.
**Tip:** Insisting on a reproduction first stops Claude patching a symptom. If it cannot reproduce, that is itself the finding, and worth knowing.

---

### Read a stack trace and fix the cause
**When to use:** You have an error and a stack trace and want it resolved.
**Prompt:**
> This error is being thrown: [PASTE ERROR AND STACK TRACE]. Read the trace, find the line that actually causes it (not just where it surfaces), explain why it happens, and fix the underlying cause. Then run the code path that produced it to confirm the error is gone. Check whether the same mistake exists elsewhere in the repo.
**Tip:** The last clause matters: one stack trace is often one instance of a pattern. Ask Claude to grep for siblings so you fix the class, not the case.

---

### Debug an intermittent or flaky failure
**When to use:** A test or behaviour fails sometimes and passes other times.
**Prompt:**
> [TEST or BEHAVIOUR] fails intermittently. Investigate the usual causes of flakiness: shared state between runs, timing and race conditions, ordering dependence, unmocked clocks or randomness, and external calls. Identify which one applies here with evidence, then fix it so the outcome is deterministic. Run it several times to confirm it is stable.
**Tip:** Ask Claude to run the case in a loop to confirm the fix held. Flaky bugs are only fixed once you have seen them pass repeatedly.

---

### Bisect to find the commit that broke it
**When to use:** Something worked before and you do not know which change broke it.
**Prompt:**
> [BEHAVIOUR] worked at [KNOWN_GOOD_REF] and is broken now. Use git history to narrow down which commit introduced the break: check the log for suspicious changes in the relevant files, and if useful run a bisect against a test that captures the failure. Report the offending commit and what in it caused the regression.
**Tip:** If you can express the failure as a one-line command that exits non-zero, Claude can drive `git bisect run` with it and find the commit automatically.

---

### Diagnose a production issue from logs
**When to use:** Something is failing in production and you have logs but no local repro.
**Prompt:**
> Here are the production logs around the failure: [PASTE LOGS]. Work out what is happening: which code path produced these lines, what state would cause this, and the most likely root cause. Rank the hypotheses by likelihood, tell me what single piece of evidence would confirm the top one, and propose the safest fix.
**Tip:** Ranked hypotheses plus the one confirming check is faster than a blind fix. Confirm the cause before you change production code.

---

### Fix a performance problem
**When to use:** Something is slow and you want it faster without guessing.
**Prompt:**
> [OPERATION] is slow. Find out why with evidence rather than intuition: look for N+1 queries, work done in loops that could be hoisted, missing indexes, repeated I/O, or unnecessary re-computation. Measure before and after where you can. Fix the biggest cause first and tell me the expected impact of each change.
**Tip:** Ask for the measurement, not just the claim. A change that is meant to help but ships without a before-and-after is a guess wearing a diff.

---

### Explain code that is behaving mysteriously
**When to use:** You do not understand why a piece of code does what it does.
**Prompt:**
> Explain exactly what [FILE:FUNCTION] does and why it produces [OBSERVED_BEHAVIOUR]. Walk through it step by step with a concrete example input, show the value at each stage, and point out the specific line where the surprising thing happens. Do not fix anything yet, I want to understand it first.
**Tip:** Understanding before fixing prevents the confident wrong fix. Once the mechanism is clear, ask for the change as a separate step.

---

### Debug when you are properly stuck
**When to use:** You have been fighting a problem for a while and are out of ideas.
**Prompt:**
> I have been stuck on this for a while: [PROBLEM]. Here is what I have already tried and ruled out: [ATTEMPTS]. Challenge my assumptions, name what I have not questioned yet, and give me three genuinely different angles of attack ranked by likelihood of working. Start with the one you would try first and why.
**Tip:** This is what `/unstick` runs. Use the command to get a fresh subagent that has not absorbed your dead ends, so it can question the assumption you cannot see past.
