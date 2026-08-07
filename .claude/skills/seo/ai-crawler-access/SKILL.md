---
user-invocable: false
description: Make a site technically reachable and readable by AI crawlers so ChatGPT, Perplexity, and Claude can cite it. Covers the server-side-rendering requirement (with a curl test), a copy-paste robots.txt allow-list for the AI citation bots, the Cloudflare default-block check, an AI-bot user-agent reference table, and GA4 AI-referral attribution setup.
version: 2.1.0
context: fork
---

# AI Crawler Access

## Purpose

The best-written, most citable page on the internet earns zero AI citations if the crawler cannot reach it or cannot read it. This skill closes the two technical gates that silently make pages invisible to AI engines: **client-side rendering** (the crawler reads a blank page) and **crawler blocking** (the crawler is turned away at robots.txt or the CDN). It also sets up the measurement so you can prove AI traffic is arriving.

These are the two **[GATE]** criteria in `geo-readiness-audit`. A gate failure forces a BLOCK verdict because no amount of editorial quality matters if the engine never sees the content. Fix these first.

**Category**: SEO & Search, GEO / AI Search

## Gate 1, Server-side rendering (the zero-JavaScript reality)

**The fact that drives everything:** the major non-Google AI crawlers execute **no JavaScript**. An analysis of over 500 million GPTBot fetches found zero evidence of JS execution. As of mid-2026, GPTBot, OAI-SearchBot, ChatGPT-User, ClaudeBot, Claude-SearchBot, PerplexityBot, and Bytespider all receive the **raw HTML response before any script runs**. The one meaningful exception is Google's Gemini, which reuses Googlebot's Web Rendering Service. [Source: industry standard, 500M+ GPTBot fetch analysis; crawler behaviour 2025-2026]

So if your answer content is injected by client-side JavaScript (a typical React/Vue/Angular SPA with `useEffect`-loaded content), every AI engine except Google receives a page with no answer on it. You are invisible to ChatGPT, Perplexity, and Claude.

### Test it with curl (do this before assuming anything)

Pick a distinctive phrase from the answer content you can see in a browser, then check whether it exists in the raw HTML:

```bash
# Does the answer content ship in the raw HTML?
curl -sL "https://example.com/your-page" | grep -i "a distinctive phrase from your answer"

# See how much real content is in the raw HTML vs an empty shell:
curl -sL "https://example.com/your-page" | grep -o '<p[^>]*>[^<]*</p>' | head -20

# Confirm the AI crawler's-eye view by sending its user-agent (no JS is run either way):
curl -sL -A "OAI-SearchBot/1.0; +https://openai.com/searchbot" "https://example.com/your-page" | grep -i "your phrase"
```

**Reading the result:**
- Phrase present in curl output -> content is server-rendered. Gate 1 PASS.
- Phrase visible in browser but **absent** from curl output -> content is client-rendered and AI-invisible. Gate 1 FAIL.

### The fix

Get the answer-bearing content into the initial HTML response:
- **SSR (server-side rendering)**, render on the server per request (Next.js `app` router server components, Nuxt, Remix, Astro SSR). Best for dynamic, frequently-changing pages.
- **SSG (static site generation)**, pre-render to HTML at build time (Astro, Next `generateStaticParams`, Hugo, Eleventy). Best for content that changes on a publish cadence: blog posts, docs, definitions, comparisons.
- **Hybrid / prerendering**, serve pre-rendered HTML to bots while humans get the SPA (e.g. a prerender service, or framework-level partial hydration).

The anti-pattern to remove: answer content loaded in a client `useEffect` / `onMounted` / `ngOnInit`. Move that content to the server render path. Then re-run the curl test to confirm it now ships in the raw HTML.

## Gate 2, Crawler access (robots.txt + the CDN)

A page can be perfectly server-rendered and still never get cited because the crawler is blocked. Two places block it: `robots.txt` and the CDN.

### Copy-paste robots.txt allow block

