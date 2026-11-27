#!/usr/bin/env python3
"""
Claudify update triage — classify every file in a new Claudify download against
the installed copy, so an update can be done safely (preserve user work, bring
vendor files up to date).

Three reference points (three-way merge logic, same as /migrate-to-2):
  N = NEW      the just-unzipped Claudify source (.claude/UPDATE-MANIFEST.json is
              ground truth for what the new version ships + each file's LF-normalized SHA-256).
  C = CURRENT  the installed .claude/ in this project (the working tree).
  B = BASELINE a prior git commit used as a "what I started from" reference, so we
              can tell "the vendor advanced and I never touched it" from "I edited it".
              Defaults to the repo's root commit (oldest ancestor).

Per file in the NEW manifest we classify into exactly one bucket:
  UNCHANGED  C hash == N hash            -> already up to date, nothing to do
  NEW        in N, absent from C         -> copy it in
  IMPROVED   C != N, but C == B          -> vendor advanced, user never edited -> safe to update
  CONFLICT   C != N, and C != B (or no B, or protected) -> keep user's, park new alongside
Files present in C but not in N are TARGET-ONLY (user-owned or obsolete) -> never overwrite.

PROTECTED files (memory.md, knowledge-base.md, settings.json, CLAUDE.md, agent-memory/,
logs/, Daily Notes/, .mcp.json, ...) are forced to CONFLICT/keep-mine regardless of hashes,
because they hold user content even when the vendor also ships a template.

IMPORTANT CAVEAT: the IMPROVED-vs-CONFLICT(i-edited) split is only reliable when the
baseline commit is a *pristine* vendor install and nothing vendor-level changed between
B and C. If C itself is a newer Claudify release than B (common: an earlier "update"
commit), many "i-edited" hits are really vendor version drift, not hand-edits. Read the
summary's CONFLICT counts with that in mind and confirm before preserving in bulk.

Usage:
  python3 scripts/claudify-update-triage.py
  python3 scripts/claudify-update-triage.py --source ~/Downloads/claudify-everything
  python3 scripts/claudify-update-triage.py --json triage.json   # also write machine-readable
"""
import argparse, hashlib, json, os, subprocess, sys
from collections import Counter

DEFAULT_SOURCE = os.path.expanduser("~/Downloads/claudify-everything")

# Files/dirs that hold user content even when Claudify also ships a template.
PROTECTED_EXACT = {
    ".claude/memory.md", ".claude/knowledge-base.md", ".claude/knowledge-nominations.md",
    ".claude/settings.json", ".claude/settings.local.json", "CLAUDE.md", "CLAUDE.local.md",
    "Scratchpad.md", "Task Board.md", ".mcp.json",
}
PROTECTED_PREFIX = (".claude/agent-memory/", ".claude/logs/", ".claude/backups/", "Daily Notes/")


def lf(b: bytes) -> bytes:
    """Normalize line endings the way UPDATE-MANIFEST.json documents: CRLF and lone CR -> LF."""
    return b.replace(b"\r\n", b"\n").replace(b"\r", b"\n")


def sha_file(path: str):
    try:
        return hashlib.sha256(lf(open(path, "rb").read())).hexdigest()
    except FileNotFoundError:
        return None
    except IsADirectoryError:
        return None


def resolve_existing(target: str, fs_path: str):
    """Find the file on disk for a manifest fs-path. The manifest stores dotfiles
    without their leading dot (claude/ = .claude/, gitignore = .gitignore), so for
    root-level keys also try the dot-prefixed form. Returns the real path or None."""
    p = os.path.join(target, fs_path)
    if os.path.isfile(p):
        return p
    if "/" not in fs_path:  # root key: maybe a dotfile whose dot was stripped
        dp = os.path.join(target, "." + fs_path)
        if os.path.isfile(dp):
            return dp
    return None


def git(args, cwd):
    return subprocess.run(["git"] + args, cwd=cwd, capture_output=True)


def sha_blob(rev: str, fs_path: str, cwd: str):
    """LF-normalized SHA-256 of a file's contents at a given git revision, or None if absent."""
    r = git(["cat-file", "blob", f"{rev}:{fs_path}"], cwd)
    if r.returncode != 0:
        return None
    return hashlib.sha256(lf(r.stdout)).hexdigest()


def root_commit(cwd: str):
    r = git(["rev-list", "--max-parents=0", "HEAD"], cwd)
    if r.returncode == 0:
        out = r.stdout.decode().strip().splitlines()
        if out:
            return out[-1]
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


def manifest_key_to_fs(key: str) -> str:
    """Manifest writes '.claude' as 'claude' (e.g. 'claude/agents/x.md'). Map back to fs path."""
    return ".claude/" + key[len("claude/"):] if key.startswith("claude/") else key


def is_protected(fs_path: str) -> bool:
    if fs_path in PROTECTED_EXACT:
        return True
    return any(fs_path.startswith(p) for p in PROTECTED_PREFIX)


def area(fs_path: str) -> str:
    if not fs_path.startswith(".claude/"):
        return "root"
    parts = fs_path.split("/")
    return parts[1] if len(parts) > 1 else ".claude"


