---
user-invocable: true
description: Decide whether and how a piece of AI-assisted content must disclose its AI use, per platform and per jurisdiction. Use when asked "do I need to disclose AI", "AI label", "EU AI Act", "Article 50", "C2PA", "is this compliant", "AI disclosure check", or before publishing any asset containing synthetic media. Covers YouTube, TikTok, Meta, X, LinkedIn, Substack, and the EU AI Act rules applying 2 Aug 2026.
version: 2.1.0
---

# AI Disclosure and Compliance

## Purpose

Answer one question deterministically before anything publishes: does this asset, on this platform, for this audience, require an AI disclosure, and if so, which mechanism? Wrong answers now carry real cost: demonetization (YouTube), ad rejection (Meta), account-health penalties (TikTok), and from 2 Aug 2026, EU fines up to EUR 15M or 3% of global turnover under AI Act Article 50.

This skill is the working matrix. The non-negotiable subset lives in `knowledge-base.md` under "Hard Rules, AI Disclosure". Both auditors (content-auditor check M16, newsletter-auditor check M26) run the disclosure check on every piece.

## Step 1: Classify the asset

| Class | Definition | Disclosure posture |
|---|---|---|
| A. Realistic synthetic media | AI-generated or AI-altered image/video/audio a viewer could take as authentic (includes AI voices, avatars, photorealistic people) | Disclose on every platform; EU visible disclosure required from 2 Aug 2026 |
| B. Stylized synthetic media | Obviously artificial (illustration, abstract art, motion graphics) | Platform label only where metadata triggers it; no EU deepfake duty (the test is: could the audience perceive it as authentic?) |
| C. AI-drafted text, human-reviewed | Copy drafted with AI, edited and signed off by a human who holds editorial responsibility | Generally no label (EU editorial-responsibility carve-out); log the human sign-off |
| D. AI-drafted public-interest text, unreviewed | Text published to inform the public on matters of public interest with no human editorial responsibility | Label required in the EU from 2 Aug 2026; do not ship this class at all if avoidable |
| E. Chatbot / conversational agent | Any agent talking to end users | Must self-identify as not human (EU, from 2 Aug 2026) |

## Step 2: Apply the platform matrix (dated record, Jun-Jul 2026)

| Platform | Mechanism | Rule | Dated source |
|---|---|---|---|
| YouTube | Studio altered/synthetic toggle | Mandatory for realistic altered/synthetic footage. Properly disclosed video suffers no distribution or monetization penalty; undisclosed escalates from forced labels to demonetization to YPP removal. HARD BLOCK: no AI persona presented as an advisor on finance, legal, health, or medical topics in monetized content. | Policy clarification 13-20 Jul 2026 (techcrunch.com/2026/07/20/youtube-clarifies-policies-around-ai-slop-and-upsetting-videos/) |
| TikTok | AIGC self-label | Self-apply on all realistic AI visuals/audio. TikTok invisible-watermarks content made with its AI tools or carrying C2PA credentials, and tests detection of AI-spam accounts; unlabeled realistic AI content may be auto-labeled, throttled, or removed. Separately: NO AI voices/audio/slideshows/loops in Shop LIVEs at all (~14-15 Jul 2026). | TikTok newsroom 14 Jul 2026 |
| Meta / Instagram | "AI info" label | Mandatory on ads; extended 1 Jun 2026 to third-party AI tools detected via C2PA metadata (Photoshop generative fill, DALL-E, Canva AI). Undisclosed AI content is an active ad-rejection reason, especially photorealistic people and political/health/financial ads. Fully synthetic personas need the account-level "AI creator" label (testing since May 2026). | Meta policy update in force Jul 2026 |
| X | "Made with AI" post toggle | Toggle on posts containing synthetic media (creator-facing toggle in test since Feb 2026); deceptive edits risk the auto "Manipulated Media" tag applied TO you. Never post realistic manipulated media of a real person unlabeled. | X policy record Jan-Feb 2026, operative Jul 2026 |
| LinkedIn | C2PA-based labeling | LinkedIn labels via C2PA content credentials and expects disclosure when AI materially generated the content. Separately, generic AI-pattern posts are actively suppressed (23 Jul 2026), so disclosure does not rescue generic output. | LinkedIn policy + Forbes 23 Jul 2026 |
| Substack | Pangram-powered AI labels + "How I make this" statement | Substack applies AI-detection labels on posts and replies and supports author disclosure statements (22-23 Jul 2026). Fill the disclosure statement honestly once; it then covers the publication's standing process. | Substack release 22-23 Jul 2026 |

Not covered here: Pinterest, Spotify, and other secondary surfaces. If publishing there, verify the current rule before publish and flag it in the deliverable; do not assert from memory.

## Step 3: Apply the jurisdiction lines

**EU (AI Act Article 50, applies 2 Aug 2026):**
- Class A assets reaching EU audiences: visible AI disclosure on the asset, and keep machine-readable marking (C2PA/metadata) intact. Deepfake labeling is intent-neutral: the test is whether the audience could perceive it as authentic, not whether deception was intended (EC final guidelines, 20 Jul 2026).
- Class C: no label needed where a human reviewed the text and holds editorial responsibility; LOG that sign-off (name + date) in the piece's record.
- Class E: the chatbot self-identifies.
- Content generated before 2 Aug 2026 needs no retroactive marking. Providers of systems already on the market before 2 Aug 2026 have until 2 Dec 2026 for machine-readable-marking conformity (AI Omnibus relief).
- Penalties: up to EUR 15M or 3% of global turnover.

**UK / US:** no equivalent horizontal statute in force as of 24 Jul 2026; platform rules above still apply. FLAG, do not assert: sector rules (political ads, financial promotions) may impose their own disclosure duties; if the content touches those sectors, name the open question in the deliverable and have the user verify with counsel.

**Other jurisdictions:** unverified in this skill's record. Flag per the knowledge-base rule: "verify before publish" with the question named.

## Step 4: C2PA / provenance guidance

- Never strip C2PA, IPTC, or watermark metadata from any asset. Platforms detect via metadata; stripping converts "labeled" into "flagged for evasion".
- Assume any C2PA-carrying asset will be auto-labeled on Meta, TikTok, LinkedIn, and Pinterest. Pre-disclose rather than get rejected.
- Keep clean, intact metadata on genuine photography so it does not get false-positive labeled.

## Output block (attach to every deliverable containing AI-assisted assets)

```
AI DISCLOSURE CHECK
Asset class: {A-E}
Platforms: {list}
Required mechanisms: {per platform, from the matrix}
EU exposure: {yes/no; if yes, which Article 50 duty applies}
Human editorial sign-off: {name + date, for Class C}
Open questions flagged for verification: {list, or "none"}
```

## Hard rules

- NEVER assert a disclosure rule this skill does not carry a dated source for. Flag it.
- NEVER present an AI persona as an advisor on finance, legal, health, or medical topics in monetized YouTube content. This is a block, not a disclosure question.
- NEVER strip provenance metadata.
- ALWAYS write the disclosure check block; "obviously fine" is not a verdict.
