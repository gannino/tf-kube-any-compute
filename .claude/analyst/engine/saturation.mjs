// Saturation estimation (RAS dimension D6): how much relevant evidence EXISTS
// that we never retrieved. Chapman-corrected capture-recapture over two
// INDEPENDENT retrieval passes: high overlap = probably found most of it; low
// overlap = a large unseen pool remains. Requires sources tagged with
// retrieval_pass; when absent, saturation is honestly NOT MEASURED (excluded
// from the roll-up, never defaulted to confident).

// captureRecapture(pass1Origins, pass2Origins) -> { nHat, recallHat, unseenMass }
export function captureRecapture(pass1Origins, pass2Origins) {
  const a = new Set(pass1Origins)
  const b = new Set(pass2Origins)
  if (!a.size || !b.size) return null
  let m = 0
  for (const x of a) if (b.has(x)) m++
  const nHat = ((a.size + 1) * (b.size + 1)) / (m + 1) - 1 // Chapman correction
  const seen = new Set([...a, ...b]).size
  const recallHat = Math.min(1, seen / Math.max(nHat, seen))
  return { nHat, seen, overlap: m, recallHat, unseenMass: 1 - recallHat }
}

// saturationForClaim: cluster the claim's origins by retrieval_pass and run
// capture-recapture across the two largest passes. null = not measured.
export function saturationForClaim(sources) {
  const byPass = new Map()
  for (const s of sources) {
    if (!s.retrieval_pass) continue
    if (!byPass.has(s.retrieval_pass)) byPass.set(s.retrieval_pass, new Set())
    byPass.get(s.retrieval_pass).add(s.origin_id)
  }
  if (byPass.size < 2) return null
  const passes = [...byPass.values()].sort((x, y) => y.size - x.size)
  return captureRecapture([...passes[0]], [...passes[1]])
}
