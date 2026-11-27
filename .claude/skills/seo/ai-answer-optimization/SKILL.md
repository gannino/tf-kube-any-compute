---
user-invocable: false
description: Rewrite a page so AI engines (ChatGPT, Perplexity, Google AI Overviews, Claude) quote it. The editorial craft of GEO, answer-first openings, self-contained 120-180-word chunks, inserting statistics, quotations and citations, definitive phrasing, and fan-out sub-question coverage. Comes with concrete before/after rewrites.
version: 2.1.0
context: fork
---

# AI Answer Optimization

## Purpose

This is the writing craft of GEO. The `geo-readiness-audit` skill tells you a page scores low on "answer-first" or "chunk structure"; this skill is how you actually fix the prose. It turns content that classic search ranks but AI engines ignore into content that gets lifted, quoted, and attributed inside AI answers.

The governing fact: **AI engines cite passages, not pages.** They retrieve a chunk, decide it answers the query, and quote it. So the unit of optimisation is the passage, and the goal of every technique below is to make individual passages independently extractable and obviously trustworthy. Everything here traces back to the Princeton GEO study (Aggarwal et al., KDD 2024, 10,000 queries), which measured exactly which edits move AI visibility, and by how much.

**Category**: SEO & Search, GEO / AI Search

## The five techniques, ranked by measured impact

These are ordered by the lift each produced in controlled GEO testing, so spend effort top-down.

| Technique | Measured lift | One-line rule |
|---|---|---|
| Quotation Addition | up to ~+41% | Quote a named authority verbatim, with attribution. |
| Cite Sources | ~+30% | Make every key claim traceable to a primary source. |
| Statistics Addition | ~+30% | Replace vague quantifiers with specific numbers. |
| Fan-out coverage | ~+161% citation odds | Answer the sub-questions, not just the head query. |
| Answer-first + chunking | structural prerequisite | Lead with the answer; split into 120-180w islands. |

[Source for the first three: industry standard, Aggarwal et al., KDD 2024. Fan-out: ALM Corp 173,000-URL study 2026. Chunking: SE Ranking 2025 citation data.]

Answer-first and chunking sit last in the table not because they are least important but because they are the substrate: quotes, citations, and stats only get cited if they live inside a liftable, answer-first chunk. Fix the structure, then load it with the high-impact elements.

## Technique 1, Answer-first (inverted pyramid)

State the answer in the first sentence, before context, history, or setup. Engines draw a disproportionate share of citations (~44%) from the first ~30% of a page, and they reward content that resolves the query immediately.

**The pattern:** `Direct answer. + the one stat or source that proves it. + then the nuance.`

**Before** (answer buried, typical "SEO content" warm-up):
> When businesses start thinking about customer relationship management, there are many factors to weigh. The history of CRM software goes back decades, and the market has evolved considerably. Pricing, in particular, is something that comes up often, and it depends on a wide range of considerations that we will explore in this comprehensive guide.

**After** (answer-first, liftable):
> CRM software typically costs between $12 and $150 per user per month, with most small-business plans landing around $25-50. Free tiers exist (HubSpot, Zoho) but cap contacts and features. Below, the full price breakdown by tier and team size.

The "after" opening can be lifted whole into an AI answer and still make sense. The "before" gives the extractor nothing.

## Technique 2, Self-contained chunks (120-180 words, the "Information Island" test)

Break the body so each distinct idea is its own chunk of **120-180 words** under a **descriptive heading**, and each chunk passes the Information Island test: *if this passage were shown entirely on its own, would a reader understand it completely?* Pages structured this way earn ~70% more citations than pages with sub-50-word fragments.

**Rules:**
- One question / one idea per chunk. Do not braid two topics into one paragraph.
- Repeat the entity inside the chunk. Write "Claudify's licence model" not "its licence model", the engine may lift the chunk away from the sentence that defined "it".
- Headings are mini-queries. "How much does it cost?" beats "Pricing". The heading should match how a user would ask.
- Expand stubs. A 30-word answer chunk is too thin to cite; give it the supporting stat and the source that bring it to 120-180 words.
- Do not over-shard. Sub-50-word chunks and 400-word walls both lose; aim for the band.

**Before** (one wall, no islands):
> Our platform supports SSO, has a 99.9% uptime SLA, integrates with Slack and Teams, offers role-based access control, and includes audit logging, and pricing starts at $40 per seat while enterprise plans add SAML and dedicated support which most large teams prefer for compliance reasons.

**After** (two islands, each liftable):
> **Does it support SSO and SAML?**
> Yes. Standard plans include SSO via Google and Microsoft. SAML and SCIM provisioning are on the Enterprise plan ($40+/seat), alongside role-based access control and audit logging. Most teams above 200 seats choose Enterprise specifically for SAML, which their security review requires.
>
> **What is the uptime guarantee?**
> The platform carries a 99.9% uptime SLA, which allows roughly 43 minutes of downtime per month. Enterprise plans add a financially-backed SLA with service credits if that threshold is missed.

## Technique 3, Insert statistics

Aim for **10-19 specific, load-bearing statistics per substantive page**, each welded to a claim. Statistics Addition was one of the three strongest GEO levers measured. Engines prefer the passage that carries a checkable number.

**The move:** find every vague quantifier and replace it with a figure.

| Vague (ignored) | Specific (citable) |
|---|---|
| "significantly faster" | "3.2x faster, 0.8s vs 2.6s median load" |
| "most users" | "of 4,100 surveyed users, 73%" |
| "a short setup" | "setup takes about 9 minutes" |
| "highly rated" | "rated 4.7/5 across 1,200 reviews" |
| "recently" | "as of June 2026" |

Every statistic should be ungameable: real, sourced, and tied to the specific claim it supports. Decorative numbers ("we have 10x passion") do not count and erode trust.

