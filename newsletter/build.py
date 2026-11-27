#!/usr/bin/env python3
"""
build.py — Claude Code Weekly issue assembler.
Usage: python3 build.py 001

Reads issues/NNN.md, replaces all {{PLACEHOLDERS}} in email-template.html,
outputs issues/NNN-rendered.html, and validates the result.

Hard errors (exit 1):
  - Missing or empty PROMPT field
  - Unfilled {{PLACEHOLDERS}} in rendered output
  - Subject line over 50 characters
  - TIP_HEADLINE over 60 characters
  - Placeholder strings in code blocks (YOUR_VALUE_HERE, <placeholder>, ...)
  - Missing prompt teaser callout in TIP_BODY
  - Missing "Copy this prompt" block
  - Raw HTML comments inside <pre> blocks (must be encoded as &lt;!--)
"""

import sys
import re
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
TEMPLATE_PATH = SCRIPT_DIR / "email-template.html"
ISSUES_DIR = SCRIPT_DIR / "issues"

BEEHIIV_UNSUBSCRIBE = "{{unsubscribe_url}}"  # Beehiiv injects this at send time

PLACEHOLDER_PATTERNS = [
    r"YOUR_VALUE_HERE",
    r"YOUR_[A-Z_]+_HERE",
    r"<placeholder>",
    r"<your-[^>]+>",
]


def die(msg: str):
    print(f"\nERROR: {msg}\n", file=sys.stderr)
    sys.exit(1)


