// The ingest gates: no Evidence enters the CEG without passing all of them.
//   Gate 1  URL liveness (dead or unreachable source contributes nothing)
//   Gate 2  scope-bound verbatim precheck (the deterministic half of quote-grounding)
//   Gate 3  numeric tripwires (deterministic sanity over values and derivations)
//   Gate 4  provenance-completeness (no naked claims, no unsourced numbers)
// Build spec section 4 + the analyst design notes fixes 3/6. Phase A step 2.
//
// Design rules:
// - Deterministic and offline-testable: the fetcher is INJECTED, never ambient.
// - The LLM half of gate 2 (entailment on the spotlighted, cached passage) lives in
//   the evidence-integrator agent (step 4). A claim only reaches "supported" after
//   BOTH halves pass. The deterministic half here fails CLOSED on fabricated numbers
//   and scope mismatches without spending a single model call.
// - Gates never raise belief. They can only quarantine, zero, or flag.

import { classifyInjection } from './classify_injection.mjs'
import { hasPuffery, PUFFERY_LR_CAP } from './sanitize.mjs'

// ---------- number normalization (gate 2 verbatim precheck) ----------
const WORD_MULT = { trillion: 1e12, billion: 1e9, bn: 1e9, million: 1e6, mn: 1e6, thousand: 1e3 }
const LETTER_MULT = { t: 1e12, b: 1e9, m: 1e6, k: 1e3 }

// Extract every plausible numeric reading of a passage: "$14B", "14 billion",
// "1,200,000,000", "92%". Returns de-duplicated absolute values.
export function extractNumbers(text) {
  const vals = new Set()
  // attached single-letter multiplier: 14B, 1.2b, 350k (letter must not start a word)
  for (const m of String(text).matchAll(/(\d[\d,]*(?:\.\d+)?)([TBMKtbmk])(?![A-Za-z])/g)) {
    vals.add(parseFloat(m[1].replace(/,/g, '')) * LETTER_MULT[m[2].toLowerCase()])
  }
  // word multiplier: 14 billion, 1.2 bn
  for (const m of String(text).matchAll(/(\d[\d,]*(?:\.\d+)?)\s+(trillion|billion|bn|million|mn|thousand)\b/gi)) {
    vals.add(parseFloat(m[1].replace(/,/g, '')) * WORD_MULT[m[2].toLowerCase()])
  }
  // bare numbers (percent values read as-is)
  for (const m of String(text).matchAll(/(\d[\d,]*(?:\.\d+)?)/g)) {
    vals.add(parseFloat(m[1].replace(/,/g, '')))
  }
  return [...vals]
}

export function valueInPassage(value, passage, relTol = 0.005) {
  if (typeof value !== 'number' || !Number.isFinite(value)) return false
  return extractNumbers(passage).some(
    (v) => Math.abs(v - value) <= relTol * Math.max(Math.abs(v), Math.abs(value))
  )
}

// Scope binding: the claim's scope entities must actually appear in the passage.
// This is what catches "correct number, wrong entity" (platform vs product
// conflation, the single most common real citation error).
export function scopeEntitiesPresent(claim, passage) {
  const ents = claim?.scope_entities
  if (!Array.isArray(ents) || ents.length === 0) return { checked: false, present: true, missing: [] }
  const hay = String(passage).toLowerCase()
  const missing = ents.filter((e) => !hay.includes(String(e).toLowerCase()))
  return { checked: true, present: missing.length === 0, missing }
}

// ---------- gate 4: provenance-completeness ----------
export function provenanceComplete(source, claim) {
  const missing = []
  for (const f of ['origin_id', 'retrieved_at', 'content_hash']) {
    if (!source?.[f]) missing.push(`source.${f}`)
  }
  if (!source?.as_of_date && !source?.publish_date) missing.push('source.as_of_date')
  if (claim && ['quantity', 'price', 'forecast'].includes(claim.ctype) && !claim.reference_class) {
    missing.push('claim.reference_class')
  }
  return { complete: missing.length === 0, missing }
}

