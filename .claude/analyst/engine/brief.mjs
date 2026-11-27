// Brief validation + the dry-run planner.
// The research-strategist EMITS a brief (brief.json); this module VALIDATES it and
// renders the research plan deterministically. Zero network, zero LLM, by
// construction: the acceptance property of /research --dry-run lives here.
// Build spec sections 6-7 + the analyst design notes fix 5 (human-signed loss) and
// section 4b (staged execution).
import { readFileSync } from 'node:fs'
import { rankFrontier } from './voi.mjs'

const PRESETS = ['venture', 'market', 'competitor', 'pricing', 'diligence']
const CTYPES = ['quantity', 'event', 'relationship', 'forecast', 'price', 'risk', 'moat_power']

export function validateBrief(brief) {
  const errs = []
  const need = (cond, msg) => { if (!cond) errs.push(msg) }

  need(brief && typeof brief === 'object', 'brief must be an object')
  if (!brief || typeof brief !== 'object') return { ok: false, errs, mode: null }

  need(typeof brief.run_id === 'string' && brief.run_id.length > 0, 'run_id required')
  need(typeof brief.question === 'string' && brief.question.length > 0, 'question required')
  need(PRESETS.includes(brief.preset), `preset must be one of ${PRESETS.join('|')}`)
  need([1, 2, 3].includes(brief.stage), 'stage must be 1, 2 or 3')

  // The decision frame (v3 fix 5): the loss is the human's, never the engine's.
  const d = brief.decision
  let mode = 'EVIDENCE_MAP'
  need(d && typeof d === 'object', 'decision node required')
  if (d) {
    need(Array.isArray(d.options) && d.options.length >= 2, 'decision.options needs at least 2 options')
    need(d.loss && d.loss.false_GO > 0 && d.loss.false_NOGO > 0, 'decision.loss.false_GO/false_NOGO must be > 0')
    if (d.loss_signed === true) {
      mode = 'DECISION'
      const ratio = d.loss.false_GO / d.loss.false_NOGO
      need(ratio >= 1 && ratio <= 20, `loss ratio ${ratio.toFixed(2)} outside the [1, 20] clamp`)
    }
  }

  // MECE issue tree with 1-3 tagged cruxes.
  const tree = brief.issue_tree
  need(tree && Array.isArray(tree.branches) && tree.branches.length >= 2, 'issue_tree needs at least 2 branches')
  const branchIds = new Set()
  let cruxes = 0
  for (const b of tree?.branches ?? []) {
    need(typeof b.id === 'string' && typeof b.text === 'string', 'each branch needs id + text')
    need(!branchIds.has(b.id), `duplicate branch id ${b.id}`)
    branchIds.add(b.id)
    if (b.crux === true) cruxes++
  }
  need(cruxes >= 1 && cruxes <= 3, `issue tree must tag 1-3 cruxes (got ${cruxes}); the crux IS the product`)

  // 3-6 MECE hypotheses, priors summing to 1.
  const hyps = brief.hypotheses ?? []
  need(hyps.length >= 3 && hyps.length <= 6, `need 3-6 competing hypotheses (got ${hyps.length})`)
  const hypIds = new Set()
  let priorSum = 0
  let anySuccess = false
  for (const h of hyps) {
    need(typeof h.id === 'string' && !hypIds.has(h.id), `hypothesis id missing or duplicate: ${h.id}`)
    hypIds.add(h.id)
    need(typeof h.prior === 'number' && h.prior > 0 && h.prior < 1, `hypothesis ${h.id}: prior in (0,1) required`)
    priorSum += h.prior ?? 0
    if (h.success_consistent) anySuccess = true
  }
  if (hyps.length) {
    need(Math.abs(priorSum - 1) <= 0.01, `hypothesis priors must sum to 1 (got ${priorSum.toFixed(3)})`)
    need(anySuccess, 'at least one hypothesis must be success_consistent (else P(success) is undefined)')
  }

  // Initial claims: every one anchored to a reference class and staffed onto a branch.
  const claims = brief.claims ?? []
  need(claims.length >= 1, 'at least one initial claim required')
  for (const c of claims) {
    const cid = c.id ?? '?'
    need(typeof c.id === 'string' && c.id.startsWith('C-'), `claim ${cid}: id must start with C-`)
    need(CTYPES.includes(c.ctype), `claim ${cid}: ctype must be one of ${CTYPES.join('|')}`)
    need(typeof c.scope === 'string' && c.scope.length > 0, `claim ${cid}: scope required`)
    need(c.half_life_days > 0, `claim ${cid}: half_life_days > 0 required`)
    const rc = c.reference_class
    need(rc && typeof rc.base_rate === 'number' && rc.base_rate > 0 && rc.base_rate < 1,
      `claim ${cid}: reference_class.base_rate in (0,1) is MANDATORY (outside view first)`)
    need(typeof c.decision_weight === 'number' && c.decision_weight > 0 && c.decision_weight <= 1,
      `claim ${cid}: decision_weight in (0,1] required`)
    const branch = brief.claim_branch?.[c.id]
    need(branch && branchIds.has(branch), `claim ${cid}: must be staffed onto a real issue-tree branch (claim_branch)`)
  }

  // Budget governor inputs are mandatory, not a hope.
  const budget = brief.budget
  need(budget && budget.agent_calls > 0 && budget.usd > 0 && budget.wall_clock_s > 0,
    'budget {agent_calls, usd, wall_clock_s} all > 0 required')

  return { ok: errs.length === 0, errs, mode }
}