Add this block to `robots.txt` to explicitly welcome the AI citation bots. Explicit allow beats silence: it is unambiguous, and it documents intent for anyone auditing the file later.

```
# --- AI citation + answer engines: explicitly allowed ---
# OpenAI (ChatGPT search + browsing citations)
User-agent: OAI-SearchBot
Allow: /

User-agent: ChatGPT-User
Allow: /

# OpenAI model-training crawler (allow only if you want training inclusion)
User-agent: GPTBot
Allow: /

# Perplexity
User-agent: PerplexityBot
Allow: /

# Anthropic / Claude (search citations + user-initiated fetches)
User-agent: ClaudeBot
Allow: /

User-agent: Claude-SearchBot
Allow: /

# Google generative (AI Overviews / Gemini grounding)
User-agent: Google-Extended
Allow: /

# Microsoft / Bing (powers Copilot)
User-agent: Bingbot
Allow: /

# Apple Intelligence
User-agent: Applebot-Extended
Allow: /

# Sitemap helps every engine discover answer pages
Sitemap: https://example.com/sitemap.xml
```

Notes:
- Replace the `Sitemap:` URL with the real one.
- `GPTBot` and `Google-Extended` govern **training/grounding** inclusion specifically; keep them allowed if you want your content used to ground AI answers, remove those two blocks if you want citations-only without training inclusion. `OAI-SearchBot`, `PerplexityBot`, `ClaudeBot`, and `Claude-SearchBot` are the ones that matter most for live citations.
- A missing `robots.txt`, or one with no rule for these agents, is default-allow, but explicit is safer and survives future edits that add a broad `Disallow`.
- Verify after deploy: `curl -sL https://example.com/robots.txt` and confirm the block is present and served (200, not a SPA 404 page).

### The Cloudflare default-block check (the silent killer)

From **1 July 2025, Cloudflare began blocking AI crawlers by default on new domains.** It moved AI bots from an opt-out to an **opt-in** model and launched Pay-Per-Crawl (blocked crawlers get an HTTP **402 Payment Required**). Many sites are blocking the exact bots they want to cite them and have no idea, because the block lives at the CDN, not in `robots.txt`. [Source: industry standard, Cloudflare announcement 1 July 2025]

**Check, on any Cloudflare-fronted site:**
1. Cloudflare dashboard -> the domain -> **Security -> Bots** (and **Security -> Settings**). Look for "Block AI bots" / AI Scrapers & Crawlers managed rules and "Bot Fight Mode".
2. If AI-bot blocking is ON, either turn it off, or exempt the citation bots: create a WAF custom rule that **skips** the AI-bot managed rule when the user-agent matches `OAI-SearchBot|PerplexityBot|ClaudeBot|Claude-SearchBot`.
3. Confirm from outside with the bot user-agent:

```bash
# A 200 with your content = reachable. A 403/402/challenge page = CDN-blocked.
curl -sL -o /dev/null -w "%{http_code}\n" -A "PerplexityBot/1.0 (+https://perplexity.ai/bot)" "https://example.com/your-page"
```

Other CDNs/WAFs (Fastly, Akamai, AWS WAF) and security plugins (Wordfence) can block by user-agent too, check their bot rules the same way if the curl test returns a challenge or 403.

## AI-bot user-agent reference table

The agents that matter for AI search visibility, what each does, and whether it runs JavaScript. Use this to read server logs and to write precise allow/exempt rules.

| User-agent token | Operator | Purpose | Runs JS? | Allow for citations? |
|---|---|---|---|---|
| `OAI-SearchBot` | OpenAI | ChatGPT search index + citations | No | Yes (key) |
| `ChatGPT-User` | OpenAI | User-initiated fetch in ChatGPT | No | Yes |
| `GPTBot` | OpenAI | Model-training crawl | No | Optional (training) |
| `PerplexityBot` | Perplexity | Perplexity answer index + citations | No | Yes (key) |
| `ClaudeBot` | Anthropic | Claude crawl / index | No | Yes (key) |
| `Claude-SearchBot` | Anthropic | Claude search citations | No | Yes (key) |
| `Google-Extended` | Google | Gemini / AI grounding inclusion control | n/a (token) | Optional (grounding) |
| `Googlebot` | Google | Powers AI Overviews; **does render JS** | Yes | Yes (already) |
| `Bingbot` | Microsoft | Powers Copilot answers | Yes | Yes |
| `Applebot-Extended` | Apple | Apple Intelligence inclusion control | n/a (token) | Optional |
| `Bytespider` | ByteDance | TikTok/Doubao AI crawl | No | Optional |

