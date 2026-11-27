// The calibration engine: the hash-chained prediction ledger + proper scoring.
// Build spec section 9 + the quality-and-calibration skill (Phase-A slice: the ledger,
// Brier/log, the Murphy decomposition, difficulty stratification (G7), interval
// coverage, the L1 temperature stage, and the drop-nothing UNRESOLVED bucket).
// Deterministic, no LLM, no clock reads: `now` is always an input.
import { createHash } from 'node:crypto'
import { readFileSync, appendFileSync, existsSync } from 'node:fs'

// ---------- canonical JSON + the hash chain (tamper evidence) ----------
export function canonicalJSON(v) {
  if (Array.isArray(v)) return '[' + v.map(canonicalJSON).join(',') + ']'
  if (v && typeof v === 'object') {
    return '{' + Object.keys(v).sort().map((k) => JSON.stringify(k) + ':' + canonicalJSON(v[k])).join(',') + '}'
  }
  return JSON.stringify(v)
}
const sha = (s) => createHash('sha256').update(s).digest('hex')

function ledgerLines(path) {
  if (!existsSync(path)) return []
  return readFileSync(path, 'utf8').split('\n').filter((l) => l.trim())
}

// Every ledger row commits the hash of the prior row. A silent post-hoc edit to
// any prediction, its p, or its resolution breaks the chain detectably.
export function appendLedger(path, rec) {
  const lines = ledgerLines(path)
  const prev_hash = lines.length ? JSON.parse(lines[lines.length - 1]).hash : 'GENESIS'
  const body = { ...rec, prev_hash }
  const hash = sha(canonicalJSON(body))
  appendFileSync(path, JSON.stringify({ ...body, hash }) + '\n')
  return { ...body, hash }
}

export function verifyChain(path) {
  const lines = ledgerLines(path)
  let prev = 'GENESIS'
  for (let i = 0; i < lines.length; i++) {
    let rec
    try {
      rec = JSON.parse(lines[i])
    } catch {
      return { ok: false, line: i + 1, reason: 'invalid JSON' }
    }
    const { hash, ...body } = rec
    if (body.prev_hash !== prev) return { ok: false, line: i + 1, reason: 'prev_hash mismatch (chain broken)' }
    if (sha(canonicalJSON(body)) !== hash) return { ok: false, line: i + 1, reason: 'hash mismatch (record altered)' }
    prev = hash
  }
  return { ok: true, count: lines.length }
}

// ---------- prediction records (the G1 substrate, G8 frozen referee) ----------
export function makePrediction(p) {
  const required = ['run_id', 'claim_id', 'statement', 'type', 'resolves_by', 'resolution_source', 'created_at']
  for (const f of required) if (!p[f]) throw new Error(`prediction: missing required field "${f}"`)
  if (p.type === 'binary') {
    if (!(typeof p.p === 'number' && p.p > 0 && p.p < 1)) throw new Error('binary prediction needs p in (0,1)')
  } else if (p.type === 'interval') {
    const iv = p.interval
    if (!(iv && iv.p10 < iv.p50 && iv.p50 < iv.p90)) throw new Error('interval prediction needs ordered {p10,p50,p90}')
  } else {
    throw new Error(`unknown prediction type "${p.type}"`)
  }
  // G8: the resolution criterion is frozen and content-hashed at prediction time.
  // Changing the referee after the fact is impossible by construction.
  const resolution_criterion_hash = sha(canonicalJSON({
    statement: p.statement, resolves_by: p.resolves_by, resolution_source: p.resolution_source,
  }))
  return { id: 'P-' + resolution_criterion_hash.slice(0, 10), ...p, resolution_criterion_hash }
}

// G1: no learning without a prior prediction_record. Scoring an outcome for an id
// that is not in the ledger is INSUFFICIENT_PRECONDITION, never retrospective story.
export function resolveOutcome(ledgerPath, predictionId, outcome, resolvedAt) {
  const pred = ledgerLines(ledgerPath).map((l) => JSON.parse(l)).find((r) => r.id === predictionId)
  if (!pred) throw new Error(`INSUFFICIENT_PRECONDITION: no prediction_record ${predictionId} in the ledger (G1)`)
  if (pred.type === 'binary') {
    if (outcome !== 0 && outcome !== 1) throw new Error('binary outcome must be 0 or 1')
    return {
      kind: 'resolution', prediction_id: pred.id, claim_id: pred.claim_id, type: 'binary',
      p: pred.p, o: outcome, brier: brier(pred.p, outcome), log: logScore(pred.p, outcome), resolved_at: resolvedAt,
    }
  }
  // interval: outcome is the realized truth value
  const inside = outcome >= pred.interval.p10 && outcome <= pred.interval.p90 ? 1 : 0
  return {
    kind: 'resolution', prediction_id: pred.id, claim_id: pred.claim_id, type: 'interval',
    interval: pred.interval, truth: outcome, inside80: inside, resolved_at: resolvedAt,
  }
}

// The drop-nothing rule: predictions past resolves_by without a resolution are
// counted UNRESOLVED and reported. Silently dropping them is how every self-graded
// forecast inflates itself; here they are arithmetic, not editorial.
export function listDue(ledgerPath, calibPath, nowISO) {
  const preds = ledgerLines(ledgerPath).map((l) => JSON.parse(l))
  const resolvedIds = new Set(ledgerLines(calibPath).map((l) => JSON.parse(l)).map((r) => r.prediction_id))
  const due = preds.filter((p) => Date.parse(p.resolves_by) <= Date.parse(nowISO))
  return {
    total: preds.length,
    due: due.length,
    resolved: due.filter((p) => resolvedIds.has(p.id)).length,
    unresolved: due.filter((p) => !resolvedIds.has(p.id)).map((p) => p.id),
  }
}

