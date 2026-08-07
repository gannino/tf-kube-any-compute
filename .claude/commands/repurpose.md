# /repurpose [source] [targets]

Atomization with a registry: takes ONE canonical asset and emits platform-native derivatives through the existing platform skills, logging every derivative to `.claude/agent-memory/content-creator/derivative-registry.md` so derivatives are tracked assets, not reformatting.

Why the registry matters (Jun-Jul 2026 record): Instagram deprioritizes aggregator-style reposts and caps trial Reels at 5 duplicates per day (Jun-Jul 2026), and X payouts are shifting to original authors away from repost accounts (rollout from late May 2026). Untracked cross-posting is now actively penalized. Each derivative must be platform-native, individually predicted, and individually graded.

## Usage

```
/repurpose "blog/how-claude-md-decays.md" x-thread,linkedin,ig-carousel
/repurpose "newsletter issue 004" x-singles:3,linkedin
/repurpose                          # no args: offers targets for the most recent approved long-form piece
```

Valid targets: `x-thread`, `x-single` (or `x-singles:N`), `linkedin`, `ig-caption`, `ig-carousel`, `threads`, `tiktok-script`, `newsletter-teaser`, `bluesky`.

## Procedure

### Step 1, Load the source and the plan

1. Read the canonical asset in full.
2. Read the brand memory for the active brand (or the brand the source belongs to).
3. Read `.claude/skills/content/branded-content/repurposing-pipeline/SKILL.md`, the derivation rules (angle extraction, platform-native reframing, the anti-republishing rule).
4. Check the derivative registry: if this source already has derivatives on a requested platform, surface them. A second derivative on the same platform needs a genuinely different angle, not a re-cut (IG duplicate caps and X originality scoring both punish near-duplicates, Jun-Jul 2026).

### Step 2, Extract the derivative angles

From the source, extract distinct angles (one insight per derivative). A 1,500-word piece typically carries 3-5. Map each angle to its target platform per the repurposing-pipeline skill's platform-fit table. Never assign the same angle to two platforms verbatim; the framing must be platform-native.

### Step 3, Produce each derivative

For each target, invoke `content-creator` via the Task tool with `subagent_type: content-creator` and `run_in_background: false`, passing: brand, platform, the assigned angle, the source path, and the instruction to apply the matching platform skill (x-thread, linkedin-post, ig-carousel, etc.). Each derivative gets its own self-check + content-auditor cycle. Derivatives that fail audit round-trip as usual.

### Step 4, Register every derivative

Append one row per derivative to `.claude/agent-memory/content-creator/derivative-registry.md`:

```
| {source path or id} | {platform} | {variant, e.g. thread-v1} | {YYYY-MM-DD} | pending | drafted |
```

### Step 5, Prediction records at publish

When the user publishes a derivative, self-execute `/content-learn record {piece-id}` for THAT derivative (guard G1) and update its registry row: prediction_record id filled, status `published`. Each derivative is its own experiment; the content-analyst grades it against its own platform baseline, never against the source's performance.

## Output

```
REPURPOSE, {brand}, {source}

Derivatives produced: {N}
| platform | variant | angle (one line) | audit |
|---|---|---|---|

Registry: {N} rows appended
Next: publish each, then /content-learn record fires per derivative
```

## Hand-off

The registry feeds the learning loop: `/content-learn status` reads it to find published-but-unpredicted derivatives, and the content-analyst reads it to grade each derivative independently. After grading, confirmed patterns (e.g. "carousel derivatives of technical blogs outperform thread derivatives for this brand") route through knowledge-nominations like any other learning.
