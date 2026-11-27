---
description: >
  Write a runnable unit test file for a specific function, module, or diff, in the
  project's existing test framework and naming conventions. Use when the user says
  "write unit tests", "add tests for this", "test this function", or "increase test
  coverage". Not for end-to-end or browser testing, and not for reviewing existing
  tests (use code-review-checklist).
user-invocable: true
version: 2.1.0
arguments:
  - name: target
    description: the file, function, or diff to test
paths:
  - "**/*.test.*"
  - "**/*.spec.*"
---

# Unit Test Writer

The output is an actual test file that runs, not a testing strategy. Read the target
code first, detect the framework already in the repo (check package.json, pyproject,
go.mod, or existing test files), and match its idioms exactly: same runner, same
assertion style, same file naming.

## Procedure

1. Read the target and its imports. List its observable behaviors: return values,
   thrown errors, side effects, boundary conditions.
2. Detect the framework and an existing test file to copy conventions from.
3. Write one describe/class block per unit, one test per behavior. Cover: the happy
   path, each documented error, at least one boundary (empty input, zero, max), and
   any regression the user mentioned.
4. Use real fixture values, never TODO stubs. Every assertion checks a concrete value.
5. State the exact command to run the file and what a pass looks like.

## Worked example (fictional code)

Target: `slugify(title: string)` which lowercases, replaces spaces with hyphens, and
strips non-alphanumerics. Framework detected: Vitest.

```ts
import { describe, it, expect } from "vitest";
import { slugify } from "../src/slugify";

describe("slugify", () => {
  it("lowercases and hyphenates spaces", () => {
    expect(slugify("Hello World")).toBe("hello-world");
  });
  it("strips non-alphanumeric characters", () => {
    expect(slugify("Q3: Report (final)")).toBe("q3-report-final");
  });
  it("returns empty string for empty input", () => {
    expect(slugify("")).toBe("");
  });
  it("collapses repeated separators", () => {
    expect(slugify("a  --  b")).toBe("a-b");
  });
});
```

Run: `npx vitest run tests/slugify.test.ts`, expect 4 passed.

## Output contract

Deliver: the complete test file in one fenced code block, the path it should be saved
to, the run command, and a short behavior-to-test mapping list. Every test must be
executable as written against the described code; no placeholder assertions, no
skipped tests, no pseudo-code.