// ---------- proper scores ----------
export const brier = (p, o) => (p - o) ** 2
export const logScore = (p, o) => -(o * Math.log(p) + (1 - o) * Math.log(1 - p))

// Murphy decomposition: Brier = Reliability - Resolution + Uncertainty.
// Reliability (calibration error) is driven to zero; Resolution (does it separate
// winners from losers) is MAXIMISED and floored (G7): a system that only predicts
// near-certainties is calibrated and useless, and must fail, not pass.
export function murphy(records, nBins = 10) {
  const N = records.length
  if (N === 0) return null
  const obar = records.reduce((a, r) => a + r.o, 0) / N
  const bins = Array.from({ length: nBins }, () => [])
  for (const r of records) bins[Math.min(nBins - 1, Math.floor(r.p * nBins))].push(r)
  let reliability = 0
  let resolution = 0
  const diagram = []
  for (const bin of bins) {
    if (!bin.length) continue
    const pbar = bin.reduce((a, r) => a + r.p, 0) / bin.length
    const ok = bin.reduce((a, r) => a + r.o, 0) / bin.length
    reliability += (bin.length / N) * (pbar - ok) ** 2
    resolution += (bin.length / N) * (ok - obar) ** 2
    diagram.push({ predicted: pbar, observed: ok, n: bin.length })
  }
  const uncertainty = obar * (1 - obar)
  const brierMean = records.reduce((a, r) => a + brier(r.p, r.o), 0) / N
  return { n: N, brier: brierMean, reliability, resolution, uncertainty, baseRate: obar, diagram }
}

// G7: difficulty stratification. The hard band [0.35, 0.65] is where the product
// earns its keep; the headline is the hard-band calibration, never the flattering
// aggregate loaded with near-certainties.
export const HARD_BAND = [0.35, 0.65]
export function stratifyByDifficulty(records) {
  const hard = records.filter((r) => r.p >= HARD_BAND[0] && r.p <= HARD_BAND[1])
  const easy = records.filter((r) => r.p < HARD_BAND[0] || r.p > HARD_BAND[1])
  return { hard, easy, hardFraction: records.length ? hard.length / records.length : 0 }
}

// Interval calibration: the 80% band should contain truth ~80% of the time.
// Coverage far below nominal = overconfident intervals (the dominant LLM bias).
export function intervalCoverage(resolutions) {
  const iv = resolutions.filter((r) => r.type === 'interval')
  if (!iv.length) return null
  const hit = iv.reduce((a, r) => a + r.inside80, 0) / iv.length
  return { n: iv.length, nominal: 0.8, observed: hit, overconfident: hit < 0.7 }
}

// L1 cold stage: one-parameter temperature fit by grid search over resolved log loss.
// T > 1 = systematic overconfidence; the correction shrinks toward the base rate.
const logit = (p) => Math.log(p / (1 - p))
const sigmoid = (x) => 1 / (1 + Math.exp(-x))
export function fitTemperature(records) {
  if (records.length < 10) return { T: 1, n: records.length, note: 'below n_min_to_use (10): identity map (cold-start contract)' }
  let best = { T: 1, loss: Infinity }
  for (let T = 0.2; T <= 5.0001; T += 0.01) {
    let loss = 0
    for (const r of records) {
      const pc = Math.min(1 - 1e-9, Math.max(1e-9, sigmoid(logit(r.p) / T)))
      loss += logScore(pc, r.o)
    }
    if (loss < best.loss - 1e-12) best = { T: Number(T.toFixed(2)), loss }
  }
  return { T: best.T, n: records.length }
}

export const applyTemperature = (p, T) => sigmoid(logit(p) / T)

// ---------- the calibration report (the honesty artifact) ----------
export function calibrationReport({ resolutions, unresolved, nowISO }) {
  const binary = resolutions.filter((r) => r.type === 'binary')
  const m = murphy(binary)
  const strat = stratifyByDifficulty(binary)
  const mHard = murphy(strat.hard)
  const cov = intervalCoverage(resolutions)
  const temp = fitTemperature(binary)
  const L = []
  L.push(`CALIBRATION REPORT (as of ${nowISO})`)
  L.push(`Resolved: ${resolutions.length} (binary ${binary.length}, interval ${resolutions.length - binary.length})   UNRESOLVED past due: ${unresolved} (counted, never dropped)`)
  if (m) {
    L.push(`Aggregate Brier ${m.brier.toFixed(3)} = reliability ${m.reliability.toFixed(3)} - resolution ${m.resolution.toFixed(3)} + uncertainty ${m.uncertainty.toFixed(3)}`)
    L.push(`HARD BAND [0.35-0.65] (the headline, G7): n=${strat.hard.length} (${(strat.hardFraction * 100).toFixed(0)}% of calls)` +
      (mHard ? ` Brier ${mHard.brier.toFixed(3)} reliability ${mHard.reliability.toFixed(3)} resolution ${mHard.resolution.toFixed(3)}` : ' insufficient'))
    L.push('Reliability diagram (predicted -> observed, n):')
    for (const d of m.diagram) L.push(`  ${d.predicted.toFixed(2)} -> ${d.observed.toFixed(2)} (n=${d.n})`)
  }
  if (cov) L.push(`Interval coverage: ${(cov.observed * 100).toFixed(0)}% vs 80% nominal${cov.overconfident ? '  OVERCONFIDENT: intervals too narrow' : ''}`)
  L.push(`Temperature (L1 cold stage): T=${temp.T}${temp.T > 1.05 ? ' (systematically overconfident; correction shrinks toward the base rate)' : ''}${temp.note ? '  ' + temp.note : ''}`)
  return L.join('\n')
}
