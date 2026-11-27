# Testing Recipes

Tests are only worth writing if you run them and they actually catch bugs. Claude Code can write focused tests, run them, and then check that they fail when the code is broken. These recipes keep the loop closed so you end up with a suite that earns its keep.

---

### Write and run tests for a change
**When to use:** You just wrote or changed code and want tests that prove it works.
**Prompt:**
> Write focused tests for the change in [FILE or the current diff]. Cover the happy path, the boundaries, and the error cases that actually matter. Follow the testing style already used in this repo. Then run the tests and show me the output. If any fail, tell me whether the test is wrong or the code is.
**Tip:** This is what `/test` runs. It writes the tests and then proves they pass with real command output, not a claim that they should pass.

---

### Fill a specific coverage gap
**When to use:** You know which paths are untested and want them covered.
**Prompt:**
> These paths in [FILE] are untested: [PATHS or BRANCHES]. Write tests that exercise exactly those, including the edge and error cases, without duplicating tests that already exist. Run the full test file after to confirm everything still passes.
**Tip:** Map the gap with a review pass first (see the code-review recipes), then feed the specific paths here. Targeted beats blanket coverage every time.

---

### Check that your tests actually catch bugs
**When to use:** The tests pass and you want to know if they would fail when they should.
**Prompt:**
> The tests for [FILE] pass. Verify they are actually meaningful: for each key behaviour, deliberately break the code in a small way and confirm a test fails. Report any change you could make that the tests do not catch, because that is a gap. Restore the code when you are done.
**Tip:** This is the idea behind `/mutation-gate`: it mutates your code and reports which mutations survive. Surviving mutants are exactly the assertions your suite is missing.

---

### Write a test that reproduces a bug before fixing it
**When to use:** You found a bug and want a failing test to lock the fix in.
**Prompt:**
> Write a test that reproduces this bug: [BUG]. Run it and confirm it fails against the current code, proving it captures the problem. Do not fix the bug yet. Once the failing test is in place, I will have you fix the code and rerun it to green.
**Tip:** A test that has never been seen to fail proves nothing. Confirming red first, then fixing to green, is the only order that guarantees the test guards the fix.

---

### Harden a flaky or slow test suite
**When to use:** The suite is unreliable or takes too long and you want it dependable.
**Prompt:**
> Audit the test suite in [DIRECTORY] for reliability and speed. Find tests that share state, depend on ordering, hit real external services, or rely on real time and randomness. Fix them to be isolated and deterministic. Report which tests were the slowest and whether any can be sped up without losing coverage. Run the suite to confirm it is stable.
**Tip:** Run the suite a few times after the fix to confirm the flakiness is genuinely gone, not just quiet for one run.

---

### Add tests for an untested legacy file
**When to use:** An important file has no tests and you want a safety net before touching it.
**Prompt:**
> [FILE] has no tests. Write characterisation tests that capture its current behaviour as it actually is, including any quirks, so I have a net before I change it. Do not judge whether the behaviour is correct, just pin down what it does today. Run them to confirm they pass.
**Tip:** Characterisation tests describe reality, not the ideal. Once they are green, you can refactor confidently and any behaviour change will trip a test.

---

### Generate test data and fixtures
**When to use:** A test needs realistic input data or fixtures and you do not want to hand-craft them.
**Prompt:**
> Create realistic test fixtures for [SCENARIO]: valid cases, boundary cases, and deliberately malformed cases. Follow the fixture format this repo already uses in [EXAMPLE_PATH]. Keep them minimal but representative, and wire them into a test that uses them so I can see they work.
**Tip:** Malformed and boundary fixtures are where real bugs hide. Ask Claude to include the ugly inputs, not just the clean ones.

---

### Write an end-to-end test for a user flow
**When to use:** You want a test that covers a whole path through the app, not just one unit.
**Prompt:**
> Write an end-to-end test for this user flow: [FLOW, step by step]. Use the e2e framework already set up in this repo. Assert the outcome the user actually cares about at each step, not implementation details. Run it and show me the result, and tell me what to check if it is flaky.
**Tip:** Keep e2e tests asserting user-visible outcomes so they survive refactors. Pair with `/verify` when the flow touches something you need to see working live.