// ---------- the composite gate ----------
// gateEvidence({source, edge, claim}, {fetcher}) -> { verdict, failures, source, edge }
// Never mutates its inputs; returns updated copies. Any failure quarantines the
// evidence and zeroes the edge weight, so it cannot move belief.
export async function gateEvidence({ source, edge, claim }, { fetcher } = {}) {
  if (typeof fetcher !== 'function') {
    throw new Error('gateEvidence requires an injected fetcher (tests stub it; never ambient network)')
  }
  const src = { ...source }
  const edg = { ...edge }
  const failures = []

  // Gate 0a: injection heuristic + credibility-puffery cap (Gate-5 design).
  // Graded, not binary: accept / cap tier + fidelity / quarantine. Self-declared
  // authority never raises an LR; it caps one.
  if (src.passage) {
    const inj = classifyInjection(src.passage)
    src.inj_score = inj.score
    if (inj.action === 'quarantine') {
      src.injection_suspected = true
      failures.push({ gate: 'injection', class: 'quarantine', detail: `inj_score ${inj.score.toFixed(2)} (${inj.classes.join(', ')})` })
    } else if (inj.action === 'cap') {
      src.injection_suspected = true
      src.tier = Math.max(src.tier ?? 6, 6)
      edg.weight = Math.min(edg.weight ?? 1, 0.5)
    }
    const puff = hasPuffery(src.passage)
    if (puff.flagged && edg.LR > PUFFERY_LR_CAP) {
      edg.LR = PUFFERY_LR_CAP
      edg.puffery_capped = true
    }
  }

  // Gate 4 first: cheapest, fail-closed.
  const prov = provenanceComplete(src, claim)
  if (!prov.complete) failures.push({ gate: 'provenance', detail: prov.missing.join(', ') })

  // Gate 1: liveness.
  let live
  try {
    live = await fetcher(src.url)
  } catch {
    live = { status: 0 }
  }
  if (!live || live.status < 200 || live.status >= 400) {
    failures.push({ gate: 'liveness', detail: `status ${live?.status ?? 'unreachable'}` })
    src.access = 'dead'
  }

  // Gate 2 (deterministic half): verbatim value + scope binding, for numeric claims.
  if (claim && ['quantity', 'price', 'forecast'].includes(claim.ctype) && typeof claim.value === 'number') {
    if (!src.passage) {
      failures.push({ gate: 'quote_grounding', class: 'unsupported', detail: 'no stored passage to ground against' })
    } else if (!valueInPassage(claim.value, src.passage)) {
      failures.push({ gate: 'quote_grounding', class: 'unsupported', detail: `claim value ${claim.value} not present in the passage` })
    } else {
      const scope = scopeEntitiesPresent(claim, src.passage)
      if (scope.checked && !scope.present) {
        failures.push({
          gate: 'quote_grounding',
          class: 'scope_mismatch',
          detail: `value present but scope entities missing from passage: ${scope.missing.join(', ')}`,
        })
      }
    }
  }

  if (failures.length) {
    if (src.access !== 'dead') src.access = 'quarantined'
    src.quarantine_reason = failures.map((f) => `${f.gate}${f.class ? ':' + f.class : ''}`).join('; ')
    edg.weight = 0
  }
  return { verdict: failures.length ? 'quarantined' : 'accepted', failures, source: src, edge: edg }
}

// ---------- gate 3: numeric tripwires (deterministic sanity) ----------
const claimVal = (c) => (typeof c?.value === 'number' ? c.value : c?.interval?.p50)

// SAM must not exceed TAM.
export function twSamVsTam(samClaim, tamClaim) {
  const sam = claimVal(samClaim)
  const tam = claimVal(tamClaim)
  if (typeof sam !== 'number' || typeof tam !== 'number') return { flag: false }
  return sam > tam
    ? { flag: true, tripwire: 'sam_exceeds_tam', detail: `SAM ${sam} > TAM ${tam}` }
    : { flag: false }
}

