# Planning and Context Recipes

Claude Code does its best work when it understands the codebase before it acts and keeps its context sharp while it works. These recipes are about the moves around the coding: getting oriented, planning before building, handing off cleanly, and staying clear-headed across a long session.

---

### Onboard yourself to an unfamiliar codebase
**When to use:** You are starting work on a repo you do not know and want to get productive fast.
**Prompt:**
> I am new to this codebase. Give me an onboarding guide: what the project does, the stack, how it is structured, where the important logic lives, how to run and test it, and the three things that would most surprise a newcomer. Read enough of the code to be accurate, and point me to the specific files I should read first.
**Tip:** This is what `/onboard` runs. Use the command so the guide comes from a subagent that has actually read the repo, and keep its output as the seed for a CLAUDE.md.

---

### Map where a feature lives before changing it
**When to use:** You need to change a feature and want to know every file it touches first.
**Prompt:**
> I need to change [FEATURE]. Before any edits, map it for me: every file involved, the entry point, the data flow, the tests that cover it, and the places a change here would ripple to. Give me the map as a short list I can reason about. Do not change anything yet.
**Tip:** Mapping the blast radius before editing is the cheapest insurance there is. Feed the map into a feature recipe once you know the full surface.

---

### Plan a task and get a step-by-step approach
**When to use:** A task is non-trivial and you want a plan to approve before work starts.
**Prompt:**
> Plan how to do [TASK]. Read the relevant code, then give me a numbered plan: the steps in order, which files each touches, the risks, and where you are uncertain. Do not start yet. I want to approve or adjust the plan first, then have you execute it step by step.
**Tip:** For anything touching a production system, treat the plan as the moment to run the ten-step pre-ship audit. Catching a bad assumption in the plan costs minutes, catching it in production costs far more.

---

### Break a big task into shippable pieces
**When to use:** A task is too large to do in one go and you want it decomposed sensibly.
**Prompt:**
> [TASK] is large. Break it into a sequence of small, independently shippable steps, each of which leaves the code working and testable. Order them so the riskiest or most uncertain part comes early, before I have sunk effort into the rest. Tell me what each step delivers and how I would verify it.
**Tip:** Front-loading the risky step is deliberate: you want to hit the wall early, while pivoting is still cheap, not after you have built everything around a wrong assumption.

---

### Decide between two implementation approaches
**When to use:** You are weighing two ways to build something and want a clear-eyed comparison.
**Prompt:**
> I am choosing between two approaches for [PROBLEM]: [APPROACH_A] and [APPROACH_B]. Read the relevant code, then compare them honestly for this codebase specifically: fit with existing patterns, complexity, testability, performance, and how hard each is to change later. Give me a recommendation with the reasoning, and say what would change your mind.
**Tip:** The say-what-would-change-your-mind clause surfaces the assumption the recommendation rests on, so you can check whether it holds for your situation.

---

### Hand off work to another person or session
**When to use:** You are stopping mid-task and someone (or a future session) needs to pick it up.
**Prompt:**
> Write a handoff for this work. Cover: what the task is, what is done, what remains, the key decisions made and why, the files touched, and the exact next action with the file to open first. Make it complete enough that someone with no memory of this session could continue without asking me anything.
**Tip:** This is what `/handoff` produces. Claudify also keeps a warm handoff on disk automatically, so a session that gets compacted resumes sharp. Use the command when a human is the recipient.

---

### Refresh context when a session is getting heavy
**When to use:** A long session is drifting: repetition, re-reading, missed details.
**Prompt:**
> This session is getting long. Distil the current state into a tight summary: what we are doing, what is decided, what is done, the files in play, and the precise next step. Write it where the project keeps session state so we can carry on cleanly from here.
**Tip:** This is what `/safe-clear` does, then it pairs with a compaction so the session actually flushes and resumes fresh. Reach for it when quality dips or when you switch to an unrelated task domain.

---

### Prove a completion claim before you trust it
**When to use:** A task is being called done and you want it demonstrated, not asserted.
**Prompt:**
> This is claimed to be done: [CLAIM]. Do not take that on trust. Run whatever proves it (the tests, the build, the actual command or user flow) and report the real result with the command output. If it does not actually work, say so plainly and tell me what is left.
**Tip:** This is exactly what `/prove` forces. A done-claim without command evidence is a hypothesis. Make the loop close with real output before you move on.
