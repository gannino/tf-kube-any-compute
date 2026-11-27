#!/bin/bash
# CEG provenance gate (PreToolUse Write|Edit) for the Claudify Analyst engine.
#
# STANDALONE AND UNWIRED BY DESIGN. Wiring requires a settings.json edit, and any
# deploy-adjacent change is gated on an explicit operator decision. Until wired, primary
# enforcement lives in-engine (ceg.mjs validateRecord + ingest.mjs provenanceComplete),
# which every engine write path goes through. This hook is the belt-and-braces layer,
# same pattern as completeness-gate.sh (which hard-blocks unsourced knowledge-base writes).
#
# To wire (later, on the operator decision): add to settings.json hooks.PreToolUse alongside
# completeness-gate.sh, matcher Write|Edit, command = this script.
#
# Contract: reads the hook JSON on stdin. If the write targets a ceg.jsonl or an
# analyst ledger .jsonl, every JSON line must carry its kind's required fields.
# Blocks with exit 2 and a reason on stderr; passes silently (exit 0) otherwise.
INPUT="$(cat 2>/dev/null || echo '{}')"

FILE=$(printf '%s' "$INPUT" | node -e '
let s = ""
process.stdin.on("data", (d) => (s += d)).on("end", () => {
  try { console.log(JSON.parse(s).tool_input?.file_path || "") } catch { console.log("") }
})' 2>/dev/null)

case "$FILE" in
  *"/analyst/"*"ceg.jsonl" | *"/analyst/ledger/"*.jsonl) ;;
  *) exit 0 ;;
esac

printf '%s' "$INPUT" | node -e '
let s = ""
process.stdin.on("data", (d) => (s += d)).on("end", () => {
  let input
  try { input = JSON.parse(s) } catch { process.exit(0) }
  const file = input.tool_input?.file_path || ""
  const content = input.tool_input?.content ?? input.tool_input?.new_string ?? ""
  const isLedger = /\/ledger\/.*\.jsonl$/.test(file)
  const REQUIRED = isLedger
    ? { prediction: ["id", "run_id", "claim_id", "statement", "type", "resolves_by", "resolution_source", "created_at"] }
    : {
        source: ["id", "url", "tier", "origin_id", "content_hash", "retrieved_at"],
        origin: ["id", "label"],
        claim: ["id", "text", "ctype", "scope", "half_life_days"],
        edge: ["id", "rel", "from", "to"],
      }
  const errs = []
  for (const line of String(content).split("\n")) {
    const t = line.trim()
    if (!t) continue
    let rec
    try { rec = JSON.parse(t) } catch { errs.push("invalid JSON line: " + t.slice(0, 60)); continue }
    const kind = isLedger ? "prediction" : rec.kind
    const req = REQUIRED[kind]
    if (!req) continue
    for (const f of req) {
      if (rec[f] === undefined || rec[f] === null) errs.push(`${kind} ${rec.id ?? "?"}: missing required field "${f}"`)
    }
    if (!isLedger && rec.kind === "source" && !rec.as_of_date && !rec.publish_date) {
      errs.push(`source ${rec.id}: missing as_of_date/publish_date (decay needs a date)`)
    }
  }
  if (errs.length) {
    console.error("CEG GATE BLOCK (no naked claims, no unsourced numbers):\n" + errs.join("\n"))
    process.exit(2)
  }
  process.exit(0)
})'
exit $?
