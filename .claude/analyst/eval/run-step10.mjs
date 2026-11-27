#!/usr/bin/env node
// Registry generator acceptance test (the analyst acceptance suite).
// Fixture-based: builds its own temporary ledger so it runs on a fresh install
// with an empty ledger. Publication is explicit (allowlist), the ledger must
// verify, backtests are labelled and never scored, unresolved is counted, bands
// never decimals. Run: node ".claude/analyst/eval/run-step10.mjs"
import { readFileSync, writeFileSync, mkdirSync, rmSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'
import { buildRegistry, renderRegistry } from '../engine/registry.mjs'
import { makePrediction, appendLedger, resolveOutcome } from '../engine/score.mjs'

const here = dirname(fileURLToPath(import.meta.url))
const TPL = join(here, '..', 'dossier', 'registry-template.html')
const NOW = '2026-07-06T00:00:00Z'
const TMP = join(here, 'tmp-registry')
rmSync(TMP, { recursive: true, force: true })
mkdirSync(TMP, { recursive: true })
const LEDGER = join(TMP, 'predictions.jsonl')
const CALIB = join(TMP, 'calibration_log.jsonl')

let failures = 0
const check = (name, ok, detail = '') => {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? `  [${detail}]` : ''}`)
  if (!ok) failures++
}

// ---------- a synthetic fixture ledger (four calls, one resolved) ----------
const mk = (claim, statement, p, resolves_by) =>
  appendLedger(LEDGER, makePrediction({
    run_id: 'fixture-run', claim_id: claim, statement, type: 'binary', p,
    resolves_by, resolution_source: 'a mechanical, exogenous source named at write time',
    baseline_used: 'reference_class base_rate 0.3', created_at: '2026-07-01T00:00:00Z',
  }))
const P1 = mk('C-f1', 'The category ships a major pricing change this quarter', 0.55, '2026-07-05')
const P2 = mk('C-f2', 'The comparable report format sustains a durable audience', 0.6, '2027-01-05')
const P3 = mk('C-f3', 'The channel moves 300 units in 12 months', 0.46, '2026-10-05')
const P4 = mk('C-f4', 'The market clears the scoped threshold', 0.35, '2027-01-05')
appendLedger(CALIB, resolveOutcome(LEDGER, P1.id, 1, '2026-07-05T12:00:00Z'))
const allIds = [P1.id, P2.id, P3.id, P4.id]

// ---------- refuses a broken ledger ----------
{
  const rows = readFileSync(LEDGER, 'utf8').split('\n').filter((l) => l.trim())
  const rec = JSON.parse(rows[0])
  rec.p = 0.99
  rows[0] = JSON.stringify(rec)
  const tampered = join(TMP, 'tampered.jsonl')
  writeFileSync(tampered, rows.join('\n') + '\n')
  let threw = ''
  try { buildRegistry({ ledgerPath: tampered, calibPath: CALIB, publishIds: allIds, now: NOW }) } catch (e) { threw = e.message }
  check('REFUSES to publish from a tampered ledger', threw.includes('REFUSING'), threw)
}

// ---------- publish all four ----------
const backtests = [
  { statement: 'A labelled retrodictive example call', band: 'LIKELY (55-80%)', outcome: 'HIT', note: 'backtest; labelled, never scored' },
]
const data = buildRegistry({ ledgerPath: LEDGER, calibPath: CALIB, publishIds: allIds, backtests, now: NOW })
check('four published: one resolved HIT, three pending', data.counts.published === 4 && data.counts.resolved === 1 && data.counts.pending === 3)
check('below 20 resolved: the honesty line says uncalibrated', data.uncalibratedNote === 'n=1, uncalibrated (the temperature stage needs 20 resolved)', data.uncalibratedNote)
check('backtests carried but never scored into the live number', data.backtests.length === 1)

const html = renderRegistry(data, TPL)
check('registry renders with no unfilled tokens', !/\{\{[A-Z_]+\}\}/.test(html))
check('bands, never decimals, in public output', html.includes('ROUGHLY EVEN (45-55%)') && !/0\.\d{3}/.test(html))
check('the frozen criterion hash is shown per call', (html.match(/class="mono">[0-9a-f]{12}</g) || []).length === 4)
check('a resolved HIT is shown as prominently as any miss would be', html.includes('>HIT<'))
check('no em dashes in the public page', !html.includes('—') && !html.includes('–'))

// ---------- publication is explicit: the allowlist filters ----------
{
  const partial = buildRegistry({ ledgerPath: LEDGER, calibPath: CALIB, publishIds: allIds.slice(0, 2), now: NOW })
  const h = renderRegistry(partial, TPL)
  check('allowlist: unpublished calls stay private and are counted as private',
    partial.counts.published === 2 && partial.counts.privateCalls === 2 && !h.includes(allIds[3]))
}

// ---------- unresolved is counted, never dropped ----------
{
  const later = buildRegistry({ ledgerPath: LEDGER, calibPath: CALIB, publishIds: allIds, now: '2028-01-01T00:00:00Z' })
  check('past-due unresolved calls are COUNTED (drop-nothing, in public)',
    later.counts.unresolved === 3 && renderRegistry(later, TPL).includes('UNRESOLVED (due, counted)'),
    `unresolved=${later.counts.unresolved}`)
}

// ---------- determinism ----------
{
  const a = renderRegistry(buildRegistry({ ledgerPath: LEDGER, calibPath: CALIB, publishIds: allIds, backtests, now: NOW }), TPL)
  check('registry generation is byte-deterministic', a === html)
}

rmSync(TMP, { recursive: true, force: true })
console.log(failures === 0 ? '\nALL CHECKS PASSED' : `\n${failures} CHECK(S) FAILED`)
process.exit(failures === 0 ? 0 : 1)
