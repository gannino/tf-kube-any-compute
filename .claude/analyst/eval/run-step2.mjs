#!/usr/bin/env node
// Phase A step 2 acceptance test (the analyst acceptance suite).
// The six adversarial poisons (spec 11.2, distilled from the real V-08 failures)
// must each be caught by the NAMED mechanism, plus gate unit checks.
// Run: node ".claude/analyst/eval/run-step2.mjs"
import {
  gateEvidence, valueInPassage, extractNumbers,
  twBreakevenDirection, twRatioCherryPick, twAbsenceEvidence, twStaleFastMover,
  twSamVsTam, twMarginBound, provenanceComplete,
} from '../engine/ingest.mjs'
import { cegFromRecords } from '../engine/ceg.mjs'
import { computeBelief } from '../engine/propagate.mjs'

const NOW = '2026-07-04T00:00:00Z'
const okFetcher = async () => ({ status: 200 })
const deadFetcher = async () => ({ status: 404 })

let failures = 0
const check = (name, ok, detail = '') => {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? `  [${detail}]` : ''}`)
  if (!ok) failures++
}

// ---------- POISON 1: platform/product conflation (mechanism: scope-bound quote-grounding) ----------
// Anthropic's $14B total ARR quoted as Claude Code product ARR. The number IS on the
// page, so the old presence-check passed it. Scope binding must quarantine it.
{
  const r = await gateEvidence(
    {
      source: {
        id: 'S-p1', url: 'https://news.example.com/anthropic-arr', tier: 4, origin_id: 'O-p1',
        retrieved_at: NOW, content_hash: 'p1', as_of_date: '2026-06-01',
        passage: 'Anthropic has reached $14 billion in annualized revenue, the company said.',
      },
      edge: { id: 'E-p1', rel: 'cites', from: 'S-p1', to: 'C-p1', weight: 1.0, LR: 4.0 },
      claim: {
        id: 'C-p1', kind: 'claim', text: 'Claude Code ARR is $14B', ctype: 'quantity', value: 14e9,
        scope: 'Claude Code product line only', scope_entities: ['claude code'], half_life_days: 90,
        reference_class: { class: 'dev-tool ARR', base_rate: 0.2 },
      },
    },
    { fetcher: okFetcher }
  )
  const hit = r.verdict === 'quarantined' && r.failures.some((f) => f.class === 'scope_mismatch')
  check('P1 conflation caught by scope-bound grounding (value present, entity absent)', hit, r.failures.map((f) => f.class || f.gate).join(','))
  check('P1 quarantined edge cannot move belief (weight zeroed)', r.edge.weight === 0)
}

// ---------- POISON 2: inverted break-even math (mechanism: numeric tripwire) ----------
{
  const r = twBreakevenDirection([
    { revenue: 100_000, breakEvenMonths: 6 },
    { revenue: 200_000, breakEvenMonths: 9 },
  ])
  check('P2 inverted break-even caught by tripwire', r.flag === true && r.tripwire === 'breakeven_inverted', r.detail)
}

// ---------- POISON 3: cherry-picked LTV:CAC from wide ranges (mechanism: ratio tripwire) ----------
{
  const r = twRatioCherryPick({ ltv: { min: 500, max: 3000 }, cac: { min: 100, max: 300 }, reported: 10 })
  const ok = r.flag === true && r.scenarios.pessimistic < 2 && r.scenarios.optimistic === 30
  check('P3 cherry-picked ratio caught; three scenarios forced', ok,
    `pess=${r.scenarios.pessimistic.toFixed(2)} base=${r.scenarios.base.toFixed(2)} opt=${r.scenarios.optimistic.toFixed(2)}`)
}

// ---------- POISON 4: "no competitor found" as bullish confirmation (mechanism: absence tripwire) ----------
{
  const r = twAbsenceEvidence({ id: 'E-p4', etype: 'absence', LR: 3.0 })
  check('P4 absence-as-confirmation caught; LR forced non-diagnostic', r.flag === true && r.forcedLR === 1.0, r.detail)
}

// ---------- POISON 5: stale fast-mover metric (mechanism: decay + visibility flag) ----------
{
  const claim = {
    id: 'C-p5', kind: 'claim', text: 'startup ARR', ctype: 'quantity', scope: 'x', half_life_days: 90,
    reference_class: { class: 'x', base_rate: 0.3 },
  }
  const source = {
    id: 'S-p5', kind: 'source', url: 'https://x.example.com', tier: 4, origin_id: 'O-p5',
    retrieved_at: NOW, content_hash: 'p5', as_of_date: '2025-01-01',
  }
  const flag = twStaleFastMover(source, claim, NOW)
  // and decay must have crushed its diagnosticity in the propagator
  const ceg = cegFromRecords([
    { kind: 'origin', id: 'O-p5', label: 'stale origin' },
    { ...source, kind: 'source' },
    claim,
    { kind: 'edge', id: 'E-p5', rel: 'cites', from: 'S-p5', to: 'C-p5', weight: 1.0, LR: 3.0 },
  ])
  const b = computeBelief('C-p5', ceg, { now: NOW })
  const lrEff = Math.exp(b.contributors[0].lnLR)
  check('P5 stale fast-mover flagged', flag.flag === true, flag.detail)
  check('P5 decay crushed the stale LR toward 1 (non-diagnostic)', lrEff < 1.05, `LR 3.0 decayed to LR_eff=${lrEff.toFixed(4)}`)
}

// ---------- POISON 6: two blogs laundering one origin (mechanism: independence haircut) ----------
{
  const ceg = cegFromRecords([
    { kind: 'origin', id: 'O-root', label: 'one Grand View press release' },
    { kind: 'source', id: 'S-a', url: 'https://a.example.com', tier: 3, origin_id: 'O-root', retrieved_at: NOW, content_hash: 'a', as_of_date: NOW },
    { kind: 'source', id: 'S-b', url: 'https://blog-b.example.com', tier: 8, origin_id: 'O-root', retrieved_at: NOW, content_hash: 'b', as_of_date: NOW },
    { kind: 'source', id: 'S-c', url: 'https://blog-c.example.com', tier: 8, origin_id: 'O-root', retrieved_at: NOW, content_hash: 'c', as_of_date: NOW },
    { kind: 'claim', id: 'C-p6', text: 'market is $3.67B', ctype: 'quantity', scope: 'x', half_life_days: 365, reference_class: { class: 'x', base_rate: 0.3 } },
    { kind: 'edge', id: 'E-a', rel: 'cites', from: 'S-a', to: 'C-p6', weight: 1.0, LR: 2.5 },
    { kind: 'edge', id: 'E-b', rel: 'cites', from: 'S-b', to: 'C-p6', weight: 1.0, LR: 2.5 },
    { kind: 'edge', id: 'E-c', rel: 'cites', from: 'S-c', to: 'C-p6', weight: 1.0, LR: 2.5 },
  ])
  const b = computeBelief('C-p6', ceg, { now: NOW })
  check('P6 three sources, one origin: N_eff = 1, not 3', b.nEff === 1, `nEff=${b.nEff}`)
}

// ---------- gate unit checks ----------
{
  // fabricated number: claim value nowhere in the passage
  const r = await gateEvidence(
    {
      source: { id: 'S-f', url: 'https://f.example.com', tier: 5, origin_id: 'O-f', retrieved_at: NOW, content_hash: 'f', as_of_date: NOW, passage: 'The market reached $3.2 billion last year.' },
      edge: { id: 'E-f', rel: 'cites', from: 'S-f', to: 'C-f', weight: 1.0, LR: 3.0 },
      claim: { id: 'C-f', kind: 'claim', text: 'market is $5B', ctype: 'quantity', value: 5e9, scope: 'x', half_life_days: 365, reference_class: { class: 'x', base_rate: 0.3 } },
    },
    { fetcher: okFetcher }
  )
  check('fabricated number quarantined as unsupported (no LLM call needed)', r.verdict === 'quarantined' && r.failures.some((f) => f.class === 'unsupported'))
}
{
  // dead URL
  const r = await gateEvidence(
    {
      source: { id: 'S-d', url: 'https://dead.example.com', tier: 5, origin_id: 'O-d', retrieved_at: NOW, content_hash: 'd', as_of_date: NOW, passage: 'irrelevant' },
      edge: { id: 'E-d', rel: 'cites', from: 'S-d', to: 'C-d', weight: 1.0, LR: 2.0 },
      claim: { id: 'C-d', kind: 'claim', text: 'anything', ctype: 'event', scope: 'x', half_life_days: 365, reference_class: { class: 'x', base_rate: 0.3 } },
    },
    { fetcher: deadFetcher }
  )
  check('dead URL: access=dead, weight zeroed', r.source.access === 'dead' && r.edge.weight === 0)
}
{
  // provenance incompleteness
  const p = provenanceComplete({ id: 'S-n', url: 'https://n.example.com', tier: 5 }, { ctype: 'quantity' })
  check('provenance gate rejects missing origin/hash/date/reference_class', !p.complete && p.missing.length >= 4, p.missing.join(', '))
}
{
  // number normalization equivalences
  const ok =
    valueInPassage(14e9, 'revenue hit $14B this year') &&
    valueInPassage(14e9, 'revenue hit 14 billion dollars') &&
    valueInPassage(1.2e9, 'about 1,200,000,000 users worth') &&
    !valueInPassage(14e9, 'revenue hit $4.1B this year')
  check('number normalization: 14B = 14 billion = 14,000,000,000', ok, `readings of "$14B": ${extractNumbers('$14B').join(',')}`)
}
{
  // remaining tripwires
  const sam = twSamVsTam({ value: 5e9 }, { value: 3e9 })
  const margin = twMarginBound({ value: 97, unit: '%' })
  check('SAM > TAM and margin > 95% both tripped', sam.flag === true && margin.flag === true)
}

console.log(failures === 0 ? '\nALL CHECKS PASSED' : `\n${failures} CHECK(S) FAILED`)
process.exit(failures === 0 ? 0 : 1)