## Technique 4, Add quotations and cite sources

These are the two highest-impact levers and they pair naturally. A quotation from a named authority plus an inline citation to a primary source turns an assertion into evidence the engine will lift with its attribution intact.

**Quotation pattern:** introduce the source, quote verbatim, keep it short.
> Per Cloudflare's July 2025 announcement, "every new domain is now asked if they want to allow AI crawlers", making opt-in the default for sites behind its network.

**Citation pattern:** every key claim earns a traceable source, inline, close to the claim. Prefer primary sources (the original study, the vendor's own docs, the standards body) over aggregators.

**Before** (unsourced):
> AI crawlers generally can't read JavaScript-rendered content, which is a growing problem for modern sites.

**After** (quoted + sourced):
> An analysis of over 500 million GPTBot fetches found zero evidence of JavaScript execution: AI crawlers receive the raw HTML before any script runs. As one rendering study put it, client-side content leaves you "invisible to every AI crawler except Google".

## Technique 5, Fan-out sub-question coverage

Modern engines decompose a query: Google AI Mode fires **8-12 sub-queries** per prompt, ChatGPT **4-20**. Pages that answer those sub-questions are **~161% more likely to be cited** than pages that only cover the head term. Coverage is one of the single strongest citation predictors.

**Method:**
1. Take the head query. Prompt an AI engine with it and capture the follow-up chips / "people also ask" it surfaces, or enumerate the natural variants: *what is, why, how, when, how much, vs [alternative], is X worth it, best X for [segment]*.
2. For each sub-question that fits the page's intent, add a dedicated, headed 120-180-word chunk that answers it directly (this is where techniques 2-4 compound).
3. Sub-questions that deserve their own page become cluster pages, interlink them with the head page so the cluster covers the full fan-out.

**Example.** Head query: "what is generative engine optimization". Fan-out chunks to add:
- "How is GEO different from SEO?"
- "Which AI engines does GEO target?"
- "Does GEO replace SEO?" (answer: no, it layers on top)
- "How do you measure GEO results?"
- "What are the highest-impact GEO techniques?"

Each becomes its own headed island. The page goes from answering one query to ranking for the whole decomposed set.

## Definitive phrasing (the connective tissue)

Across all five techniques, write with authority. Engines lift confident, declarative statements far more readily than hedged ones, because a hedge is hard to quote as an answer.

| Hedged (rarely cited) | Definitive (citable) |
|---|---|
| "It might be a good idea to consider using SSR." | "Use SSR. AI crawlers run zero JavaScript, so client-rendered content is not seen." |
| "Some say longer content can sometimes help." | "Chunks of 120-180 words earn ~70% more citations than sub-50-word fragments." |
| "There are various factors that could affect this." | "Three factors set this: rendering, chunk length, and citation density." |

Definitive does not mean overclaiming. Stay honest and sourced; just state the sourced conclusion plainly instead of burying it in qualifiers.

## Full before/after (a complete passage)

**Before**, ranks in classic search, never cited by AI:
> Server-side rendering is an important topic that many developers think about when building modern web applications. There are a lot of different opinions on this, and it can depend on your specific situation. Generally speaking, it might be worth considering for SEO reasons, and possibly for other reasons too, depending on what you are trying to achieve with your website and your goals.

**After**, answer-first, chunked, statistic, citation, definitive:
> **Do AI crawlers need server-side rendering?**
> Yes. AI crawlers do not execute JavaScript, so client-rendered content is invisible to them. An analysis of over 500 million GPTBot fetches found zero JavaScript execution, and as of mid-2026 GPTBot, OAI-SearchBot, ClaudeBot, Claude-SearchBot, and PerplexityBot all read only the raw HTML. The single exception is Google's Gemini, which reuses Googlebot's render service. If your answer content is injected client-side, every AI engine except Google receives a blank page. Render answer-bearing content server-side (SSR), pre-render it (SSG), or use hybrid rendering, then confirm it ships in the raw HTML with `curl -sL {url}`.

That single passage now scores well on answer-first, chunk structure, statistic density, citation, and definitive phrasing at once. That is the target.

## Process (applying this to a real page)

1. **Run `geo-readiness-audit` first** to get the per-criterion scores. This skill fixes whatever scored low.
2. **Fix structure before substance.** Apply answer-first (T1) and chunking (T2) so there are liftable islands to fill.
3. **Load the islands** with statistics (T3), then quotations and citations (T4) on the highest-value chunks.
4. **Close the coverage gap** (T5) by adding chunks for the missing fan-out sub-questions.
5. **Pass over for phrasing**, convert hedges to definitive, sourced statements.
6. **Re-run `geo-readiness-audit`** and confirm the editorial criteria (1-4, 8) now pass.

## Quality validation (before returning the rewrite)

- [ ] The opening answers the primary question in the first ~50 words.
- [ ] Every answer-bearing chunk passes the Information Island test and sits in 120-180 words.
- [ ] At least 10 specific, load-bearing statistics, each tied to a claim.
- [ ] Key claims carry an inline citation; at least one direct quotation from a named source.
- [ ] The major fan-out sub-questions each have a dedicated chunk.
- [ ] Phrasing is definitive and sourced, not hedged, and no claim was inflated to achieve that.
- [ ] No em dashes; numbers have breathing room and are easy to scan.

## After completion

- Note the rewrite in `.claude/agent-memory/seo/MEMORY.md` and schedule a check: did the page start appearing in AI answers within 2-4 weeks?
- If a particular technique reliably moves citations for this site, nominate the pattern to `.claude/knowledge-nominations.md` tagged `[SEO]`.
- Pair with `ai-crawler-access` (so the rewritten content is actually reachable) and `entity-optimization` (so the engine trusts the publisher).
