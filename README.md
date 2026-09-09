# Zyntax NDK r29

An Android-ARM64 host port of NDK **r29 / 29.0.14206865**. This is a public,
standalone toolchain project; it does not contain or require Zyntax app source.

**Status: native-build NDK r29 and three exact AGP forks passed USB builds,
including full Zyntax DevDebug and R8-enabled DevRelease self-builds. Optional toolchain packages are
published at `pkg.zyntax.app`; signed indexes and AGP package 1.0.0-2 downloads
were verified on USB.** See [verification](docs/verification.md) and [installation](agp/README.md#explicit-project-selection).

## Design

- Build the r29 compiler from its recorded LLVM source and Android changes.
- Use dynamic Android host executables so ordinary process launch and runtime
  environment handling remain available. Do not reuse fully static host tools.
- Preserve the official target sysroot, runtimes and NDK version metadata.
- Identify the actual host architecture; do not add x86-directory aliases.
- Use Bash for shell entrypoints and explicit tool dependencies.
- Keep exact NDK versions separately installable. NDK r28 is deferred.

The available community r29 archive was inspected, not installed: its compiler,
Make and Python binaries are fully static, and its LLDB entrypoint delegates to
an external executable. It is not the source of release host binaries here.

## Repository roles

- This repository: pinned source inputs, Android-host portability changes,
  build scripts, notices and verification evidence.
- `zyntax-packages`: `.deb` recipes and package builds consuming verified output.
- `zyntax-packages-repo`: signed APT publication at `pkg.zyntax.app`.
- App/SDK: unchanged. Studio UI is deferred until the toolchain works headlessly.

## Build the compiler

Requires Docker with Linux containers and Bash (Git Bash on Windows). The build
uses two compilation jobs and one linker job by default; set `BUILD_JOBS` to
change compilation concurrency. Allow substantial disk space for LLVM sources
and intermediate files. Source builds are resumable in the Docker volume
`zyntax-ndk-r29-work`; deleting that volume discards build progress.

```bash
bash scripts/build.sh
```

Downloads are checked against `sources.tsv` and cached in `.work/downloads`.
The official NDK input's SHA-1 also matches Google's published r29 checksum;
the build pins its SHA-256. LLVM's base and Android changes are taken from the
NDK's own `clang_source_info.md`, applying exactly those changes in the source
manifest's order. Original source archives remain available for provenance.

The first stage produces compiler/tools under `/work/install/linux-aarch64`
inside the Docker volume, with logs at `/work/logs/compiler-build.log`.
Only the tools declared in `build-tools.txt` and Clang resource headers are
built and installed through LLVM's standard component targets.
`scripts/assemble-build-tools.sh` assembles the native build components with
the actual `linux-arm64` host tag and checks host ELF files and entrypoints.
It does not copy desktop executables or produce debugger placeholders.
See [distribution scope and dependencies](docs/build-distribution.md).
The focused USB checks are recorded separately from packaging checks.

LLDB is a separate [optional source-build stage](docs/debugger-build.md), with
checksum-pinned shared package dependencies; it is not compiled or verified yet.
Profiling and shader tools
from the desktop bundle are outside the initial native-build package.

The [AGP source build](agp/README.md) compiles versions 8.12.3, 8.13.0 and 9.2.1
under distinct Maven coordinates. All three source builds and local packaging
passed host checks. AGP 9.2.1 built both native sample projects on Android.
AGP 8.12.3 and 8.13.0 then built the complete unchanged Zyntax 0.9.4 DevDebug
project with its declared NDK r29 and Gradle 8.14.3 wrapper. Native compilation,
stripping, signing and APK checks passed; the APK was not installed or published.
DevRelease APK/AAB builds also passed with test-only signing and Bundletool
validation. R8 reduced DEX from 16,155,288 to 2,441,276 bytes. Generated app
artifacts remain private and uninstalled; this is not a release-runtime test.

The unpublished AGP work adds typed missing-NDK diagnostics and finalized CMake
settings through existing AGP models. The `-zyntax.2` NDK diagnostic check and
`-zyntax.3` CMake model check passed on USB; all three exact AGP/model source
builds passed. A shared recipe builds one public model dependency, without duplicate
API classes. App/SDK are unchanged. Native package resolution and complete automatic
setup remain unfinished; model values alone do not establish tool availability.

The [Android-qualified Gradle distribution](gradle/distribution/README.md) is
source-built and passes two-build USB native/terminal/watcher integration checks.
Default F2FS watching now retains unchanged snapshots and detects edits across
the real nested Android mount table, without an explicit watching flag.
Distribution publication remains pending. No app or SDK code changed.

## Roadmap

- [x] Inspect the r29 candidate and reject static tools and fallback wrappers.
- [x] Verify publishing authentication and the connected USB device.
- [x] Pin official r29 source inputs and preserve source/license provenance.
- [x] Build dynamic Android-ARM64 Clang, LLD and LLVM binary utilities.
- [x] Port NDK host discovery and Bash entrypoints without architecture aliases.
- [x] Audit the native-build tools and preserve distribution notices.
- [x] Address AGP's desktop-only NDK host lookup through proper tooling source
      changes, not app code, binary modification or a disguised host directory.
- [x] Package the exact NDK revision as a coinstallable `.deb`.
- [x] Verify CMake and `ndk-build` on USB, without UI navigation.
- [x] Verify native sample APK/AAB builds and signatures; keys stay outside
      projects under the app's `~/.secrets`.
- [x] Compile the unchanged Zyntax JNI component using packaged NDK r29 and
      explicit AGP 8.12.3 selection, without publishing an app APK.
- [x] Verify Zyntax's complete Android project with its declared r29; do not
      install or publish the generated APK.
- [x] Publish the verified packages and check signed repository installation.
- [x] Verify R8-enabled DevRelease APK/AAB artifacts with test-only signing.
- [x] Verify source-built Android Gradle native-platform and file-events components.
- [x] Verify native terminal components and source-built Android Gradle integration.
- [x] Enable and verify default F2FS watching in the Android distribution.
- [x] Expose and verify typed missing-NDK sync diagnostics without weakening build errors.
- [x] Expose and verify finalized CMake settings through the existing AGP public model.
- [ ] Publish the verified Android Gradle distribution after release approval.

Both sample projects now compile native libraries and produce verified signed
release APKs/AABs. Their device copies retain the earlier compile SDK 37 change
required by their declared AndroidX dependencies, plus the requested native
test module. This is not a claim that the original projects were unchanged.

`tests/check-native.bash` is the focused device check: it builds one small C++
shared library with CMake and `ndk-build`, then checks linking, loading and C++
exceptions. It requires explicit tool paths and a new private output directory;
it does not install packages, navigate the UI or touch signing keys.

## License

Original infrastructure is [Apache-2.0](LICENSE). Upstream software keeps its
own licenses; see [NOTICE.md](NOTICE.md). Generated sources, binaries and local
credentials are excluded from Git.
