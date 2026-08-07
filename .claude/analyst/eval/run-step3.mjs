#!/usr/bin/env node
// Phase A step 3 acceptance test (the analyst acceptance suite).
// Checks:
//   1. the section-5.5 VOI example reproduces exactly (WTP EVPI = 2.2, TAM EVPI = 0)
//   2. ACH ranks the LEAST-DISCONFIRMED hypothesis, not the most-supported
//   3. low-diagnostic evidence (consistent with everything) is flagged and moves nothing
//   4. the origin haircut applies inside ACH too (laundered evidence cannot vote twice)
//   5. unsigned loss -> EVIDENCE_MAP mode (the engine refuses a GO/NOGO)
//   6. the loss-ratio clamp, the flip-point sweep, tier-0 ranking, the stopping rule
//   7. determinism
// Run: node ".claude/analyst/eval/run-step3.mjs"
import { achPosteriors } from '../engine/ach.mjs'
import { evpi, bestAction, flipPointSweep, tier0Priority, rankFrontier, shouldStop } from '../engine/voi.mjs'
import { cegFromRecords } from '../engine/ceg.mjs'

const NOW = '2026-07-04T00:00:00Z'
let failures = 0
const check = (name, ok, detail = '') => {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? `  [${detail}]` : ''}`)
  if (!ok) failures++
}

// ---------- 1. the worked VOI example (spec 5.5) ----------
const decision = { kind: 'decision', id: 'D-1', options: ['GO', 'NOGO'], loss: { false_GO: 100, false_NOGO: 40 }, loss_signed: true }
{
  const base = bestAction(0.55, decision)
  check('base action: NOGO at EL0 = 22', base.action === 'NOGO' && Math.abs(base.loss - 22) < 1e-9, `${base.action} @ ${base.loss}`)
  const wtp = evpi({ basePS: 0.55, p: 0.6, psIfTrue: 0.75, psIfFalse: 0.3 }, decision)
  check('EVPI(WTP) = 2.2 (the crux earns budget)', Math.abs(wtp - 2.2) < 1e-9, `evpi=${wtp}`)
  const tam = evpi({ basePS: 0.55, p: 0.5, psIfTrue: 0.57, psIfFalse: 0.53 }, decision)
  check('EVPI(TAM) = 0 (settled facts earn nothing)', Math.abs(tam) < 1e-9, `evpi=${tam}`)
}

// ---------- ACH fixture ----------
const srcRec = (n) => ({
  kind: 'source', id: `S-${n}`, url: `https://s${n}.example.com`, tier: 3, origin_id: `O-${n}`,
  retrieved_at: NOW, content_hash: `h${n}`, as_of_date: NOW,
})
const records = [
  { kind: 'hypothesis', id: 'H1', text: 'winnable premium wedge', prior: 0.4, success_consistent: true },
  { kind: 'hypothesis', id: 'H2', text: 'right engine, wrong package', prior: 0.35, success_consistent: false },
  { kind: 'hypothesis', id: 'H3', text: 'dead zone', prior: 0.25, success_consistent: false },
  { kind: 'origin', id: 'O-1', label: 'panel' }, { kind: 'origin', id: 'O-2', label: 'pricing page' },
  { kind: 'origin', id: 'O-3', label: 'churn data' }, { kind: 'origin', id: 'O-4', label: 'generic TAM report' },
  srcRec(1), srcRec(2), srcRec(3), srcRec(4),
  { kind: 'claim', id: 'C-1', text: 'WTP signal', ctype: 'event', scope: 'x', half_life_days: 365, reference_class: { class: 'x', base_rate: 0.3 } },
  { kind: 'edge', id: 'E-1', rel: 'cites', from: 'S-1', to: 'C-1', weight: 1.0, LR: 3.0, hypothesis_scores: { H1: 'CC', H2: 'C', H3: 'II' } },
  { kind: 'edge', id: 'E-2', rel: 'cites', from: 'S-2', to: 'C-1', weight: 1.0, LR: 1.6, hypothesis_scores: { H1: 'C', H2: 'C', H3: 'I' } },
  { kind: 'edge', id: 'E-3', rel: 'cites', from: 'S-3', to: 'C-1', weight: 1.0, LR: 1.5, hypothesis_scores: { H1: 'I', H2: 'C', H3: 'C' } },
  { kind: 'edge', id: 'E-4', rel: 'cites', from: 'S-4', to: 'C-1', weight: 1.0, LR: 2.0, hypothesis_scores: { H1: 'C', H2: 'C', H3: 'C' } },
]
const ceg = cegFromRecords(records)
const ach = achPosteriors(ceg, { now: NOW })

