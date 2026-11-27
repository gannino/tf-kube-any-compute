// The Retrieval Adequacy Score (RAS): did we LOOK hard enough, and is the pool
// skewed? The retrieval analog of the selection-bias fix (the analyst design notes section
// 2b). Computed, never assumed, from the pool's structure: coverage vs the
// expected-source-class checklist, primary depth, viewpoint diversity, recency
// spread, spam fraction, and saturation. A perfectly calibrated engine over a
// biased retrieval is confidently biased; this is the term that admits it.
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'
import { node, citesEdges } from './ceg.mjs'
import { spamScore } from './spamscore.mjs'
import { saturationForClaim } from './saturation.mjs'

const here = dirname(fileURLToPath(import.meta.url))
export function loadESC(path = join(here, '..', 'config', 'expected-source-classes.json')) {
  return JSON.parse(readFileSync(path, 'utf8'))
}

// Mechanical source-class heuristic when source_class is not set explicitly.
export function classifySource(src) {
  if (src.source_class) return src.source_class
  if (String(src.url ?? '').startsWith('internal://')) return 'internal_primary'
  if (src.is_primary && (src.tier ?? 9) <= 3) return 'primary_artifact'
  if ((src.tier ?? 9) <= 5) return 'reputable_secondary'
  return 'weak_secondary'
}

const EPS = 0.05
const geoMean = (dims, weights) => {
  let num = 0
  let den = 0
  for (const [k, v] of Object.entries(dims)) {
    if (v === null || v === undefined) continue // not measured: excluded, never defaulted
    const w = weights[k] ?? 0
    num += w * Math.log(Math.max(v, EPS))
    den += w
  }
  return den > 0 ? Math.exp(num / den) : 0
}

