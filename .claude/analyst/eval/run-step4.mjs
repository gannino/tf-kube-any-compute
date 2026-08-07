#!/usr/bin/env node
// Phase A step 4 acceptance test (the analyst acceptance suite).
// Acceptance: the /research --dry-run path (brief validation + plan rendering) works
// deterministically with ZERO network calls, and every malformed frame is refused.
// Run: node ".claude/analyst/eval/run-step4.mjs"
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, join } from 'node:path'
import { validateBrief, planFromBrief } from '../engine/brief.mjs'

const here = dirname(fileURLToPath(import.meta.url))
const FIXTURE = join(here, 'fixtures', 'brief-example.json')

let failures = 0
const check = (name, ok, detail = '') => {
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? `  [${detail}]` : ''}`)
  if (!ok) failures++
}
const load = () => JSON.parse(readFileSync(FIXTURE, 'utf8'))

// 1. the fixture brief validates in DECISION mode
const brief = load()
const v = validateBrief(brief)
check('fixture brief validates (DECISION mode)', v.ok && v.mode === 'DECISION', v.errs.join('; '))

// 2. the plan renders: decision frame, crux markers, ranked frontier
const plan = planFromBrief(brief)
check('plan shows the human-signed loss ratio', plan.text.includes('loss ratio wrong-commit:wrong-walk = 2.5 (human-signed)'))
check('plan marks the cruxes', (plan.text.match(/► CRUX/g) || []).length === 3)
check('frontier ranked by decision weight: attach > substitute > channel > tam',
  plan.frontier.map((f) => f.id).join(',') === 'C-attach,C-substitute,C-channel,C-tam',
  plan.frontier.map((f) => `${f.id}:${f.priority.toFixed(2)}`).join(' '))
check('plan states the staged next step (pay only for chosen cruxes)', plan.text.includes('You pay only for the cruxes you choose'))

// 3. unsigned loss -> EVIDENCE-MAP mode, stated in the plan
{
  const b = load()
  b.decision.loss_signed = false
  const p = planFromBrief(b)
  check('unsigned loss: plan declares EVIDENCE-MAP mode and the GO/NOGO refusal',
    p.mode === 'EVIDENCE_MAP' && p.text.includes('REFUSE a GO/NOGO'))
}

// 4. malformed frames are refused, each for the right reason
const refuse = (mutate, needle, name) => {
  const b = load()
  mutate(b)
  const r = validateBrief(b)
  check(name, !r.ok && r.errs.some((e) => e.includes(needle)), r.errs.join('; '))
}
refuse((b) => { b.hypotheses[0].prior = 0.42 }, 'sum to 1', 'refuses priors not summing to 1')
refuse((b) => { for (const br of b.issue_tree.branches) br.crux = false }, 'crux', 'refuses a tree with zero cruxes')
refuse((b) => { for (const br of b.issue_tree.branches) br.crux = true }, 'crux', 'refuses a tree where everything is a crux (4+)')
refuse((b) => { delete b.claims[0].reference_class }, 'reference_class', 'refuses a claim without a reference class')
refuse((b) => { b.decision.loss = { false_GO: 100, false_NOGO: 2 } }, 'clamp', 'refuses a loss ratio outside [1,20]')
refuse((b) => { b.claim_branch['C-attach'] = 'B-nonexistent' }, 'staffed', 'refuses a claim staffed onto a missing branch')
refuse((b) => { delete b.budget }, 'budget', 'refuses a brief without a budget governor')
refuse((b) => { b.hypotheses = b.hypotheses.slice(0, 2) }, '3-6', 'refuses fewer than 3 hypotheses')

// 5. determinism + zero network by construction
{
  const a = planFromBrief(load()).text
  const b = planFromBrief(load()).text
  check('plan renders byte-identically across runs', a === b)
  const src = readFileSync(join(here, '..', 'engine', 'brief.mjs'), 'utf8')
  check('brief.mjs contains no network primitives (zero-network dry run by construction)',
    !/fetch\(|WebSearch|https?:\/\//.test(src.replace(/\/\/.*$/gm, '')))
}

console.log(failures === 0 ? '\nALL CHECKS PASSED' : `\n${failures} CHECK(S) FAILED`)
process.exit(failures === 0 ? 0 : 1)
