// Deterministic belief propagator over the claim-evidence graph.
// Pure arithmetic: no LLM, no network, no Date.now(). Same frozen CEG in,
// same numbers out. Build spec: the analyst design notes
// v3 note: the QBAF calculus (argumentation.mjs) replaces these internals later
// and MUST degrade to exactly these numbers on an attack-free graph
// (the analyst design notes, punch list item 1). Do not add hidden nondeterminism here.
import { citesEdges, node } from './ceg.mjs'
import { haircut } from './independence.mjs'

export const LR_MIN = 0.1
export const LR_MAX = 10

export function clampLR(lr) {
  if (typeof lr !== 'number' || !Number.isFinite(lr) || lr <= 0) throw new Error(`invalid LR: ${lr}`)
  return Math.min(LR_MAX, Math.max(LR_MIN, lr))
}

// Fact decay (spec 4.5): freshness = 0.5 ^ (age_days / half_life_days)
export function freshness(asOfISO, nowISO, halfLifeDays) {
  const ageMs = Date.parse(nowISO) - Date.parse(asOfISO)
  if (!Number.isFinite(ageMs)) throw new Error(`bad dates: as_of=${asOfISO} now=${nowISO}`)
  if (!(halfLifeDays > 0)) throw new Error(`half_life_days must be > 0, got ${halfLifeDays}`)
  const ageDays = Math.max(0, ageMs / 86_400_000)
  return Math.pow(0.5, ageDays / halfLifeDays)
}

const sigmoid = (x) => 1 / (1 + Math.exp(-x))

// computeBelief(claimId, ceg, { now }) -> { claimId, belief, logOdds, prior, nEff, contributors }
// opts.now (ISO) is REQUIRED: determinism forbids reading the clock inside the engine.
export function computeBelief(claimId, ceg, opts = {}) {
  if (!opts.now) throw new Error('opts.now (ISO timestamp) is required: determinism forbids Date.now()')
  const claim = node(ceg, claimId)
  if (!claim || claim.kind !== 'claim') throw new Error(`no such claim: ${claimId}`)

  // 3.1 prior from the reference class (outside view FIRST); refuse to score without one.
  const rc = claim.reference_class
  if (!rc || typeof rc.base_rate !== 'number' || rc.base_rate <= 0 || rc.base_rate >= 1) {
    throw new Error(`claim ${claimId}: reference_class.base_rate in (0,1) is MANDATORY (outside view first)`)
  }
  // inside-view adjustment is applied in log-odds and recorded on the claim, so the anchor move is auditable.
  const L0 = Math.log(rc.base_rate / (1 - rc.base_rate)) + (claim.inside_view_delta || 0)

  // 3.2 evidence as likelihood ratios, shrunk toward 1 (non-diagnostic) by fidelity,
  // freshness, and retrieval adequacy (RAS): evidence pulled from an inadequate or
  // skewed pool is less diagnostic, because it may be an artifact of what was
  // searchable rather than what is true. ras_claim = 1 reproduces the pre-RAS math.
  const ras = typeof claim.ras_claim === 'number' && claim.ras_claim >= 0 && claim.ras_claim <= 1 ? claim.ras_claim : 1
  const items = []
  for (const e of citesEdges(ceg, claimId)) {
    const src = node(ceg, e.from)
    if (!src || src.kind !== 'source') throw new Error(`edge ${e.id}: source ${e.from} missing from graph`)
    // Gate outcomes: dead or quarantined sources contribute nothing (weight forced to zero upstream).
    if (src.access === 'dead' || src.access === 'quarantined') continue
    const asOf = src.as_of_date || src.publish_date
    if (!asOf) throw new Error(`source ${src.id}: as_of_date or publish_date required (provenance gate)`)
    const fid = e.weight
    if (typeof fid !== 'number' || fid < 0 || fid > 1) {
      throw new Error(`edge ${e.id}: weight (extraction fidelity) must be in [0,1], got ${fid}`)
    }
    const fresh = freshness(asOf, opts.now, claim.half_life_days)
    const lrEff = 1 + (clampLR(e.LR) - 1) * fid * fresh * ras
    // Gate-5 containment: a suspected source can NEVER raise belief. A hostile page
    // arguing FOR a claim contributes nothing; one arguing AGAINST may still lower
    // belief (fail-safe toward skepticism). The property that matters for GO/NOGO.
    if (src.injection_suspected && lrEff > 1) continue
    items.push({
      edgeId: e.id, sourceId: src.id, originId: src.origin_id,
      lr: e.LR, lrEff, lnLR: Math.log(lrEff), fidelity: fid, freshness: fresh,
    })
  }

  // 3.3 correlation haircut across ORIGINS, not sources.
  const { totalLnLR, perOrigin, nEff } = haircut(items)

  const logOdds = L0 + totalLnLR
  return {
    claimId,
    belief: sigmoid(logOdds),
    logOdds,
    prior: { baseRate: rc.base_rate, L0 },
    nEff,
    contributors: perOrigin,
  }
}

// 3.4 conclusion aggregation + the weakest-link cap.
// Phase-A provisional: signed, weighted sum of supporting/refuting claims' log-odds,
// then capped by the weakest load-bearing claim. QBAF replaces these internals in v3.
export function computeConclusionBelief(conclusionId, ceg, opts = {}) {
  const conc = node(ceg, conclusionId)
  if (!conc || conc.kind !== 'conclusion') throw new Error(`no such conclusion: ${conclusionId}`)
  let L = 0
  for (const e of ceg.edges) {
    if (e.to !== conclusionId || (e.rel !== 'supports' && e.rel !== 'refutes')) continue
    const c = computeBelief(e.from, ceg, opts)
    const w = Math.abs(e.weight ?? 1)
    L += (e.rel === 'supports' ? 1 : -1) * w * c.logOdds
  }
  let belief = sigmoid(L)
  let cappedBy = null
  for (const cid of conc.load_bearing_claims || []) {
    const c = computeBelief(cid, ceg, opts)
    if (c.belief < belief) { belief = c.belief; cappedBy = cid }
  }
  return { conclusionId, belief, cappedBy }
}
