"""Validate and apply the exact Android changes recorded by an NDK release."""

import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import subprocess


def read_pinned(path, expected, label):
    if not re.fullmatch(r"[0-9a-f]{64}", expected):
        raise ValueError(f"Invalid {label} SHA-256")
    if path.is_symlink() or not path.is_file():
        raise ValueError(f"Expected a regular {label} file: {path}")
    data = path.read_bytes()
    if hashlib.sha256(data).hexdigest() != expected:
        raise ValueError(f"{label} SHA-256 mismatch")
    return data


def patch_path(value):
    if not isinstance(value, str) or not re.fullmatch(r"[A-Za-z0-9_.+-]+(?:/[A-Za-z0-9_.+-]+)*\.patch", value):
        raise ValueError(f"Invalid Android change path: {value!r}")
    path = PurePosixPath(value)
    if any(part in (".", "..") for part in value.split("/")) or path.as_posix() != value:
        raise ValueError(f"Invalid Android change path: {value!r}")
    return value


def legacy_report_path(relative):
    """Reproduce AOSP PatchInfo.format_patch_line's historical URL formatter.

    That formatter inferred cherry/ from the basename with this exact regex.
    Hyphen-suffixed cherry patch names consequently lost their directory in the
    report. The manifest remains authoritative for their actual paths/order.
    """
    name = PurePosixPath(relative).name
    if re.match(r"([0-9a-f]+)(_v[0-9]+)?\.patch$", name):
        return f"cherry/{name}"
    return name


def recorded_paths(recorded, base, android_revision):
    lines = recorded.splitlines()
    expected_base = f"Base revision: [{base}](https://github.com/llvm/llvm-project/commits/{base})"
    if not lines or lines[0] != expected_base:
        raise ValueError("Unexpected LLVM base revision in source report")
    prefix = f"https://android.googlesource.com/toolchain/llvm_android/+/{android_revision}/patches/"
    paths = []
    for line in lines[1:]:
        if not line:
            continue
        match = re.fullmatch(r"- \[.*\]\((https://[^\s)]+)\)", line)
        if match is None or not match[1].startswith(prefix):
            raise ValueError("Invalid source report or unexpected Android source revision")
        paths.append(patch_path(match[1][len(prefix):]))
    if not paths or len(paths) != len(set(paths)):
        raise ValueError("Missing or duplicate recorded Android changes")
    return paths


def eligible_paths(entries, svn):
    if not isinstance(entries, list):
        raise ValueError("Android patch manifest must be a list")
    selected = []
    for entry in entries:
        if not isinstance(entry, dict):
            raise ValueError("Invalid Android patch manifest entry")
        relative = patch_path(entry.get("rel_patch_path"))
        platforms = entry.get("platforms")
        version_range = entry.get("version_range")
        if not isinstance(platforms, list) or not all(isinstance(item, str) for item in platforms) or not isinstance(version_range, dict):
            raise ValueError(f"Invalid patch selection metadata: {relative}")
        start, end = version_range.get("from"), version_range.get("until")
        if any(value is not None and (type(value) is not int or value < 0) for value in (start, end)):
            raise ValueError(f"Invalid patch version range: {relative}")
        if start is not None and end is not None and start >= end:
            raise ValueError(f"Invalid patch version range: {relative}")
        if "android" in platforms and (start is None or start <= svn) and (end is None or svn < end):
            selected.append(relative)
    if not selected or len(selected) != len(set(selected)):
        raise ValueError("Missing or duplicate eligible Android changes")
    return selected


def reconcile_paths(ordered, recorded):
    # Accept exact modern links and the proven AOSP formatter output only.
    aliases = {}
    for relative in ordered:
        for alias in {relative, legacy_report_path(relative)}:
            aliases.setdefault(alias, set()).add(relative)
    matched = set()
    for reported in recorded:
        candidates = aliases.get(reported, set())
        if len(candidates) != 1:
            raise ValueError(f"Unknown or ambiguous recorded Android change: {reported}")
        relative = next(iter(candidates))
        if relative in matched:
            raise ValueError(f"Duplicate recorded Android change: {relative}")
        matched.add(relative)
    if matched != set(ordered):
        raise ValueError("Android change manifest differs from the NDK source report")


def load_patch_plan(android, recorded_file, *, base, android_revision, svn,
                    source_info_sha256, patch_manifest_sha256):
    if not re.fullmatch(r"[0-9a-f]{40}", base) or not re.fullmatch(r"[0-9a-f]{40}", android_revision):
        raise ValueError("LLVM base and Android revision must be exact Git commits")
    if type(svn) is not int or svn <= 0:
        raise ValueError("LLVM SVN revision must be a positive integer")
    patch_root = android / "patches"
    if patch_root.is_symlink() or not patch_root.is_dir():
        raise ValueError("Expected a regular Android patches directory")
    # Authenticate both byte sequences before decoding or parsing either one.
    report_data = read_pinned(recorded_file, source_info_sha256, "source report")
    manifest_data = read_pinned(patch_root / "PATCHES.json", patch_manifest_sha256, "patch manifest")
    recorded = recorded_paths(report_data.decode("utf-8"), base, android_revision)
    ordered = eligible_paths(json.loads(manifest_data.decode("utf-8")), svn)
    reconcile_paths(ordered, recorded)
    resolved_root = patch_root.resolve()
    plan = []
    for relative in ordered:
        path = patch_root
        for part in PurePosixPath(relative).parts:
            path = path / part
            if path.is_symlink():
                raise ValueError(f"Android change path contains a symlink: {relative}")
        if not path.is_file() or not path.resolve().is_relative_to(resolved_root):
            raise ValueError(f"Missing or unsafe Android change file: {relative}")
        plan.append((relative, path.resolve()))
    return plan


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("android", type=Path)
    parser.add_argument("recorded_file", type=Path)
    parser.add_argument("--base", required=True)
    parser.add_argument("--android-revision", required=True)
    parser.add_argument("--svn", required=True, type=int)
    parser.add_argument("--source-info-sha256", required=True)
    parser.add_argument("--patch-manifest-sha256", required=True)
    parser.add_argument("--check-only", action="store_true")
    args = parser.parse_args(argv)
    try:
        plan = load_patch_plan(args.android, args.recorded_file, base=args.base,
                               android_revision=args.android_revision, svn=args.svn,
                               source_info_sha256=args.source_info_sha256,
                               patch_manifest_sha256=args.patch_manifest_sha256)
        if args.check_only:
            print(f"Validated {len(plan)} Android source changes (check only; no patches applied).")
            return 0
        if not args.source.is_dir():
            raise ValueError(f"LLVM source directory does not exist: {args.source}")
    except (OSError, ValueError) as error:
        parser.exit(1, f"{error}\n")
    for relative, path in plan:
        print(f"Applying Android source change: {relative}", flush=True)
        # Match AOSP llvm_tools.patch_utils.gnu_patch. Failed changes stop here;
        # none is skipped or manually rewritten.
        subprocess.run(["patch", "-f", "-E", "-p1", "--no-backup-if-mismatch", "-i", str(path)],
                       cwd=args.source, check=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
