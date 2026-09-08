"""Apply exactly the Android changes recorded by the pinned NDK distribution."""
import json
from pathlib import Path
import re
import subprocess
import sys

source, android, recorded_file = map(Path, sys.argv[1:])
recorded = recorded_file.read_text()
base = "386af4a5c64ab75eaee2448dc38f2e34a40bfed0"
android_revision = "1dab3288f660d43a6cb2479107e2b54b3ab0a2a1"
if not recorded.startswith(f"Base revision: [{base}]"):
    raise SystemExit("Unexpected r29 LLVM base revision")

prefix = f"https://android.googlesource.com/toolchain/llvm_android/+/{android_revision}/patches/"
paths = re.findall(re.escape(prefix) + r"([^\s)]+)", recorded)
if not paths or len(paths) != len(set(paths)):
    raise SystemExit("Missing or duplicate recorded Android changes")
if len(paths) != len(re.findall(r"https://android.googlesource.com/", recorded)):
    raise SystemExit("Recorded changes reference an unexpected Android source revision")

# PATCHES.json records application order; the human-readable report is sorted.
entries = json.loads((android / "patches/PATCHES.json").read_text())
ordered = [entry["rel_patch_path"] for entry in entries if entry["rel_patch_path"] in paths]
if len(ordered) != len(paths) or set(ordered) != set(paths):
    raise SystemExit("Android change manifest differs from the NDK source report")
for relative in ordered:
    if Path(relative).is_absolute() or ".." in Path(relative).parts:
        raise SystemExit("Invalid Android change path")
    print(f"Applying Android source change: {relative}", flush=True)
    # Match AOSP llvm_tools.patch_utils.gnu_patch, including normal GNU patch
    # context handling. No failed change is skipped or manually rewritten.
    subprocess.run([
        "patch", "-f", "-E", "-p1", "--no-backup-if-mismatch", "-i",
        str((android / "patches" / relative).resolve()),
    ], cwd=source, check=True)
