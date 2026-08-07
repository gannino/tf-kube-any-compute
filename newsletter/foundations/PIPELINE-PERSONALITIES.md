# Pipeline Personalities — what each rendering layer does to our HTML

The newsletter passes through multiple rendering layers between source file and subscriber inbox. Each layer has its own quirks. Each quirk has bitten us at least once. This file documents every known one so the stylist agent and the auditor can pre-flight check for them.

---

## The pipeline (top to bottom)

```
issues/NNN.md  (source, markdown + frontmatter + raw HTML for TIP_BODY)
   ↓ build.py applies template + replaces placeholders
issues/NNN-rendered.html  (rendered HTML, our authoritative output)
   ↓ paste into Beehiiv editor
Beehiiv post  (Beehiiv strips/transforms before send)
   ↓ Beehiiv send to subscriber
Email rendering  (varies wildly per client)
   ↓ subscriber reads
The actual user experience
```

Every transition can degrade quality. Every transition has a personality.

---

## Layer 1: Beehiiv (the broadcast platform)

Beehiiv is the platform we send from. It does heavy processing before sending.

### What Beehiiv strips

- **`<style>` tags** — completely removed. No `@media` queries, no class-based styling, no `prefers-color-scheme`.
- **`<link>` tags** — removed.
- **`<script>` tags** — removed (correctly, for security).
- **CSS classes** — kept in HTML attributes, but useless because there's no `<style>` block to apply them.
- **External font references** — `@font-face` and Google Fonts links don't survive.

### What Beehiiv preserves

- **Inline styles on elements** — these survive intact.
- **HTML attributes** — `width`, `align`, `border`, `cellpadding` preserved.
- **HTML structure** — divs, tables, paragraphs preserved.
- **Standard HTML entities** (`&middot;`, `&mdash;`, `&rarr;`, `&hellip;`) — preserved.

### What Beehiiv mangles

- **Non-ASCII characters in raw paste** — UTF-8 bytes get re-decoded as Mac Roman or Latin-1, producing mojibake (e.g., `↓` becomes `‚Üì`, `·` becomes `¬∑`, `—` becomes various nonsense).
- **`<body>` background colour** — Beehiiv overrides this with its own canvas (typically white). Any styling that relied on a dark `<body>` background is gone.
- **Wide `<table>` layouts** — Beehiiv may add its own `<table>` borders that show as visible lines. Suppress with `border="0" cellpadding="0" cellspacing="0" style="border:0;border-collapse:collapse"`.

### Implications for our HTML

1. **Use HTML entities for every non-ASCII character.** No literal `↓`, `·`, `—`, `→`, `…`. Use `&darr;`, `&middot;`, `&mdash;`, `&rarr;`, `&hellip;`. The auditor enforces this.
2. **Inline styles only.** Never rely on `<style>` blocks or CSS classes.
3. **Don't depend on `<body>` background.** Every block that needs a background colour must declare it on its own wrapper element (a div or table cell).
4. **Tables get explicit border-suppressing styling.** All layout tables include `role="presentation" border="0" cellpadding="0" cellspacing="0" style="border-collapse:collapse;border:0"`.

### Beehiiv API gating (relevant to send automation)

- The Beehiiv `POST /v2/publications/{pub}/posts` endpoint requires the **Enterprise plan**. We are not on Enterprise. Send automation is therefore manual paste only until plan changes.
- Subscriber count, publication metadata, and other GET endpoints work on all plans.

---

## Layer 2: Gmail web (largest desktop client, ~30% of all opens)

Gmail web is the dominant rendering target. Most of our deliverability decisions are calibrated against it.

### Gmail's defaults that affect rendering

- **Images blocked by default** until the user clicks "Display images below". Implications: images can't carry critical content. Alt text matters.
- **Maximum HTML size before clipping**: 102KB. Beyond this, Gmail shows `[Message clipped]` with a "View entire message" link. Subscribers who hit this lose the bottom half of the email until they click through.
- **`prefers-color-scheme` is NOT respected.** Gmail web has its own dark mode handling that ignores the media query. Designing for both light and dark with media queries doesn't work for Gmail web subscribers.
- **Threading by subject line.** Gmail groups emails with the same subject and may collapse "duplicate" content across the thread, hiding it as `...` markers. Implication: every preview send must use a unique subject.

### Gmail's specific quirks

- **Auto-dark-mode** on some accounts inverts background and text colours via its own algorithm. The result can be unpredictable. Designing light-first with explicit text colours on light backgrounds gives the best cross-mode result.
- **Promotions tab classification.** Triggers include: too many images, too many links, marketing language, lots of inline tracking pixels. Newsletters with low link-to-text ratio and personal voice (like ours) usually land in Primary.
- **Reply detection.** When subscribers reply to our emails, Gmail uses that as a strong signal to keep future emails in Primary tab. The "Hit reply, I read every email personally" CTA is partly a deliverability play.

### Implications for our HTML

1. **Total HTML size kept under 80KB.** Hard budget in BUDGETS.md.
2. **Every preview send uses timestamp-suffixed subject.** Implemented in `send.js`.
3. **No `prefers-color-scheme` media queries.** Don't try to be dark/light adaptive. Pick light-first with strategic dark accents (the hybrid pattern we settled on).
4. **No image-dependent meaning.** All critical content is text.
5. **The reply ask is real, not decorative.** It's a deliverability signal; treat it accordingly.

