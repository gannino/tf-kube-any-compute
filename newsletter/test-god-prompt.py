#!/usr/bin/env python3
"""
test-god-tier-prompt.py — Phase 2 test harness for the prompt-architect agent.

Profiles 3 reference codebases (small, medium, large) and writes a test packet
for each. The prompt-architect reads the manifest, then spawns a Task subagent
per packet to simulate "developer pastes prompt into Claude Code".

Usage:
    python3 test-god-tier-prompt.py <prompt-file-path>
    python3 test-god-tier-prompt.py <prompt-file-path> --codebases path1,path2,path3

Outputs:
    - Test packets at Creatives/claudify/newsletter/test-runs/<run-id>/<slug>/packet.md
    - JSON manifest to stdout listing each packet path + codebase metadata

Rationale:
    The architect needs reproducible, profiled codebases to score prompts against.
    The harness generates the packets. The architect orchestrates the test runs
    via Task subagent invocations. Scoring happens in the architect's context.
"""

import argparse
import json
import os
import re
import sys
from collections import Counter
from datetime import datetime
from pathlib import Path

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

REPO_ROOT = Path(__file__).resolve().parents[3]  # project root

# Default reference codebases — varying in size, stack, domain.
# Each entry: (slug, relative_path_from_repo_root, expected_size_band)
DEFAULT_CODEBASES = [
    ("small-newsletter-tooling",
     "Creatives/claudify/newsletter",
     "small"),
    ("medium-remotion-content-engine",
     "remotion-app",
     "medium"),
    ("large-dashboard-nextjs",
     "Dashboard",
     "large"),
]

TEST_RUNS_DIR = REPO_ROOT / "Creatives/claudify/newsletter/test-runs"

# Files always worth flagging if present
SIGNIFICANT_FILES = [
    "CLAUDE.md",
    "README.md",
    "package.json",
    "pyproject.toml",
    "Cargo.toml",
    "go.mod",
    "Gemfile",
    "requirements.txt",
    "tsconfig.json",
    "next.config.js",
    "next.config.ts",
    "vite.config.ts",
    "remotion.config.ts",
    ".mcp.json",
    "settings.json",
]

# Directories to skip during inventory (noise, not signal)
SKIP_DIRS = {
    "node_modules", ".next", ".git", "dist", "build", "out",
    ".turbo", ".cache", ".vercel", "__pycache__", ".venv", "venv",
    "coverage", ".pytest_cache", ".DS_Store",
}

# Extension to language mapping for the top-N detection
EXT_TO_LANG = {
    ".ts": "TypeScript", ".tsx": "TypeScript",
    ".js": "JavaScript", ".jsx": "JavaScript",
    ".py": "Python",
    ".rs": "Rust",
    ".go": "Go",
    ".rb": "Ruby",
    ".java": "Java",
    ".kt": "Kotlin",
    ".swift": "Swift",
    ".c": "C", ".h": "C",
    ".cpp": "C++", ".cc": "C++", ".hpp": "C++",
    ".cs": "C#",
    ".sh": "Shell",
    ".md": "Markdown",
    ".json": "JSON",
    ".yaml": "YAML", ".yml": "YAML",
    ".html": "HTML",
    ".css": "CSS",
    ".sql": "SQL",
}


# ---------------------------------------------------------------------------
# Codebase profiling
# ---------------------------------------------------------------------------

