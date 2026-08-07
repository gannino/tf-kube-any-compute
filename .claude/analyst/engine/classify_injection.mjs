// Local injection heuristic (Gate 0a): a deterministic, weighted pattern rubric
// scoring how hard a passage is trying to steer the reasoner. Deliberately a
// heuristic, not a promise: the Gate-5 design is defense in depth, and the honest
// residual is stated in the analyst design notes (injection is unsolvable at the model layer;
// detection here is graded, and containment (quarantine + the cannot-raise-belief
// rule in the propagator) is what actually bounds the damage.
//
// Graded action thresholds (the design's table):
//   < 0.40         accept normally
//   0.40 - 0.75    accept but cap tier at 6 and fidelity at 0.5, flag suspected
//   > 0.75         quarantine: weight 0, excluded from N_eff
export const INJECTION_ACCEPT = 0.4
export const INJECTION_QUARANTINE = 0.75

const PATTERNS = [
  { w: 0.6, re: /ignore\s+(all\s+|any\s+)?(previous|prior|above|earlier)\s+(instructions|rules|prompts?)/i, cls: 'override_instruction' },
  { w: 0.5, re: /disregard\s+(your|the|all|any)\s+(instructions|rules|guidelines|task)/i, cls: 'override_instruction' },
  { w: 0.45, re: /\byou\s+are\s+now\b|\bnew\s+instructions?\s*:/i, cls: 'role_hijack' },
  { w: 0.35, re: /\bact\s+as\s+if\b|\bact\s+as\s+(a|an)\s+/i, cls: 'role_hijack' },
  { w: 0.35, re: /\bsystem\s+prompt\b|\bdeveloper\s+message\b/i, cls: 'system_probe' },
  { w: 0.4, re: /\b(assistant|claude|model|the\s+ai)\b[^.]{0,40}\b(must|should|shall|you\s+will)\b/i, cls: 'directed_at_model' },
  { w: 0.35, re: /(respond|reply|output|answer)\s+(with\s+)?(exactly|only|verbatim)/i, cls: 'output_steering' },
  { w: 0.5, re: /mark\s+(this|it)\s+as\s+(verified|entailed|confirmed|true)/i, cls: 'gate_steering' },
  { w: 0.45, re: /(assign|give|rate)\s+(this|it)\s+(a\s+)?(high|maximum|top)\s+(score|rating|likelihood|lr)/i, cls: 'score_steering' },
  { w: 0.6, re: /UNTRUSTED_EVIDENCE/i, cls: 'delimiter_forgery' },
  { w: 0.3, re: /fetch|navigate\s+to|visit\s+https?:\/\//i, cls: 'egress_lure' },
]

// classifyInjection(passage) -> { score 0..1, classes: [...], action }
export function classifyInjection(passage) {
  const text = String(passage ?? '')
  let score = 0
  const classes = []
  for (const p of PATTERNS) {
    if (p.re.test(text)) {
      score += p.w
      if (!classes.includes(p.cls)) classes.push(p.cls)
    }
  }
  score = Math.min(1, score)
  const action = score > INJECTION_QUARANTINE ? 'quarantine' : score >= INJECTION_ACCEPT ? 'cap' : 'accept'
  return { score, classes, action }
}
