#!/usr/bin/env node
// Phase B2 acceptance test: the RAS retrieval-adequacy layer.
// The retrieval analog of the selection-bias fix: skewed pools are detected
// mechanically, discount belief, emit repair tasks onto the frontier, and cap
// the verdict. Run: node ".claude/analyst/eval/run-step9.mjs"
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'
import { rasForClaim, rasRun, retrievalGapPriority, classifySource, loadESC } from '../engine/ras.mjs'
import { captureRecapture, saturationForClaim } from '../engine/saturation.mjs'
import { spamScore } from '../engine/spamscore.mjs'
import { cegFromRecords, loadCEG } from '../engine/ceg.mjs'
import { computeBelief } from '../engine/propagate.mjs'
import { buildDossier, renderHTML } from '../engine/dossier.mjs'

const here = dirname(fileURLToPath(import.meta.url))
const NOW = '2026-07-05T00:00:00Z'
let failures = 0
const check = (name, ok, detail = '') => {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? `  [${detail}]` : ''}`)
  if (!ok) failures++
}
const esc = loadESC()

const src = (id, origin, over = {}) => ({
  kind: 'source', id, url: over.url ?? `https://${id.toLowerCase()}.example.com/a`, publisher: over.publisher ?? 'pub',
  tier: over.tier ?? 4, origin_id: origin, retrieved_at: NOW, content_hash: id,
  as_of_date: over.as_of ?? NOW, is_primary: over.is_primary ?? false, ...over,
})
const edge = (id, from, to, LR, w = 1) => ({ kind: 'edge', id, rel: 'cites', from, to, weight: w, LR })
const qClaim = (id, over = {}) => ({
  kind: 'claim', id, text: 'market is $X', ctype: 'quantity', scope: 'x', half_life_days: 365,
  reference_class: { class: 'x', base_rate: 0.3 }, falsifier: 'a credible lower figure', ...over,
})

// ---------- 1. the laundered pool: six blogs, one press release, no primary ----------
{
  const recs = [
    { kind: 'origin', id: 'O-pr', label: 'one press release' },
    qClaim('C-l'),
  ]
  for (let i = 1; i <= 6; i++) {
    recs.push(src(`S-l${i}`, 'O-pr', { tier: 7, url: `https://blog${i}.example.com/top-10-markets` }))
    recs.push(edge(`E-l${i}`, `S-l${i}`, 'C-l', 2.0))
  }
  const r = rasForClaim('C-l', cegFromRecords(recs), { esc, isCrux: true })
  check('laundered pool: primary anchor floors + crux RAS floored at 0.25',
    r.dims.primary_depth === 0.25 && r.rasClaim <= 0.25, `ras=${r.rasClaim.toFixed(3)} nEffOrigins=${r.nEffOrigins}`)
  check('laundered pool: the missing primary is NAMED and a repair gap emitted',
    r.missingRequired.includes('primary_artifact') && r.gaps.some((g) => g.type === 'source_class_fill' && g.missing === 'primary_artifact'))
}

// ---------- 2. the adequate pool passes without false alarms ----------
{
  const recs = [
    { kind: 'origin', id: 'O-fil', label: 'filing' }, { kind: 'origin', id: 'O-press', label: 'trade press' },
    { kind: 'origin', id: 'O-con', label: 'contrarian analysis' },
    qClaim('C-g'),
    src('S-g1', 'O-fil', { tier: 2, is_primary: true, as_of: '2025-09-01T00:00:00Z' }),
    src('S-g2', 'O-press', { tier: 4, as_of: '2026-03-01T00:00:00Z' }),
    src('S-g3', 'O-con', { tier: 4, as_of: NOW }),
    edge('E-g1', 'S-g1', 'C-g', 2.5, 0.9),
    edge('E-g2', 'S-g2', 'C-g', 1.6),
    edge('E-g3', 'S-g3', 'C-g', 0.6), // the refuting origin
  ]
  const r = rasForClaim('C-g', cegFromRecords(recs), { esc, isCrux: true })
  check('adequate pool (primary + press + refuter + spread dates): high RAS, zero required gaps',
    r.rasClaim > 0.6 && r.missingRequired.length === 0 && !r.viewpointCapped,
    `ras=${r.rasClaim.toFixed(3)} dims=${JSON.stringify(Object.fromEntries(Object.entries(r.dims).map(([k, v]) => [k, v === null ? null : +v.toFixed(2)])))}`)
}

// ---------- 3. the all-confirming pool on a falsifiable claim ----------
{
  const recs = [
    { kind: 'origin', id: 'O-a1', label: 'a' }, { kind: 'origin', id: 'O-a2', label: 'b' }, { kind: 'origin', id: 'O-a3', label: 'c' },
    qClaim('C-a', { ctype: 'event' }),
    src('S-a1', 'O-a1', { tier: 3, is_primary: true }), src('S-a2', 'O-a2', { tier: 4 }), src('S-a3', 'O-a3', { tier: 4 }),
    edge('E-a1', 'S-a1', 'C-a', 2.0), edge('E-a2', 'S-a2', 'C-a', 1.8), edge('E-a3', 'S-a3', 'C-a', 1.5),
  ]
  const r = rasForClaim('C-a', cegFromRecords(recs), { esc })
  check('all-confirming pool on a falsifiable claim: viewpoint capped at 0.4 + disconfirming gap',
    r.viewpointCapped && r.dims.viewpoint_diversity <= 0.4 && r.gaps.some((g) => g.type === 'disconfirming'))
}

