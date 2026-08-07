// The Conviction Dossier builder: deterministic assembly of every computed section.
// Build spec section 10 + the analyst design notes fix 4 (two-axis output) and section 4b
// (coverage state, emergent verdict). The synthesizer AGENT writes prose AROUND
// this data; it never produces a number. Same frozen CEG + brief in, same dossier
// data out, byte for byte.
import { readFileSync, writeFileSync } from 'node:fs'
import { computeBelief } from './propagate.mjs'
import { achPosteriors } from './ach.mjs'
import { bestAction, expectedLosses, flipPointSweep, tier0Priority } from './voi.mjs'

// ---------- the two axes (ICD 203 discipline) ----------
// Axis 1: LIKELIHOOD as a fixed 7-band estimative lexicon. Bands, never decimals,
// in anything customer-facing (v3 via-negativa: two-significant-figure beliefs cut).
export function estimativeBand(p) {
  if (p < 0.05) return 'ALMOST NO CHANCE (1-5%)'
  if (p < 0.2) return 'VERY UNLIKELY (5-20%)'
  if (p < 0.45) return 'UNLIKELY (20-45%)'
  if (p <= 0.55) return 'ROUGHLY EVEN (45-55%)'
  if (p <= 0.8) return 'LIKELY (55-80%)'
  if (p <= 0.95) return 'VERY LIKELY (80-95%)'
  return 'ALMOST CERTAIN (95-99%)'
}

// Axis 2: CONFIDENCE, computed from the evidence structure (N_eff, fidelity,
// diagnostic weight, min source tier). A one-origin claim and a three-origin claim
// can NEVER print the same confidence: single-origin is hard-capped at LOW.
export function computedConfidence(beliefResult, ceg) {
  const items = beliefResult.contributors.flatMap((o) => o.items)
  if (items.length === 0) return { score: 0, band: 'NONE', singleOrigin: true, minTier: null }
  let fidSum = 0
  let minTier = 9
  for (const it of items) {
    const edge = ceg.edges.find((e) => e.id === it.edgeId)
    const src = ceg.nodes.get(edge?.from)
    fidSum += edge?.weight ?? 0
    if (src && src.tier < minTier) minTier = src.tier
  }
  const nEffScore = Math.min(beliefResult.nEff, 3) / 3
  const fidelityScore = fidSum / items.length
  const totalLnLR = beliefResult.logOdds - beliefResult.prior.L0
  const diagScore = Math.min(Math.abs(totalLnLR), 1.5) / 1.5
  const tierScore = (10 - minTier) / 9
  let score = 0.35 * nEffScore + 0.2 * fidelityScore + 0.25 * diagScore + 0.2 * tierScore
  const singleOrigin = beliefResult.nEff <= 1
  if (singleOrigin) score = Math.min(score, 0.4) // the hard cap
  const band = score < 0.45 ? 'LOW' : score <= 0.7 ? 'MODERATE' : 'HIGH'
  return { score, band, singleOrigin, minTier }
}

