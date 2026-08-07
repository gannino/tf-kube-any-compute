#!/usr/bin/env node
// Phase A step 7 acceptance test (the analyst acceptance suite).
// The golden set (known-answer, seeded from the 27 researched markets) with a
// SHARPNESS-PENALIZED gate (Winkler interval score: vagueness scores worse, not
// better), the Murphy resolution floor (G7: a base-rate parrot fails even when
// perfectly calibrated), and the staleness golden case run through the live engine.
// Run: node ".claude/analyst/eval/run-step7.mjs"
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'
import { cegFromRecords } from '../engine/ceg.mjs'
import { computeBelief } from '../engine/propagate.mjs'
import { twStaleFastMover } from '../engine/ingest.mjs'
import { murphy } from '../engine/score.mjs'
import { lognormalFromFractiles } from '../engine/interval.mjs'

const here = dirname(fileURLToPath(import.meta.url))
const NOW = '2026-07-05T00:00:00Z'
let failures = 0
const check = (name, ok, detail = '') => {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? `  [${detail}]` : ''}`)
  if (!ok) failures++
}

// ---------- the sharpness-penalized interval gate (Winkler, 80% central) ----------
// score = width + (2/alpha) * distance-outside. Lower is better. An interval that
// is honest-but-wide beats a narrow one that misses; a narrow one that COVERS beats
// both. "Interval overlaps band" is gone: vagueness now costs, and missing costs more.
const ALPHA = 0.2
export function winkler(interval, truth) {
  const w = interval.p90 - interval.p10
  if (truth < interval.p10) return w + (2 / ALPHA) * (interval.p10 - truth)
  if (truth > interval.p90) return w + (2 / ALPHA) * (truth - interval.p90)
  return w
}
// The gate: pass iff truth is covered AND the score is no worse than k times the
// band width (so an absurdly wide interval cannot pass by covering everything).
export function goldenGate(interval, band, k = 3) {
  const width = band[1] - band[0]
  const worst = Math.max(winkler(interval, band[0]), winkler(interval, band[1]))
  const covered = interval.p10 <= band[0] && interval.p90 >= band[1]
  return { pass: covered && worst <= k * width, worst, covered }
}

// ---------- golden: structure of the market set ----------
const golden = JSON.parse(readFileSync(join(here, 'golden', 'markets.json'), 'utf8'))
check('golden set: 10 known-answer market cases, all bands ordered',
  golden.cases.length === 10 && golden.cases.every((c) => c.band[0] < c.band[1] && c.note && c.source))
check('golden set: scope-sensitive cases carry the scope warning',
  golden.cases.filter((c) => c.scope_sensitive).length >= 4)

// ---------- golden G-aivideo: honest interval passes, overconfident point fails ----------
{
  const band = golden.cases.find((c) => c.id === 'G-aivideo').band
  const honest = { p10: 750e6, p50: 1.8e9, p90: 4.0e9 } // covers the 4.3x scope range
  const narrow = { p10: 3.0e9, p50: 3.2e9, p90: 3.5e9 } // confidently wrong at the low scope
  lognormalFromFractiles(honest) // must be a valid elicitation
  const g1 = goldenGate(honest, band)
  const g2 = goldenGate(narrow, band)
  check('G-aivideo: the honest scope-covering interval passes the sharpness gate', g1.pass, `worst=${(g1.worst / 1e9).toFixed(2)}B`)
  check('G-aivideo: the narrow overconfident interval FAILS (penalty, not a miss ignored)', !g2.pass, `worst=${(g2.worst / 1e9).toFixed(2)}B covered=${g2.covered}`)
}

// ---------- golden G-anthropic-arr: the staleness lesson, live through the engine ----------
{
  const ceg = cegFromRecords([
    { kind: 'origin', id: 'O-old', label: 'early-2025 press coverage' },
    { kind: 'source', id: 'S-old', url: 'https://old.example.com/anthropic-arr', tier: 4, origin_id: 'O-old', retrieved_at: NOW, content_hash: 'g', as_of_date: '2025-01-15T00:00:00Z', passage: 'Anthropic ARR reached $2.5 billion.' },
    { kind: 'claim', id: 'C-arr', text: 'Anthropic ARR is $2.5B', ctype: 'quantity', value: 2.5e9, scope: 'Anthropic total, current', scope_entities: ['anthropic'], half_life_days: 90, reference_class: { class: 'AI lab ARR', base_rate: 0.3 }, status: 'open' },
    { kind: 'edge', id: 'E-old', rel: 'cites', from: 'S-old', to: 'C-arr', weight: 1.0, LR: 3.0 },
  ])
  const r = computeBelief('C-arr', ceg, { now: NOW })
  const drift = Math.abs(r.belief - 0.3)
  const flag = twStaleFastMover({ as_of_date: '2025-01-15T00:00:00Z' }, { half_life_days: 90 }, NOW)
  check('G-anthropic-arr: 18-month-old fast-mover evidence cannot move belief off the prior', drift < 0.01, `belief=${r.belief.toFixed(4)} vs prior 0.30 (the 5.6x staleness error, now impossible)`)
  check('G-anthropic-arr: and the staleness is flagged visibly, not just decayed', flag.flag === true)
}

// ---------- the Murphy resolution floor (G7: the base-rate parrot must fail) ----------
{
  // 20 outcomes at base rate 0.5; the parrot predicts 0.5 every time: perfectly
  // calibrated (reliability 0) and perfectly useless (resolution 0).
  const parrot = Array.from({ length: 20 }, (_, i) => ({ p: 0.5, o: i % 2 }))
  // The discriminator separates: 0.8 on winners, 0.2 on losers.
  const sharp = Array.from({ length: 20 }, (_, i) => ({ p: i % 2 ? 0.8 : 0.2, o: i % 2 }))
  const FLOOR = 0.005
  const mP = murphy(parrot)
  const mS = murphy(sharp)
  const gate = (m) => m.n >= 10 && m.resolution >= FLOOR
  check('resolution floor: the calibrated-but-useless base-rate parrot FAILS', !gate(mP), `resolution=${mP.resolution.toFixed(4)} reliability=${mP.reliability.toFixed(4)}`)
  check('resolution floor: the discriminating forecaster passes', gate(mS), `resolution=${mS.resolution.toFixed(4)}`)
}

console.log(failures === 0 ? '\nALL CHECKS PASSED' : `\n${failures} CHECK(S) FAILED`)
process.exit(failures === 0 ? 0 : 1)