def triage(source, target, baseline, baseline_manifest):
    manifest_path = os.path.join(source, ".claude", "UPDATE-MANIFEST.json")
    if not os.path.isfile(manifest_path):
        sys.exit(f"ERROR: no UPDATE-MANIFEST.json at {manifest_path} — is --source the unzipped Claudify folder?")
    man = json.load(open(manifest_path))["files"]

    unchanged, new, improved, conflict = [], [], [], []
    for key, n_hash in man.items():
        fs = manifest_key_to_fs(key)
        real = resolve_existing(target, fs)
        c_hash = sha_file(real) if real else None

        # NEW / deleted-by-child logic (only when baseline manifest is present)
        if c_hash is None:
            if baseline_manifest and fs in baseline_manifest:
                # File absent in target but was in baseline -> child deleted it
                conflict.append((fs, "child-deleted"))
            else:
                # Truly new (not in baseline or no baseline manifest)
                new.append(fs)
            continue

        if c_hash == n_hash:
            unchanged.append(fs)
            continue

        # Differs from new version.
        if is_protected(fs):
            conflict.append((fs, "protected"))
            continue

        # Baseline comparison: prefer manifest over git commit
        if baseline_manifest:
            # Use manifest baseline
            s_hash = baseline_manifest.get(fs)
            if s_hash is not None:
                if c_hash == s_hash:
                    improved.append(fs)
                else:
                    conflict.append((fs, "edited"))
            else:
                # File not in baseline manifest - treat as conflict
                conflict.append((fs, "not-in-baseline"))
        elif baseline:
            # Use git commit baseline
            b_hash = sha_blob(baseline, fs, target)
            if b_hash is not None and c_hash == b_hash:
                improved.append(fs)
            elif b_hash is not None and c_hash != b_hash:
                conflict.append((fs, "i-edited"))
            else:
                conflict.append((fs, "not-in-baseline"))
        else:
            conflict.append((fs, "no-baseline"))

    # Target-only: present in C, not shipped by N.
    man_fs = {manifest_key_to_fs(k) for k in man}
    tgt = set()
    for root, _, fns in os.walk(os.path.join(target, ".claude")):
        for fn in fns:
            tgt.add(os.path.relpath(os.path.join(root, fn), target))
    target_only = sorted(tgt - man_fs)

    return {
        "manifest_count": len(man),
        "baseline": baseline,
        "unchanged": sorted(unchanged),
        "new": sorted(new),
        "improved": sorted(improved),
        "conflict": sorted(conflict),
        "target_only": target_only,
    }


def print_report(r):
    w = 70
    print("=" * w)
    print(f"Claudify update triage   (manifest files: {r['manifest_count']})   baseline: {r['baseline'] or '(none)'}")
    print("=" * w)
    print(f"  UNCHANGED  (already == new version)          : {len(r['unchanged'])}")
    print(f"  NEW        (in source, not installed)        : {len(r['new'])}")
    print(f"  IMPROVED   (vendor advanced, user didn't edit): {len(r['improved'])}   <- safe to update")
    print(f"  CONFLICT   (user-edited / protected / no base): {len(r['conflict'])}   <- keep user's")
    print(f"  TARGET-ONLY (user-owned or obsolete)         : {len(r['target_only'])}")
    print()
    print("NEW by area      :", dict(Counter(area(f) for f in r["new"])))
    print("IMPROVED by area :", dict(Counter(area(f) for f in r["improved"])))
    print("CONFLICT by reason:", dict(Counter(w for _, w in r["conflict"])))
    print()
    print("CAVEAT: if the current install is itself a newer Claudify release than the baseline,")
    print('many "i-edited" hits are vendor version drift, not hand-edits. Confirm before bulk-preserving.')
    print()
    for title, key in [("IMPROVED (safe to update)", "improved"),
                       ("CONFLICT (review; default keep mine)", None),
                       ("NEW (copy in)", "new"),
                       ("TARGET-ONLY (mine / obsolete; never overwrite)", "target_only")]:
        if key is not None:
            items = r[key]
            print(f"--- {title} ({len(items)}) ---")
            for fs in items:
                print("   ", fs)
        else:
            items = r["conflict"]
            print(f"--- {title} ({len(items)}) ---")
            for fs, why in items:
                print(f"    [{why:14}] {fs}")
        print()


def main():
    ap = argparse.ArgumentParser(description="Triage a Claudify update against the installed copy.")
    ap.add_argument("--source", default=DEFAULT_SOURCE, help="unzipped Claudify folder (default ~/Downloads/claudify-everything)")
    ap.add_argument("--target", default=os.getcwd(), help="installed project root (default cwd)")
    ap.add_argument("--baseline", default=None, help="git commit to use as 'what I started from' (default: repo root commit)")
    ap.add_argument("--baseline-manifest", default=None, help="baseline manifest file (blueprint-origin.json or manifest); takes priority over --baseline")
    ap.add_argument("--no-baseline", action="store_true", help="skip git baseline; treat all differs as conflict")
    ap.add_argument("--json", default=None, help="also write machine-readable classification to this path")
    args = ap.parse_args()

    baseline = None if args.no_baseline else (args.baseline or root_commit(args.target))
    baseline_manifest = load_baseline_manifest(args.baseline_manifest) if args.baseline_manifest else None
    r = triage(args.source, args.target, baseline, baseline_manifest)
    print_report(r)
    if args.json:
        json.dump(r, open(args.json, "w"), indent=2)
        print(f"(machine-readable classification written to {args.json})")


if __name__ == "__main__":
    main()
