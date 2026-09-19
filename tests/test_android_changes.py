"""Pure fixtures for release-pinned Android patch ordering; no source builds."""

import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[1] / "scripts/apply-android-changes.py"
SPEC = importlib.util.spec_from_file_location("android_changes", SCRIPT)
changes = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(changes)

BASE = "a" * 40
ANDROID_REVISION = "b" * 40


def entry(relative, start=100, end=200, platforms=None):
    return {"rel_patch_path": relative, "platforms": platforms or ["android"],
            "version_range": {"from": start, "until": end}}


class AndroidChangesTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.android = self.root / "android"
        self.patch_root = self.android / "patches"
        self.patch_root.mkdir(parents=True)
        self.report = self.root / "clang_source_info.md"
        self.source = self.root / "source"
        self.source.mkdir()

    def fixture(self, entries, reported=None):
        for item in entries:
            relative = item["rel_patch_path"]
            try:
                changes.patch_path(relative)
            except ValueError:
                continue
            path = self.patch_root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("fixture patch\n", encoding="utf-8")
        manifest = self.patch_root / "PATCHES.json"
        manifest.write_text(json.dumps(entries), encoding="utf-8")
        if reported is None:
            reported = [item["rel_patch_path"] for item in entries]
        prefix = f"https://android.googlesource.com/toolchain/llvm_android/+/{ANDROID_REVISION}/patches/"
        text = f"Base revision: [{BASE}](https://github.com/llvm/llvm-project/commits/{BASE})\n\n"
        text += "\n".join(f"- [fixture]({prefix}{relative})" for relative in reported)
        self.report.write_text(text, encoding="utf-8")
        self.options = dict(base=BASE, android_revision=ANDROID_REVISION, svn=150,
                            source_info_sha256=hashlib.sha256(self.report.read_bytes()).hexdigest(),
                            patch_manifest_sha256=hashlib.sha256(manifest.read_bytes()).hexdigest())

    def plan(self):
        return changes.load_patch_plan(self.android, self.report, **self.options)

    def test_manifest_order_and_version_platform_filtering(self):
        self.fixture([entry("z.patch"), entry("future.patch", start=151),
                      entry("other.patch", platforms=["chromiumos"]),
                      entry("expired.patch", end=150), entry("a.patch", start=150, end=None)],
                     ["a.patch", "z.patch"])
        self.assertEqual([relative for relative, _ in self.plan()], ["z.patch", "a.patch"])

    def test_truthful_upstream_hyphen_suffix_formatter_defect(self):
        names = ["79a32609759af317a62184c2c7b1300263a336c8-v0.patch",
                 "9a2fd97d391caf1060e303f636d7113501788d2f-r530567.patch",
                 "b433076fcbacba8a3b91446390bbea5843322bcd-v2.patch"]
        self.fixture([entry(f"cherry/{name}") for name in names], names)
        self.assertEqual([relative for relative, _ in self.plan()], [f"cherry/{name}" for name in names])

    def test_modern_exact_paths_and_legacy_hex_paths(self):
        names = ["cherry/fix-v2.patch", "cherry/abc123_v2.patch"]
        self.fixture([entry(name) for name in names])
        self.assertEqual(len(self.plan()), 2)
        self.assertEqual(changes.legacy_report_path("cherry/abc123_v2.patch"), "cherry/abc123_v2.patch")

    def test_no_arbitrary_basename_fallback(self):
        self.fixture([entry("nested/abc123.patch")], ["abc123.patch"])
        with self.assertRaisesRegex(ValueError, "Unknown or ambiguous"):
            self.plan()

    def test_ambiguous_formatter_alias_rejected(self):
        self.fixture([entry("cherry/fix-v2.patch"), entry("fix-v2.patch")], ["fix-v2.patch"])
        with self.assertRaisesRegex(ValueError, "ambiguous"):
            self.plan()

    def test_duplicate_report_path_rejected(self):
        self.fixture([entry("a.patch")], ["a.patch", "a.patch"])
        with self.assertRaisesRegex(ValueError, "duplicate recorded"):
            self.plan()

    def test_duplicate_alias_for_same_patch_rejected(self):
        self.fixture([entry("cherry/fix-v2.patch")], ["cherry/fix-v2.patch", "fix-v2.patch"])
        with self.assertRaisesRegex(ValueError, "Duplicate recorded"):
            self.plan()

    def test_duplicate_manifest_path_rejected(self):
        self.fixture([entry("a.patch"), entry("a.patch")], ["a.patch"])
        with self.assertRaisesRegex(ValueError, "duplicate eligible"):
            self.plan()

    def test_missing_and_extra_report_paths_rejected(self):
        for reported in (["a.patch"], ["a.patch", "b.patch", "extra.patch"]):
            with self.subTest(reported=reported):
                self.fixture([entry("a.patch"), entry("b.patch")], reported)
                with self.assertRaises(ValueError):
                    self.plan()

    def test_source_report_hash_checked_before_parsing(self):
        self.fixture([entry("a.patch")])
        self.report.write_bytes(b"\xffinvalid source report")
        with self.assertRaisesRegex(ValueError, "source report SHA-256 mismatch"):
            self.plan()

    def test_manifest_hash_checked_before_report_parsing(self):
        self.fixture([entry("a.patch")])
        self.report.write_bytes(b"\xffinvalid source report")
        self.options["source_info_sha256"] = hashlib.sha256(self.report.read_bytes()).hexdigest()
        (self.patch_root / "PATCHES.json").write_bytes(b"not json")
        with self.assertRaisesRegex(ValueError, "patch manifest SHA-256 mismatch"):
            self.plan()

    def test_wrong_base_and_android_revision_rejected(self):
        for field in ("base", "android_revision"):
            with self.subTest(field=field):
                self.fixture([entry("a.patch")])
                self.options[field] = "c" * 40
                with self.assertRaisesRegex(ValueError, "revision"):
                    self.plan()

    def test_unsafe_paths_rejected(self):
        for relative in ("../a.patch", "/a.patch", "C:/a.patch", "cherry\\a.patch", "cherry/./a.patch"):
            with self.subTest(relative=relative):
                self.fixture([entry(relative)], ["a.patch"])
                with self.assertRaisesRegex(ValueError, "Invalid Android change path"):
                    self.plan()

    def test_missing_patch_rejected_before_application(self):
        self.fixture([entry("a.patch"), entry("b.patch")])
        (self.patch_root / "b.patch").unlink()
        with self.assertRaisesRegex(ValueError, "Missing or unsafe"):
            self.plan()

    def test_invalid_selection_metadata_rejected(self):
        for start, end in ((True, 200), (200, 100), ("100", 200)):
            with self.subTest(start=start, end=end):
                self.fixture([entry("a.patch", start=start, end=end)])
                with self.assertRaisesRegex(ValueError, "version range"):
                    self.plan()

    def test_symlink_patch_rejected(self):
        self.fixture([entry("a.patch")])
        target = self.root / "outside.patch"
        target.write_text("outside", encoding="utf-8")
        path = self.patch_root / "a.patch"
        path.unlink()
        try:
            path.symlink_to(target)
        except OSError as error:
            self.skipTest(f"Symlinks unavailable: {error}")
        with self.assertRaisesRegex(ValueError, "symlink"):
            self.plan()

    def arguments(self):
        argv = [str(self.source), str(self.android), str(self.report)]
        for key, value in self.options.items():
            argv += ["--" + key.replace("_", "-"), str(value)]
        return argv

    def test_check_only_never_applies(self):
        self.fixture([entry("a.patch")])
        with patch.object(changes.subprocess, "run") as run, patch("builtins.print"):
            self.assertEqual(changes.main(self.arguments() + ["--check-only"]), 0)
            run.assert_not_called()

    def test_apply_preserves_exact_patch_command_and_order(self):
        self.fixture([entry("z.patch"), entry("a.patch")], ["a.patch", "z.patch"])
        with patch.object(changes.subprocess, "run") as run, patch("builtins.print"):
            self.assertEqual(changes.main(self.arguments()), 0)
        self.assertEqual([Path(call.args[0][-1]).name for call in run.call_args_list], ["z.patch", "a.patch"])
        for call in run.call_args_list:
            self.assertEqual(call.args[0][:-1], ["patch", "-f", "-E", "-p1", "--no-backup-if-mismatch", "-i"])
            self.assertEqual(call.kwargs, {"cwd": self.source, "check": True})

    def test_release_arguments_are_required(self):
        with patch("sys.stderr"), self.assertRaises(SystemExit) as exit_error:
            changes.main([str(self.source), str(self.android), str(self.report)])
        self.assertEqual(exit_error.exception.code, 2)


if __name__ == "__main__":
    unittest.main()
