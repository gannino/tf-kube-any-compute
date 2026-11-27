// Seeded Monte-Carlo fractile propagation (build spec section 3.5).
// Deterministic by construction: the seed derives from a caller-supplied key,
// never from the clock. Same inputs + same key = identical fractiles, always.
const Z90 = 1.2815515655446004 // Phi^-1(0.90)

export function seedFromString(s) {
  // FNV-1a 32-bit
  let h = 2166136261 >>> 0
  for (let i = 0; i < s.length; i++) {
    h ^= s.charCodeAt(i)
    h = Math.imul(h, 16777619)
  }
  return h >>> 0
}

export function mulberry32(seed) {
  let a = seed >>> 0
  return function () {
    a |= 0
    a = (a + 0x6d2b79f5) | 0
    let t = Math.imul(a ^ (a >>> 15), 1 | a)
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

// Fit a lognormal to elicited fractiles: mu from the median, sigma from the 80% band.
export function lognormalFromFractiles({ p10, p50, p90 }) {
  if (!(p10 > 0 && p50 > p10 && p90 > p50)) throw new Error('fractiles must satisfy 0 < p10 < p50 < p90')
  return { mu: Math.log(p50), sigma: (Math.log(p90) - Math.log(p10)) / (2 * Z90) }
}

function normal(rng) {
  // Box-Muller (two uniforms per draw)
  const u1 = Math.max(rng(), 1e-12)
  const u2 = rng()
  return Math.sqrt(-2 * Math.log(u1)) * Math.cos(2 * Math.PI * u2)
}

export const sampleLognormal = (params, rng) => Math.exp(params.mu + params.sigma * normal(rng))

// deriveInterval: joint samples of the input intervals through fn, reported as fractiles.
// inputs: [{p10,p50,p90}, ...]; fn(...sampledValues) -> derived value; seedKey REQUIRED.
export function deriveInterval(inputs, fn, { n = 10000, seedKey } = {}) {
  if (!seedKey) throw new Error('seedKey is required (determinism forbids unseeded sampling)')
  const rng = mulberry32(seedFromString(seedKey))
  const params = inputs.map(lognormalFromFractiles)
  const out = new Array(n)
  for (let k = 0; k < n; k++) out[k] = fn(...params.map((p) => sampleLognormal(p, rng)))
  out.sort((a, b) => a - b)
  const q = (p) => out[Math.min(n - 1, Math.floor(p * n))]
  return { p10: q(0.1), p50: q(0.5), p90: q(0.9) }
}
