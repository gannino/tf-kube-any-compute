# God-tier Prompt Rubric

Every god-tier prompt that ships in the newsletter must clear this bar before send. The rubric exists because mediocre prompts kill the perceived value of the entire newsletter — and from Issue 002 onwards, the prompt is the literal reward people refer friends to unlock. If it's not exceptional, the referral mechanism collapses.

---

## The 6 criteria (each scored 1-5)

| Criterion | What 5/5 looks like |
|---|---|
| **1. Time saved** | Saves the reader at least 1 hour of work from a single paste |
| **2. Specificity** | Output is concrete and actionable: file paths, line numbers, exact diffs, named tools — not "consider doing X" |
| **3. Novelty** | The reader thinks "I'd never have asked this in this way" — not a generic "act as a senior X" pattern |
| **4. Universality** | Works on any project, any stack, any team size, any seniority level |
| **5. Shareability** | The reader's first thought after running it is "I need to forward this to [specific person]" |
| **6. Relevance** | Directly extends, deepens, or applies the issue's main tip — the two halves of the email reinforce each other |

---

## Hard gate: ship only if 4+ on at least 5 of 6 criteria

A prompt that scores 3 or below on more than 1 criterion does NOT ship. Iterate.

---

## Anti-patterns the rubric rejects

- Generic personas ("act as an expert", "act as a senior X with N years experience")
- Procedural output format without voice
- No anti-patterns specified ("don't write generic advice")
- No example output to anchor calibration (bad rule vs good rule)
- Doesn't leverage Claude's tools (Read, Bash, Grep) — Claude imagines instead of investigates
- No self-grading step before output
- Closer is just "Begin" or similar — no quality reinforcement
- Output is procedural headings without character or stance
- Topic has no relationship to the week's main tip — feels like two unrelated emails stapled together

---

## Test methodology before shipping

Every god-tier prompt is tested on **3 different codebases** (small/medium/large, different languages or domains) before going into the newsletter. For each test:

1. Run the prompt
2. Score the output against the 6 criteria
3. Note what was missing or mediocre
4. Revise the prompt
5. Re-test

Ship only when 3 consecutive runs score 4+ on at least 5 criteria.

If you can't get 3 consecutive 4+ scores, the prompt isn't ready — pick a different angle for that week's issue or push the issue to next week.

---

## Relevance: how to make the god-tier prompt land within the issue's theme

The god-tier prompt should feel like a natural progression from the main tip, not a parallel topic. Pick the angle by asking:

| Issue type | Where to look for the prompt |
|---|---|
| Config | A meta-prompt that operates on the configuration itself (rebuild it, audit it, optimise it) |
| Workflow | A prompt that automates the next step in the workflow taught |
| Agent | A prompt that designs a custom agent variant for the reader's specific project |
| Debug | A prompt that diagnoses the next class of error after the one taught |
| Command | A prompt that combines the command with another in a higher-leverage chain |

**Test:** does the god-tier prompt make sense as the natural next thing to do AFTER applying the main tip? If yes, relevance scores 5. If it's adjacent but not directly extending, 3-4. If it's totally unrelated, 1-2 (and the prompt fails the rubric).

---

## Calibration examples

### A prompt that fails relevance (Issue 001 v1 — the Senior Engineer Review)
- Issue 001 taught: how to make CLAUDE.md self-improve via Stop hook + Learnings section
- Prompt was: act as a senior engineer reviewing the codebase
- Relevance: 2/5. The two are about Claude Code, but the prompt has no connection to the CLAUDE.md / self-improving / hooks technique just taught. Reader finishes the issue with two disconnected ideas.

### A prompt that passes relevance (Issue 001 v2 — the CLAUDE.md Surgeon)
- Issue 001 taught: how to make CLAUDE.md self-improve
- Prompt is: do surgery on the entire CLAUDE.md to keep it sharp over time
- Relevance: 5/5. The reader's mental flow: "I've set up self-improving CLAUDE.md → now what? → the file will eventually get bloated → here's the god-tier prompt that keeps it lean." The two halves compound.

---

## Process for drafting a new god-tier prompt

1. Identify the issue's main tip
2. Ask: what's the next problem the reader will hit after applying it?
3. Ask: what's a higher-leverage application of the same technique?
4. Ask: what does this teach that wasn't covered in the main body?
5. Draft the prompt with at least one anti-pattern, one calibration example, one self-check, and a closer that reinforces quality
6. Score against the 6 criteria honestly
7. Test on 3 codebases
8. Ship only when consistently 4+ on 5 of 6

---

**Owner:** you
**Reviewer at draft stage:** the strategist running `/newsletter new`
**Reviewer at ship stage:** you (final approval before paste into Beehiiv)
