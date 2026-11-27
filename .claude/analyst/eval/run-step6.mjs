#!/usr/bin/env node
// Phase A step 6 acceptance test (the analyst acceptance suite).
// The accountability layer: hash-chained prediction ledger (G1 substrate, G8 frozen
// referee, tamper evidence), proper scoring (Brier/log/Murphy + hard-band G7),
// interval coverage, the L1 temperature stage, the drop-nothing UNRESOLVED rule,
// and a reliability diagram on a seeded historical set.
// Run: node ".claude/analyst/eval/run-step6.mjs"
import { readFileSync, writeFileSync, mkdirSync, rmSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'
import {
  makePrediction, appendLedger, verifyChain, resolveOutcome, listDue,
  murphy, stratifyByDifficulty, intervalCoverage, fitTemperature, applyTemperature,
  calibrationReport, canonicalJSON, brier, logScore,
} from '../engine/score.mjs'
import { loadCEG } from '../engine/ceg.mjs'
import { buildDossier } from '../engine/dossier.mjs'

const here = dirname(fileURLToPath(import.meta.url))
const NOW = '2026-07-05T00:00:00Z'
const TMP = join(here, 'tmp')
rmSync(TMP, { recursive: true, force: true })
mkdirSync(TMP, { recursive: true })
const LEDGER = join(TMP, 'predictions.jsonl')
const CALIB = join(TMP, 'calibration_log.jsonl')

let failures = 0
const check = (name, ok, detail = '') => {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? `  [${detail}]` : ''}`)
  if (!ok) failures++
}

// ---------- Mode A: predictions from the seeded dossier ----------
const brief = JSON.parse(readFileSync(join(here, 'fixtures', 'brief-example.json'), 'utf8'))
const data = buildDossier(loadCEG(join(here, 'fixtures', 'venture-seeded.jsonl')), brief, { now: NOW })
const written = []
for (const c of data.cruxes.filter((r) => r.falsifier)) {
  const src = brief.claims.find((x) => x.id === c.claimId)
  const pred = makePrediction({
    run_id: brief.run_id, claim_id: c.claimId, statement: c.text, type: 'binary', p: c.belief,
    resolves_by: src.resolves_by, resolution_source: src.resolution_source,
    hypothesis_id: 'H2', baseline_used: `reference_class base_rate ${c.baseRate}`, created_at: NOW,
  })
  written.push(appendLedger(LEDGER, pred))
}
check('prediction records written from the dossier (G1 substrate)', written.length === 4,
  written.map((w) => w.id).join(' '))
check('every record carries the frozen resolution criterion hash (G8)', written.every((w) => /^[0-9a-f]{64}$/.test(w.resolution_criterion_hash)))
check('the chain verifies', verifyChain(LEDGER).ok, JSON.stringify(verifyChain(LEDGER)))

// G8 determinism: the same criterion always yields the same id (the referee cannot drift)
{
  const again = makePrediction({
    run_id: brief.run_id, claim_id: written[0].claim_id, statement: written[0].statement, type: 'binary',
    p: 0.99, resolves_by: written[0].resolves_by, resolution_source: written[0].resolution_source, created_at: '2027-01-01',
  })
  check('criterion hash is stable across re-elicitation (G8: referee frozen)', again.resolution_criterion_hash === written[0].resolution_criterion_hash)
}

// ---------- tamper evidence ----------
{
  const lines = readFileSync(LEDGER, 'utf8').split('\n').filter((l) => l.trim())
  const rec = JSON.parse(lines[1])
  rec.p = 0.95 // the quiet post-hoc improvement every self-graded scoreboard is tempted by
  lines[1] = JSON.stringify(rec)
  const tampered = join(TMP, 'tampered.jsonl')
  writeFileSync(tampered, lines.join('\n') + '\n')
  const v = verifyChain(tampered)
  check('tampering a past prediction breaks the chain detectably', !v.ok && v.line === 2, JSON.stringify(v))
}

// ---------- G1: no learning without a prior record ----------
{
  let msg = ''
  try { resolveOutcome(LEDGER, 'P-doesnotexist', 1, NOW) } catch (e) { msg = e.message }
  check('grading without a record returns INSUFFICIENT_PRECONDITION (G1)', msg.includes('INSUFFICIENT_PRECONDITION'), msg)
}

// ---------- resolve one for real; the UNRESOLVED bucket counts the rest ----------
{
  const res = resolveOutcome(LEDGER, written[0].id, 1, '2026-10-02T00:00:00Z')
  appendLedger(CALIB, res)
  check('resolution scored with proper scores and chained', verifyChain(CALIB).ok && res.brier === brier(written[0].p, 1) && res.log === logScore(written[0].p, 1))
  const due = listDue(LEDGER, CALIB, '2028-01-01T00:00:00Z')
  check('drop-nothing: due-but-unresolved predictions are counted, never dropped',
    due.due === 4 && due.resolved === 1 && due.unresolved.length === 3, JSON.stringify(due))
}

// ---------- the seeded historical set (the reliability diagram) ----------
const seeded = []
const push = (p, n, hits) => { for (let i = 0; i < n; i++) seeded.push({ type: 'binary', p, o: i < hits ? 1 : 0 }) }
push(0.9, 10, 6)   // overconfident at the top: said 90, delivered 60
push(0.7, 6, 4)
push(0.5, 4, 2)    // the hard band
push(0.25, 4, 1)
{
  const m = murphy(seeded)
  const identity = Math.abs(m.brier - (m.reliability - m.resolution + m.uncertainty)) < 1e-9
  check('Murphy identity holds: Brier = reliability - resolution + uncertainty', identity,
    `${m.brier.toFixed(4)} = ${m.reliability.toFixed(4)} - ${m.resolution.toFixed(4)} + ${m.uncertainty.toFixed(4)}`)
  check('reliability term exposes the overconfidence', m.reliability > 0.03, `reliability=${m.reliability.toFixed(4)}`)
  check('reliability diagram produced (4 populated bins)', m.diagram.length === 4,
    m.diagram.map((d) => `${d.predicted.toFixed(2)}->${d.observed.toFixed(2)}`).join(' '))

  const strat = stratifyByDifficulty(seeded)
  check('hard-band stratification (G7): the [0.35,0.65] band is scored separately', strat.hard.length === 4 && strat.easy.length === 20,
    `hardFraction=${(strat.hardFraction * 100).toFixed(0)}%`)

  const t = fitTemperature(seeded)
  check('temperature fit detects systematic overconfidence (T > 1)', t.T > 1.05, `T=${t.T} on n=${t.n}`)
  const cooled = applyTemperature(0.9, t.T)
  check('applying T shrinks an overconfident 0.90 toward the base rate', cooled < 0.9 && cooled > 0.5, `0.90 -> ${cooled.toFixed(3)}`)
  check('cold-start contract: below n_min the map is identity', fitTemperature(seeded.slice(0, 5)).T === 1)
}

// ---------- interval coverage ----------
{
  const iv = Array.from({ length: 10 }, (_, i) => ({ type: 'interval', inside80: i < 6 ? 1 : 0 }))
  const cov = intervalCoverage(iv)
  check('interval coverage flags overconfident intervals (60% vs 80% nominal)', cov.observed === 0.6 && cov.overconfident)
}

// ---------- the calibration report (the honesty artifact) ----------
{
  const report = calibrationReport({
    resolutions: [...seeded, ...Array.from({ length: 10 }, (_, i) => ({ type: 'interval', inside80: i < 6 ? 1 : 0 }))],
    unresolved: 3,
    nowISO: NOW,
  })
  const ok = report.includes('HARD BAND') && report.includes('Reliability diagram') &&
    report.includes('UNRESOLVED past due: 3 (counted, never dropped)') && report.includes('OVERCONFIDENT') && report.includes('T=')
  check('calibration report leads with the hard band and hides nothing', ok)
  console.log('\n' + report + '\n')
}

// ---------- determinism of the canonical form ----------
check('canonical JSON is key-order independent', canonicalJSON({ b: 1, a: { d: 2, c: [3] } }) === canonicalJSON({ a: { c: [3], d: 2 }, b: 1 }))

rmSync(TMP, { recursive: true, force: true })
console.log(failures === 0 ? 'ALL CHECKS PASSED' : `${failures} CHECK(S) FAILED`)
process.exit(failures === 0 ? 0 : 1)
