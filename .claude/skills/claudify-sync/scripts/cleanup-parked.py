#!/usr/bin/env python3
"""
Claudify parked-file cleanup — drop adopted .blueprint-new files.

After a claudify-sync, the target may have `<file>.blueprint-new` parked
copies left over (written by the apply step's --park-new, and possibly by
the agent-merge steps). Once the real file has been adopted (made identical
to the parked copy), the parked copy is redundant and should be removed.

This walks <target> for every `*.blueprint-new` file. For each, let
`real = path without the .blueprint-new suffix`:
  - if `real` exists AND is byte-identical to the parked file -> delete the
    parked file (it was adopted).
  - otherwise -> keep it (genuine diff; needs manual review).

Prints:  `<n> removed (adopted), <m> kept (genuine diffs)` and lists the
kept ones. Exits 0.

Usage:
  python3 scripts/cleanup-parked.py --target <dir>
"""
import argparse, os, sys

PARKED_SUFFIX = ".blueprint-new"


def find_parked(target):
    """Yield absolute paths of every *.blueprint-new file under target."""
    for root, _dirs, files in os.walk(target):
        for fn in files:
            if fn.endswith(PARKED_SUFFIX):
                yield os.path.join(root, fn)


def read_bytes(path):
    try:
        with open(path, "rb") as f:
            return f.read()
    except (FileNotFoundError, IsADirectoryError):
        return None


def main():
    ap = argparse.ArgumentParser(description="Drop adopted .blueprint-new files; keep genuine diffs.")
    ap.add_argument("--target", required=True, help="target directory to clean")
    args = ap.parse_args()
    if not os.path.isdir(args.target):
        sys.exit(f"ERROR: target not a directory: {args.target}")

    removed = []
    kept = []
    for parked in find_parked(args.target):
        real = parked[: -len(PARKED_SUFFIX)]
        parked_bytes = read_bytes(parked)
        real_bytes = read_bytes(real)
        if real_bytes is not None and parked_bytes is not None and real_bytes == parked_bytes:
            os.remove(parked)
            removed.append(os.path.relpath(parked, args.target))
        else:
            kept.append(os.path.relpath(parked, args.target))

    print(f"{len(removed)} removed (adopted), {len(kept)} kept (genuine diffs)")
    for p in sorted(kept):
        print(f"  KEPT: {p}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
