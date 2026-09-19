# Exact source reconstruction

The source manifest is `releases.json`. Each release uses its own official
Linux archive as a cross-build input and preserves the official target sysroot,
resource libraries, notices and version metadata. Desktop host executables are
not installed in the Android distribution. Existing qualified r29 output is
unchanged; preparing another release does not qualify it for publication.

## Source provenance

Google's [SDK repository index](https://dl.google.com/android/repository/repository2-1.xml)
supplies exact NDK archive URLs, sizes and SHA-1 checksums. The official archive
contains `clang_source_info.md`, `AndroidVersion.txt` and the original XML build
manifests. These identify the LLVM base and Android patch repository commit.

Archive SHA-256 checksums in this repository pin acquired payloads. Where Google
publishes only SHA-1, initial acquisition validates that checksum and size over
HTTPS before recording SHA-256. A locally calculated SHA-256 is not represented
as an independently published Google value.

Both `clang_source_info.md` and `patches/PATCHES.json` have exact SHA-256 pins.
The latter determines application order and selects `android` patches whose
version interval contains the release's LLVM SVN revision. The human-readable
report is sorted and must describe exactly that same complete set.

Older AOSP [`PatchInfo.format_patch_line`](https://android.googlesource.com/toolchain/llvm_android/+/2a4ee244d6dd0dcb8365590b898f7a40ec3cb87a/source_manager.py)
emits `cherry/` only when a filename matches its hexadecimal hash pattern with
an optional `_v<number>` suffix. Three hyphen-suffixed patch names in r27b/r28c
therefore have report links missing their real `cherry/` directory. Validation
uses the exact manifest path and that known formatter, not arbitrary basename
matching or skipped patches. Any unrecognized discrepancy fails preparation.

## Cache and build boundaries

- `.work/downloads`: one checksum-verified input cache in this repository.
- `/work/ndk/android-ndk-<tag>`: each exact official cross-compiler/sysroot input.
- `/work/src/common`: shared, versioned zlib and Zstandard source directories.
- `/work/releases/<revision>/src`: exact patched LLVM and Android patch sources.
- `/work/releases/<revision>/build`: release-specific host generators and target
  CMake caches; never reused by another revision.
- `/work/releases/<revision>/install`, `dist`, `logs`: corresponding outputs.

The historical Docker volume name remains `zyntax-ndk-r29-work` to preserve its
cached official r29 input. It holds separate exact-revision subdirectories;
it does not imply that another release uses r29's compiler or target files.

Source preparation and patch validation do not execute Android programs. Actual
compiler builds, assembly/ELF checks and a focused native CMake/ndk-build check
are separate release requirements. No additional release is published merely
because its recipe or source validation passes.

## Source checkpoint: 2026-09-19

| Release | Exact NDK revision | Clang | Ordered Android patches | Official NDK + LLVM source size |
| --- | --- | --- | ---: | ---: |
| r27b | 27.1.12297006 | r522817b / 18 | 71 | 3.37 GiB |
| r28c | 28.2.13676358 | r530567e / 19 | 51 | 3.60 GiB |
| r29 | 29.0.14206865 | r563880c / 21 | 46 | 3.95 GiB |
| r30 | 30.0.16248370 | r574158c / 21 | 59 | 3.85 GiB |

All 14 distinct archive inputs are cached once and match the manifest SHA-256
pins. New official NDK ZIPs also passed Google's exact sizes and SHA-1 checks.
Their actual embedded source reports match the independently read official
metadata pins, and all ordered patch files exist in the selected Android source
archives. Both r30 XML provenance files are present. No patch was omitted.

The existing shared host patch passes `patch --dry-run --batch --fuzz=0` against
all four exact official NDK build trees. r27b's legacy CMake hunk has a nine-line
offset only; all source context matches without fuzz. No new host patch or
version-specific workaround was necessary. The 25 focused Python manifest and
patch-plan tests pass; Bash scripts pass syntax checks.

This checkpoint does **not** claim that the three additional LLVM trees have
been fully extracted/patched or their compilers built. Qualification awaits
adequate Linux build storage and the serial compiler lane. The current Docker
disk is backed by C:, with roughly 25 GiB physically free; its much larger
logical ext4 capacity is not actual host free space. No caches were deleted or
storage settings changed. The exact input-only sizes above exclude CMake build
trees, installed tools and assembly copies. Budget approximately 20–30 GiB for
one active Release build; that is a planning estimate, not a measured bound.

The host's D: source directory is currently case-insensitive. Do not substitute
an unverified Windows bind-mounted build tree for Linux filesystem semantics.
[Docker recommends Linux filesystem storage for container build inputs](https://docs.docker.com/desktop/features/wsl/best-practices/);
a supported Docker disk-location change can preserve the existing Linux volume
and caches, but requires explicit user approval and stopped workloads.
