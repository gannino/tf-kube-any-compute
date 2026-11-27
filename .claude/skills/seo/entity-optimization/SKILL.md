---
user-invocable: false
description: Make a brand a machine-resolvable entity so AI engines trust and cite it. Covers Organization schema with sameAs, the Wikidata and Wikipedia notability path, and how entity clarity helps ChatGPT, Perplexity, Google AI Overviews, and Claude resolve "who is making this claim" and attribute the brand confidently.
version: 2.1.0
---

# Entity Optimization

## Purpose

Before an AI engine quotes a claim, it has to answer a quieter question: *who is making this claim, and can I trust them?* If the publishing organisation is a fuzzy string the engine cannot resolve to a known entity, the claim is harder to trust and harder to attribute. Entity optimization makes the brand an unambiguous, machine-resolvable node, so engines can connect the page to a known organisation, carry the attribution, and cite with confidence.

This is criterion 9 in `geo-readiness-audit`. It is lower-weighted than the rendering and chunking gates because it is a trust multiplier rather than a visibility gate, but for branded and competitive queries it is often the difference between being cited *by name* and being paraphrased anonymously.

**Category**: SEO & Search, GEO / AI Search

## The core idea: strings vs things

Search and AI engines model the world as **entities** (things: organisations, people, products, places) connected in a graph, not as loose strings of text. "Claudify" as a bare word is a string. "Claudify, the organisation at claudify.tech, also known as the Wikidata item Q-xxxxx, the LinkedIn company page, the Crunchbase profile" is a **resolved entity**. The engine can attach reputation, relationships, and trust to the entity; it cannot to the string.

Three signals make a brand resolvable: explicit **`Organization` schema**, a **`sameAs` web of authoritative profiles**, and, at the top end, presence in **Wikidata / Wikipedia**, the knowledge bases the major engines lean on. [Source: industry standard, entity resolution for AI engines 2026]

## Signal 1, Organization schema (the foundation)

Put `Organization` (or the relevant subtype: `LocalBusiness`, `Corporation`, `SoftwareApplication` publisher) JSON-LD on the site, ideally site-wide (homepage + footer) so every page inherits a clear publisher. This is the declaration that says "this content is published by this specific, described organisation".

### Copy-paste Organization JSON-LD

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "@id": "https://example.com/#organization",
  "name": "Example Company",
  "alternateName": "Example",
  "url": "https://example.com",
  "logo": {
    "@type": "ImageObject",
    "url": "https://example.com/logo.png",
    "width": 512,
    "height": 512
  },
  "description": "One precise sentence on what the organisation does and for whom.",
  "foundingDate": "2024",
  "sameAs": [
    "https://www.wikidata.org/wiki/Q00000000",
    "https://en.wikipedia.org/wiki/Example_Company",
    "https://www.linkedin.com/company/example-company",
    "https://www.crunchbase.com/organization/example-company",
    "https://github.com/example-company",
    "https://x.com/examplecompany",
    "https://www.youtube.com/@examplecompany"
  ],
  "contactPoint": {
    "@type": "ContactPoint",
    "contactType": "customer support",
    "email": "support@example.com"
  }
}
</script>
```

**Rules:**
- One canonical `Organization` node with a stable `@id` (the `#organization` fragment), referenced site-wide so the graph has a single source of truth.
- `name` must be the exact brand name used everywhere else (LinkedIn, the logo, the footer). Consistency is what lets the engine match the nodes.
- `logo` should be a real, square, accessible image URL, engines use it in knowledge-panel-style displays.
- Include only `sameAs` URLs that genuinely exist and that you control or that authoritatively describe the brand. Do not pad with dead links, a broken `sameAs` weakens the cluster.
- Validate every change with Google's Rich Results Test / Schema Markup Validator before shipping. Malformed JSON-LD silently voids the markup.

## Signal 2, the sameAs web (corroboration)

`sameAs` is how you tell the engine "all of these profiles are the same entity as this organisation". It lets the engine cross-corroborate: the same name, logo, and description appearing across Wikidata, LinkedIn, Crunchbase, GitHub, and the official socials raises confidence that the entity is real and consistent.

**Priority order for `sameAs` (highest corroboration value first):**
1. **Wikidata** item, the machine-readable backbone most engines consult.
2. **Wikipedia** article, high-trust human-readable corroboration.
3. **LinkedIn** company page, near-universal, high-trust for organisations.
4. **Crunchbase**, strong for companies/startups.
5. **GitHub org**, strong for developer-tool and software brands.
6. **Official social profiles**, X, YouTube, etc.
7. **Industry-specific authoritative directories**, relevant association or registry listings.

**Consistency is the whole game.** Use the identical name, logo, one-line description, and URL across every one of these profiles. Discrepancies (different names, mismatched descriptions) make the entity harder to resolve, not easier. Audit the profiles and align them before adding them to `sameAs`.

