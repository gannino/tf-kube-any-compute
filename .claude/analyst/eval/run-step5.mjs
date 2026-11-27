#!/usr/bin/env node
// Phase A step 5 acceptance test (the analyst acceptance suite).
// A full seeded venture run yields computed beliefs + a rendered Conviction Dossier
// in which every headline number is traceable, two-axis, band-not-decimal, coverage
// honest, and the verdict emergent. Run: node ".claude/analyst/eval/run-step5.mjs"
import { readFileSync, writeFileSync, mkdirSync, rmSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'
import { loadCEG, cegFromRecords } from '../engine/ceg.mjs'
import { buildDossier, renderHTML, estimativeBand, computedConfidence } from '../engine/dossier.mjs'
import { achPosteriors } from '../engine/ach.mjs'
import { bestAction, expectedLosses } from '../engine/voi.mjs'

const here = dirname(fileURLToPath(import.meta.url))
const NOW = '2026-07-05T00:00:00Z'
const CEG_PATH = join(here, 'fixtures', 'venture-seeded.jsonl')
const TPL = join(here, '..', 'dossier', 'template.html')
const brief = JSON.parse(readFileSync(join(here, 'fixtures', 'brief-example.json'), 'utf8'))

let failures = 0
const check = (name, ok, detail = '') => {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? `  [${detail}]` : ''}`)
  if (!ok) failures++
}
const records = () => readFileSync(CEG_PATH, 'utf8').split('\n').filter((l) => l.trim()).map((l) => JSON.parse(l))

// ---------- the estimative lexicon (unit checks) ----------
check('estimative bands map correctly',
  estimativeBand(0.02) === 'ALMOST NO CHANCE (1-5%)' &&
  estimativeBand(0.5) === 'ROUGHLY EVEN (45-55%)' &&
  estimativeBand(0.67) === 'LIKELY (55-80%)' &&
  estimativeBand(0.9) === 'VERY LIKELY (80-95%)' &&
  estimativeBand(0.97) === 'ALMOST CERTAIN (95-99%)')

// ---------- full build over the seeded graph ----------
const ceg = loadCEG(CEG_PATH)
const data = buildDossier(ceg, brief, { now: NOW })

check('beliefs computed for all 4 claims', data.claims.length === 4 && data.claims.every((c) => typeof c.belief === 'number'),
  data.claims.map((c) => `${c.claimId}=${c.belief.toFixed(3)}`).join(' '))

// two-axis: the single-origin channel claim can never look like the two-origin attach claim
const attach = data.claims.find((c) => c.claimId === 'C-attach')
const channel = data.claims.find((c) => c.claimId === 'C-channel')
check('C-attach has two independent origins', attach.nEff === 2, `nEff=${attach.nEff}`)
check('C-channel single-origin: confidence hard-capped at LOW + tagged', channel.confidence.singleOrigin && channel.confidence.band === 'LOW',
  `score=${channel.confidence.score.toFixed(3)}`)
check('two-axis separation: attach confidence exceeds channel confidence', attach.confidence.score > channel.confidence.score,
  `${attach.confidence.score.toFixed(3)} > ${channel.confidence.score.toFixed(3)}`)

// disconfirming evidence pulls belief DOWN through the same math:
// compare the graph WITH the LR 0.5 head-to-head edge vs WITHOUT it
const sub = data.claims.find((c) => c.claimId === 'C-substitute')
{
  const withoutDisconfirm = records().filter((r) => r.id !== 'E-h1')
  const dNo = buildDossier(cegFromRecords(withoutDisconfirm), brief, { now: NOW })
  const subNo = dNo.claims.find((c) => c.claimId === 'C-substitute')
  check('disconfirming head-to-head evidence (LR 0.5) pulls C-substitute belief down', sub.belief < subNo.belief,
    `with=${sub.belief.toFixed(3)} < without=${subNo.belief.toFixed(3)}`)
}

// contested tagging (assert-only-supported discipline)
check('contested claims tagged, supported claims not',
  sub.contested && data.claims.find((c) => c.claimId === 'C-tam').contested && !attach.contested && !channel.contested)

// coverage + emergent verdict, consistent with an independent ACH + loss recompute
check('coverage: all 3 cruxes resolved', data.coverage.sufficient && data.coverage.cruxResolved === 3)
{
  const ach = achPosteriors(ceg, { now: NOW })
  const act = bestAction(ach.pSuccess, brief.decision)
  const el = expectedLosses(ach.pSuccess, brief.decision.loss)
  const margin = Math.abs(el.GO - el.NOGO) / Math.max(el.GO, el.NOGO)
  const expected = margin < 0.15 ? `CONDITIONAL ${act.action}` : act.action
  check('verdict matches the independent ACH + loss recompute', data.judgment.verdict === expected,
    `verdict="${data.judgment.verdict}" pS=${ach.pSuccess.toFixed(3)}`)
  check('P(success) reported as a band, never a decimal', data.judgment.pBand === estimativeBand(ach.pSuccess), data.judgment.pBand)
}

// low-diagnostic evidence flagged (the generic estimate consistent with everything)
check('low-diagnostic evidence flagged (E-t1)', data.ach.lowDiagnostic.includes('E-t1'), data.ach.lowDiagnostic.join(','))

// traceability: every crux row carries a full evidence chain; the quarantined source is visible and inert
check('every crux row has a traceable evidence chain (origin + tier + url)',
  data.cruxes.length === 4 && data.cruxes.every((r) => r.evidence.length >= 1 && r.evidence.every((e) => e.url && e.originId)))
check('quarantined source visible in the dossier and absent from belief', data.quarantined.some((q) => q.id === 'S-quar') &&
  !data.claims.find((c) => c.claimId === 'C-tam').evidence.some((e) => e.sourceId === 'S-quar'))
check('kill-line names the highest-priority unsettled claim', data.judgment.killLine.startsWith('C-substitute:'), data.judgment.killLine)

// ---------- the emergent-verdict invariants ----------
{
  const open = records().map((r) => (r.id === 'C-attach' ? { ...r, status: 'open' } : r))
  const d = buildDossier(cegFromRecords(open), brief, { now: NOW })
  check('an open crux claim withholds the verdict (coverage state instead)',
    d.judgment.verdict === 'NOT YET A VERDICT: resolved 2 of 3 cruxes', d.judgment.verdict)
}
{
  const unsignedBrief = JSON.parse(JSON.stringify(brief))
  unsignedBrief.decision.loss_signed = false
  const d = buildDossier(loadCEG(CEG_PATH), unsignedBrief, { now: NOW })
  check('unsigned framing: EVIDENCE MAP, no GO/NOGO', d.judgment.verdict.startsWith('EVIDENCE MAP'), d.judgment.verdict)
}

// ---------- HTML render ----------
const outDir = join(here, 'tmp-step5')
rmSync(outDir, { recursive: true, force: true })
mkdirSync(outDir, { recursive: true })
const html = renderHTML(data, TPL)
writeFileSync(join(outDir, 'dossier.html'), html)
check('template fully filled (no leftover tokens)', !/\{\{[A-Z_]+\}\}/.test(html))
check('dossier shows bands, tags, and the ACH winner',
  html.includes('SINGLE ORIGIN') && html.includes('CONTESTED') && html.includes('LEAST DISCONFIRMED') && !/belief=0\.\d{3}/.test(html))
check('dossier renders byte-identically across builds', html === renderHTML(buildDossier(loadCEG(CEG_PATH), brief, { now: NOW }), TPL))
check('no em dashes in the rendered dossier', !html.includes('—') && !html.includes('–'))

rmSync(outDir, { recursive: true, force: true })
console.log(failures === 0 ? '\nALL CHECKS PASSED' : `\n${failures} CHECK(S) FAILED`)
console.log(`dossier: ${join(outDir, 'dossier.html')}`)
process.exit(failures === 0 ? 0 : 1)