Note the split: `Googlebot` and `Bingbot` render JavaScript (so Google's and Microsoft's AI features can see client-rendered content), but the dedicated AI crawlers do not. That is precisely why Gate 1 (SSR) exists, optimising only for Google's renderer leaves you invisible to ChatGPT, Perplexity, and Claude.

## Measurement, GA4 AI-referral attribution

Once the gates are open, prove AI traffic is arriving. GA4 does not group AI engines out of the box, so build the segment yourself.

### Step 1, confirm the referrers reaching you

AI engines send referral traffic from hosts like: `chatgpt.com`, `chat.openai.com`, `perplexity.ai`, `gemini.google.com`, `copilot.microsoft.com`, `claude.ai`, `bing.com` (Copilot). In GA4: **Reports -> Acquisition -> Traffic acquisition**, add **Session source / medium** as the dimension, and search for these hosts to see current volume.

### Step 2, create an "AI Referrals" channel/segment

- **Exploration (fastest):** Explore -> Free-form -> add dimension **Session source**, add a filter where Session source `matches regex`:
  ```
  chatgpt|openai|perplexity|gemini|copilot|claude|bing\.com
  ```
  Add **Sessions**, **Engaged sessions**, **Conversions** as values. Save it as the AI-referrals view.
- **Durable channel group:** Admin -> Data settings -> Channel groups -> create a custom group with a channel "AI Assistants" defined by the same Source regex, so AI traffic shows in standard reports going forward.

### Step 3, watch the crawler hits (server-side, complements GA4)

GA4 only sees humans who clicked through. To confirm the **bots** themselves are fetching (the leading indicator that citations are coming), grep server/access logs for the user-agents in the reference table:

```bash
grep -E "OAI-SearchBot|PerplexityBot|ClaudeBot|Claude-SearchBot|GPTBot" /path/to/access.log | wc -l
```

Rising bot fetches -> the gates are open and engines are ingesting. Rising referral sessions in the GA4 AI segment -> citations are converting to clicks. Track both.

## Process (run order)

1. **Gate 1 first.** Curl-test the page. If client-rendered, fix rendering (SSR/SSG/hybrid) and re-test. Nothing else matters until this passes.
2. **Gate 2 robots.txt.** Add the allow block, deploy, verify it serves.
3. **Gate 2 CDN.** Check Cloudflare (or other CDN/WAF) for default AI-bot blocking; exempt the citation bots; curl-test with a bot user-agent for a 200.
4. **Measurement.** Stand up the GA4 AI-referrals segment and the log grep so impact is visible.
5. **Re-score** in `geo-readiness-audit` and confirm both gates now PASS.

## Quality validation (before returning)

- [ ] Gate 1 verified empirically with `curl` (phrase present in raw HTML), not assumed.
- [ ] robots.txt allow block deployed and confirmed served (200, real file).
- [ ] CDN checked for AI-bot default-block; citation bots confirmed reachable via a bot-user-agent curl returning 200.
- [ ] GA4 AI-referrals segment created with the source regex; log grep in place for bot fetches.
- [ ] Every figure cited carries its source; no em dashes.

## After completion

- Record both gate results and the current AI-referral baseline in `.claude/agent-memory/seo/MEMORY.md` for regression tracking.
- If the site was silently CDN-blocking AI bots, that is a high-value learning, nominate it to `.claude/knowledge-nominations.md` tagged `[SEO]`.
- With access open, the editorial work in `ai-answer-optimization` is what actually earns the citations, recommend it next.
