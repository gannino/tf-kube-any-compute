#!/usr/bin/env node
// The Claudify Analyst eval harness: runs every acceptance suite (golden +
// adversarial + engine + ledger), reports pass/fail per suite, and enforces the
// CI budget (under 5 minutes; in practice seconds, everything is deterministic).
// Run: node ".claude/analyst/eval/run.mjs"
import { execFileSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'

const here = dirname(fileURLToPath(import.meta.url))
const SUITES = [
  { id: 'step1', name: 'belief propagator + independence + intervals' },
  { id: 'step2', name: 'ingest gates + the six adversarial poisons' },
  { id: 'step3', name: 'ACH (least-disconfirmed) + tier-0 VOI + the loss clamp' },
  { id: 'step4', name: 'brief validation + the zero-network dry run' },
  { id: 'step5', name: 'the Conviction Dossier (two-axis, emergent verdict, traceable)' },
  { id: 'step6', name: 'hash-chained ledger + proper scoring + the calibration report' },
  { id: 'step7', name: 'golden known-answer set + the sharpness gate + the resolution floor' },
  { id: 'step8', name: 'Gate-5 hostile-source layer + the L0 recalibration seam' },
  { id: 'step9', name: 'RAS retrieval adequacy (skew detection, repair frontier, the verdict cap)' },
  { id: 'step10', name: 'the public Prediction Registry generator (explicit publish, drop-nothing, tamper-refusing)' },
]

const t0 = Date.now()
let failed = 0
console.log('CLAUDIFY ANALYST EVAL HARNESS\n')
for (const s of SUITES) {
  const start = Date.now()
  let out = ''
  let ok = true
  try {
    out = execFileSync(process.execPath, [join(here, `run-${s.id}.mjs`)], { encoding: 'utf8' })
  } catch (e) {
    out = (e.stdout ?? '') + (e.stderr ?? '')
    ok = false
  }
  const passes = (out.match(/^PASS /gm) || []).length
  const fails = (out.match(/^FAIL /gm) || []).length
  if (fails > 0) ok = false
  if (!ok) failed++
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${s.id} (${passes} checks, ${((Date.now() - start) / 1000).toFixed(1)}s)  ${s.name}`)
  if (!ok) console.log(out.split('\n').filter((l) => l.startsWith('FAIL')).map((l) => '      ' + l).join('\n'))
}

const seconds = (Date.now() - t0) / 1000
console.log(`\nTotal: ${SUITES.length - failed}/${SUITES.length} suites, ${seconds.toFixed(1)}s (CI budget: 300s)`)
if (seconds > 300) {
  console.log('FAIL: over the CI budget')
  process.exit(1)
}
process.exit(failed === 0 ? 0 : 1)
