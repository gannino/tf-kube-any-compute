#!/usr/bin/env node
// Phase A step 1 acceptance test (the analyst acceptance suite).
// Checks:
//   1. the section-3.7 worked example reproduces: belief = 0.67, N_eff = 2
//   2. determinism: identical results across 3 independent runs
//   3. the propagator REFUSES a claim without a reference class (outside view first)
//   4. LR bounds clamp to [0.1, 10]
//   5. the independence haircut demonstrably lowers belief vs naive per-source counting
//   6. seeded Monte-Carlo intervals are deterministic and ordered
// Run: node ".claude/analyst/eval/run-step1.mjs"
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'
import { loadCEG, cegFromRecords } from '../engine/ceg.mjs'
import { computeBelief, clampLR, LR_MAX, LR_MIN } from '../engine/propagate.mjs'
import { deriveInterval } from '../engine/interval.mjs'

const here = dirname(fileURLToPath(import.meta.url))
const FIXTURE = join(here, 'fixtures', 'wtp-worked-example.jsonl')
const NOW = '2026-07-04T00:00:00Z' // determinism: the clock is an INPUT, never read inside the engine

let failures = 0
const check = (name, ok, detail = '') => {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? `  [${detail}]` : ''}`)
  if (!ok) failures++
}

// 1. the worked example
const ceg = loadCEG(FIXTURE)
const r = computeBelief('C-wtp', ceg, { now: NOW })
check('worked example: belief = 0.67', Math.abs(r.belief - 0.6705) < 0.002, `belief=${r.belief.toFixed(4)} logOdds=${r.logOdds.toFixed(4)}`)
check('worked example: N_eff = 2 (origins, not sources)', r.nEff === 2, `nEff=${r.nEff} from 3 sources`)
check('worked example: prior L0 = -0.80', Math.abs(r.prior.L0 + 0.8001) < 0.001, `L0=${r.prior.L0.toFixed(4)}`)

// 2. determinism across 3 fresh loads
const runs = [1, 2, 3].map(() => JSON.stringify(computeBelief('C-wtp', loadCEG(FIXTURE), { now: NOW })))
check('deterministic across 3 runs (byte-identical result)', runs[0] === runs[1] && runs[1] === runs[2])

// 3. refuses to score a claim without a reference class
const noRC = cegFromRecords([
  { kind: 'origin', id: 'O-x', label: 'x' },
  { kind: 'source', id: 'S-x', url: 'https://x.example.com', tier: 5, origin_id: 'O-x', as_of_date: NOW },
  { kind: 'claim', id: 'C-norc', text: 'unanchored claim', ctype: 'quantity', scope: 'test', half_life_days: 180 },
  { kind: 'edge', id: 'E-x', rel: 'cites', from: 'S-x', to: 'C-norc', weight: 1.0, LR: 2.0 },
])
let threw = false
try { computeBelief('C-norc', noRC, { now: NOW }) } catch { threw = true }
check('refuses a claim without reference_class (outside view first)', threw)

// 4. LR bounds
check('LR clamps to [0.1, 10]', clampLR(50) === LR_MAX && clampLR(0.001) === LR_MIN)

// 5. the haircut lowers belief vs naive counting (same-origin duplicate must not count as independent)
const records = readFileSync(FIXTURE, 'utf8').split('\n').filter((l) => l.trim()).map((l) => JSON.parse(l))
const naiveRecords = records.map((rec) => (rec.id === 'S-e3' ? { ...rec, origin_id: 'O-blog' } : rec))
naiveRecords.push({ kind: 'origin', id: 'O-blog', label: 'blog treated (wrongly) as its own origin' })
const naive = computeBelief('C-wtp', cegFromRecords(naiveRecords), { now: NOW })
check('haircut lowers belief vs naive origin counting', r.belief < naive.belief, `haircut=${r.belief.toFixed(4)} < naive=${naive.belief.toFixed(4)}`)

// 6. seeded intervals: deterministic and ordered (derived SAM = TAM * share)
const inputs = [
  { p10: 900_000, p50: 3_200_000, p90: 11_000_000 }, // TAM
  { p10: 0.05, p50: 0.1, p90: 0.2 }, // share
]
const i1 = deriveInterval(inputs, (tam, share) => tam * share, { seedKey: 'C-sam' })
const i2 = deriveInterval(inputs, (tam, share) => tam * share, { seedKey: 'C-sam' })
check(
  'seeded Monte-Carlo interval deterministic + ordered',
  JSON.stringify(i1) === JSON.stringify(i2) && i1.p10 < i1.p50 && i1.p50 < i1.p90,
  `p10=${Math.round(i1.p10)} p50=${Math.round(i1.p50)} p90=${Math.round(i1.p90)}`
)

console.log(failures === 0 ? '\nALL CHECKS PASSED' : `\n${failures} CHECK(S) FAILED`)
process.exit(failures === 0 ? 0 : 1)