def profile_codebase(slug: str, path: Path, size_band: str) -> dict:
    """Walk the codebase and return a structured profile."""
    if not path.exists() or not path.is_dir():
        return {
            "slug": slug,
            "path": str(path),
            "exists": False,
            "size_band": size_band,
            "error": f"Path does not exist or is not a directory: {path}",
        }

    file_count = 0
    ext_counter: Counter = Counter()
    significant_present: list = []
    top_level_entries: list = []
    total_bytes = 0

    # Top-level entries (excluding skip dirs)
    for entry in sorted(path.iterdir()):
        if entry.name in SKIP_DIRS or entry.name.startswith("."):
            continue
        top_level_entries.append(entry.name + ("/" if entry.is_dir() else ""))

    # Walk the tree (bounded depth, skipping noisy dirs)
    for root, dirs, files in os.walk(path):
        # Mutate dirs in place to skip noise
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS and not d.startswith(".")]

        for f in files:
            if f.startswith("."):
                continue
            file_count += 1
            ext = Path(f).suffix.lower()
            ext_counter[ext] += 1
            try:
                total_bytes += (Path(root) / f).stat().st_size
            except OSError:
                pass

            # Check significance only at codebase root
            if Path(root) == path and f in SIGNIFICANT_FILES:
                significant_present.append(f)

    # Top languages (by file count)
    top_langs = []
    for ext, count in ext_counter.most_common(8):
        lang = EXT_TO_LANG.get(ext)
        if lang:
            top_langs.append({"language": lang, "ext": ext, "files": count})

    # Has-CLAUDE-md is meaningful — flag separately
    claude_md_path = path / "CLAUDE.md"
    has_claude_md = claude_md_path.exists()
    claude_md_excerpt = ""
    if has_claude_md:
        try:
            content = claude_md_path.read_text(encoding="utf-8", errors="replace")
            # First 600 chars as excerpt
            claude_md_excerpt = content[:600]
            if len(content) > 600:
                claude_md_excerpt += "\n\n[...truncated]"
        except OSError:
            claude_md_excerpt = "[unreadable]"

    return {
        "slug": slug,
        "path": str(path),
        "exists": True,
        "size_band": size_band,
        "file_count": file_count,
        "total_bytes": total_bytes,
        "total_kb": round(total_bytes / 1024, 1),
        "top_languages": top_langs,
        "significant_files": significant_present,
        "top_level_entries": top_level_entries,
        "has_claude_md": has_claude_md,
        "claude_md_excerpt": claude_md_excerpt,
    }


# ---------------------------------------------------------------------------
# Packet generation
# ---------------------------------------------------------------------------