def parse_issue(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    fields = {}

    fm_match = re.match(r"^---\s*\n(.*?)\n---\s*\n", text, re.DOTALL)
    if not fm_match:
        die(f"No frontmatter found in {path.name}")

    for line in fm_match.group(1).splitlines():
        line = line.strip()
        if ":" in line:
            key, _, val = line.partition(":")
            fields[key.strip()] = val.strip()

    body = text[fm_match.end():]
    # Section header pattern: only "## NAME" where NAME is uppercase + underscores only,
    # followed by end-of-line. The lookahead is identical so that nested headings inside
    # a section body (e.g. "## NEW CLAUDE.md" inside GOD_PROMPT_BODY) don't truncate
    # the section. Without this, the regex was treating any "## " line as a delimiter,
    # silently dropping the rest of GOD_PROMPT_BODY (root cause of MISTAKE-016).
    section_pattern = re.compile(
        r"^## ([A-Z_]+)\s*\n(.*?)(?=^## [A-Z_]+\s*\n|\Z)",
        re.MULTILINE | re.DOTALL,
    )
    for m in section_pattern.finditer(body):
        fields[m.group(1).strip()] = m.group(2).strip()

    return fields


def prose_paragraph_split(text: str) -> str:
    """Convert blank-line paragraph breaks in prose fields to <br><br>.

    Email clients (Gmail web, Outlook, Apple Mail) collapse multiple consecutive
    whitespace inside a single <p> tag, a blank line in source content renders
    as one space and the intended two-beat hook reads as one wall-of-text
    paragraph. <br><br> survives the collapse and preserves the visual break.

    Applies ONLY to plain-text prose fields (TIP_INTRO, GOD_PROMPT_INTRO,
    GOD_PROMPT_CLOSER, PRO_TIP_BODY, QUICK_WIN_BODY). HTML-bearing fields
    (TIP_BODY, TLDR, READ_THIS_WEEK) already have their own structure and are
    NOT processed by this helper.

    See MISTAKE-018 in foundations/MISTAKES-LOG.md.
    """
    return text.replace("\n\n", "<br><br>")


def god_prompt_body_format(text: str) -> str:
    """Convert god-tier prompt body to HTML with explicit <br> tags per newline.

    The original implementation relied on `white-space:pre-wrap` CSS to preserve
    newlines in the prompt body. Empirically, Beehiiv (and likely some email
    clients) strip or normalise whitespace inside <p> tags during paste/render,
    even when pre-wrap is set. The result is the entire structured prompt
    rendering as one flowing paragraph: all bullet lists, step headers, and
    BAD/GOOD calibration pairs collapse together. Reader cannot follow the
    structure, prompt becomes useless.

    Fix: every newline becomes an explicit <br> tag at build time. <br> survives
    every platform's whitespace normalisation. The wrapper style still keeps
    `white-space:pre-wrap` as belt-and-suspenders for any stray newlines, but
    the actual line-breaking work is done by the <br>s.

    See MISTAKE-022 in foundations/MISTAKES-LOG.md.
    """
    return text.replace("\n", "<br>")


def build_god_gift_block(fields: dict) -> str:
    """Render the god-tier prompt gift block, or empty string if no prompt is provided.

    Issue 001 includes a free god-tier prompt as a thank-you to early subscribers. From
    Issue 002+ this either renders nothing OR (once the referral program ships) renders
    a teaser block telling subscribers to refer friends to unlock.
    """
    body_raw = fields.get("GOD_PROMPT_BODY", "").strip()
    if not body_raw:
        return ""

    body = god_prompt_body_format(body_raw)
    headline = fields.get("GOD_PROMPT_HEADLINE", "").strip()
    intro = prose_paragraph_split(fields.get("GOD_PROMPT_INTRO", "").strip())
    closer = prose_paragraph_split(fields.get("GOD_PROMPT_CLOSER", "").strip())
    pill = fields.get("GOD_PROMPT_PILL", "God-tier prompt &middot; Free this week").strip()

    return f'''<div style="background:#0d0d1a;border:1px solid #2e2e48;border-radius:10px;padding:24px 26px;margin:0 0 32px">
  <span style="display:inline-block;background:#ffb800;color:#0a0a0f;font-family:'SF Mono',Monaco,'JetBrains Mono',monospace;font-size:9px;font-weight:700;letter-spacing:0.15em;text-transform:uppercase;padding:3px 8px;border-radius:3px">{pill}</span>
  <p style="color:#ffffff;font-size:17px;font-weight:700;margin:14px 0 10px;line-height:1.35">{headline}</p>
  <p style="color:#a0a0b8;font-size:13px;line-height:1.65;margin:0 0 16px">{intro}</p>
  <div style="background:#080910;border:1px solid #1a1a2e;border-radius:6px;padding:16px 18px;margin:0 0 16px">
    <p style="font-family:'SF Mono',Monaco,'JetBrains Mono',monospace;font-size:12px;color:#a0a8d0;line-height:1.7;margin:0;white-space:pre-wrap">{body}</p>
  </div>
  <p style="color:#72728a;font-size:12px;line-height:1.65;margin:0;font-style:italic">{closer}</p>
</div>'''


def build_replacements(fields: dict, read_time: int) -> dict:
    return {
        "ISSUE_NUM":              fields.get("issue", ""),
        "DATE":                   fields.get("date", ""),
        "READ_TIME":              str(read_time),
        "DIFFICULTY":             fields.get("difficulty", "Beginner-friendly"),
        "TIP_HEADLINE":           fields.get("TIP_HEADLINE", ""),
        "TLDR":                   fields.get("TLDR", ""),
        "TIP_INTRO":              prose_paragraph_split(fields.get("TIP_INTRO", "")),
        "TIP_BODY":               fields.get("TIP_BODY", ""),
        "DEEP_DIVE_TITLE":        fields.get("DEEP_DIVE_TITLE", ""),
        "DEEP_DIVE_URL":          fields.get("DEEP_DIVE_URL", ""),
        "DEEP_DIVE_DESCRIPTION":  fields.get("DEEP_DIVE_DESCRIPTION", ""),
        "PROMPT":                 fields.get("PROMPT", ""),
        "PRO_TIP_HEADLINE":       fields.get("PRO_TIP_HEADLINE", ""),
        "PRO_TIP_BODY":           prose_paragraph_split(fields.get("PRO_TIP_BODY", "")),
        "QUICK_WIN_HEADLINE":     fields.get("QUICK_WIN_HEADLINE", ""),
        "QUICK_WIN_BODY":         prose_paragraph_split(fields.get("QUICK_WIN_BODY", "")),
        "READ_THIS_WEEK":         fields.get("READ_THIS_WEEK", ""),
        "GOD_GIFT_BLOCK":       build_god_gift_block(fields),
        "NEXT_TEASE":             fields.get("NEXT_TEASE", ""),
        "UNSUBSCRIBE_URL":        BEEHIIV_UNSUBSCRIBE,
    }


def apply_replacements(template: str, replacements: dict) -> str:
    result = template
    for key, value in replacements.items():
        result = result.replace("{{" + key + "}}", value)
    return result


def validate_fields(fields: dict):
    errors = []

    # PROMPT is mandatory
    if not fields.get("PROMPT", "").strip():
        errors.append("PROMPT field is empty. Every issue must have a copyable plain-English prompt.")

    # New mandatory fields (added with denser format)
    for required in ("TLDR", "DEEP_DIVE_TITLE", "DEEP_DIVE_URL", "DEEP_DIVE_DESCRIPTION",
                     "PRO_TIP_HEADLINE", "PRO_TIP_BODY",
                     "READ_THIS_WEEK", "NEXT_TEASE"):
        if not fields.get(required, "").strip():
            errors.append(f"{required} field is empty. Required for the new format.")

    # DEEP_DIVE_URL must be http(s)
    deep_url = fields.get("DEEP_DIVE_URL", "").strip()
    if deep_url and not (deep_url.startswith("http://") or deep_url.startswith("https://") or deep_url.startswith("/")):
        errors.append(f"DEEP_DIVE_URL must be a full URL or absolute path: '{deep_url}'")

    # Subject line length
    subject = fields.get("subject", "")
    if len(subject) > 50:
        errors.append(f"Subject line is {len(subject)} chars (max 50): '{subject}'")

    # Headline length
    headline = fields.get("TIP_HEADLINE", "")
    if len(headline) > 60:
        errors.append(f"TIP_HEADLINE is {len(headline)} chars (max 60): '{headline}'")

    # Issue type present
    if not fields.get("type", "").strip():
        errors.append("Frontmatter missing 'type' field (Command|Config|Workflow|Agent|Debug)")

    for e in errors:
        print(f"VALIDATION FAIL: {e}", file=sys.stderr)
    if errors:
        sys.exit(1)


def validate_rendered(html: str):
    errors = []

    # Unfilled uppercase placeholders
    remaining = re.findall(r"\{\{[A-Z_]+\}\}", html)
    if remaining:
        errors.append(f"Unfilled placeholders: {', '.join(set(remaining))}")

    # Placeholder strings in code blocks
    code_blocks = re.findall(r"<pre[^>]*>.*?</pre>", html, re.DOTALL)
    for block in code_blocks:
        for pattern in PLACEHOLDER_PATTERNS:
            if re.search(pattern, block, re.IGNORECASE):
                errors.append(f"Code block contains incomplete placeholder: {pattern}")
                break

    # Raw HTML comments inside <pre> blocks
    for block in code_blocks:
        if "<!--" in block:
            errors.append("Raw <!-- comment found inside <pre> block. Use &lt;!-- or email clients strip it.")

    # Prompt teaser callout must be present
    if "Ready-to-run prompt at the bottom" not in html:
        errors.append("Missing prompt teaser callout. Add '↓ Ready-to-run prompt at the bottom' after THE SETUP.")

    # Copy this prompt block must be present
    if "Copy this prompt" not in html:
        errors.append("Missing 'Copy this prompt' block. Every issue must have a copyable prompt section.")

    for e in errors:
        print(f"VALIDATION FAIL: {e}", file=sys.stderr)
    if errors:
        sys.exit(1)


def word_count(html: str) -> int:
    text = re.sub(r"<[^>]+>", " ", html)
    text = re.sub(r"&[a-z]+;", " ", text)
    return len(text.split())


def main():
    if len(sys.argv) < 2:
        die("Usage: python3 build.py <issue-number>  e.g.  python3 build.py 001")

    issue_num = sys.argv[1].zfill(3)
    issue_path = ISSUES_DIR / f"{issue_num}.md"

    if not issue_path.exists():
        die(f"Issue file not found: {issue_path}")
    if not TEMPLATE_PATH.exists():
        die(f"Template not found: {TEMPLATE_PATH}")

    print(f"Building issue {issue_num}...")

    fields = parse_issue(issue_path)
    validate_fields(fields)

    # Compute read time first (needed by replacements). Estimate from word count
    # of all text fields (intro + body + tldr + pro tip + quick win + reading list).
    text_for_count = " ".join([
        fields.get("TIP_INTRO", ""),
        re.sub(r"<[^>]+>", " ", fields.get("TIP_BODY", "")),
        re.sub(r"<[^>]+>", " ", fields.get("TLDR", "")),
        fields.get("PRO_TIP_BODY", ""),
        fields.get("QUICK_WIN_BODY", ""),
        re.sub(r"<[^>]+>", " ", fields.get("READ_THIS_WEEK", "")),
    ])
    word_estimate = len(text_for_count.split())
    read_time = max(2, round(word_estimate / 200))  # 200 words/min, min 2 min

    replacements = build_replacements(fields, read_time)
    template = TEMPLATE_PATH.read_text(encoding="utf-8")
    rendered = apply_replacements(template, replacements)

    validate_rendered(rendered)

    out_path = ISSUES_DIR / f"{issue_num}-rendered.html"
    out_path.write_text(rendered, encoding="utf-8")

    print()
    print(f"  Issue:      #{issue_num}")
    print(f"  Type:       {fields.get('type', '?')}")
    print(f"  Date:       {fields.get('date', '?')}")
    print(f"  Subject:    {fields.get('subject', '?')}  ({len(fields.get('subject', ''))} chars)")
    print(f"  Difficulty: {fields.get('difficulty', 'Beginner-friendly')}")
    print(f"  Read time:  {read_time} min")
    print(f"  Words:      {word_count(rendered)}")
    print(f"  Output:     {out_path}")
    print()
    print("Build complete.")


if __name__ == "__main__":
    main()
