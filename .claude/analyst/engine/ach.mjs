// Analysis of Competing Hypotheses (Heuer) over the CEG.
// Build spec section 7.2 + the analyst design notes (fixed discrete diagnosticity rubric).
//
// The rules that make this the reasoning spine and not template-filling:
// - Hypotheses are MECE with priors summing to 1 (validated, tolerance 1%).
// - Consistency labels are a FIXED discrete rubric (CC/C/N/I/II), never free-typed
//   floats, so two runs converge on the same numbers.
// - The recommendation is the LEAST-DISCONFIRMED hypothesis (fewest weighted
//   inconsistencies), never the most-supported. This structurally inverts the
//   bullish default: absence-of-competitor evidence scored consistent with BOTH
//   blue-ocean and dead-zone moves nothing on its own.
// - Evidence consistent with ALL hypotheses (a generic big TAM) has near-zero
//   diagnosticity and is flagged so it cannot manufacture conviction.
// - Same origin haircut and freshness weighting as the belief propagator:
//   laundered evidence cannot vote twice inside ACH either.
import { node } from './ceg.mjs'
import { freshness } from './propagate.mjs'
import { haircut } from './independence.mjs'

export const LABEL_LR = { CC: 3.0, C: 1.5, N: 1.0, I: 0.66, II: 0.33 }
export const LOW_DIAGNOSTIC_SD = 0.05

// achPosteriors(ceg, { now }) ->
//   { hypotheses: [{id, prior, posterior, inconsistency}], leastDisconfirmed,
//     pSuccess, lowDiagnostic: [edgeIds], items }
export function achPosteriors(ceg, opts = {}) {
  if (!opts.now) throw new Error('opts.now (ISO timestamp) is required: determinism forbids Date.now()')
  const hyps = [...ceg.nodes.values()].filter((n) => n.kind === 'hypothesis')
  if (hyps.length < 2) throw new Error('ACH needs at least 2 competing hypotheses')
  const priorSum = hyps.reduce((a, h) => a + h.prior, 0)
  if (Math.abs(priorSum - 1) > 0.01) throw new Error(`hypothesis priors must sum to 1 (got ${priorSum.toFixed(3)})`)

  // Collect scored evidence: cites edges carrying hypothesis_scores.
  const items = []
  for (const e of ceg.edges) {
    if (e.rel !== 'cites' || !e.hypothesis_scores) continue
    if (e.weight === 0) continue // gated-out evidence cannot vote
    const src = node(ceg, e.from)
    if (!src || src.kind !== 'source') throw new Error(`ACH edge ${e.id}: source ${e.from} missing`)
    if (src.access === 'dead' || src.access === 'quarantined') continue
    const claim = node(ceg, e.to)
    const halfLife = claim?.half_life_days ?? 365
    const asOf = src.as_of_date || src.publish_date
    if (!asOf) throw new Error(`ACH source ${src.id}: as_of_date required`)
    const w = e.weight * freshness(asOf, opts.now, halfLife) // the evidence exponent
    for (const label of Object.values(e.hypothesis_scores)) {
      if (!(label in LABEL_LR)) throw new Error(`ACH edge ${e.id}: unknown consistency label "${label}"`)
    }
    items.push({ edgeId: e.id, originId: src.origin_id, scores: e.hypothesis_scores, w })
  }

  // Diagnosticity per item = spread of log-label-LR across hypotheses.
  // Near-zero spread = consistent with everything = moves nothing = flagged.
  const lowDiagnostic = []
  for (const it of items) {
    const lns = hyps.map((h) => Math.log(LABEL_LR[it.scores[h.id] ?? 'N']))
    const mean = lns.reduce((a, b) => a + b, 0) / lns.length
    const sd = Math.sqrt(lns.reduce((a, b) => a + (b - mean) ** 2, 0) / lns.length)
    it.diagnosticitySD = sd
    if (sd < LOW_DIAGNOSTIC_SD) lowDiagnostic.push(it.edgeId)
  }

  // Per-hypothesis log-likelihood with the origin haircut, then normalized posteriors.
  const rows = hyps.map((h) => {
    const hItems = items.map((it) => ({
      edgeId: it.edgeId,
      sourceId: it.edgeId,
      originId: it.originId,
      lnLR: Math.log(LABEL_LR[it.scores[h.id] ?? 'N']) * it.w,
    }))
    const { totalLnLR } = hItems.length ? haircut(hItems) : { totalLnLR: 0 }
    // Weighted inconsistency tally: the least-disconfirmed metric (Heuer).
    let inconsistency = 0
    for (const it of items) {
      const label = it.scores[h.id] ?? 'N'
      if (label === 'I') inconsistency += 1 * it.w
      if (label === 'II') inconsistency += 2 * it.w
    }
    return { id: h.id, text: h.text, prior: h.prior, success_consistent: !!h.success_consistent, logLik: totalLnLR, inconsistency }
  })

  const maxLog = Math.max(...rows.map((r) => Math.log(r.prior) + r.logLik))
  let z = 0
  for (const r of rows) {
    r.unnorm = Math.exp(Math.log(r.prior) + r.logLik - maxLog)
    z += r.unnorm
  }
  for (const r of rows) {
    r.posterior = r.unnorm / z
    delete r.unnorm
  }

  // The survivor: fewest weighted inconsistencies; posterior breaks ties.
  const ranked = [...rows].sort((a, b) => a.inconsistency - b.inconsistency || b.posterior - a.posterior)
  const pSuccess = rows.filter((r) => r.success_consistent).reduce((a, r) => a + r.posterior, 0)

  return {
    hypotheses: rows,
    ranking: ranked.map((r) => r.id),
    leastDisconfirmed: ranked[0].id,
    pSuccess,
    lowDiagnostic,
    items: items.map((it) => ({ edgeId: it.edgeId, originId: it.originId, diagnosticitySD: it.diagnosticitySD, w: it.w })),
  }
}