---

## Layer 3: Outlook (desktop + web)

Outlook is the second-most-common client and the trickiest to render for. Two sub-flavours: Outlook Desktop (Word-based renderer) and Outlook Web/365 (modern but quirky).

### Outlook Desktop quirks

- **Renders HTML using Microsoft Word's engine.** This is genuinely awful for modern HTML.
- **No CSS Flexbox.** Doesn't render at all.
- **No CSS Grid.** Doesn't render at all.
- **No SVG.** Falls back to broken image icon.
- **Background images often broken.** Use solid colours.
- **`<table>` layouts are required** for any multi-column structure.
- **Some CSS properties simply ignored**: `border-radius` (sharp corners only), `box-shadow` (no shadows), some `padding` configurations.

### Outlook Web quirks

- **Better than Desktop but still not great.** Modern HTML mostly renders, but with subtle differences from Gmail.
- **`prefers-color-scheme` not respected.**
- **Some inline style properties stripped**, especially newer ones.

### Implications for our HTML

1. **Always use `<table>` for multi-column layouts.** Even if it's just a 2-column header. Never `<div style="display:flex">`.
2. **Test rendering in Outlook before any new template change.** Specifically: verify the byline, header, and code blocks don't blow up.
3. **No reliance on `border-radius` for critical visual signal.** It's a nice-to-have, not load-bearing.
4. **No SVG.** Use PNG or skip imagery entirely.

---

## Layer 4: Apple Mail / iOS Mail (most permissive, ~25-30% of opens for tech newsletters)

The friendliest client. Almost everything renders correctly. But it has its own surprises.

### Apple Mail behavior

- **Respects `prefers-color-scheme`.** This is the only major client where dark/light adaptive media queries actually work.
- **Auto-dark-mode by default on iOS.** Some users always read email in dark mode, which inverts our light-mode design. Critical text-on-background contrast must be readable both ways.
- **Renders modern CSS mostly correctly** — flex, grid, svg, custom fonts.

### Implications

1. **Light-first design works.** When iOS auto-inverts to dark, our light-on-white scheme generally inverts to light-on-dark cleanly.
2. **Don't put critical content on coloured backgrounds without explicit text-colour declaration.** Auto-invert can mess this up.
3. **Test on actual iPhone before any major template change.** Most subscribers read on phone, and iOS Mail is the dominant phone client.

---

## Layer 5: Mobile reading (across all clients)

~70% of email opens are on mobile. The viewport is narrow, attention is short.

### Implications

1. **Single-column layout.** Two-column layouts collapse awkwardly.
2. **600px max width** for the main container. This is the email-design standard.
3. **Tap targets at least 44px tall.** Buttons, links — make sure they're easy to tap.
4. **Font size minimum 14px in body content.** Smaller is hard to read on phone.
5. **Test mobile preview** before every issue. The Resend preview to your inbox is a real test on real device.

---

## Pre-flight rendering tests (run before every send)

The stylist agent runs these tests on the rendered HTML before approving for send.

### Mechanical tests (automated)

1. **Non-ASCII character scan.** Every literal non-ASCII character is replaced with its HTML entity (`&...;`). Zero literal `→`, `↓`, `·`, `—`, `…` in source.
2. **HTML size check.** Total bytes < 80KB.
3. **Outbound link validation.** Every `<a href="...">` returns 200 (HTTP HEAD request).
4. **Inline-style enforcement.** No `<style>` blocks, no `<link>` tags, no `class=` attributes that would require external CSS.
5. **Table-layout check.** Every layout `<table>` includes `border="0" cellpadding="0" cellspacing="0" style="border-collapse:collapse;border:0"`.
6. **Background-colour declarations.** Every visible block that's not on a default white/light page has `background:` declared on its own wrapper.

### Manual tests (visual review)

1. **Open the Resend preview in Gmail web.** Confirm: full content visible, no clipping, no `[Message clipped]` warning.
2. **Open the Resend preview in Apple Mail (iOS or macOS).** Confirm: dark-mode auto-invert is acceptable, all text readable.
3. **Paste into Beehiiv editor and use Beehiiv's preview.** Confirm: no mojibake, no Beehiiv-added borders, all blocks render.
4. **Open on a phone.** Confirm: single-column readable, tap targets work, font size acceptable.

---

## Updating this file

When a new pipeline quirk is discovered:
1. Add it to the relevant layer's section above
2. Add the implication for our HTML
3. Add a pre-flight test that catches it
4. Document in the changelog below

This file gets longer over time as we discover more quirks. That's expected and correct.

---

## Changelog

- **2026-04-27** — Initial document. Beehiiv quirks documented from Issue 001 development (mojibake encoding issue, body-background stripping, broadcast API plan-gating). Gmail quirks documented from Issue 001 testing (thread-trimming on duplicate subjects, 102KB clip threshold, `prefers-color-scheme` non-support). Outlook and Apple Mail quirks documented from general email-rendering knowledge and standard email-design references. Mobile rendering implications standardised against 600px / 14px / 44px-tap conventions.
