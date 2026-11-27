#!/usr/bin/env python3
"""
Claudify update applier — the write-capable companion to claudify-update-triage.py.

Recomputes the same three-way classification, then maps every file to an action and
(either in --dry-run or --apply mode) executes the SAFE subset:

  copy   -> NEW files (additive) + IMPROVED + bulk vendor content in the safe dirs
            (.claude/agents, .claude/skills, .claude/commands except command-index.md,
             .claude/analyst). These are pure instruction/knowledge files; overwriting an
             older vendor version with the newer one is the intended update.
  keep   -> protected (CLAUDE.md, settings.json, knowledge-base.md, memory*, agent-memory,
            logs, Daily Notes, Scratchpad, Task Board, CLAUDE.local.md, .mcp.json,
            settings.local.json, proven-config*) and newsletter user-content (foundations,
            issues, drafts, briefs, BACKLOG) and recipes that differ. Never overwritten.
  review -> integration-sensitive: .claude/hooks/**, command-index.md, newsletter/send.js,
            INTEGRATION.md, SPEC.md, plus anything differing outside the safe dirs.
            Collected for manual diff/merge, NEVER auto-written.
  skip   -> UNCHANGED, and SETUP.md (rename collision with your Claudify_SETUP.md).

Source path resolution matches the manifest's dotfile convention (claude/ = .claude/,
gitignore = .gitignore).

Usage:
  python3 scripts/claudify-update-apply.py --dry-run               # show the plan, write nothing
  python3 scripts/claudify-update-apply.py --apply                 # perform the 'copy' actions
  python3 scripts/claudify-update-apply.py --apply --json ap.json  # also write what was done
"""
import argparse, hashlib, json, os, shutil, subprocess, sys
from collections import Counter

DEFAULT_SOURCE = os.path.expanduser("~/Downloads/claudify-everything")
PROTECTED_EXACT = {
    ".claude/memory.md", ".claude/knowledge-base.md", ".claude/knowledge-nominations.md",
    ".claude/settings.json", ".claude/settings.local.json", "CLAUDE.md", "CLAUDE.local.md",
    "Scratchpad.md", "Task Board.md", ".mcp.json", "gitignore",
    # ^ "gitignore" (dot-stripped manifest key) — held back so the agent merge step
    #   handles it; never copied over the target's (would clobber target gitignore lines).
}
PROTECTED_PREFIX = (".claude/agent-memory/", ".claude/logs/", ".claude/backups/", "Daily Notes/")
RENAME_SKIP = {"SETUP.md"}  # user renamed to Claudify_SETUP.md; copying would duplicate


def lf(b): return b.replace(b"\r\n", b"\n").replace(b"\r", b"\n")
def sha_file(p):
    try: return hashlib.sha256(lf(open(p, "rb").read())).hexdigest()
    except (FileNotFoundError, IsADirectoryError): return None
def to_fs(k): return ".claude/" + k[len("claude/"):] if k.startswith("claude/") else k
def is_protected(fs): return fs in PROTECTED_EXACT or any(fs.startswith(p) for p in PROTECTED_PREFIX)
def root_commit(cwd):
    r = subprocess.run(["git", "rev-list", "--max-parents=0", "HEAD"], cwd=cwd, capture_output=True)
    out = r.stdout.decode().strip().splitlines()
    return out[-1] if r.returncode == 0 and out else None
def sha_blob(rev, fs, cwd):
    r = subprocess.run(["git", "cat-file", "blob", f"{rev}:{fs}"], cwd=cwd, capture_output=True)
    return hashlib.sha256(lf(r.stdout)).hexdigest() if r.returncode == 0 else None


def resolve(base, fs):
    """Real path for a manifest fs-path under `base`, applying the dotfile convention."""
    p = os.path.join(base, fs)
    if os.path.isfile(p): return p
    if "/" not in fs:  # root key whose leading dot was stripped (gitignore -> .gitignore)
        dp = os.path.join(base, "." + fs)
        if os.path.isfile(dp): return dp
    return None


