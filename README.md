# Zyntax Android-host NDK

Source-built Android-ARM64 host ports of exact Android NDK releases. This is a public,
standalone toolchain project; it does not contain or require Zyntax app source.

**Status: native-build NDK r29 passed USB CMake/ndk-build checks and Android
APK/AAB builds. Its optional package is published at `pkg.zyntax.app`.** See
[verification](docs/verification.md). AGP is a different tool and is maintained
in the separate [zyntax-agp repository](https://github.com/amitkhare/zyntax-agp).

## Design

- Build each compiler from that release's recorded LLVM source and Android changes.
- Use dynamic Android host executables so ordinary process launch and runtime
  environment handling remain available. Do not reuse fully static host tools.
- Preserve the official target sysroot, runtimes and NDK version metadata.
- Identify the actual host architecture; do not add x86-directory aliases.
- Use Bash for shell entrypoints and explicit tool dependencies.
- Keep exact NDK versions separately installable; never replace a project's pin
  with another release just because its compiler is already installed.

The available community r29 archive was inspected, not installed: its compiler,
Make and Python binaries are fully static, and its LLDB entrypoint delegates to
an external executable. It is not the source of release host binaries here.

## Repository roles

- This repository: pinned source inputs, Android-host portability changes,
  build scripts, notices and verification evidence.
- `zyntax-packages`: `.deb` recipes and package builds consuming verified output.
- `zyntax-packages-repo`: signed APT publication at `pkg.zyntax.app`.
- [`zyntax-gradle`](https://github.com/amitkhare/zyntax-gradle): separate Android
  Gradle runtime sources, build recipes and distribution releases.
- [`zyntax-agp`](https://github.com/amitkhare/zyntax-agp): separate Android Gradle
  Plugin and public model source builds, exact-version selector and AGP caches.
- App/SDK: unchanged. Studio UI is deferred until the toolchain works headlessly.

## Build the compiler

Requires Docker with Linux containers and Bash (Git Bash on Windows). The build
uses two compilation jobs and one linker job by default; set `BUILD_JOBS` to
change compilation concurrency. Allow substantial disk space for LLVM sources
and intermediate files. Source builds are resumable in the Docker volume
`zyntax-ndk-r29-work`; deleting that volume discards build progress.

```bash
bash scripts/build.sh
# Select an exact additional release; setup does not alter any project.
NDK_RELEASE=r27b bash scripts/build.sh
```

`releases.json` is the single source of exact input/version pins. Downloads are
checked by SHA-256 and cached in `.work/downloads`; matching archives are reused,
not downloaded per project or per build. Initial official NDK acquisitions also
verify Google's published byte length and SHA-1 over HTTPS. Newly recorded
SHA-256 values pin the acquired bytes; they are not claimed to be separately
published Google checksums. Immutable LLVM and Android source commit URLs are
pinned by SHA-256 after acquisition. The original source archives are retained.

Each release uses its own exact official Linux NDK as the **build-host** cross
compiler, not an Android runtime substitute. Host CMake, Ninja and the native
source-generator compiler are shared. Sources, CMake caches, installed compiler
outputs and logs are isolated under `/work/releases/<exact-revision>/`; official
NDKs remain under `/work/ndk/android-ndk-<release>`. Common zlib/Zstandard source
archives and extracted sources are shared, while target libraries are built
separately. A changed source pin refuses reuse of that revision's prepared tree.

LLVM's base, Clang revision and Android patch manifest are checked against the
NDK's own source metadata. Exact hashed manifests determine the ordered patch
set. For older Android releases, source-report links are matched using AOSP's
documented filename formatter; an unknown, missing or duplicate patch is fatal.
No failed patch is skipped. See [source preparation](docs/source-preparation.md).

The compiler output is `install/linux-aarch64` inside the release directory,
with logs at `logs/compiler-build.log`. Only the tools in `build-tools.txt`,
the selected release's real `clang-<major>` alias and Clang resource headers are
built and installed through LLVM's standard component targets.
`scripts/assemble-build-tools.sh` assembles the native build components with
the actual `linux-arm64` host tag and checks host ELF files and entrypoints.
It does not copy desktop executables or produce debugger placeholders.
See [distribution scope and dependencies](docs/build-distribution.md).
The focused USB checks are recorded separately from packaging checks.

LLDB is a separate [optional source-build stage](docs/debugger-build.md), with
checksum-pinned shared package dependencies; the prepared recipe is r29-only
and has not been compiled or verified yet.
Profiling and shader tools
from the desktop bundle are outside the initial native-build package.

AGP source and its ignored build cache moved to `zyntax-agp` on 2026-09-19,
preserving AGP-only Git history and existing output bytes. They are no longer
built in this repository. The existing [verification record](docs/verification.md)
retains historical integration evidence, including native APK/AAB self-builds;
moving repositories does not qualify new artifacts or require rebuilding old ones.

## Roadmap

Additional r27b, r28c and r30 source recipes and verified input caches are ready. They are **not
qualified or published** until the exact compiler, host source patch, assembly
and focused Android native-build checks pass. The existing verified r29 package
remains valid and is not rebuilt or changed merely by adding source recipes.

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
- [x] Separate AGP source/history/cache into its own repository; keep NDK ownership here.
- [x] Pin exact r27b, r28c and r30 inputs; validate provenance and the shared host patch.
- [ ] Reconstruct each complete LLVM tree with its exact ordered Android patches.
- [ ] Build and qualify those exact additional Android-host NDK distributions.
- [ ] Publish verified additional revisions as coinstallable packages.

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