// rasForClaim(claimId, ceg, { esc, isCrux }) ->
//   { rasClaim, dims, nEffOrigins, missingRequired, missingRecommended, gaps, notMeasured }
export function rasForClaim(claimId, ceg, { esc = loadESC(), isCrux = false } = {}) {
  const claim = node(ceg, claimId)
  if (!claim || claim.kind !== 'claim') throw new Error(`no such claim: ${claimId}`)
  const cfg = esc.classes_by_ctype[claim.ctype] ?? esc.classes_by_ctype.event
  const edges = citesEdges(ceg, claimId).filter((e) => (e.weight ?? 0) > 0)
  const sources = edges
    .map((e) => ({ edge: e, src: node(ceg, e.from) }))
    .filter(({ src }) => src && src.access !== 'dead' && src.access !== 'quarantined')

  const gaps = []
  const notMeasured = []
  if (!sources.length) {
    const missingRequired = [...cfg.required]
    for (const c of missingRequired) gaps.push({ type: 'source_class_fill', missing: c, severity: 1 })
    return { rasClaim: 0, dims: {}, nEffOrigins: 0, missingRequired, missingRecommended: [...cfg.recommended], gaps, notMeasured: ['all'] }
  }

  // D1 coverage vs the checklist (internal primary satisfies the primary anchor).
  const classes = new Set(sources.map(({ src }) => classifySource(src)))
  const has = (c) => classes.has(c) || (c === 'primary_artifact' && classes.has('internal_primary'))
  const missingRequired = cfg.required.filter((c) => !has(c))
  const missingRecommended = cfg.recommended.filter((c) => !has(c))
  const reqScore = cfg.required.length ? (cfg.required.length - missingRequired.length) / cfg.required.length : 1
  const recScore = cfg.recommended.length ? (cfg.recommended.length - missingRecommended.length) / cfg.recommended.length : 1
  const coverage = 0.7 * reqScore + 0.3 * recScore
  for (const c of missingRequired) gaps.push({ type: 'source_class_fill', missing: c, severity: 1 })
  for (const c of missingRecommended) gaps.push({ type: 'source_class_fill', missing: c, severity: 0.4 })

  // D2 primary depth over ORIGINS (six blogs paraphrasing one press release is one
  // non-primary origin, and a quantity claim without a primary anchor floors).
  const originPrimary = new Map()
  for (const { src } of sources) {
    const cls = classifySource(src)
    const isP = cls === 'primary_artifact' || cls === 'internal_primary'
    originPrimary.set(src.origin_id, (originPrimary.get(src.origin_id) ?? false) || isP)
  }
  const nEffOrigins = originPrimary.size
  const primaryFrac = [...originPrimary.values()].filter(Boolean).length / nEffOrigins
  const primary_depth = cfg.primary_anchor_required && primaryFrac === 0 ? 0.25 : Math.min(1, 0.5 + 0.5 * primaryFrac)

  // D3 viewpoint diversity by origin stance (from edge LRs, zero extra model calls).
  const stance = new Map()
  for (const { edge, src } of sources) {
    const st = edge.LR < 0.95 ? 'ref' : edge.LR > 1.05 ? 'sup' : 'neu'
    const cur = stance.get(src.origin_id)
    stance.set(src.origin_id, cur === 'ref' ? 'ref' : st) // a refuting edge marks the origin refuting
  }
  const counts = { sup: 0, neu: 0, ref: 0 }
  for (const st of stance.values()) counts[st]++
  const total = stance.size
  let H = 0
  for (const k of ['sup', 'neu', 'ref']) {
    const p = counts[k] / total
    if (p > 0) H -= p * Math.log(p)
  }
  let viewpoint_diversity = H / Math.log(3)
  let viewpointCapped = false
  if (claim.falsifier && counts.ref === 0 && nEffOrigins >= 2) {
    viewpoint_diversity = Math.min(viewpoint_diversity, esc.viewpoint_cap_no_refuting_origin ?? 0.4)
    viewpointCapped = true
    gaps.push({ type: 'disconfirming', missing: 'no refuting origin despite a falsifiable claim', severity: 0.8 })
  }

  // D4 recency spread: a slow-moving claim sourced ONLY from the last few weeks has
  // no historical baseline (recency monoculture).
  const dates = sources.map(({ src }) => Date.parse(src.as_of_date ?? src.publish_date)).filter(Number.isFinite)
  let distribution = 1
  if (dates.length >= 2 && (claim.half_life_days ?? 365) >= 180) {
    const spreadDays = (Math.max(...dates) - Math.min(...dates)) / 86_400_000
    if (spreadDays < 45) distribution = 0.5
  }

  // D5 cleanliness: 1 - origin-mean spam score.
  const originSpam = new Map()
  for (const { src } of sources) {
    const arr = originSpam.get(src.origin_id) ?? []
    arr.push(spamScore(src))
    originSpam.set(src.origin_id, arr)
  }
  const meanSpam = [...originSpam.values()].map((a) => a.reduce((x, y) => x + y, 0) / a.length).reduce((x, y) => x + y, 0) / originSpam.size
  const serp_cleanliness = 1 - meanSpam

  // D6 saturation via capture-recapture; honestly not-measured without two passes.
  const sat = saturationForClaim(sources.map(({ src }) => src))
  const saturation = sat ? sat.recallHat : null
  if (!sat) notMeasured.push('saturation')

  const dims = { coverage, primary_depth, viewpoint_diversity, distribution, serp_cleanliness, saturation }
  const weights = esc.dimension_weights[claim.ctype] ?? esc.dimension_weights.default
  let rasClaim = geoMean(dims, weights)
  if (isCrux && missingRequired.length) {
    rasClaim = Math.min(rasClaim, esc.ras_floor_on_missing_required_crux ?? 0.25)
  }
  return { rasClaim, dims, nEffOrigins, missingRequired, missingRecommended, gaps, notMeasured, viewpointCapped, saturationDetail: sat }
}

// The run-level roll-up: decision-weighted, so a skewed pool on the crux tanks it
// and a skewed pool on a settled peripheral claim barely dents it.
export function rasRun(perClaim) {
  const rows = perClaim.filter((r) => typeof r.ras === 'number')
  if (!rows.length) return null
  const den = rows.reduce((a, r) => a + r.decisionWeight, 0)
  return rows.reduce((a, r) => a + r.decisionWeight * r.ras, 0) / den
}

// Retrieval-repair tasks join the SAME frontier as claims: a missing primary on the
// crux out-prioritises a nice-to-have on a peripheral. Feed the result to
// rankFrontier as priorityOverride.
export function retrievalGapPriority({ decisionWeight, rasClaim, belief = 0.5, severity = 1 }) {
  const deficit = 1 - rasClaim
  const sensitivity = Math.max(4 * belief * (1 - belief), 0.25)
  return decisionWeight * deficit * sensitivity * severity
}
