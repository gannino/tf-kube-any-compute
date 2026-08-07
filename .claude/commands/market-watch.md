# /market-watch

Continuous monitoring for a completed Claudify Analyst run: watches the run's own
INDICATORS AND SIGNPOSTS (the dossier's forward-looking monitorables) and the
kill-lines, and alerts when one fires. This is what turns a dossier from a
snapshot into a living instrument. It ARMS and ALERTS; it never re-runs research
or changes a verdict on its own.

```
/market-watch <run_id> [--check]
```

## Procedure

1. Read the run's dossier data: the indicators table (claim id + watch-for) and
   the kill-line. Each indicator is a checkable condition with a source.
2. For each indicator: check the current state via the named source (WebSearch or
   the internal source; the egress guard applies). Three outcomes per indicator:
   QUIET (no movement), FIRED (the condition is met, with the evidence quoted
   verbatim + URL + date), or UNCHECKABLE (the source cannot answer it today,
   said plainly).
3. On any FIRED indicator: write a dated alert into the run directory
   (`watch-YYYY-MM-DD.md`) with the evidence, and surface it to the operator with the
   recommendation as a RECOMMEND line (`RECOMMEND: /research --run=<id>
   --crux=<claim>` to re-research the touched crux, or `/research-learn` if a
   prediction is now resolvable early). The watch never executes the re-run
   itself.
4. A kill-line firing is a headline alert, not a footnote: it names the verdict
   it undermines.

## Cadence

On demand, or after any notable ecosystem event in the run domain. Every run
with a rendered dossier has a watchlist: its indicators table plus its kill-line.

## Registration note

Not yet in command-index.md (deploy-gated). No em dashes in any output.