// Deterministic dry-run plan: the decision frame, the tree with crux markers,
// the hypotheses, and the tier-0-ranked frontier. Renders identically every time.
export function planFromBrief(brief) {
  const { ok, errs, mode } = validateBrief(brief)
  if (!ok) throw new Error('invalid brief:\n  ' + errs.join('\n  '))

  const frontier = rankFrontier(
    brief.claims.map((c) => ({
      id: c.id,
      kind: 'claim',
      claim: { belief: typeof c.belief === 'number' ? c.belief : null, status: c.status ?? 'open' },
      decisionWeight: c.decision_weight,
    }))
  )

  const L = []
  L.push(`RESEARCH PLAN (stage ${brief.stage}, dry run: zero network, zero spend beyond this framing)`)
  L.push(`Question: ${brief.question}`)
  L.push(`Preset: ${brief.preset}   Run: ${brief.run_id}`)
  L.push('')
  if (mode === 'DECISION') {
    const ratio = brief.decision.loss.false_GO / brief.decision.loss.false_NOGO
    L.push(`Decision frame: ${brief.decision.options.join(' / ')}   loss ratio wrong-commit:wrong-walk = ${ratio.toFixed(1)} (human-signed)`)
  } else {
    L.push('Decision frame: NOT SIGNED. Running in EVIDENCE-MAP mode: the engine will map the evidence and REFUSE a GO/NOGO conviction.')
  }
  L.push('')
  L.push('Issue tree (MECE):')
  for (const b of brief.issue_tree.branches) {
    L.push(`  ${b.crux ? '► CRUX ' : '       '}${b.id}: ${b.text}`)
    for (const s of b.sub ?? []) L.push(`             - ${s}`)
  }
  L.push('')
  L.push('Competing hypotheses (MECE, priors sum to 1):')
  for (const h of brief.hypotheses) {
    L.push(`  ${h.id} (${h.prior.toFixed(2)}${h.success_consistent ? ', success' : ''}): ${h.text}`)
  }
  L.push('')
  L.push('Frontier (tier-0 priority = decision_weight x uncertainty x unresolved-gap):')
  for (const f of frontier) {
    const c = brief.claims.find((x) => x.id === f.id)
    L.push(`  ${f.priority.toFixed(3)}  ${f.id} [${brief.claim_branch[f.id]}] ${c.text ?? ''}`)
  }
  L.push('')
  L.push(`Budget: ${brief.budget.agent_calls} agent calls / $${brief.budget.usd} / ${Math.round(brief.budget.wall_clock_s / 60)} min`)
  L.push(`Next: stage 2 researches ONE crux to full rigor (you pick which, or the top of the frontier). You pay only for the cruxes you choose.`)

  return { mode, frontier, text: L.join('\n') }
}

// CLI: node brief.mjs <brief.json> [--print]
// Exit 0 valid (prints the plan with --print), exit 1 invalid with reasons.
if (process.argv[1] && import.meta.url.endsWith(process.argv[1].split('/').pop())) {
  const path = process.argv[2]
  if (!path) {
    console.error('usage: node brief.mjs <brief.json> [--print]')
    process.exit(1)
  }
  const brief = JSON.parse(readFileSync(path, 'utf8'))
  const v = validateBrief(brief)
  if (!v.ok) {
    console.error('INVALID BRIEF:\n  ' + v.errs.join('\n  '))
    process.exit(1)
  }
  if (process.argv.includes('--print')) console.log(planFromBrief(brief).text)
  else console.log(`brief OK (mode: ${v.mode})`)
}
