// Deterministic SERP-spam rubric (RAS dimension D5). Structural signals only,
// no LLM: content-farm URL shapes, missing publisher, bottom-tier sourcing,
// puffery density. Scores in [0,1]; higher = more slop.
import { hasPuffery } from './sanitize.mjs'

const FARM_URL = /(top-?\d+|best-?\d+|\d+-(best|top|ways|reasons|things)|listicle|ultimate-guide-to|you-wont-believe)/i

export function spamScore(source) {
  let s = 0
  const url = String(source.url ?? '')
  if (FARM_URL.test(url)) s += 0.35
  if (!source.publisher || /content\s*farm|unknown/i.test(source.publisher)) s += 0.25
  if ((source.tier ?? 5) >= 8) s += 0.3
  if (source.passage && hasPuffery(source.passage).flagged) s += 0.25
  if (source.is_primary) s -= 0.2
  return Math.max(0, Math.min(1, s))
}
