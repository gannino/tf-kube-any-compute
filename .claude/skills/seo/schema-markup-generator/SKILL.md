---
user-invocable: false
description: Generate valid, paste-ready JSON-LD structured data for a page. Use when the user says "add schema", "structured data", "JSON-LD", "rich results", "product schema", "article schema", or a page audit flags missing markup. Emits the actual script blocks, not advice about schema.
version: 2.1.0
paths:
  - "**/*.jsonld"
---

# Schema Markup Generator

## Purpose

Produce the actual `<script type="application/ld+json">` blocks a page needs, filled with the
page's real values, validated, and ready to paste. The deliverable is markup, not a memo about
markup. Every generated block states which outcome it targets: a Google rich result (only for
types that still produce one), AI-extractability, or entity clarity.

**Category**: SEO & Search

## What schema can and cannot deliver in 2026 (dated, load-bearing)

- **Still rich-result-producing** (confirmed as of 24 Jul 2026): Product, Review/AggregateRating,
  Article, Recipe, Video, Organization, LocalBusiness, BreadcrumbList.
- **FAQ rich results were removed 7 May 2026** (GSC reporting removed Jun 2026, API Aug 2026).
  FAQPage markup remains valid schema, but its payoff is now AI-extractability of clean Q&A pairs,
  never SERP real estate. Generate it only for genuine Q&A content and label it accordingly.
- **No special schema exists for AI features.** Google's AI-features documentation states no
  machine-readable files or special markup are needed for AI Overviews / AI Mode
  (developers.google.com/search/docs/appearance/ai-features, retrieved 24 Jul 2026), and Ahrefs'
  75,000-brand study (26-27 May 2026) found schema correlates weakly with AI visibility. Schema
  supports entity clarity and eligibility for the surviving rich results; do not sell it as an AI
  citation lever.
- **Product schema now feeds AI shopping surfaces directly**: ChatGPT opened product feeds in its
  Ads Manager on 2 Jun 2026 using the same catalog format as Google Shopping, and Google announced
  AI Mode ad formats at Marketing Live 2026. Clean Product markup and feeds are the crawl surface
  for AI commerce.

## Inputs

### Required
- **Page URL or draft content**: the actual page (WebFetch it when a URL is given)
- **Page type**: article/blog, product, service, local business, organization/home, recipe, video,
  how-to content, Q&A content

### Optional
- **Existing markup**: current JSON-LD to audit and extend rather than duplicate
- **Entity facts**: org name, logo URL, sameAs profiles (else pull from the site and
  `entity-optimization` outputs)

## Process

### Step 1: Inventory
Fetch the page. Extract the real values (headline, author, dates, prices, availability, images).
Detect existing JSON-LD with `grep 'application/ld+json'` on the raw HTML; never emit a duplicate
type, extend or correct instead.

### Step 2: Select types by page type
| Page type | Emit | Outcome targeted |
|-----------|------|------------------|
| Blog/article | Article (or BlogPosting) + BreadcrumbList | rich result + freshness signal (dateModified) |
| Product | Product with offers (price, priceCurrency, availability) + AggregateRating if real reviews | rich result + AI shopping surfaces |
| Home/about | Organization with sameAs (defer to `entity-optimization` for the entity web) | entity clarity |
| Local business | LocalBusiness + Organization | rich result + maps surfaces |
| Q&A section | FAQPage | AI-extractability ONLY (label it; no rich result since 7 May 2026) |
| Tutorial | HowTo | structure; note HowTo rich results retired 2023, so structure and extractability only |
| Recipe / video | Recipe / VideoObject | rich result |

### Step 3: Generate the JSON-LD
Rules for every block:
- Fill with the page's REAL values; placeholder text is a hard failure. Where a value is unknown,
  ask or omit the property; never invent prices, ratings, or dates.
- One `@graph` or clearly separated blocks; stable `@id` for the Organization node
  (`{origin}/#organization`).
- `dateModified` only when it reflects a genuine content change (date-bumping without edits is a
  spam signal).
- AggregateRating only when reviews genuinely exist on or for that page.
- Match visible page content exactly: markup that contradicts the visible page violates Google's
  structured-data guidelines.

### Step 4: Validate
- Parse-check the JSON (a malformed block voids all structured data on the page).
- Check required properties per type against schema.org and Google's structured-data docs.
- Instruct the user to confirm in Google's Rich Results Test before shipping (only for the types
  that still produce rich results) and the Schema Markup Validator for the rest.

## Output Format

```markdown
# Schema for {url}

## Blocks to add
{one fenced html block per script tag, paste-ready, real values}

## Per-block intent
| Block | Type | Outcome targeted | Rich-result eligible (24 Jul 2026) |
|-------|------|------------------|-------------------------------------|

## Existing markup findings
{duplicates, errors, contradictions with visible content, or "none found"}

## Validation instructions
{exact steps: which validator per block, what a pass looks like}
```

## Quality validation (before returning)

- [ ] Every block parses as valid JSON
- [ ] No placeholder or invented values; unknown properties omitted or asked for
- [ ] No duplicate types against existing page markup
- [ ] FAQPage (if emitted) labelled AI-extractability only, with the 7 May 2026 removal noted
- [ ] Rich-result claims made only for the confirmed surviving types
- [ ] dateModified / AggregateRating only where genuinely true

## After Completion

- Log the markup state for the domain in `.claude/agent-memory/seo/MEMORY.md`
- Recommend `entity-optimization` if the Organization/sameAs web is thin, and `/geo-audit` if the
  goal is AI citation (schema alone will not get it)
- Add a re-validation task to `Task Board.md` for after deployment
