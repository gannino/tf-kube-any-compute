#!/usr/bin/env python3
"""
Claudify manifest generator — walk a Claudify tree and generate UPDATE-MANIFEST.json.

Walks <root>/.claude/ (skipping symlinks) plus <root>/CLAUDE.md, <root>/.gitignore,
and <root>/.mcp.json, LF-normalizes each file's content, and emits a manifest with SHA-256 hashes.

Manifest format:
{
  "format": 2,
  "generated": "<ISO timestamp with Z>",
  "normalization": "CRLF and lone CR are normalized to LF before hashing",
  "purpose": "Track exact file state for three-way merge updates",
  "files": {
    "<dotted key>": "<sha256>",
    ...
  }
}

Keys use the dotfile convention:
  - .claude/agents/x.md -> "claude/agents/x.md" (leading dot stripped)
  - CLAUDE.md -> "CLAUDE.md"
  - .gitignore -> "gitignore"
  - .mcp.json -> ".mcp.json" (NOT stripped — only .claude/ and .gitignore get special treatment)

This matches the key format used by the triage and apply scripts.

Usage:
  python3 scripts/claudify-generate-manifest.py
  python3 scripts/claudify-generate-manifest.py --root /path/to/project --out manifest.json
"""
import argparse, hashlib, json, os, sys
from datetime import datetime, timezone


def lf(b: bytes) -> bytes:
    """Normalize line endings the way UPDATE-MANIFEST.json documents: CRLF and lone CR -> LF."""
    return b.replace(b"\r\n", b"\n").replace(b"\r", b"\n")


def sha_file(path: str):
    """Compute LF-normalized SHA-256 of a file. Returns None if file cannot be read."""
    try:
        return hashlib.sha256(lf(open(path, "rb").read())).hexdigest()
    except (FileNotFoundError, IsADirectoryError, PermissionError):
        return None


def to_fs(key: str) -> str:
    """Manifest writes '.claude' as 'claude' (e.g. 'claude/agents/x.md'). Map back to fs path."""
    return ".claude/" + key[len("claude/"):] if key.startswith("claude/") else key


def manifest_key_from_fs(fs_path: str) -> str:
    """Convert a filesystem path to a manifest key (dotfile convention)."""
    # .claude/* -> claude/*
    if fs_path.startswith(".claude/"):
        return "claude/" + fs_path[len(".claude/"):]
    # .gitignore -> gitignore
    if fs_path == ".gitignore":
        return "gitignore"
    # Others unchanged (CLAUDE.md, etc.)
    return fs_path


def walk_claudify(root: str):
    """Walk .claude/, CLAUDE.md, .gitignore, and .mcp.json under root. Skip symlinks and
    never-synced (per-developer / runtime) paths. Yields fs_path."""
    # Walk .claude/ directory
    claude_dir = os.path.join(root, ".claude")
    if os.path.isdir(claude_dir):
        for root_dir, dirs, files in os.walk(claude_dir):
            # Prune symlinked dirs AND never-synced dirs (don't descend into them)
            kept = []
            for d in dirs:
                dp = os.path.join(root_dir, d)
                if os.path.islink(dp):
                    continue
                rel = os.path.relpath(dp, root).replace(os.sep, "/")
                if _never_synced(rel):
                    continue
                kept.append(d)
            dirs[:] = kept
            for fn in files:
                fp = os.path.join(root_dir, fn)
                if os.path.islink(fp):  # Skip file symlinks
                    continue
                fs_path = os.path.relpath(fp, root)
                if _never_synced(fs_path):
                    continue
                yield fs_path

    # CLAUDE.md at root (synced — handled by the merge step on the child)
    claude_md = os.path.join(root, "CLAUDE.md")
    if os.path.isfile(claude_md) and not os.path.islink(claude_md):
        yield "CLAUDE.md"

    # .gitignore at root
    gitignore = os.path.join(root, ".gitignore")
    if os.path.isfile(gitignore) and not os.path.islink(gitignore):
        yield ".gitignore"

    # .mcp.json at root (synced — via the agent merge step on the child; protected/keep in apply).
    # Key stays ".mcp.json" (no dot stripping — only .claude/ and .gitignore get special treatment).
    mcp = os.path.join(root, ".mcp.json")
    if os.path.isfile(mcp) and not os.path.islink(mcp):
        yield ".mcp.json"


# Per-developer / runtime paths that are NEVER synced to children.
# NOTE: CLAUDE.md and .claude/settings.json are intentionally NOT here — they ARE
# synced (CLAUDE.md via section-preserving merge, settings.json via additive merge).
NEVER_SYNCED_DIRS = (".claude/agent-memory", ".claude/logs", ".claude/backups")
NEVER_SYNCED_FILES = {
    ".claude/memory.md", ".claude/knowledge-base.md", ".claude/knowledge-nominations.md",
    ".claude/settings.local.json", ".claude/proven-config.json", ".claude/.proven-config-version",
    "CLAUDE.local.md",
    ".claude/UPDATE-MANIFEST.json",  # the manifest must not list itself (self-reference -> false positives)
}


def _never_synced(fs_path: str) -> bool:
    for d in NEVER_SYNCED_DIRS:
        if fs_path == d or fs_path.startswith(d + "/"):
            return True
    if fs_path in NEVER_SYNCED_FILES:
        return True
    # runtime dotfiles directly under .claude/ (.session-*, .tool-call-count, .quality-gate-active, .compaction-occurred, ...)
    if fs_path.startswith(".claude/."):
        return True
    return False


def generate_manifest(root: str):
    """Generate manifest dict for a Claudify tree."""
    files = {}
    for fs_path in walk_claudify(root):
        full_path = os.path.join(root, fs_path)
        hash_val = sha_file(full_path)
        if hash_val is not None:
            key = manifest_key_from_fs(fs_path)
            files[key] = hash_val

    return {
        "format": 2,
        "generated": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "normalization": "CRLF and lone CR are normalized to LF before hashing",
        "purpose": "Track exact file state for three-way merge updates",
        "files": files,
    }


def main():
    ap = argparse.ArgumentParser(description="Generate UPDATE-MANIFEST.json for a Claudify tree.")
    ap.add_argument("--root", default=os.getcwd(), help="Project root (default cwd)")
    ap.add_argument("--out", default=None, help="Output path (default <root>/.claude/UPDATE-MANIFEST.json)")
    args = ap.parse_args()

    if args.out is None:
        args.out = os.path.join(args.root, ".claude", "UPDATE-MANIFEST.json")

    manifest = generate_manifest(args.root)

    # Ensure output directory exists
    os.makedirs(os.path.dirname(args.out) or ".", exist_ok=True)

    with open(args.out, "w") as f:
        json.dump(manifest, f, indent=2, sort_keys=True)
        f.write("\n")

    print(f"Generated manifest with {len(manifest['files'])} files -> {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