def load_baseline_manifest(path: str):
    """Load baseline manifest from a blueprint-origin.json or manifest file.

    Accepts:
    - blueprint-origin.json with top-level "files" using DOTTED keys (.claude/...)
    - Bare {"files": {...}} with dotted keys
    - Full UPDATE-MANIFEST.json (strips "claude/" prefix to get dotted keys)

    Returns dict mapping dotted keys (.claude/...) to hashes, or None if missing.
    """
    if not path or not os.path.isfile(path):
        return None
    try:
        data = json.load(open(path))
    except (json.JSONDecodeError, FileNotFoundError):
        return None

    # Extract files map - support both blueprint-origin.json and bare/manifest formats
    if isinstance(data, dict) and "files" in data:
        files = data["files"]
    else:
        return None

    # Normalize keys to dotted (.claude/...) form for comparison
    normalized = {}
    for key, hash_val in files.items():
        # If key is in manifest format (claude/...), convert to dotted (.claude/...)
        if key.startswith("claude/"):
            dotted = ".claude/" + key[len("claude/"):]
            normalized[dotted] = hash_val
        elif key.startswith(".claude/"):
            # Already dotted
            normalized[key] = hash_val
        else:
            # Root-level files (CLAUDE.md, gitignore, etc.) - keep as-is
            normalized[key] = hash_val

    return normalized


def status_of(fs, n_hash, target, baseline, baseline_manifest):
    real = resolve(target, fs)
    if real is None:
        # File absent in target
        if baseline_manifest and fs in baseline_manifest:
            # Deleted by child
            return "DELETED_BY_CHILD"
        return "NEW"
    c = sha_file(real)
    if c is None: return "NEW"
    if c == n_hash: return "UNCHANGED"
    if baseline_manifest:
        # Use manifest baseline
        s = baseline_manifest.get(fs)
        if s is not None and c == s: return "IMPROVED"
    elif baseline:
        # Use git commit baseline
        b = sha_blob(baseline, fs, target)
        if b is not None and c == b: return "IMPROVED"
    return "DIFFERS"


def action_for(fs, status, has_baseline):
    if status == "UNCHANGED": return ("skip", "unchanged")
    if is_protected(fs):      return ("keep", "protected")
    if fs in RENAME_SKIP:     return ("skip", "rename-collision")
    if fs.startswith(".claude/hooks/tests/"):  # vendor test-harness scripts: safe to add/update
        return ("copy", "test-harness" if status == "DIFFERS" else ("add" if status == "NEW" else "improved"))
    if fs.startswith(".claude/hooks/"):  # hooks are infrastructure — ALWAYS take blueprint's version (not customizable). Child-created hooks (not in manifest) are untouched.
        return ("copy", "hook-sync")
    if fs == ".claude/command-index.md" or fs == "newsletter/send.js" or fs in ("INTEGRATION.md", "SPEC.md"):
        return ("review", "sensitive")
    if (fs.startswith("newsletter/foundations/") or fs.startswith("newsletter/issues/")
        or fs.startswith("newsletter/drafts/") or fs.startswith("newsletter/briefs/")
        or fs == "newsletter/BACKLOG.md"):
        return ("keep", "newsletter-user-content")
    if fs.startswith(".claude/recipes/") and status == "DIFFERS":
        return ("keep", "recipes-mine")
    if status in ("NEW", "IMPROVED"):
        return ("copy", "add" if status == "NEW" else "improved")
    if status == "DELETED_BY_CHILD":
        return ("keep", "child-deleted")
    # DIFFERS
    if (fs.startswith(".claude/agents/") or fs.startswith(".claude/skills/")
        or fs.startswith(".claude/commands/") or fs.startswith(".claude/analyst/")):
        if has_baseline:
            return ("keep", "conflict-bulk")
        return ("copy", "bulk-update")
    return ("review", "unclear-differs")


def classify(source, target, baseline, baseline_manifest):
    man = json.load(open(os.path.join(source, ".claude", "UPDATE-MANIFEST.json")))["files"]
    plan = []
    has_baseline = bool(baseline_manifest or baseline)
    for key, n_hash in man.items():
        fs = to_fs(key)
        st = status_of(fs, n_hash, target, baseline, baseline_manifest)
        act, why = action_for(fs, st, has_baseline)
        plan.append({"fs": fs, "status": st, "action": act, "why": why, "src": resolve(source, fs)})
    return plan