// ---------- 4. spam lowers cleanliness ----------
{
  const farm = spamScore({ url: 'https://x.example.com/top-10-best-ai-tools', publisher: '', tier: 8, passage: 'This definitive report proves it.' })
  const clean = spamScore({ url: 'https://sec.gov/filing/10k', publisher: 'SEC', tier: 2, is_primary: true, passage: 'Revenue was $3.2 billion.' })
  check('spam rubric separates the content farm from the filing', farm > 0.7 && clean === 0, `farm=${farm.toFixed(2)} clean=${clean}`)
}

// ---------- 5. saturation: capture-recapture over independent passes ----------
{
  const high = captureRecapture(['O-1', 'O-2', 'O-3', 'O-4'], ['O-1', 'O-2', 'O-3', 'O-5'])
  const low = captureRecapture(['O-1', 'O-2', 'O-3'], ['O-4', 'O-5', 'O-6'])
  check('high overlap between independent passes = high estimated recall', high.recallHat > 0.75, `recall=${high.recallHat.toFixed(2)}`)
  check('disjoint passes = a large unseen pool, honestly reported', low.unseenMass > 0.5, `unseen=${low.unseenMass.toFixed(2)}`)
  const noPasses = saturationForClaim([{ origin_id: 'O-1' }, { origin_id: 'O-2' }])
  check('no pass tags: saturation is NOT MEASURED, never defaulted', noPasses === null)
}

// ---------- 6. the belief coupling: a skewed pool is less diagnostic ----------
{
  const mk = (ras) => cegFromRecords([
    { kind: 'origin', id: 'O-c', label: 'x' },
    src('S-c', 'O-c', { tier: 3 }),
    qClaim('C-c', { ctype: 'event', ras_claim: ras }),
    edge('E-c', 'S-c', 'C-c', 3.0),
  ])
  const full = computeBelief('C-c', mk(1), { now: NOW })
  const half = computeBelief('C-c', mk(0.5), { now: NOW })
  check('ras_claim = 0.5 pulls belief toward the prior (same evidence, weaker pool)',
    half.belief < full.belief && half.belief > 0.3, `full=${full.belief.toFixed(4)} half=${half.belief.toFixed(4)}`)
  check('ras_claim = 1 reproduces the pre-RAS numbers exactly (no regression)', Math.abs(full.belief - computeBelief('C-c', mk(undefined), { now: NOW }).belief) < 1e-12)
}

// ---------- 7. repair tasks join the frontier with honest priorities ----------
{
  const cruxGap = retrievalGapPriority({ decisionWeight: 0.9, rasClaim: 0.25, belief: 0.5, severity: 1 })
  const periGap = retrievalGapPriority({ decisionWeight: 0.2, rasClaim: 0.7, belief: 0.8, severity: 0.4 })
  check('a missing primary on the crux out-prioritises a nice-to-have on a peripheral', cruxGap > 10 * periGap,
    `crux=${cruxGap.toFixed(3)} peripheral=${periGap.toFixed(3)}`)
}

// ---------- 8. the run roll-up + the verdict cap in the dossier ----------
{
  const rr = rasRun([
    { claimId: 'a', ras: 0.3, decisionWeight: 0.9 },
    { claimId: 'b', ras: 0.9, decisionWeight: 0.1 },
  ])
  check('run roll-up is decision-weighted (the crux dominates)', Math.abs(rr - 0.36) < 1e-9, `rasRun=${rr}`)

  const brief = JSON.parse(readFileSync(join(here, 'fixtures', 'brief-example.json'), 'utf8'))
  const records = readFileSync(join(here, 'fixtures', 'venture-seeded.jsonl'), 'utf8').split('\n').filter((l) => l.trim()).map((l) => JSON.parse(l))
  const lowRas = records.map((r) => (r.kind === 'claim' ? { ...r, ras_claim: 0.4, missing_source_classes: ['primary_artifact'] } : r))
  const d = buildDossier(cegFromRecords(lowRas), brief, { now: NOW })
  check('low run-level RAS makes a clean verdict CONDITIONAL (retrieval-capped)',
    d.judgment.verdict.includes('CONDITIONAL') && d.judgment.verdict.includes('retrieval-capped'), d.judgment.verdict)
  const html = renderHTML(d, join(here, '..', 'dossier', 'template.html'))
  check('dossier renders the retrieval confidence + the missing-sources ledger',
    html.includes('Retrieval confidence') && html.includes('primary_artifact') && !/\{\{[A-Z_]+\}\}/.test(html))
}

// ---------- 9. determinism ----------
{
  const recs = [
    { kind: 'origin', id: 'O-d', label: 'x' }, qClaim('C-d'),
    src('S-d', 'O-d', { tier: 3, is_primary: true }), edge('E-d', 'S-d', 'C-d', 2.0),
  ]
  const a = JSON.stringify(rasForClaim('C-d', cegFromRecords(recs), { esc }))
  const b = JSON.stringify(rasForClaim('C-d', cegFromRecords(recs), { esc }))
  check('RAS deterministic (byte-identical across runs)', a === b)
  check('mechanical source classification: internal, primary, secondary, weak', (() => {
    return classifySource({ url: 'internal://ops' }) === 'internal_primary' &&
      classifySource({ url: 'https://sec.gov/x', is_primary: true, tier: 2 }) === 'primary_artifact' &&
      classifySource({ url: 'https://press.example.com', tier: 4 }) === 'reputable_secondary' &&
      classifySource({ url: 'https://blog.example.com', tier: 8 }) === 'weak_secondary'
  })())
}

console.log(failures === 0 ? '\nALL CHECKS PASSED' : `\n${failures} CHECK(S) FAILED`)
process.exit(failures === 0 ? 0 : 1)
