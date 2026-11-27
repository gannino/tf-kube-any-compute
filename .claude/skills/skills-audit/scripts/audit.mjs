#!/usr/bin/env node
// =============================================================================
// audit.mjs - deterministic skill-library scorer for /skills-audit
// =============================================================================
// Zero dependencies. Pure functions of file bytes: same input, same score,
// every run. No LLM call anywhere in scoring.
//
// Usage:
//   node audit.mjs [--root <dir>] [--scope <substring>] [--json] [--summary]
//                  [--evals static|live|off]
//
//   --root    project root (or skills dir parent) to audit. Default: walk up
//             from cwd to the nearest directory containing .claude/skills/.
//   --scope   only score skills whose relative path contains this substring.
//   --json    print the machine report to stdout as well.
//   --summary print a one-line tier summary and exit (no report files).
//   --evals   static (default) runs the free deterministic checks against the
//             skill's own worked example and output template. live is repo-CI
//             only: refused unless CLAUDIFY_LIVE_EVALS=1 is set, prints a cost
//             note first, and pipes each eval input to `claude -p`. Live mode
//             never runs on customer machines by default and never runs
//             unannounced.
//
// Rubric (100 points), tiers:
//   DEEP >= 85 with at least one eval; STANDARD 60-84; SHALLOW 40-59;
//   BROKEN < 40, or invalid YAML, or an unreachable description
//   (under 12 words with zero quoted trigger phrases).
// =============================================================================

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const FINGERPRINT_DESC = 'structured process, quality checks, and system integration';
const FINGERPRINT_BODY = 'delivers actionable, measurable results';
const KNOWN_KEYS = new Set([
  'name', 'description', 'version', 'user-invocable', 'disable-model-invocation',
  'paths', 'model', 'effort', 'context', 'agent', 'arguments', 'allowed-tools', 'hooks',
]);
// Category demand weights (sales-conversation signal; adjustable).
const DEMAND_WEIGHTS = {
  marketing: 3, development: 3, sales: 3, content: 3, finance: 3,
  product: 2, startup: 2, seo: 2, data: 2, operations: 2, email: 2,
  'social-media': 2, hr: 2, 'ai-automation': 2, 'customer-success': 2,
  ecommerce: 2, legal: 2, healthcare: 2,
};

// ---------- tiny YAML subset parser (frontmatter + eval files) ---------------