def main():
    ap = argparse.ArgumentParser(description="Apply a Claudify update (safe subset).")
    ap.add_argument("--source", default=DEFAULT_SOURCE)
    ap.add_argument("--target", default=os.getcwd())
    ap.add_argument("--baseline", default=None)
    ap.add_argument("--baseline-manifest", default=None, help="baseline manifest file (blueprint-origin.json or manifest); takes priority over --baseline")
    ap.add_argument("--dry-run", action="store_true", help="show plan, write nothing (default)")
    ap.add_argument("--apply", action="store_true", help="perform 'copy' actions")
    ap.add_argument("--park-new", action="store_true", help="park conflicting files alongside target as <file>.blueprint-new")
    ap.add_argument("--json", default=None)
    args = ap.parse_args()
    if not args.apply:
        args.dry_run = True  # safe default: never write unless --apply explicitly given
    baseline = args.baseline or root_commit(args.target)
    baseline_manifest = load_baseline_manifest(args.baseline_manifest) if args.baseline_manifest else None
    plan = classify(args.source, args.target, baseline, baseline_manifest)

    by_action = Counter(p["action"] for p in plan)
    print("=" * 70)
    print(f"Claudify apply   mode={'APPLY' if args.apply else 'DRY-RUN'}   baseline={baseline}")
    print("=" * 70)
    print("Action counts:", dict(by_action))
    print("  copy   (will write):", by_action.get("copy", 0))
    print("  keep   (preserve yours):", by_action.get("keep", 0))
    print("  review (manual, NOT written):", by_action.get("review", 0))
    print("  skip   :", by_action.get("skip", 0))
    print()
    print("--- REVIEW (sensitive / unclear; handle manually, not auto-written) ---")
    for p in sorted([p for p in plan if p["action"] == "review"], key=lambda x: x["fs"]):
        print(f"   [{p['why']:18}] {p['fs']}")
    print()
    print("--- KEEP (yours; preserved) sample ---")
    for p in sorted([p for p in plan if p["action"] == "keep"], key=lambda x: x["fs"])[:25]:
        print(f"   [{p['why']:22}] {p['fs']}")
    keep_more = max(0, by_action.get("keep", 0) - 25)
    if keep_more: print(f"   ... +{keep_more} more")
    print()

    copied = []
    parked = []
    if args.apply:
        for p in plan:
            if p["action"] != "copy" or not p["src"]:
                continue
            dst = os.path.join(args.target, p["fs"])
            os.makedirs(os.path.dirname(dst) or ".", exist_ok=True)
            shutil.copy2(p["src"], dst)
            copied.append(p["fs"])

        # Park conflicting files if --park-new specified
        if args.park_new:
            for p in plan:
                # Only park keep/review items (not copy/skip)
                if p["action"] not in ("keep", "review") or not p["src"]:
                    continue
                # Check if source differs from target or target is absent
                target_path = os.path.join(args.target, p["fs"])
                target_hash = sha_file(target_path)
                if target_hash is None or target_hash != sha_file(p["src"]):
                    # Park the source version
                    park_path = target_path + ".blueprint-new"
                    os.makedirs(os.path.dirname(park_path) or ".", exist_ok=True)
                    shutil.copy2(p["src"], park_path)
                    parked.append(p["fs"])

        print(f"APPLIED: copied/updated {len(copied)} files.")
        if parked:
            print(f"PARKED: {len(parked)} conflicting files as <file>.blueprint-new.")
    else:
        print("DRY-RUN: no files written. Re-run with --apply to perform the 'copy' actions.")
    print()
    print("NOT auto-applied (do manually after): hooks/, command-index.md, send.js, "
          "INTEGRATION.md, SPEC.md (review); CLAUDE.md + settings.json (merge); "
          "knowledge-base.md (keep).")

    if args.json:
        json.dump({"plan": plan, "copied": copied, "dry_run": not args.apply},
                  open(args.json, "w"), indent=2)
        print(f"(report written to {args.json})")


if __name__ == "__main__":
    main()
