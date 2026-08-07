// The public Prediction Registry generator (the analyst design notes fix 7 + section 4).
// Turns the hash-chained ledgers into the public accountability page: dated,
// falsifiable, entity-safe calls with frozen criteria, graded in public, misses
// as prominent as hits, UNRESOLVED counted, backtests labelled as backtests.
//
// Publication is an EXPLICIT decision, never a default: only prediction ids on
// the publish allowlist enter the page (private dossier calls stay private), and
// deploying the generated page to claudify.tech is an explicit operator decision.
// Generation is deterministic: same ledgers + same allowlist = same page.
import { readFileSync, existsSync } from 'node:fs'
import { verifyChain, murphy, stratifyByDifficulty, HARD_BAND } from './score.mjs'
import { estimativeBand } from './dossier.mjs'

const lines = (p) => (existsSync(p) ? readFileSync(p, 'utf8').split('\n').filter((l) => l.trim()).map((l) => JSON.parse(l)) : [])

// buildRegistry({ ledgerPath, calibPath, publishIds, backtests, now }) -> data
// publishIds: the explicit allowlist. backtests: [{statement, band, outcome, note}]
// retrodictive entries, ALWAYS labelled, never mixed into the live score.
export function buildRegistry({ ledgerPath, calibPath, publishIds = [], backtests = [], now }) {
  if (!now) throw new Error('now (ISO) required: determinism forbids clock reads')
  const chain = verifyChain(ledgerPath)
  if (!chain.ok) throw new Error(`REFUSING to publish from a broken ledger: line ${chain.line} (${chain.reason})`)
  const calibChain = verifyChain(calibPath)
  if (existsSync(calibPath) && !calibChain.ok) throw new Error(`REFUSING: calibration log broken at line ${calibChain.line}`)

  const preds = lines(ledgerPath)
  const resolutions = new Map(lines(calibPath).map((r) => [r.prediction_id, r]))
  const allow = new Set(publishIds)
  const published = []
  for (const p of preds) {
    if (!allow.has(p.id)) continue
    const res = resolutions.get(p.id)
    const due = Date.parse(p.resolves_by) <= Date.parse(now)
    const status = res
      ? res.o === 1 ? 'HIT' : res.o === 0 ? 'MISS' : 'PARTIAL'
      : due ? 'UNRESOLVED (due, counted)' : 'PENDING'
    published.push({
      id: p.id,
      statement: p.statement,
      band: p.type === 'binary' ? estimativeBand(p.p) : `interval ${p.interval.p10}-${p.interval.p90}`,
      hardBand: p.type === 'binary' && p.p >= HARD_BAND[0] && p.p <= HARD_BAND[1],
      created_at: p.created_at,
      resolves_by: p.resolves_by,
      criterion_hash: (p.resolution_criterion_hash ?? '').slice(0, 12),
      status,
    })
  }
  published.sort((a, b) => a.resolves_by.localeCompare(b.resolves_by) || a.id.localeCompare(b.id))

  // The live score: resolved published binaries only; backtests NEVER enter it.
  const scored = published
    .map((p) => resolutions.get(p.id))
    .filter((r) => r && r.type === 'binary')
    .map((r) => ({ p: r.p, o: r.o }))
  const m = scored.length ? murphy(scored) : null
  const strat = scored.length ? stratifyByDifficulty(scored) : null
  const unresolved = published.filter((p) => p.status.startsWith('UNRESOLVED')).length

  return {
    generatedAt: now,
    chain: { predictions: chain.count, intact: true },
    counts: {
      published: published.length,
      pending: published.filter((p) => p.status === 'PENDING').length,
      resolved: scored.length,
      unresolved,
      privateCalls: preds.length - published.length,
    },
    calibration: m
      ? { n: m.n, brier: m.brier, reliability: m.reliability, resolution: m.resolution, hardBandN: strat.hard.length }
      : null,
    uncalibratedNote: scored.length < 20 ? `n=${scored.length}, uncalibrated (the temperature stage needs 20 resolved)` : null,
    calls: published,
    backtests,
  }
}

const esc = (s) => String(s ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')

export function renderRegistry(data, templatePath) {
  const tpl = readFileSync(templatePath, 'utf8')
  const statusCls = (s) => (s === 'HIT' ? 'ok' : s === 'MISS' ? 'warn' : s.startsWith('UNRESOLVED') ? 'contested' : 'muted')
  const map = {
    GENERATED: esc(data.generatedAt),
    CHAIN_LINE: `ledger hash-chain intact over ${data.chain.predictions} records; every criterion frozen at prediction time`,
    COUNTS_LINE: `${data.counts.published} public calls (${data.counts.pending} pending, ${data.counts.resolved} resolved, ${data.counts.unresolved} unresolved and counted). ${data.counts.privateCalls} further calls remain private by design.`,
    HONESTY_LINE: data.uncalibratedNote
      ? esc(data.uncalibratedNote)
      : data.calibration
        ? `Brier ${data.calibration.brier.toFixed(3)} over n=${data.calibration.n}; hard-band calls: ${data.calibration.hardBandN}`
        : 'no resolved public calls yet',
    CALL_ROWS: data.calls.length
      ? data.calls
          .map(
            (c) =>
              `<tr><td class="mono">${esc(c.id)}</td><td>${esc(c.statement)}${c.hardBand ? ' <span class="tag ok">HARD BAND</span>' : ''}</td>` +
              `<td>${esc(c.band)}</td><td class="mono">${esc(c.created_at.slice(0, 10))}</td><td class="mono">${esc(c.resolves_by.slice(0, 10))}</td>` +
              `<td class="mono">${esc(c.criterion_hash)}</td><td><span class="tag ${statusCls(c.status)}">${esc(c.status)}</span></td></tr>`
          )
          .join('\n')
      : '<tr><td colspan="7">no public calls yet</td></tr>',
    BACKTEST_ROWS: data.backtests.length
      ? data.backtests
          .map((b) => `<tr><td>${esc(b.statement)}</td><td>${esc(b.band)}</td><td>${esc(b.outcome)}</td><td class="small">${esc(b.note ?? '')}</td></tr>`)
          .join('\n')
      : '<tr><td colspan="4">none published</td></tr>',
  }
  let html = tpl
  for (const [k, v] of Object.entries(map)) html = html.split(`{{${k}}}`).join(v)
  const leftovers = html.match(/\{\{[A-Z_]+\}\}/g)
  if (leftovers) throw new Error(`unfilled registry tokens: ${[...new Set(leftovers)].join(', ')}`)
  return html
}