// ---------- the dossier data ----------
// buildDossier(ceg, brief, { now }) -> every computed section, prose-free.
export function buildDossier(ceg, brief, opts = {}) {
  if (!opts.now) throw new Error('opts.now required (determinism forbids Date.now())')
  const now = opts.now
  const decision = brief.decision
  const signed = decision?.loss_signed === true

  // Per-claim computation (belief, two axes, traceability chain).
  const claims = [...ceg.nodes.values()].filter((n) => n.kind === 'claim')
  const rows = claims.map((c) => {
    const r = computeBelief(c.id, ceg, { now })
    const conf = computedConfidence(r, ceg)
    const evidence = r.contributors.flatMap((o) =>
      o.items.map((it) => {
        const edge = ceg.edges.find((e) => e.id === it.edgeId)
        const src = ceg.nodes.get(edge?.from)
        return { sourceId: src?.id, url: src?.url, originId: o.originId, tier: src?.tier, lrEff: it.lrEff }
      })
    )
    const bw = brief.claims?.find((x) => x.id === c.id)?.decision_weight ?? c.decision_weight ?? 0.5
    return {
      claimId: c.id,
      text: c.text,
      ras: typeof c.ras_claim === 'number' ? c.ras_claim : null,
      missingSources: c.missing_source_classes ?? [],
      status: c.status ?? 'open',
      contested: (c.status ?? 'open') !== 'supported',
      belief: r.belief,
      band: estimativeBand(r.belief),
      confidence: conf,
      nEff: r.nEff,
      baseRate: r.prior.baseRate,
      falsifier: c.falsifier ?? null,
      branch: brief.claim_branch?.[c.id] ?? null,
      decisionWeight: bw,
      priority: tier0Priority({ belief: r.belief, status: c.status ?? 'open' }, bw),
      evidence,
    }
  })
  rows.sort((a, b) => b.priority - a.priority || a.claimId.localeCompare(b.claimId))

  // Coverage: a crux branch is resolved when none of its claims is still open.
  const cruxBranches = (brief.issue_tree?.branches ?? []).filter((b) => b.crux)
  const coverageRows = cruxBranches.map((b) => {
    const cs = rows.filter((r) => r.branch === b.id)
    return { branch: b.id, text: b.text, resolved: cs.length > 0 && cs.every((r) => r.status !== 'open') }
  })
  const coverage = {
    cruxTotal: coverageRows.length,
    cruxResolved: coverageRows.filter((c) => c.resolved).length,
    sufficient: coverageRows.length > 0 && coverageRows.every((c) => c.resolved),
    rows: coverageRows,
  }

  // ACH (only if scored evidence exists).
  let ach = null
  try {
    ach = achPosteriors(ceg, { now })
  } catch {
    ach = null
  }

  // The emergent verdict (v3 4b invariant 2: never mistakable for the answer early).
  let verdict
  let action = null
  let losses = null
  let sweep = null
  if (!signed) {
    verdict = 'EVIDENCE MAP: no GO/NOGO conviction (the decision framing was not signed)'
  } else if (!coverage.sufficient) {
    verdict = `NOT YET A VERDICT: resolved ${coverage.cruxResolved} of ${coverage.cruxTotal} cruxes`
  } else if (!ach) {
    verdict = 'NOT YET A VERDICT: no hypothesis-scored evidence in the graph'
  } else {
    action = bestAction(ach.pSuccess, decision)
    losses = expectedLosses(ach.pSuccess, decision.loss)
    sweep = flipPointSweep(ach.pSuccess)
    const margin = Math.abs(losses.GO - losses.NOGO) / Math.max(losses.GO, losses.NOGO)
    verdict = margin < 0.15 ? `CONDITIONAL ${action.action}` : action.action
  }

  // The retrieval cap (RAS): a verdict cannot exceed the conviction its own
  // retrieval adequacy supports. Low run-level RAS makes any clean verdict CONDITIONAL.
  const rasRows = rows.filter((r) => typeof r.ras === 'number')
  const retrievalConfidence = rasRows.length
    ? rasRows.reduce((a, r) => a + r.decisionWeight * r.ras, 0) / rasRows.reduce((a, r) => a + r.decisionWeight, 0)
    : null
  if (retrievalConfidence !== null && retrievalConfidence < 0.6 && (verdict === 'GO' || verdict === 'NOGO')) {
    verdict = `CONDITIONAL ${verdict} (retrieval-capped: adequacy ${retrievalConfidence.toFixed(2)})`
  }

  // The kill-line: the highest-priority unsettled claim and what would flip it.
  const kill = rows.find((r) => r.status !== 'supported') ?? rows[0]
  const killLine = kill ? `${kill.claimId}: ${kill.falsifier ?? 'no falsifier recorded'}` : 'none'

  // Key Assumptions Check + quarantine visibility + indicators.
  const assumptions = [...ceg.nodes.values()]
    .filter((n) => n.kind === 'assumption')
    .map((a) => ({ id: a.id, text: a.text, rating: a.rating, indicator: a.falsifying_indicator ?? null }))
  const quarantined = [...ceg.nodes.values()]
    .filter((n) => n.kind === 'source' && (n.access === 'quarantined' || n.access === 'dead'))
    .map((s) => ({ id: s.id, url: s.url, reason: s.quarantine_reason ?? s.access }))
  const indicators = rows.filter((r) => r.falsifier).map((r) => ({ claimId: r.claimId, watch: r.falsifier }))

  return {
    runId: brief.run_id,
    question: brief.question,
    generatedAt: now,
    mode: signed ? 'DECISION' : 'EVIDENCE_MAP',
    coverage,
    judgment: {
      verdict,
      pSuccess: ach?.pSuccess ?? null,
      pBand: ach ? estimativeBand(ach.pSuccess) : null,
      lossRatio: decision ? decision.loss.false_GO / decision.loss.false_NOGO : null,
      losses,
      flipSweep: sweep,
      killLine,
      retrievalConfidence,
    },
    cruxes: rows.filter((r) => cruxBranches.some((b) => b.id === r.branch)),
    claims: rows,
    ach: ach
      ? {
          hypotheses: ach.hypotheses,
          leastDisconfirmed: ach.leastDisconfirmed,
          ranking: ach.ranking,
          lowDiagnostic: ach.lowDiagnostic,
        }
      : null,
    assumptions,
    quarantined,
    indicators,
  }
}