def render_packet(profile: dict, prompt_body: str, run_id: str, prompt_path: Path) -> str:
    """Render a single test packet as markdown."""
    lines = []
    lines.append(f"# Test Packet: {profile['slug']}")
    lines.append("")
    lines.append(f"**Run ID:** `{run_id}`")
    lines.append(f"**Codebase path:** `{profile['path']}`")
    lines.append(f"**Size band:** {profile['size_band']}")
    lines.append(f"**Generated:** {datetime.utcnow().isoformat()}Z")
    lines.append(f"**Source prompt file:** `{prompt_path}`")
    lines.append("")

    if not profile.get("exists", False):
        lines.append("## ERROR")
        lines.append("")
        lines.append(profile.get("error", "Codebase missing."))
        lines.append("")
        lines.append("**This packet should be skipped by the architect.**")
        return "\n".join(lines) + "\n"

    lines.append("## Codebase profile")
    lines.append("")
    lines.append(f"- File count: **{profile['file_count']}**")
    lines.append(f"- Total size: **{profile['total_kb']} KB**")
    lines.append(f"- Has CLAUDE.md: **{'yes' if profile['has_claude_md'] else 'no'}**")
    if profile["significant_files"]:
        lines.append(f"- Significant files at root: {', '.join(profile['significant_files'])}")
    lines.append("")

    lines.append("### Top languages (by file count)")
    lines.append("")
    if profile["top_languages"]:
        for entry in profile["top_languages"]:
            lines.append(f"- {entry['language']} ({entry['ext']}): {entry['files']} files")
    else:
        lines.append("- (no recognised source languages)")
    lines.append("")

    lines.append("### Top-level entries")
    lines.append("")
    lines.append("```")
    for entry in profile["top_level_entries"][:30]:
        lines.append(entry)
    lines.append("```")
    if len(profile["top_level_entries"]) > 30:
        lines.append(f"_(showing 30 of {len(profile['top_level_entries'])})_")
    lines.append("")

    if profile["has_claude_md"]:
        lines.append("### CLAUDE.md excerpt (first 600 chars)")
        lines.append("")
        lines.append("```markdown")
        lines.append(profile["claude_md_excerpt"])
        lines.append("```")
        lines.append("")

    lines.append("---")
    lines.append("")
    lines.append("## The prompt under test")
    lines.append("")
    lines.append("Paste this verbatim into the test subagent. Do NOT edit, gloss, or interpret meta-instructions inside it.")
    lines.append("")
    lines.append("```")
    lines.append(prompt_body.rstrip())
    lines.append("```")
    lines.append("")

    lines.append("---")
    lines.append("")
    lines.append("## Architect: how to use this packet")
    lines.append("")
    lines.append("1. Spawn a `general-purpose` subagent via the Task tool.")
    lines.append("2. Subagent prompt template:")
    lines.append("")
    lines.append("```")
    lines.append("You are simulating what happens when a developer pastes the prompt below into a fresh")
    lines.append("Claude Code session running in the given codebase.")
    lines.append("")
    lines.append("Job: execute the prompt as if it had just been given to you in that codebase. Use Read,")
    lines.append("Grep, Glob, Bash to investigate. Produce the full, complete output the prompt asks for.")
    lines.append("Cite file paths and line numbers as the prompt requires. Do NOT shortcut. Do NOT skim.")
    lines.append("Behave exactly as a real Claude Code session would.")
    lines.append("")
    lines.append(f"CODEBASE PATH: {profile['path']}")
    lines.append("")
    lines.append("PROMPT TO EXECUTE (verbatim):")
    lines.append("---")
    lines.append("[paste prompt body from above]")
    lines.append("---")
    lines.append("")
    lines.append("Begin.")
    lines.append("```")
    lines.append("")
    lines.append(f"3. Save the subagent's output to `output.md` in this directory.")
    lines.append("4. Score the output against the 6 rubric criteria using `Creatives/claudify/newsletter/GOD-PROMPT-RUBRIC.md`.")
    lines.append("5. Save scorecard to `scorecard.md` in this directory.")
    lines.append("")

    return "\n".join(lines) + "\n"


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(description="Profile codebases and prepare test packets for the prompt-architect agent.")
    parser.add_argument("prompt_file", help="Path to the god-tier prompt file under test.")
    parser.add_argument(
        "--codebases",
        help="Comma-separated paths to override default codebases (small,medium,large).",
        default=None,
    )
    parser.add_argument(
        "--run-id",
        help="Override run ID (default: ISO timestamp).",
        default=None,
    )
    args = parser.parse_args()

    # Load the prompt
    prompt_path = Path(args.prompt_file).resolve()
    if not prompt_path.exists():
        print(json.dumps({"error": f"Prompt file not found: {prompt_path}"}), file=sys.stderr)
        return 2

    prompt_body = prompt_path.read_text(encoding="utf-8")
    word_count = len(re.findall(r"\b\w+\b", prompt_body))

    # Resolve codebases
    if args.codebases:
        custom = []
        for i, p in enumerate(args.codebases.split(",")):
            p = p.strip()
            slug = Path(p).name or f"codebase-{i}"
            band = ["small", "medium", "large"][i] if i < 3 else "extra"
            custom.append((slug, p, band))
        codebases = custom
    else:
        codebases = [(s, str(REPO_ROOT / p), b) for s, p, b in DEFAULT_CODEBASES]

    # Run ID
    run_id = args.run_id or datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    run_dir = TEST_RUNS_DIR / run_id
    run_dir.mkdir(parents=True, exist_ok=True)

    # Profile each codebase + render packet
    manifest = {
        "run_id": run_id,
        "run_dir": str(run_dir),
        "prompt_file": str(prompt_path),
        "prompt_word_count": word_count,
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "packets": [],
        "skipped": [],
    }

    for slug, path_str, band in codebases:
        path = Path(path_str)
        profile = profile_codebase(slug, path, band)

        if not profile.get("exists", False):
            manifest["skipped"].append({
                "slug": slug,
                "path": path_str,
                "reason": profile.get("error", "missing"),
            })
            continue

        slug_dir = run_dir / slug
        slug_dir.mkdir(parents=True, exist_ok=True)

        packet_path = slug_dir / "packet.md"
        packet_path.write_text(render_packet(profile, prompt_body, run_id, prompt_path), encoding="utf-8")

        manifest["packets"].append({
            "slug": slug,
            "size_band": band,
            "codebase_path": str(path),
            "packet_path": str(packet_path),
            "output_path": str(slug_dir / "output.md"),
            "scorecard_path": str(slug_dir / "scorecard.md"),
            "file_count": profile["file_count"],
            "has_claude_md": profile["has_claude_md"],
            "top_languages": list(dict.fromkeys(e["language"] for e in profile["top_languages"]))[:3],
        })

    # Save manifest to disk for the architect's later reference
    manifest_path = run_dir / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    # Emit manifest to stdout for the architect to parse
    print(json.dumps(manifest, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