// ---------- 2. least-disconfirmed wins, not most-supported ----------
{
  const byPosterior = [...ach.hypotheses].sort((a, b) => b.posterior - a.posterior)[0]
  check('ACH survivor is the LEAST-disconfirmed (H2)', ach.leastDisconfirmed === 'H2', `survivor=${ach.leastDisconfirmed}`)
  check(
    'and it is NOT the max-posterior hypothesis (refutation beats support)',
    byPosterior.id === 'H1' && ach.leastDisconfirmed !== byPosterior.id,
    `maxPosterior=${byPosterior.id} (${byPosterior.posterior.toFixed(3)})`
  )
  const h3 = ach.hypotheses.find((h) => h.id === 'H3')
  check('inconsistency tallies computed (H3 most disconfirmed)', h3.inconsistency === 3, `H3 tally=${h3.inconsistency}`)
  const sum = ach.hypotheses.reduce((a, h) => a + h.posterior, 0)
  check('posteriors sum to 1', Math.abs(sum - 1) < 1e-9, `sum=${sum.toFixed(6)}`)
  const h1 = ach.hypotheses.find((h) => h.id === 'H1')
  check('P(success) = posterior of success-consistent hypotheses only', Math.abs(ach.pSuccess - h1.posterior) < 1e-12, `pS=${ach.pSuccess.toFixed(4)}`)
}

// ---------- 3. low-diagnostic evidence flagged ----------
check('generic-TAM evidence (consistent with everything) flagged low-diagnostic', ach.lowDiagnostic.includes('E-4'), ach.lowDiagnostic.join(','))

// ---------- 4. the haircut applies inside ACH ----------
{
  // duplicate E-1's strong pro-H1 vote through a SECOND source with the SAME origin
  const launder = [
    ...records,
    { kind: 'source', id: 'S-5', url: 'https://blog5.example.com', tier: 8, origin_id: 'O-1', retrieved_at: NOW, content_hash: 'h5', as_of_date: NOW },
    { kind: 'edge', id: 'E-5', rel: 'cites', from: 'S-5', to: 'C-1', weight: 1.0, LR: 3.0, hypothesis_scores: { H1: 'CC', H2: 'C', H3: 'II' } },
  ]
  // the same vote through a genuinely DISTINCT origin
  const distinct = launder.map((r) => (r.id === 'S-5' ? { ...r, origin_id: 'O-5' } : r))
  distinct.push({ kind: 'origin', id: 'O-5', label: 'independent second panel' })
  const pLaunder = achPosteriors(cegFromRecords(launder), { now: NOW }).hypotheses.find((h) => h.id === 'H1').posterior
  const pDistinct = achPosteriors(cegFromRecords(distinct), { now: NOW }).hypotheses.find((h) => h.id === 'H1').posterior
  check('same-origin duplicate moves H1 less than an independent origin would', pLaunder < pDistinct, `laundered=${pLaunder.toFixed(4)} < independent=${pDistinct.toFixed(4)}`)
}

// ---------- 5. unsigned loss -> evidence-map mode ----------
{
  const unsigned = { ...decision, loss_signed: false }
  const a = bestAction(0.55, unsigned)
  check('unsigned loss: engine refuses a GO/NOGO (EVIDENCE_MAP mode)', a.action === 'EVIDENCE_MAP')
  check('unsigned loss: EVPI is 0 (no decision, no decision-relevant value)', evpi({ basePS: 0.55, p: 0.6, psIfTrue: 0.75, psIfFalse: 0.3 }, unsigned) === 0)
}

// ---------- 6. clamp, sweep, tier-0, stopping ----------
{
  let threw = false
  try { bestAction(0.5, { ...decision, loss: { false_GO: 100, false_NOGO: 2 } }) } catch { threw = true }
  check('loss ratio outside [1,20] throws (the clamp is enforced, not advisory)', threw)

  const sweep = flipPointSweep(0.55)
  const flip = sweep.find((s) => s.action === 'NOGO')
  check('flip-point sweep: GO at ratio 1, flips to NOGO near 1.22', sweep[0].action === 'GO' && flip && Math.abs(flip.ratio - 1.22) < 0.15, JSON.stringify(sweep))

  const crux = { belief: 0.5, status: 'open' }
  const settled = { belief: 0.95, status: 'supported' }
  const ranked = rankFrontier([
    { id: 'C-settled', kind: 'claim', claim: settled, decisionWeight: 0.9 },
    { id: 'C-crux', kind: 'claim', claim: crux, decisionWeight: 0.9 },
  ])
  check('tier-0 frontier: the open crux outranks the settled claim', ranked[0].id === 'C-crux',
    `crux=${tier0Priority(crux, 0.9).toFixed(3)} vs settled=${tier0Priority(settled, 0.9).toFixed(4)}`)

  const s1 = shouldStop({ maxEVPI: 0.1, costOfNextAction: 0.5 })
  const s2 = shouldStop({ budget: { agent_calls: 0, usd: 3, wall_clock_s: 100 } })
  const s3 = shouldStop({ maxEVPI: 2.2, costOfNextAction: 0.5, budget: { agent_calls: 5, usd: 3, wall_clock_s: 100 } })
  check('stopping rule: stops on low EVPI and on exhausted budget, continues otherwise', s1.stop && s2.stop && !s3.stop)
}

// ---------- 7. determinism ----------
{
  const a = JSON.stringify(achPosteriors(cegFromRecords(records), { now: NOW }))
  const b = JSON.stringify(achPosteriors(cegFromRecords(records), { now: NOW }))
  check('ACH deterministic (byte-identical across runs)', a === b)
}

console.log(failures === 0 ? '\nALL CHECKS PASSED' : `\n${failures} CHECK(S) FAILED`)
process.exit(failures === 0 ? 0 : 1)
