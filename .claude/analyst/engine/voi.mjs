// The decision model + Value-of-Information frontier, TIER-0 ONLY.
// Build spec section 5, cut down per the analyst design notes via-negativa: EVSI,
// Knowledge Gradient, and submodular batch selection are DELETED, not merely
// off by default. What remains is what a run actually uses:
//   - the asymmetric-loss decision model (human-signed, engine may never edit it)
//   - exact EVPI on a pinned-outcome basis (the crux finder + the stopping rule)
//   - the tier-0 frontier proxy: decision_weight x uncertainty x unresolved-gap
//
// v3 fix 5: the loss must be HUMAN-SIGNED. If decision.loss_signed !== true the
// engine runs in EVIDENCE-MAP mode: bestAction() refuses to emit a GO/NOGO.

export function expectedLosses(pSuccess, loss) {
  return { GO: (1 - pSuccess) * loss.false_GO, NOGO: pSuccess * loss.false_NOGO }
}

export function bestAction(pSuccess, decision) {
  if (!decision?.loss) throw new Error('decision.loss required')
  if (decision.loss_signed !== true) {
    return { action: 'EVIDENCE_MAP', loss: null, reason: 'loss not human-signed: the engine refuses a GO/NOGO conviction (v3 fix 5)' }
  }
  const ratio = decision.loss.false_GO / decision.loss.false_NOGO
  if (ratio < 1 || ratio > 20) throw new Error(`loss ratio ${ratio.toFixed(2)} outside the [1, 20] clamp`)
  const el = expectedLosses(pSuccess, decision.loss)
  return el.GO <= el.NOGO ? { action: 'GO', loss: el.GO } : { action: 'NOGO', loss: el.NOGO }
}

// Exact EVPI on one claim: expected reduction in decision loss if the claim were
// resolved to certainty. Needs the pinned P(success) both ways, which the caller
// derives by re-running ACH with the claim pinned (deterministic, no LLM).
// evpi({ basePS, p, psIfTrue, psIfFalse }, decision) -> number >= 0
export function evpi({ basePS, p, psIfTrue, psIfFalse }, decision) {
  const base = bestAction(basePS, decision)
  if (base.action === 'EVIDENCE_MAP') return 0 // no decision, no decision-relevant information value
  const ifTrue = bestAction(psIfTrue, decision).loss
  const ifFalse = bestAction(psIfFalse, decision).loss
  return Math.max(0, base.loss - (p * ifTrue + (1 - p) * ifFalse))
}

// The flip-point sensitivity sweep (v3 fix 5): for which wrong-commit:wrong-walk
// ratios does the best action change? Reported in the dossier so the elicited
// loss is audited, not laundered.
export function flipPointSweep(pSuccess, { lo = 1, hi = 20, steps = 191 } = {}) {
  const out = []
  let prev = null
  for (let i = 0; i < steps; i++) {
    const ratio = lo + ((hi - lo) * i) / (steps - 1)
    const el = expectedLosses(pSuccess, { false_GO: ratio, false_NOGO: 1 })
    const action = el.GO <= el.NOGO ? 'GO' : 'NOGO'
    if (action !== prev) {
      out.push({ ratio: Number(ratio.toFixed(2)), action })
      prev = action
    }
  }
  return out
}

// ---------- the tier-0 frontier ----------
const GAP = { open: 1, contested: 0.7, supported: 0.05, refuted: 0.05, unresolvable: 0.02 }

// tier0Priority: cheap, deterministic, and the ONLY frontier tier that ships.
export function tier0Priority(claim, decisionWeight = 0.5) {
  const b = typeof claim.belief === 'number' ? claim.belief : 0.5
  const uncertainty = 4 * b * (1 - b) // max 1 at b = 0.5, ~0 at the extremes
  const gap = GAP[claim.status ?? 'open'] ?? 1
  return decisionWeight * uncertainty * gap
}

// rankFrontier: claims + retrieval-gap tasks share one queue (RAS lands later;
// the interface is ready). items: [{id, kind:'claim'|'retrieval_gap', claim, decisionWeight, priorityOverride}]
export function rankFrontier(items) {
  return items
    .map((it) => ({ ...it, priority: it.priorityOverride ?? tier0Priority(it.claim, it.decisionWeight) }))
    .sort((a, b) => b.priority - a.priority)
}

// The stopping rule: research is DONE when the most valuable open question is
// worth less than the next action costs, or the budget governor says stop.
export function shouldStop({ maxEVPI, costOfNextAction, budget }) {
  if (budget && (budget.agent_calls <= 0 || budget.usd <= 0 || budget.wall_clock_s <= 0)) {
    return { stop: true, reason: 'budget exhausted (graceful degradation: return the best-effort CEG + open questions)' }
  }
  if (typeof maxEVPI === 'number' && typeof costOfNextAction === 'number' && maxEVPI < costOfNextAction) {
    return { stop: true, reason: `max EVPI ${maxEVPI.toFixed(3)} below the cost of the next action ${costOfNextAction.toFixed(3)}` }
  }
  return { stop: false }
}
