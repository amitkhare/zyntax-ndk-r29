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

## r28c source-only checkpoint: 2026-09-20

NDK `28.2.13676358` now has its complete LLVM tree prepared at
`/work/releases/28.2.13676358/src/llvm-project` in the existing Linux volume.
Preparation reused the verified cached inputs, reconstructed LLVM base
`3b5e7c83a6e226d5bd7ed2e9b67449b64812074c`, and applied all 51 ordered patches
from Android changes `e727bfb014bd436f581a66a450c939a6983a1fc3`. No patch failed
or was skipped. This does not claim a compiler build, assembled distribution,
device qualification or publication. The r27b and r30 source preparations are
documented separately below.

Four hunks in three upstream patches used fuzz. A read-only audit confirmed
their intended targets:

| Patch / hunk | Context difference from the pinned LLVM base | Verified result |
| --- | --- | --- |
| `cherry/24684bb4a9791145a36a97477eb1fd525a122d8e.patch`, hunk 1, fuzz 2 | The preceding offload conditional is unbraced in the base. | Removes the old sanitizer-argument call in `clang/lib/Driver/ToolChains/Clang.cpp`; the replacement follows `-Xclang` and `-mllvm` forwarding. |
| `Add-stubs-and-headers-for-nl_types-APIs.patch`, hunk 1, fuzz 2 | Profiling includes replaced the old HWLOC include context. | Adds Android-only includes before source collection, outside the profiling condition in `openmp/runtime/src/CMakeLists.txt`. |
| Same patch, hunk 2, fuzz 2 | The assembly list became `LIBOMP_GNUASMFILES`, with an added AIX branch. | Adds Android-only `nltypes_stubs.cpp` inside the full-runtime branch, after platform assembly selection. |
| `Ensure-that-we-use-our-toolchain-s-lipo-and-not-the-.patch`, hunk 1, fuzz 1 | Compiler-launcher arguments were added to the trailing context. | Adds the toolchain `CMAKE_LIPO` argument inside the compiler-rt external build in `clang/runtime/CMakeLists.txt`. |

For each affected file, the complete postpatch bytes matched the untouched
checksum-pinned LLVM archive plus exactly the intended upstream edits. All
insertion anchors were unique; no unintended changes or accidental matches
were found.

The official NDK's `manifest_13624864.xml` pins `external/toolchain-utils` to
`dd1ee45a84cb07337f9d5d0a6769d9b865c6e620`. Its
[`patch_manager.py`](https://android.googlesource.com/platform/external/toolchain-utils/+/dd1ee45a84cb07337f9d5d0a6769d9b865c6e620/llvm_tools/patch_manager.py)
defaults to GNU patch, and
[`patch_utils.py`](https://android.googlesource.com/platform/external/toolchain-utils/+/dd1ee45a84cb07337f9d5d0a6769d9b865c6e620/llvm_tools/patch_utils.py)
does not require zero fuzz or reject successful fuzzy-hunk output. The audited
applications conform to that pinned upstream policy; no source correction or
check relaxation was needed. The separate NDK host patch still requires and
passes a zero-fuzz dry run.

The prepared official NDK, release sources and shared source trees occupy
4,329,787,392 allocated bytes (4.03 GiB). Host C: free space was approximately
42.99 GiB after preparation, superseding the earlier storage snapshot; another
build was active, so the total free-space change is not attributed solely to
source preparation. No storage migration or pruning was performed. Compiler
and runtime qualification remain separate, resource-budgeted steps.

## r27b and r30 source-only checkpoints: 2026-09-20

NDK `27.1.12297006` and `30.0.16248370` now have complete LLVM trees in their
release-specific source directories. The preparations used the checksum-pinned
LLVM archives and authenticated Android patch manifests. They applied all 71
r27b patches from Android changes
`2a4ee244d6dd0dcb8365590b898f7a40ec3cb87a` and all 59 r30 patches from
Android changes `9e20ac0b949feedcfe3da791189310f6ebcbc7a8`; none failed or was
skipped.

An isolated, network-disabled replay extracted only the paths touched by each
authenticated plan from the pinned LLVM base archive, applied the complete plan
in order with the same GNU patch invocation, and compared every resulting path
with the prepared tree. All 215 r27b paths and all 278 r30 paths matched by
type and complete file bytes. No reject or backup file was produced.

r27b used fuzz for four hunks in three upstream patches:

| Patch / hunk | Context difference from the pinned LLVM base | Verified result |
| --- | --- | --- |
| `cherry/55c466da2f2f0baa509eb709b8de8926bd498b9b.patch`, hunk 1, fuzz 2 | The authored terminal `concat_zero_v8bf16` test is absent; the base ends with `extract_v32bf16_v8bf16`. | Adds the exact independent `concat_dup_v8bf16` definition at end of file, outside the preceding function. LLVM IR top-level definition order does not change its meaning. |
| `Add-stubs-and-headers-for-nl_types-APIs.patch`, hunk 1, fuzz 2 | Profiling includes replaced the old HWLOC include context. | Adds Android-only includes before source collection, outside the profiling condition in `openmp/runtime/src/CMakeLists.txt`. |
| Same patch, hunk 2, fuzz 2 | Platform assembly selection became a longer Windows/non-Windows branch and uses `LIBOMP_GNUASMFILES`. | Adds Android-only `nltypes_stubs.cpp` after platform assembly selection, inside the full-runtime branch. |
| `Ensure-that-we-use-our-toolchain-s-lipo-and-not-the-.patch`, hunk 1, fuzz 1 | Compiler-launcher arguments were added to the trailing context. | Adds the toolchain `CMAKE_LIPO` argument inside the compiler-rt external build in `clang/runtime/CMakeLists.txt`. |

The first hunk above was not present in the truncated preparation output and is
recorded here explicitly. Its reduced textual context is not a unique semantic
anchor, so the audit also checked its actual placement and full inserted body.
The other three placements retain their intended enclosing CMake scopes. r30's
complete 59-patch replay produced no fuzzy hunks.

These are source-only checkpoints. They do not claim compiler builds, assembled
distributions, device qualification or publication; those remain separate
release requirements.