// Segments must sum to (about) the total.
export function twSegmentSum(totalClaim, partClaims, tol = 0.05) {
  const total = claimVal(totalClaim)
  const sum = partClaims.map(claimVal).reduce((a, b) => a + b, 0)
  if (typeof total !== 'number' || !Number.isFinite(sum)) return { flag: false }
  const off = Math.abs(sum - total) / Math.max(Math.abs(total), 1e-9)
  return off > tol
    ? { flag: true, tripwire: 'segment_sum', detail: `segments sum ${sum} vs total ${total} (${(off * 100).toFixed(1)}% off)` }
    : { flag: false }
}

// Margins above 95% are flagged unless explicitly acknowledged.
export function twMarginBound(claim, max = 0.95) {
  let v = claimVal(claim)
  if (typeof v !== 'number') return { flag: false }
  if (claim.unit === '%' && v > 1) v = v / 100
  if (v > max && !(claim.flags || []).includes('high_margin_ok')) {
    return { flag: true, tripwire: 'margin_bound', detail: `margin ${v} exceeds ${max} without high_margin_ok` }
  }
  return { flag: false }
}

// Higher revenue must break even SOONER, never later (the V-08 inversion).
export function twBreakevenDirection(scenarios) {
  const s = [...scenarios].sort((a, b) => a.revenue - b.revenue)
  for (let i = 1; i < s.length; i++) {
    if (s[i].breakEvenMonths > s[i - 1].breakEvenMonths) {
      return {
        flag: true,
        tripwire: 'breakeven_inverted',
        detail: `revenue ${s[i].revenue} breaks even later (${s[i].breakEvenMonths}mo) than revenue ${s[i - 1].revenue} (${s[i - 1].breakEvenMonths}mo)`,
      }
    }
  }
  return { flag: false }
}

// A single reported ratio built from wide input ranges is cherry-picking.
// Force pessimistic / base / optimistic reporting instead.
export function twRatioCherryPick({ ltv, cac, reported }, wideFactor = 3) {
  const wide = ltv.max / ltv.min >= wideFactor || cac.max / cac.min >= wideFactor
  const scenarios = {
    pessimistic: ltv.min / cac.max,
    base: (ltv.min + ltv.max) / 2 / ((cac.min + cac.max) / 2),
    optimistic: ltv.max / cac.min,
  }
  if (wide && typeof reported === 'number') {
    return {
      flag: true,
      tripwire: 'ratio_cherrypick',
      detail: `single ratio ${reported} reported from wide ranges; must report all three scenarios`,
      scenarios,
    }
  }
  return { flag: false, scenarios }
}

// Absence of evidence must not confirm. "No competitor found" is a finding with
// TWO readings (blue ocean AND dead zone); it may never carry a strong LR on its own.
export function twAbsenceEvidence(edge, maxLR = 1.5) {
  if (edge.etype === 'absence' && edge.LR > maxLR) {
    return {
      flag: true,
      tripwire: 'absence_as_confirmation',
      detail: `absence-of-evidence carried LR ${edge.LR}; forced to 1.0 (non-diagnostic) pending ACH dual-reading`,
      forcedLR: 1.0,
    }
  }
  return { flag: false }
}

// Fast-moving metrics older than 6 months are flagged visibly (decay already
// down-weights them; the tripwire makes the staleness legible in the dossier).
export function twStaleFastMover(source, claim, nowISO, maxAgeDays = 180) {
  const asOf = source.as_of_date || source.publish_date
  if (!asOf) return { flag: false }
  const ageDays = (Date.parse(nowISO) - Date.parse(asOf)) / 86_400_000
  const fastMover = (claim.half_life_days ?? 365) <= 90
  if (fastMover && ageDays > maxAgeDays) {
    return {
      flag: true,
      tripwire: 'stale_fast_mover',
      detail: `fast-moving metric is ${Math.round(ageDays)} days old (half-life ${claim.half_life_days}d); decay has down-weighted it and it must be flagged in the dossier`,
    }
  }
  return { flag: false }
}
