#!/usr/bin/env node
/**
 * send.js — Claude Code Weekly broadcast creator / preview sender.
 *
 * Usage:
 *   node send.js 001           — create Beehiiv broadcast draft
 *   node send.js 001 --preview — send test email to you@example.com via Resend
 *
 * Required env vars (set in .env or export before running):
 *   RESEND_API_KEY      — Resend secret key
 *   BEEHIIV_API_KEY     — Beehiiv API key
 *
 * Optional env vars (have defaults):
 *   BEEHIIV_PUB_ID      — Beehiiv publication ID
 *   RESEND_FROM         — Sender address shown to recipients
 *   PREVIEW_TO          — Preview recipient email
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// ── Load .env if present ─────────────────────────────────────────────────────

const envPath = path.join(__dirname, ".env");
if (fs.existsSync(envPath)) {
  for (const line of fs.readFileSync(envPath, "utf8").split("\n")) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const eqIdx = trimmed.indexOf("=");
    if (eqIdx === -1) continue;
    const key = trimmed.slice(0, eqIdx).trim();
    const val = trimmed.slice(eqIdx + 1).trim().replace(/^["']|["']$/g, "");
    if (!process.env[key]) process.env[key] = val;
  }
}

// ── Config ───────────────────────────────────────────────────────────────────

const RESEND_API_KEY   = process.env.RESEND_API_KEY;
const RESEND_FROM      = process.env.RESEND_FROM || "Claude Code Weekly <hello@claudify.tech>";
const PREVIEW_TO       = process.env.PREVIEW_TO  || "you@example.com";

const BEEHIIV_API_KEY  = process.env.BEEHIIV_API_KEY;
const BEEHIIV_PUB_ID   = process.env.BEEHIIV_PUB_ID || "pub_44a9e61a-5206-45bb-bd6b-e5d7af2fa178";
const BEEHIIV_BASE_URL = "https://api.beehiiv.com/v2";

// ── Helpers ──────────────────────────────────────────────────────────────────

function die(msg) {
  console.error(`ERROR: ${msg}`);
  process.exit(1);
}

function requireEnv(name) {
  const val = process.env[name];
  if (!val) die(`Missing required env var: ${name}\nSet it in ${envPath} or export ${name}=...`);
  return val;
}

/**
 * Parse key: value pairs from the frontmatter block of an issue markdown file.
 */
function parseFrontmatter(text) {
  const match = text.match(/^---\s*\n([\s\S]*?)\n---\s*\n/);
  if (!match) return {};

  const fields = {};
  for (const line of match[1].split("\n")) {
    const colonIdx = line.indexOf(":");
    if (colonIdx === -1) continue;
    const key = line.slice(0, colonIdx).trim();
    const val = line.slice(colonIdx + 1).trim();
    fields[key] = val;
  }
  return fields;
}

// ── Main ─────────────────────────────────────────────────────────────────────

const args = process.argv.slice(2);
if (args.length === 0) {
  die("Usage: node send.js <issue-number> [--preview]  e.g.  node send.js 001");
}

const issueNum  = args[0].padStart(3, "0");
const isPreview = args.includes("--preview");
const issuesDir = path.join(__dirname, "issues");
const issueFile = path.join(issuesDir, `${issueNum}.md`);
const htmlFile  = path.join(issuesDir, `${issueNum}-rendered.html`);

// Validate source files exist
if (!fs.existsSync(issueFile)) {
  die(`Issue file not found: ${issueFile}\nRun: python3 build.py ${issueNum} first`);
}
if (!fs.existsSync(htmlFile)) {
  die(`Rendered HTML not found: ${htmlFile}\nRun: python3 build.py ${issueNum} first`);
}

const issueText = fs.readFileSync(issueFile, "utf8");
const html      = fs.readFileSync(htmlFile, "utf8");
const fm        = parseFrontmatter(issueText);

const subject     = fm.subject || `Claude Code Weekly #${issueNum}`;
const previewText = fm.preview || "";

console.log(`\nIssue:   #${issueNum}`);
console.log(`Subject: ${subject}`);
console.log(`Mode:    ${isPreview ? "preview (Resend)" : "broadcast draft (Beehiiv)"}`);
console.log();

// ── Preview mode — Resend ────────────────────────────────────────────────────

if (isPreview) {
  const apiKey = requireEnv("RESEND_API_KEY");
  console.log(`Sending preview to ${PREVIEW_TO}...`);

  // Use a timestamp-suffixed subject so Gmail doesn't thread + trim repeated previews
  // (Gmail collapses "duplicate" content across same-subject messages into "..." markers)
  const previewStamp = new Date().toISOString().slice(11, 19).replace(/:/g, "");
  const previewSubject = `[PREVIEW ${previewStamp}] ${subject}`;

  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type":  "application/json",
    },
    body: JSON.stringify({
      from:    RESEND_FROM,
      to:      [PREVIEW_TO],
      subject: previewSubject,
      html,
    }),
  });

  const data = await res.json();

  if (!res.ok) {
    console.error("Resend error:", JSON.stringify(data, null, 2));
    die(`Resend API returned ${res.status}`);
  }

  console.log(`Preview sent.`);
  console.log(`  Resend ID: ${data.id}`);
  console.log(`  To:        ${PREVIEW_TO}`);
  console.log();
  process.exit(0);
}

// ── Broadcast mode — Beehiiv ─────────────────────────────────────────────────

const apiKey       = requireEnv("BEEHIIV_API_KEY");
const broadcastUrl = `${BEEHIIV_BASE_URL}/publications/${BEEHIIV_PUB_ID}/broadcasts`;

console.log("Creating Beehiiv broadcast draft...");

const payload = {
  subject,
  preview_text: previewText,
  content: {
    free: {
      web:   html,
      email: html,
    },
  },
  status: "draft",
};

const res = await fetch(broadcastUrl, {
  method: "POST",
  headers: {
    "Authorization": `Bearer ${apiKey}`,
    "Content-Type":  "application/json",
  },
  body: JSON.stringify(payload),
});

const data = await res.json();

if (!res.ok) {
  console.error("Beehiiv error:", JSON.stringify(data, null, 2));
  die(`Beehiiv API returned ${res.status}`);
}

const broadcastId = data?.data?.id || data?.id || "(unknown)";
const draftUrl    = `https://app.beehiiv.com/publications/${BEEHIIV_PUB_ID}/broadcasts/${broadcastId}`;

console.log("Broadcast draft created.");
console.log(`  Broadcast ID: ${broadcastId}`);
console.log(`  Draft URL:    ${draftUrl}`);
console.log();
