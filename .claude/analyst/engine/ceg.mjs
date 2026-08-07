// Claim-Evidence Graph (CEG) load/append/query helpers.
// Pure file + data helpers: no LLM, no network. Phase A step 1.
// Build spec: the analyst design notes
import { readFileSync, appendFileSync } from 'node:fs'

export const NODE_KINDS = ['source', 'origin', 'claim', 'assumption', 'hypothesis', 'conclusion', 'decision']
export const EDGE_RELS = ['cites', 'derives_from', 'supports', 'refutes', 'corroborates', 'contradicts', 'assumes', 'depends_on']

// Minimal structural validation (full JSON Schemas live in ../schema/).
// reference_class is deliberately NOT required here: a claim may exist un-scored;
// the propagator refuses to SCORE a claim without one (outside view first).
const REQUIRED = {
  source: ['id', 'url', 'tier', 'origin_id'],
  origin: ['id', 'label'],
  claim: ['id', 'text', 'ctype', 'scope', 'half_life_days'],
  assumption: ['id', 'text', 'rating'],
  hypothesis: ['id', 'text', 'prior'],
  conclusion: ['id', 'text', 'load_bearing_claims'],
  decision: ['id', 'options', 'loss'],
  edge: ['id', 'rel', 'from', 'to'],
}

export function validateRecord(rec) {
  if (!rec || typeof rec !== 'object' || !rec.kind) throw new Error('CEG record needs a "kind"')
  const req = REQUIRED[rec.kind]
  if (!req) throw new Error(`unknown CEG kind: ${rec.kind}`)
  for (const f of req) {
    if (rec[f] === undefined || rec[f] === null) {
      throw new Error(`${rec.kind} ${rec.id ?? '?'}: missing required field "${f}"`)
    }
  }
  if (rec.kind === 'edge' && !EDGE_RELS.includes(rec.rel)) {
    throw new Error(`edge ${rec.id}: unknown rel "${rec.rel}"`)
  }
  return rec
}

export function cegFromRecords(records) {
  const ceg = { nodes: new Map(), edges: [] }
  for (const rec of records) {
    validateRecord(rec)
    if (rec.kind === 'edge') {
      ceg.edges.push(rec)
    } else {
      if (ceg.nodes.has(rec.id)) throw new Error(`duplicate CEG node id: ${rec.id}`)
      ceg.nodes.set(rec.id, rec)
    }
  }
  return ceg
}

export function loadCEG(path) {
  const lines = readFileSync(path, 'utf8').split('\n').filter((l) => l.trim())
  return cegFromRecords(lines.map((l) => JSON.parse(l)))
}

export function appendRecord(path, rec) {
  validateRecord(rec)
  appendFileSync(path, JSON.stringify(rec) + '\n')
}

export const node = (ceg, id) => ceg.nodes.get(id)
export const citesEdges = (ceg, claimId) => ceg.edges.filter((e) => e.rel === 'cites' && e.to === claimId)
