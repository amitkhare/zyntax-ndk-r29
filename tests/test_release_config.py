"""Focused manifest and generated provenance checks; no compiler or downloads."""
import contextlib
import copy
import importlib.util
import io
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parent.parent
SPEC = importlib.util.spec_from_file_location("release_config", ROOT / "scripts/release-config.py")
CONFIG = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CONFIG)


class ReleaseConfigTests(unittest.TestCase):
    def setUp(self):
        self.manifest = json.loads((ROOT / "releases.json").read_text())

    def test_all_releases_have_distinct_exact_identity_and_complete_pins(self):
        revisions = set()
        for tag in self.manifest["releases"]:
            selected, release, sources = CONFIG.load_release(tag, self.manifest)
            self.assertEqual(tag, selected)
            self.assertNotIn(release["revision"], revisions)
            revisions.add(release["revision"])
            self.assertEqual(5, len(sources))

    def test_r29_baseline_keeps_exact_original_inputs(self):
        _, release, sources = CONFIG.load_release("r29", self.manifest)
        self.assertEqual("29.0.14206865", release["revision"])
        self.assertEqual("4abbbcdc842f3d4879206e9695d52709603e52dd68d3c1fff04b3b5e7a308ecf", sources["ndk"]["sha256"])
        self.assertEqual("386af4a5c64ab75eaee2448dc38f2e34a40bfed0", release["llvmBase"])
        self.assertEqual("1dab3288f660d43a6cb2479107e2b54b3ab0a2a1", release["androidChanges"])

    def test_unknown_version_is_not_mapped_to_another(self):
        with self.assertRaisesRegex(ValueError, "No exact source recipe"):
            CONFIG.load_release("r999", self.manifest)

    def test_unsafe_or_unpinned_inputs_are_rejected(self):
        for field, value in (("name", "../source.tar.gz"), ("sha256", "unverified"), ("url", "http://example.com/source")):
            with self.subTest(field=field):
                manifest = copy.deepcopy(self.manifest)
                manifest["releases"]["r29"]["sources"]["llvm"][field] = value
                with self.assertRaises(ValueError):
                    CONFIG.load_release("r29", manifest)

    def test_wrong_ndk_or_source_commit_is_rejected(self):
        for key, value in (("ndk", "https://example.com/other.zip"), ("llvm", "https://example.com/other.tar.gz")):
            manifest = copy.deepcopy(self.manifest)
            manifest["releases"]["r29"]["sources"][key]["url"] = value
            if key == "ndk":
                manifest["releases"]["r29"]["sources"][key]["name"] = "android-ndk-r30-linux.zip"
            with self.assertRaises(ValueError):
                CONFIG.load_release("r29", manifest)

    def test_selected_tools_have_only_the_real_clang_major_alias(self):
        for tag, release in self.manifest["releases"].items():
            output = io.StringIO()
            with contextlib.redirect_stdout(output):
                CONFIG.emit(tag, "tools")
            tools = output.getvalue().splitlines()
            self.assertEqual(1, tools.count(f'clang-{release["clangMajor"]}'))
            self.assertEqual(len(tools), len(set(tools)))
            self.assertEqual(1, sum(tool.startswith("clang-") and tool[6:].isdigit() for tool in tools))


if __name__ == "__main__":
    unittest.main()
