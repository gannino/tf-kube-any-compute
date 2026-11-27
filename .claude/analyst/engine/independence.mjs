// Origin clustering + the correlation haircut (build spec section 3.3).
// N sources tracing to ONE origin are approximately one independent vote:
// per origin, the strongest item (by |log-LR|) counts in full and each
// additional item contributes only ALPHA of its log-LR. N_eff counts
// distinct origins, never raw source count. This is the primary defense
// against N citations laundering one press release.
export const ALPHA = 0.1

// items: [{ edgeId, sourceId, originId, lnLR, lrEff }]
export function haircut(items) {
  const byOrigin = new Map()
  for (const it of items) {
    if (!it.originId) {
      throw new Error(`evidence ${it.edgeId ?? '?'}: missing originId (independence requires origin clustering)`)
    }
    if (!byOrigin.has(it.originId)) byOrigin.set(it.originId, [])
    byOrigin.get(it.originId).push(it)
  }
  const perOrigin = []
  let totalLnLR = 0
  for (const [originId, list] of byOrigin) {
    const sorted = [...list].sort((a, b) => Math.abs(b.lnLR) - Math.abs(a.lnLR))
    let lnLR = sorted[0].lnLR
    for (let i = 1; i < sorted.length; i++) lnLR += ALPHA * sorted[i].lnLR
    perOrigin.push({
      originId,
      lnLR,
      items: sorted.map((s) => ({ edgeId: s.edgeId, sourceId: s.sourceId, lnLR: s.lnLR, lrEff: s.lrEff })),
    })
    totalLnLR += lnLR
  }
  perOrigin.sort((a, b) => Math.abs(b.lnLR) - Math.abs(a.lnLR))
  return { totalLnLR, perOrigin, nEff: byOrigin.size }
}