export function parseYaml(text) {
  // Supports: scalar keys, quoted scalars, folded (> / |) blocks, inline JSON
  // style arrays, block lists of scalars, and one level of nested maps and
  // list-of-map entries. Enough for the documented skill contract set.
  const lines = text.split('\n');
  let i = 0;
  const parseScalar = (raw) => {
    let v = raw.trim();
    if (v === '') return '';
    if ((v.startsWith('"') && v.endsWith('"') && v.length > 1) ||
        (v.startsWith("'") && v.endsWith("'") && v.length > 1)) return v.slice(1, -1);
    if (v === 'true') return true;
    if (v === 'false') return false;
    if (/^-?\d+(\.\d+)?$/.test(v)) return Number(v);
    if (v.startsWith('[')) {
      try { return JSON.parse(v.replace(/'/g, '"')); } catch { return v; }
    }
    return v;
  };
  const indentOf = (l) => l.length - l.trimStart().length;
  const parseBlock = (baseIndent) => {
    const obj = {};
    while (i < lines.length) {
      const line = lines[i];
      if (!line.trim() || line.trim().startsWith('#')) { i++; continue; }
      const ind = indentOf(line);
      if (ind < baseIndent) break;
      if (ind > baseIndent) { i++; continue; }
      const t = line.trim();
      if (t.startsWith('- ')) break;
      const m = t.match(/^([A-Za-z0-9_./-]+):\s*(.*)$/);
      if (!m) { i++; continue; }
      const key = m[1];
      const rest = m[2];
      i++;
      if (rest === '>' || rest === '|' || rest === '>-' || rest === '|-') {
        const parts = [];
        while (i < lines.length && (!lines[i].trim() || indentOf(lines[i]) > baseIndent)) {
          parts.push(lines[i].trim());
          i++;
        }
        obj[key] = parts.join(rest.startsWith('|') ? '\n' : ' ').trim();
      } else if (rest === '') {
        while (i < lines.length && !lines[i].trim()) i++;
        if (i < lines.length && indentOf(lines[i]) > baseIndent) {
          const childIndent = indentOf(lines[i]);
          if (lines[i].trim().startsWith('- ')) {
            const arr = [];
            while (i < lines.length) {
              const l = lines[i];
              if (!l.trim()) { i++; continue; }
              if (indentOf(l) < childIndent || !l.trim().startsWith('- ')) break;
              const itemText = l.trim().slice(2);
              i++;
              if (/^[A-Za-z0-9_-]+:\s*/.test(itemText)) {
                const item = {};
                const fm = itemText.match(/^([A-Za-z0-9_./-]+):\s*(.*)$/);
                item[fm[1]] = parseScalar(fm[2]);
                while (i < lines.length && lines[i].trim() &&
                       indentOf(lines[i]) > childIndent && !lines[i].trim().startsWith('- ')) {
                  const nm = lines[i].trim().match(/^([A-Za-z0-9_./-]+):\s*(.*)$/);
                  if (nm) item[nm[1]] = parseScalar(nm[2]);
                  i++;
                }
                arr.push(item);
              } else {
                arr.push(parseScalar(itemText));
              }
            }
            obj[key] = arr;
          } else {
            obj[key] = parseBlock(childIndent);
          }
        } else {
          obj[key] = '';
        }
      } else {
        obj[key] = parseScalar(rest);
      }
    }
    return obj;
  };
  return parseBlock(0);
}

// ---------- skill file model -------------------------------------------------

export function splitFrontmatter(raw) {
  if (!raw.startsWith('---')) return { fmText: null, fm: null, body: raw, fmValid: false };
  const end = raw.indexOf('\n---', 3);
  if (end === -1) return { fmText: null, fm: null, body: raw, fmValid: false };
  const fmText = raw.slice(raw.indexOf('\n') + 1, end);
  const body = raw.slice(raw.indexOf('\n', end + 1) + 1);
  let fm = null;
  let fmValid = true;
  try {
    fm = parseYaml(fmText);
    if (!fm || typeof fm !== 'object' || Object.keys(fm).length === 0) fmValid = false;
    for (const l of fmText.split('\n')) {
      if (!l.trim()) continue;
      if (/^\S/.test(l) && !/^[A-Za-z0-9_-]+:/.test(l) && !l.startsWith('- ') && !l.trim().startsWith('#')) {
        fmValid = false; break;
      }
    }
  } catch {
    fmValid = false;
  }
  return { fmText, fm, body, fmValid };
}

const words = (s) => (s.match(/\S+/g) || []);
const wordCount = (s) => words(s).length;

function quotedTriggerCount(desc) {
  const m = desc.match(/"([^"]+)"/g) || [];
  return m.filter((q) => wordCount(q.slice(1, -1)) >= 2).length;
}

export function shingles(text, n = 8) {
  const w = words(text.toLowerCase());
  const out = new Set();
  for (let k = 0; k + n <= w.length; k++) out.add(w.slice(k, k + n).join(' '));
  return out;
}

export function placeholderRatio(blockText) {
  const lines = blockText.split('\n').map((l) => l.trim()).filter(Boolean);
  if (lines.length === 0) return 1;
  let ph = 0;
  for (const l of lines) {
    const stripped = l.replace(/^[-*|#>\s\d.]+/, '').replace(/\|/g, ' ').trim();
    if (!stripped) continue;
    // a line is a placeholder line when, after stripping list/table syntax,
    // it consists only of [bracketed] tokens (optionally labeled)
    const noBrackets = stripped.replace(/\[[^\]]*\]/g, '').replace(/[*_:.,\s]/g, '');
    const hadBracket = /\[[^\]]*\]/.test(stripped);
    if (hadBracket && noBrackets.length <= 20 && !/\]\(/.test(stripped)) ph++;
  }
  return ph / lines.length;
}

function fencedBlocks(body) {
  const blocks = [];
  const re = /```[^\n]*\n([\s\S]*?)```/g;
  let m;
  while ((m = re.exec(body)) !== null) blocks.push(m[1]);
  return blocks;
}

function outputSection(body) {
  const m = body.match(/^#{1,4}\s*(Output|Output Format|Deliverable|Artifact)[^\n]*\n([\s\S]*?)(?=^#{1,4}\s|$(?![\s\S]))/im);
  return m ? m[2] : null;
}

// ---------- scaffold corpus (self-calibrating) -------------------------------

export function buildScaffoldCorpus(skills) {
  // The corpus is the two known generator fingerprints plus the 40 highest
  // document-frequency lines: any line in > 25% of skills is boilerplate by
  // definition. Self-calibrating: no hardcoded generator copy, catches future
  // generators too.
  const df = new Map();
  const threshold = Math.max(2, Math.floor(skills.length * 0.25));
  for (const s of skills) {
    const seen = new Set();
    for (const raw of s.body.split('\n')) {
      const l = raw.trim();
      if (l.length < 12 || seen.has(l)) continue;
      seen.add(l);
      df.set(l, (df.get(l) || 0) + 1);
    }
  }
  const frequent = [...df.entries()]
    .filter(([, c]) => c > threshold)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 40)
    .map(([l]) => l);
  const corpusLines = new Set([FINGERPRINT_DESC, FINGERPRINT_BODY, ...frequent]);
  const corpusShingles = shingles([...corpusLines].join('\n'));
  return { corpusLines, corpusShingles };
}

// ---------- eval static checks ----------------------------------------------

export function loadEvals(skillDir) {
  const evalDir = path.join(skillDir, 'evals');
  if (!fs.existsSync(evalDir)) return [];
  return fs.readdirSync(evalDir)
    .filter((f) => /^eval-.*\.ya?ml$/.test(f))
    .sort()
    .map((f) => {
      try { return { file: f, spec: parseYaml(fs.readFileSync(path.join(evalDir, f), 'utf8')) }; }
      catch { return { file: f, spec: null }; }
    });
}

export function runStaticEval(spec, body, mode = 'static') {
  // Static mode proves the skill CONTAINS a passing artifact shape: the
  // STRUCTURAL checks (required_sections, banned_patterns, placeholder ratio,
  // format parse gate) run against the skill's own worked example and output
  // template, free and deterministic. The input-bound checks
  // (required_patterns, min_words) describe the artifact PRODUCED from the
  // eval's input, so they apply only in live mode.
  const failures = [];
  const checks = (spec && spec.checks) || {};
  const live = mode === 'live';
  const blocks = fencedBlocks(body).filter((b) => placeholderRatio(b) < 0.5);
  let artifact = live ? body : blocks.join('\n\n');
  if (!artifact.trim()) artifact = outputSection(body) || '';
  if (!artifact.trim()) failures.push('no worked example or output artifact found in skill body');
  for (const sec of checks.required_sections || []) {
    if (!body.toLowerCase().includes(String(sec).toLowerCase())) failures.push(`missing required section: ${sec}`);
  }
  if (live) {
    for (const pat of checks.required_patterns || []) {
      try { if (!new RegExp(pat, 'im').test(body)) failures.push(`required pattern not found: ${pat}`); }
      catch { failures.push(`invalid required pattern: ${pat}`); }
    }
    if (checks.min_words && wordCount(body) < checks.min_words) {
      failures.push(`body under min_words ${checks.min_words}`);
    }
  }
  for (const pat of checks.banned_patterns || []) {
    try { if (artifact && new RegExp(pat, 'im').test(artifact)) failures.push(`banned pattern present in artifact: ${pat}`); }
    catch { failures.push(`invalid banned pattern: ${pat}`); }
  }
  if (checks.max_placeholder_ratio != null && artifact.trim()) {
    const r = placeholderRatio(artifact);
    if (r > checks.max_placeholder_ratio) failures.push(`artifact placeholder ratio ${r.toFixed(2)} over ${checks.max_placeholder_ratio}`);
  }
  const fmt = checks.format;
  if (fmt === 'json' || fmt === 'json-ld') {
    const jsonBlock = fencedBlocks(body).find((b) => { try { JSON.parse(b); return true; } catch { return false; } });
    if (!jsonBlock) failures.push('no parseable JSON block found');
    else if (fmt === 'json-ld') {
      const flat = JSON.stringify(JSON.parse(jsonBlock));
      if (!flat.includes('@context') || !flat.includes('@type')) failures.push('JSON-LD block missing @context or @type');
    }
  }
  return { pass: failures.length === 0, failures };
}

// ---------- scoring ----------------------------------------------------------

export function scoreSkill(skill, corpus, evalMode = 'static') {
  const d = { d1: 0, d2: 0, d3: 0, d4: 0, d5: 0 };
  const notes = [];
  const { fm, fmValid, body } = skill;

  // D1 frontmatter validity (15)
  if (fmValid) {
    d.d1 += 8;
    const descV = fm && typeof fm.description === 'string' ? fm.description : '';
    if (descV.trim()) d.d1 += 3;
    if (fm && typeof fm.version === 'string' && /^\d+\.\d+\.\d+$/.test(String(fm.version).trim())) d.d1 += 2;
    const unknown = fm ? Object.keys(fm).filter((k) => !KNOWN_KEYS.has(k)) : [];
    if (fm && unknown.length === 0) d.d1 += 2;
    else if (unknown.length) notes.push(`unknown frontmatter keys: ${unknown.join(', ')}`);
  } else {
    notes.push('invalid or missing YAML frontmatter');
  }

  const desc = (fm && typeof fm.description === 'string') ? fm.description : '';
  const dw = wordCount(desc);
  const triggers = quotedTriggerCount(desc);

  // D2 description quality (25)
  if (dw >= 20) d.d2 += 8; else if (dw >= 12) d.d2 += 4;
  d.d2 += Math.min(10, triggers * 2.5);
  if (/not for|do not use/i.test(desc)) d.d2 += 4;
  if (!desc.includes(FINGERPRINT_DESC)) d.d2 += 3;

  // D3 body substance (35)
  const nonBoiler = body.split('\n').filter((l) => !corpus.corpusLines.has(l.trim())).join('\n');
  const nbWords = wordCount(nonBoiler);
  if (nbWords >= 200) d.d3 += 12; else if (nbWords >= 100) d.d3 += 6;
  const bodyShingles = shingles(body);
  let hit = 0;
  for (const sh of bodyShingles) if (corpus.corpusShingles.has(sh)) hit++;
  const shingleScore = bodyShingles.size ? hit / bodyShingles.size : 1;
  if (shingleScore <= 0.30) d.d3 += 13;
  else if (shingleScore < 0.80) d.d3 += (13 * (0.80 - shingleScore)) / 0.50;
  const blocks = fencedBlocks(body);
  if (blocks.some((b) => placeholderRatio(b) < 0.20 && wordCount(b) >= 10)) d.d3 += 10;
  d.d3 = Math.round(d.d3 * 100) / 100;

  // D4 artifact shape (15)
  const out = outputSection(body);
  const artifactBlock = out || (blocks.length ? blocks.join('\n') : null);
  if (artifactBlock) {
    d.d4 += 5;
    const pr = placeholderRatio(artifactBlock);
    if (pr <= 0.40) d.d4 += 10; else if (pr <= 0.70) d.d4 += 5;
  }

  // D5 evals (10)
  const evals = loadEvals(skill.dir);
  let evalResults = [];
  if (evals.length > 0) {
    d.d5 += 4;
    if (evalMode !== 'off') {
      evalResults = evals.map((e) => ({
        file: e.file,
        ...(e.spec ? runStaticEval(e.spec, body) : { pass: false, failures: ['unparseable eval file'] }),
      }));
      if (evalResults.every((r) => r.pass)) d.d5 += 6;
    }
  }

  const score = Math.round((d.d1 + d.d2 + d.d3 + d.d4 + d.d5) * 100) / 100;
  let tier;
  if (!fmValid || (dw < 12 && triggers === 0)) tier = 'BROKEN';
  else if (score >= 85 && d.d5 > 0) tier = 'DEEP';
  else if (score >= 60) tier = 'STANDARD';
  else if (score >= 40) tier = 'SHALLOW';
  else tier = 'BROKEN';

  return {
    score, tier, dims: d, notes, evalResults,
    shingleScore: Math.round(shingleScore * 1000) / 1000,
    nonBoilerWords: nbWords,
  };
}

// ---------- discovery + report ----------------------------------------------

function findSkillsRoot(start) {
  let dir = path.resolve(start);
  for (;;) {
    if (fs.existsSync(path.join(dir, '.claude', 'skills'))) return dir;
    const parent = path.dirname(dir);
    if (parent === dir) return null;
    dir = parent;
  }
}

export function discoverSkills(skillsDir) {
  const out = [];
  const walk = (d) => {
    for (const ent of fs.readdirSync(d, { withFileTypes: true })) {
      if (ent.isDirectory()) walk(path.join(d, ent.name));
      else if (ent.name === 'SKILL.md') out.push(path.join(d, ent.name));
    }
  };
  walk(skillsDir);
  return out.sort();
}

export function loadSkill(file, skillsDir) {
  const raw = fs.readFileSync(file, 'utf8');
  const rel = path.relative(skillsDir, path.dirname(file));
  const parsed = splitFrontmatter(raw);
  return { file, dir: path.dirname(file), rel, category: rel.split(path.sep)[0], raw, ...parsed };
}

function mergeCandidates(skills, corpus) {
  // Cross-skill overlap of NON-boilerplate shingles >= 0.70 = merge candidates.
  // Bucketed by shared shingle so this never does a full pairwise pass.
  const pairs = [];
  const bySkill = skills.map((s) => new Set([...shingles(s.body)].filter((x) => !corpus.corpusShingles.has(x))));
  const index = new Map();
  bySkill.forEach((sh, i) => {
    for (const x of sh) {
      let arr = index.get(x);
      if (!arr) { arr = []; index.set(x, arr); }
      arr.push(i);
    }
  });
  const counted = new Map();
  for (const arr of index.values()) {
    if (arr.length < 2 || arr.length > 20) continue;
    for (let a = 0; a < arr.length; a++) {
      for (let b = a + 1; b < arr.length; b++) {
        const key = arr[a] * 100000 + arr[b];
        counted.set(key, (counted.get(key) || 0) + 1);
      }
    }
  }
  for (const [key, shared] of counted) {
    const a = Math.floor(key / 100000);
    const b = key % 100000;
    const denom = Math.min(bySkill[a].size, bySkill[b].size);
    if (denom >= 10 && shared / denom >= 0.70) {
      pairs.push([skills[a].rel, skills[b].rel, Math.round((shared / denom) * 100) / 100]);
    }
  }
  return pairs.sort((x, y) => y[2] - x[2]).slice(0, 50);
}

export function auditLibrary(skillsDir, { scope = null, evalMode = 'static' } = {}) {
  const files = discoverSkills(skillsDir).filter((f) => !scope || path.relative(skillsDir, f).includes(scope));
  const skills = files.map((f) => loadSkill(f, skillsDir));
  const corpus = buildScaffoldCorpus(skills);
  const results = skills.map((s) => ({ skill: s.rel, category: s.category, ...scoreSkill(s, corpus, evalMode) }));
  const tiers = { DEEP: 0, STANDARD: 0, SHALLOW: 0, BROKEN: 0 };
  for (const r of results) tiers[r.tier]++;
  const prune = results.filter((r) => r.tier === 'BROKEN').map((r) => r.skill);
  const merges = mergeCandidates(skills, corpus);
  const deepen = results
    .filter((r) => r.tier === 'SHALLOW')
    .map((r) => ({ skill: r.skill, priority: Math.round((DEMAND_WEIGHTS[r.category] || 1) * (85 - r.score) * 100) / 100 }))
    .sort((a, b) => b.priority - a.priority);
  const fixFrontmatter = results
    .filter((r) => r.tier !== 'BROKEN' && (r.dims.d1 < 15 || r.dims.d2 < 15) && r.dims.d3 >= 20)
    .map((r) => r.skill);
  return {
    skillsDir, count: results.length, tiers, results,
    recommendations: { prune, mergeCandidates: merges, deepen, fixFrontmatter },
  };
}

function writeReports(report, projectRoot) {
  const logsDir = path.join(projectRoot, '.claude', 'logs');
  fs.mkdirSync(logsDir, { recursive: true });
  const date = new Date().toISOString().slice(0, 10);
  const jsonPath = path.join(logsDir, `skills-audit-${date}.json`);

  let prev = null;
  const prevFiles = fs.readdirSync(logsDir)
    .filter((f) => /^skills-audit-\d{4}-\d{2}-\d{2}\.json$/.test(f) && f !== path.basename(jsonPath))
    .sort();
  if (prevFiles.length) {
    try { prev = JSON.parse(fs.readFileSync(path.join(logsDir, prevFiles[prevFiles.length - 1]), 'utf8')); } catch { /* ignore */ }
  }
  fs.writeFileSync(jsonPath, JSON.stringify(report, null, 2));

  const byCat = new Map();
  for (const r of report.results) {
    if (!byCat.has(r.category)) byCat.set(r.category, { DEEP: 0, STANDARD: 0, SHALLOW: 0, BROKEN: 0, n: 0 });
    const c = byCat.get(r.category); c[r.tier]++; c.n++;
  }
  const lines = [];
  lines.push(`# Skills Audit, ${date}`, '');
  lines.push(`Skills scored: ${report.count}`, '');
  lines.push('| Tier | Count |', '|---|---|');
  for (const t of ['DEEP', 'STANDARD', 'SHALLOW', 'BROKEN']) lines.push(`| ${t} | ${report.tiers[t]} |`);
  lines.push('', '## Per category', '', '| Category | Skills | DEEP | STANDARD | SHALLOW | BROKEN |', '|---|---|---|---|---|---|');
  for (const [cat, c] of [...byCat.entries()].sort()) lines.push(`| ${cat} | ${c.n} | ${c.DEEP} | ${c.STANDARD} | ${c.SHALLOW} | ${c.BROKEN} |`);
  if (prev && prev.results) {
    const prevScores = new Map(prev.results.map((r) => [r.skill, r.score]));
    const movers = report.results
      .map((r) => ({ skill: r.skill, delta: prevScores.has(r.skill) ? Math.round((r.score - prevScores.get(r.skill)) * 100) / 100 : null }))
      .filter((m) => m.delta !== null && m.delta !== 0)
      .sort((a, b) => Math.abs(b.delta) - Math.abs(a.delta))
      .slice(0, 15);
    if (movers.length) {
      lines.push('', '## Top movers vs last run', '');
      for (const m of movers) lines.push(`- ${m.skill}: ${m.delta > 0 ? '+' : ''}${m.delta}`);
    }
  }
  const rec = report.recommendations;
  lines.push('', '## Recommendations', '');
  lines.push(`- PRUNE (${rec.prune.length}): ${rec.prune.slice(0, 20).join(', ') || 'none'}${rec.prune.length > 20 ? ', ...' : ''}`);
  lines.push(`- MERGE candidates (${rec.mergeCandidates.length}): ${rec.mergeCandidates.slice(0, 10).map((p) => `${p[0]} + ${p[1]} (${p[2]})`).join('; ') || 'none'}`);
  lines.push(`- DEEPEN queue top 20: ${rec.deepen.slice(0, 20).map((x) => x.skill).join(', ') || 'none'}`);
  lines.push(`- FIX-FRONTMATTER (${rec.fixFrontmatter.length}): ${rec.fixFrontmatter.slice(0, 20).join(', ') || 'none'}${rec.fixFrontmatter.length > 20 ? ', ...' : ''}`);
  const mdPath = path.join(logsDir, `skills-audit-${date}.md`);
  fs.writeFileSync(mdPath, lines.join('\n') + '\n');
  return { jsonPath, mdPath };
}

// ---------- live evals (repo CI only, consent-gated) -------------------------

async function runLiveEvals(report, skillsDir) {
  if (process.env.CLAUDIFY_LIVE_EVALS !== '1') {
    console.error('Live evals are repo-CI only and consent-gated. Set CLAUDIFY_LIVE_EVALS=1 to enable.');
    console.error('They pipe each eval input to `claude -p` and cost tokens. Not run.');
    process.exit(2);
  }
  const { execFileSync } = await import('node:child_process');
  const evalSkills = report.results.filter((r) => r.evalResults && r.evalResults.length > 0);
  console.error(`Live evals: ${evalSkills.length} skills with evals, ~${evalSkills.length} claude -p calls (tokens billed). Proceeding because CLAUDIFY_LIVE_EVALS=1.`);
  for (const r of evalSkills) {
    const dir = path.join(skillsDir, r.skill);
    for (const e of loadEvals(dir)) {
      if (!e.spec || !e.spec.input) continue;
      try {
        const outText = execFileSync('claude', ['-p', String(e.spec.input)], { encoding: 'utf8', timeout: 300000 });
        const res = runStaticEval(e.spec, outText, 'live');
        const goldenPath = path.join(dir, 'evals', `golden-${e.spec.id || e.file.replace(/\.ya?ml$/, '')}.md`);
        fs.writeFileSync(goldenPath, outText);
        console.log(`${r.skill} ${e.file}: ${res.pass ? 'PASS' : 'FAIL ' + res.failures.join('; ')}`);
      } catch (err) {
        console.log(`${r.skill} ${e.file}: ERROR ${err.message}`);
      }
    }
  }
}

// ---------- CLI --------------------------------------------------------------

const isMain = process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (isMain) {
  const args = process.argv.slice(2);
  const get = (flag) => { const i = args.indexOf(flag); return i >= 0 ? args[i + 1] : null; };
  const rootArg = get('--root');
  const scope = get('--scope');
  const evalMode = get('--evals') || 'static';
  const projectRoot = rootArg
    ? (fs.existsSync(path.join(rootArg, '.claude', 'skills')) ? path.resolve(rootArg) : findSkillsRoot(rootArg))
    : findSkillsRoot(process.cwd());
  if (!projectRoot) {
    console.error('No .claude/skills directory found from here. Pass --root <project>.');
    process.exit(1);
  }
  const skillsDir = path.join(projectRoot, '.claude', 'skills');
  const report = auditLibrary(skillsDir, { scope, evalMode: evalMode === 'live' ? 'static' : evalMode });

  if (args.includes('--summary')) {
    const t = report.tiers;
    console.log(`skills-audit: ${report.count} skills | DEEP ${t.DEEP} | STANDARD ${t.STANDARD} | SHALLOW ${t.SHALLOW} | BROKEN ${t.BROKEN}`);
    process.exit(0);
  }
  const { jsonPath, mdPath } = writeReports(report, projectRoot);
  if (args.includes('--json')) console.log(JSON.stringify(report, null, 2));
  const t = report.tiers;
  console.log(`Scored ${report.count} skills under ${skillsDir}`);
  console.log(`DEEP ${t.DEEP} | STANDARD ${t.STANDARD} | SHALLOW ${t.SHALLOW} | BROKEN ${t.BROKEN}`);
  console.log(`Reports: ${mdPath} , ${jsonPath}`);
  if (evalMode === 'live') await runLiveEvals(report, skillsDir);
}
