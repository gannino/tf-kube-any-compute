// The L0 input-calibration seam (the analyst design notes, Phase-A/B slice).
// Every belief-math input passes through here BETWEEN elicitation and the graph.
// Today the maps are identity or temperature-only (the cold-start contract: below
// n_min the correction is the identity map); the seam exists from day one so the
// single-tenant instance can ship fitted maps later without touching the engine.
//
// Invariants (the "honest, not false-precision-one-layer-back" rules):
// - The map can only TEMPER, never fabricate confidence: corrections are clamped
//   to a bounded log-space move and never flip a direction.
// - A run reads the map effective at run start (reproducibility extends from
//   beliefs to the controller state).
import { readFileSync, existsSync } from 'node:fs'

export const MAX_LOG_MOVE = Math.log(4) // one map may move an input by at most 4x in log space
export const IDENTITY = { stage: 'identity', T: 1 }

// applyMap(x, map): x in log space (ln LR, or logit base-rate). Temperature T > 1
// shrinks toward 0 (non-diagnostic / the base rate), the overconfidence correction.
export function applyMap(x, map = IDENTITY) {
  if (!map || map.stage === 'identity') return x
  if (map.stage !== 'temperature') throw new Error(`unknown map stage "${map.stage}" (Phase B ships identity + temperature only)`)
  if (!(map.T > 0)) throw new Error(`bad temperature ${map.T}`)
  let xc = x / map.T
  // bounded move, and never a sign flip (a correction cannot turn support into attack)
  const move = xc - x
  if (Math.abs(move) > MAX_LOG_MOVE) xc = x + Math.sign(move) * MAX_LOG_MOVE
  if (x !== 0 && Math.sign(xc) !== Math.sign(x)) xc = 0
  return xc
}

export function recalibrateLR(lr, map = IDENTITY) {
  if (!(lr > 0)) throw new Error(`bad LR ${lr}`)
  if (!map || map.stage === 'identity') return lr // exact passthrough, no float round-trip
  return Math.exp(applyMap(Math.log(lr), map))
}

const logit = (p) => Math.log(p / (1 - p))
const sigmoid = (x) => 1 / (1 + Math.exp(-x))
export function recalibrateBaseRate(p, map = IDENTITY) {
  if (!(p > 0 && p < 1)) throw new Error(`bad base rate ${p}`)
  if (!map || map.stage === 'identity') return p // exact passthrough
  return sigmoid(applyMap(logit(p), map))
}

// loadMap(parametersPath, key, atISO): the latest row for `key` whose effective_from
// is at or before the run start; identity when the ledger or the key is absent.
// Rows: {key, value: {stage, T}, effective_from, superseded_by?}
export function loadMap(parametersPath, key, atISO) {
  if (!existsSync(parametersPath)) return IDENTITY
  const rows = readFileSync(parametersPath, 'utf8')
    .split('\n').filter((l) => l.trim()).map((l) => JSON.parse(l))
    .filter((r) => r.key === key && !r.superseded_by && Date.parse(r.effective_from) <= Date.parse(atISO))
    .sort((a, b) => Date.parse(a.effective_from) - Date.parse(b.effective_from))
  return rows.length ? rows[rows.length - 1].value : IDENTITY
}