// ---------- HTML rendering ----------
const esc = (s) =>
  String(s ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')

const tag = (r) => (r.contested ? ` <span class="tag contested">CONTESTED</span>` : ` <span class="tag ok">SUPPORTED</span>`)

export function renderHTML(data, templatePath) {
  const tpl = readFileSync(templatePath, 'utf8')
  const map = {
    RUN_ID: esc(data.runId),
    QUESTION: esc(data.question),
    GENERATED: esc(data.generatedAt),
    MODE: esc(data.mode),
    VERDICT: esc(data.judgment.verdict),
    P_BAND: esc(data.judgment.pBand ?? 'n/a'),
    LOSS_RATIO: data.judgment.lossRatio ? data.judgment.lossRatio.toFixed(1) : 'n/a',
    KILL_LINE: esc(data.judgment.killLine),
    RETRIEVAL_CONFIDENCE: data.judgment.retrievalConfidence !== null && data.judgment.retrievalConfidence !== undefined
      ? `${Math.round(data.judgment.retrievalConfidence * 100)}/100`
      : 'not measured (RAS ships with the SENSE layer runs)',
    MISSING_SOURCE_ROWS: (() => {
      const rows = data.claims.filter((r) => r.missingSources.length)
        .map((r) => `<tr><td class="mono">${esc(r.claimId)}</td><td>${r.missingSources.map(esc).join(', ')}</td></tr>`)
      return rows.length ? rows.join('\n') : '<tr><td colspan="2">none: every expected source class was found</td></tr>'
    })(),
    COVERAGE: `resolved ${data.coverage.cruxResolved} of ${data.coverage.cruxTotal} cruxes`,
    COVERAGE_ROWS: data.coverage.rows
      .map((c) => `<tr><td>${esc(c.branch)}</td><td>${esc(c.text)}</td><td>${c.resolved ? 'resolved' : 'OPEN'}</td></tr>`)
      .join('\n'),
    CRUX_ROWS: data.cruxes
      .map(
        (r) =>
          `<tr><td class="mono">${esc(r.claimId)}</td><td>${esc(r.text)}${tag(r)}</td>` +
          `<td>${esc(r.band)}</td><td>${esc(r.confidence.band)}${r.confidence.singleOrigin ? ' <span class="tag warn">SINGLE ORIGIN</span>' : ''}</td>` +
          `<td class="mono">${r.nEff}</td><td>${esc(r.falsifier ?? '')}</td></tr>`
      )
      .join('\n'),
    ACH_ROWS: (data.ach?.hypotheses ?? [])
      .map(
        (h) =>
          `<tr${h.id === data.ach.leastDisconfirmed ? ' class="winner"' : ''}><td class="mono">${esc(h.id)}</td>` +
          `<td>${esc(h.text)}${h.id === data.ach.leastDisconfirmed ? ' <span class="tag ok">LEAST DISCONFIRMED</span>' : ''}</td>` +
          `<td>${esc(estimativeBand(h.posterior))}</td><td class="mono">${h.inconsistency.toFixed(1)}</td></tr>`
      )
      .join('\n'),
    ASSUMPTION_ROWS: data.assumptions
      .map((a) => `<tr><td class="mono">${esc(a.id)}</td><td>${esc(a.text)}</td><td>${esc(a.rating)}</td><td>${esc(a.indicator ?? '')}</td></tr>`)
      .join('\n'),
    ANNEX_ROWS: data.claims
      .map(
        (r) =>
          `<tr><td class="mono">${esc(r.claimId)}</td><td>${esc(r.band)}</td><td>${esc(r.confidence.band)}</td>` +
          `<td class="mono">${r.nEff}</td><td>${esc(r.status)}</td>` +
          `<td class="small">${r.evidence.map((e) => `${esc(e.originId)} (t${e.tier}) ${esc(e.url)}`).join('<br>')}</td></tr>`
      )
      .join('\n'),
    QUARANTINE_ROWS: data.quarantined.length
      ? data.quarantined.map((q) => `<tr><td class="mono">${esc(q.id)}</td><td>${esc(q.url)}</td><td>${esc(q.reason)}</td></tr>`).join('\n')
      : '<tr><td colspan="3">none</td></tr>',
    INDICATOR_ROWS: data.indicators.map((i) => `<tr><td class="mono">${esc(i.claimId)}</td><td>${esc(i.watch)}</td></tr>`).join('\n'),
    LOW_DIAGNOSTIC: data.ach?.lowDiagnostic?.length ? esc(data.ach.lowDiagnostic.join(', ')) : 'none',
  }
  let html = tpl
  for (const [k, v] of Object.entries(map)) html = html.split(`{{${k}}}`).join(v)
  const leftovers = html.match(/\{\{[A-Z_]+\}\}/g)
  if (leftovers) throw new Error(`unfilled template tokens: ${[...new Set(leftovers)].join(', ')}`)
  return html
}

// CLI: node dossier.mjs <ceg.jsonl> <brief.json> <template.html> <out.html> --now=<ISO>
if (process.argv[1] && import.meta.url.endsWith(process.argv[1].split('/').pop())) {
  const [cegPath, briefPath, tplPath, outPath] = process.argv.slice(2, 6)
  const nowArg = process.argv.find((a) => a.startsWith('--now='))
  if (!cegPath || !briefPath || !tplPath || !outPath || !nowArg) {
    console.error('usage: node dossier.mjs <ceg.jsonl> <brief.json> <template.html> <out.html> --now=<ISO>')
    process.exit(1)
  }
  const { loadCEG } = await import('./ceg.mjs')
  const ceg = loadCEG(cegPath)
  const brief = JSON.parse(readFileSync(briefPath, 'utf8'))
  const data = buildDossier(ceg, brief, { now: nowArg.slice(6) })
  writeFileSync(outPath, renderHTML(data, tplPath))
  console.log(JSON.stringify({ out: outPath, verdict: data.judgment.verdict, coverage: `${data.coverage.cruxResolved}/${data.coverage.cruxTotal}`, mode: data.mode }))
}