## Signal 3, the Wikidata / Wikipedia notability path (the top tier)

Presence in Wikidata and Wikipedia is the strongest entity signal available, because these are the knowledge bases the major engines treat as ground truth for "who is this". They are also the hardest to earn, because both enforce **notability**, you cannot simply self-publish a page.

### Wikidata (do this first, it is the achievable one)

Wikidata is more permissive than Wikipedia and is machine-first, which makes it the right first target. An item needs to be backed by at least one serious, independent reference.

1. Confirm the brand is not already an item (search Wikidata).
2. Create an item with the core statements: `instance of` (e.g. business / software company), `official website`, `inception`, `country`, and identifiers (LinkedIn, Crunchbase, GitHub) where they exist.
3. Cite an independent source on the key statements, a news article, an industry database, a funding announcement. Self-citations alone are weak.
4. Once live, add the Wikidata URL to the site's `Organization.sameAs`. The link is now bidirectional and machine-traceable.

### Wikipedia (the high bar, earn it, never fake it)

Wikipedia requires **significant coverage in multiple independent, reliable secondary sources** (press, books, established industry publications, not the brand's own site, press releases, or sponsored posts). The honest path:

- **Build the source base first.** Earn genuine independent coverage (the `digital-pr-plan` and `haro-response` skills are the engine for this). Without multiple independent reliable sources, a Wikipedia article will be rejected or deleted, and a deleted article is worse than none.
- **Only then** is a neutral, well-cited article viable. Write it neutrally, cite the independent sources, and disclose any connection. Promotional or under-sourced articles get removed and can damage the entity's standing.
- **Do not** create or pay for a Wikipedia page before the coverage exists. It will not stick and it signals manipulation.

Treat Wikipedia as a *lagging* indicator of real-world notability, not a lever you pull directly. Wikidata is the lever; Wikipedia follows the press.

## Dated evidence note (24 Jul 2026): mentions carry the entity

The Ahrefs 75,000-brand correlation study (26-27 May 2026) found earned brand mentions are the
strongest measured correlates of AI visibility (YouTube mentions r=0.737, branded web mentions
r=0.664) while backlinks correlate weakly (r=0.218). Entity work and mention-earning compound:
mentions build the corroboration that makes the entity resolvable, and a resolvable entity lets
engines attribute those mentions to the right brand. When prioritising, pair this skill with
`digital-pr-plan` and `youtube-seo` for the mention supply, and treat schema as the plumbing that
makes mentions attributable, not as a citation lever on its own.
[Source: ahrefs.com/blog/ai-brand-visibility-correlations]

## How this helps AI citation specifically

- **Disambiguation.** Many brand names collide with common words or other companies. A resolved entity tells the engine *which* "Example" published the page, so it attributes correctly instead of conflating or hedging.
- **Trust transfer.** A claim from a corroborated, well-described entity is safer for the engine to quote than a claim from an unresolvable string, so resolved entities clear the citation bar more often on competitive queries.
- **Named attribution.** When the engine does cite, a clear entity makes it more likely to name the brand ("according to Example Company") rather than paraphrase anonymously, which is the entire commercial point of GEO.
- **Knowledge-panel and grounding inclusion.** Wikidata/Wikipedia presence feeds the structured knowledge layers that Google's AI Overviews and other engines use to ground answers.

## Process

1. **Audit current state.** Is there `Organization` schema? Does a Wikidata item exist? Are the social/Crunchbase/LinkedIn profiles consistent in name, logo, description?
2. **Ship the schema.** Add the site-wide `Organization` JSON-LD with a full, real `sameAs` list. Validate it.
3. **Align the profiles.** Make name, logo, and one-line description identical across every `sameAs` destination.
4. **Create the Wikidata item** with independent citations; add its URL to `sameAs`.
5. **Build toward Wikipedia** via genuine press, only attempt the article once multiple independent reliable sources exist.
6. **Re-score** criterion 9 in `geo-readiness-audit`.

## Quality validation (before returning)

- [ ] `Organization` schema present site-wide with a stable `@id`, real `logo`, and a populated `sameAs`.
- [ ] Every `sameAs` URL resolves and authoritatively describes the brand (no dead or padded links).
- [ ] Name, logo, and description are consistent across all linked profiles.
- [ ] JSON-LD validated in a schema validator (no errors).
- [ ] Wikipedia is pursued only where genuine independent coverage exists, no fabricated or premature article.
- [ ] Figures and claims sourced; no em dashes.

## After completion

- Log the entity state (schema live, Wikidata item ID, profile consistency) in `.claude/agent-memory/seo/MEMORY.md`.
- If the brand lacks the independent coverage Wikipedia needs, that is a digital-PR task, recommend `digital-pr-plan` and `haro-response`.
- Pair with `schema-markup-generator` for non-entity structured data and with `geo-readiness-audit` to confirm the full GEO picture.
