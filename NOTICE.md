# Licensing scope

Copyright 2026 Zyntax contributors.

The original build infrastructure and documentation in this repository are
licensed under Apache-2.0; see [LICENSE](LICENSE). This does not relicense the
Android NDK, LLVM, their dependencies or any upstream source changes.

Upstream components retain their own copyright notices and licenses, including
LLVM's Apache-2.0 license with LLVM exceptions and the Android NDK's component
notices. Source changes retain the license of the affected upstream component.
Generated distributions must carry the applicable complete license/notice files
and exact source provenance. Copyleft components require their corresponding
source and build instructions when distributed, according to their licenses.

## Native build distribution

| Component | License material carried with the distribution |
| --- | --- |
| Official r29 build files, target headers and libraries | Original `NOTICE`, `NOTICE.toolchain`, toolchain notice and source-tree notices |
| Source-built LLVM/Clang/LLD and LLVM utilities | `LLVM-LICENSE.TXT`, including LLVM exceptions and its component notices |
| Statically linked zlib 1.3.1 | `zlib-LICENSE` |
| Statically linked Zstandard 1.5.6 | `zstd-LICENSE`; the BSD license option is selected |
| Original port infrastructure | `port-LICENSE` and this notice |

The exact archives are recorded in `sources.tsv`; the original toolchain source
manifest is preserved. Modified NDK source files are identified by the included
source patch. The build-only distribution does not include GNU Make, Python,
SWIG, LLDB, profiling or shader tools. Shared package dependencies retain their
own licenses and are not relicensed or duplicated by this package.

The separate AGP and public builder-model source builds preserve their upstream
notices and provide their prepared sources artifacts. Neither contains Zyntax app code.

This public repository contains no Zyntax app implementation, signing keys or
credentials. The NDK port is separate tooling, not app code. Publication is
blocked until the actual distribution's notices and source obligations are
verified; the repository license alone is not a redistribution audit.
