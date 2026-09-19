"""Read the single, checksum-pinned NDK release manifest for the Bash pipeline."""
import argparse
import json
from pathlib import Path, PurePosixPath
import re

ROOT = Path(__file__).resolve().parent.parent


def require(pattern, value, label):
    if not isinstance(value, str) or not re.fullmatch(pattern, value):
        raise ValueError(f"Invalid {label}: {value!r}")


def load_release(tag, manifest=None):
    manifest = manifest or json.loads((ROOT / "releases.json").read_text())
    if manifest["schemaVersion"] != 1:
        raise ValueError("Unsupported release manifest schema")
    tag = tag or manifest["defaultRelease"]
    require(r"r[0-9]+[a-z]?", tag, "release tag")
    if tag not in manifest["releases"]:
        raise ValueError(f"No exact source recipe for NDK {tag}")
    release = manifest["releases"][tag]
    require(r"[0-9]+\.[0-9]+\.[0-9]+", release["revision"], "NDK revision")
    require(r"r[0-9]+[a-z]*", release["clangRevision"], "Clang revision")
    for field in ("clangMajor", "llvmSvnRevision"):
        if type(release[field]) is not int or release[field] < 1:
            raise ValueError(f"Invalid {field}")
    for field in ("llvmBase", "androidChanges"):
        require(r"[0-9a-f]{40}", release[field], field)
    for field in ("sourceInfoSha256", "patchManifestSha256"):
        require(r"[0-9a-f]{64}", release[field], field)
    require(r"patches/[A-Za-z0-9_.-]+\.patch", release["hostPatch"], "host source patch")
    patch = PurePosixPath(release["hostPatch"])
    if patch.is_absolute() or ".." in patch.parts or patch.parts[0] != "patches":
        raise ValueError("Host patch must be a repository-relative source patch")
    if not release["provenanceFiles"]:
        raise ValueError("Missing original source manifests")
    for name in release["provenanceFiles"]:
        require(r"[a-z_]+[0-9]+\.xml", name, "source manifest filename")
    sources = {**release["sources"], **manifest["sharedSources"]}
    if set(sources) != {"ndk", "llvm", "android", "zlib", "zstd"}:
        raise ValueError("Expected exact NDK, LLVM, Android patches, zlib and zstd inputs")
    names = set()
    for source in sources.values():
        require(r"[A-Za-z0-9][A-Za-z0-9_.-]+", source["name"], "archive filename")
        require(r"[0-9a-f]{64}", source["sha256"], "archive SHA256")
        require(r"https://[^\s]+", source["url"], "archive HTTPS URL")
        if source["name"] in names:
            raise ValueError("Duplicate source archive filename")
        names.add(source["name"])
        if "sha1" in source:
            require(r"[0-9a-f]{40}", source["sha1"], "official SHA1")
        if "size" in source and (type(source["size"]) is not int or source["size"] < 1):
            raise ValueError("Invalid official input size")
    if sources["ndk"]["name"] != f"android-ndk-{tag}-linux.zip":
        raise ValueError("NDK input does not match the exact selected release")
    if sources["ndk"]["url"] != f"https://dl.google.com/android/repository/android-ndk-{tag}-linux.zip":
        raise ValueError("NDK input must use the exact official archive URL")
    for key, field in (("llvm", "llvmBase"), ("android", "androidChanges")):
        expected_url = (f'https://github.com/llvm/llvm-project/archive/{release[field]}.tar.gz'
                        if key == "llvm" else f'https://android.googlesource.com/toolchain/llvm_android/+archive/{release[field]}.tar.gz')
        if sources[key]["url"] != expected_url:
            raise ValueError(f"{key} input does not identify its exact source commit")
    return tag, release, sources


def emit(tag, action):
    tag, release, sources = load_release(tag)
    if action == "sources":
        for source in sources.values():
            print(f'{source["name"]}\t{source["sha256"]}\t{source["url"]}')
    elif action == "environment":
        fields = {
            "NDK_RELEASE": tag, "NDK_REVISION": release["revision"],
            "CLANG_REVISION": release["clangRevision"], "CLANG_MAJOR": release["clangMajor"],
            "LLVM_BASE": release["llvmBase"], "ANDROID_CHANGES": release["androidChanges"],
            "LLVM_SVN": release["llvmSvnRevision"], "HOST_PATCH": release["hostPatch"],
            "SOURCE_INFO_SHA256": release["sourceInfoSha256"],
            "PATCH_MANIFEST_SHA256": release["patchManifestSha256"],
        }
        fields.update({f"{key.upper()}_ARCHIVE": value["name"] for key, value in sources.items()})
        fields.update({f"{key.upper()}_SHA256": sources[key]["sha256"] for key in ("zlib", "zstd")})
        for key, value in fields.items():
            print(f"{key}\t{value}")
    elif action == "provenance":
        print("\n".join(release["provenanceFiles"]))
    elif action == "tools":
        for tool in (ROOT / "build-tools.txt").read_text().splitlines():
            print(tool)
            if tool == "clang++":
                print(f'clang-{release["clangMajor"]}')
    else:
        print(json.dumps({"release": tag, **release, "sources": sources}, indent=2) + "\n", end="")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("release", help="Exact NDK release, such as r29")
    parser.add_argument("action", choices=("environment", "sources", "provenance", "tools", "json"))
    args = parser.parse_args()
    try:
        emit(args.release, args.action)
    except (KeyError, ValueError) as error:
        parser.error(str(error))
