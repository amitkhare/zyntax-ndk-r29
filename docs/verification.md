# Native-build verification

Focused Android ARM64 USB checks completed on 2026-09-09. Execution used the
existing app-private runtime; no UI navigation, app/SDK changes or app release.

| Check | Result |
| --- | --- |
| Host tools | Android AArch64 dynamic PIE; platform-only shared dependencies |
| CMake 4.4.3 / Ninja 1.13.2 | C++ shared library and executable built; result 42, including exceptions |
| ndk-build / Make 4.4.1 / Python 3.14.6 | Same shared library built and loaded successfully |
| Groovy DSL, AGP 9.2.1 fork / Gradle 9.4.1 | Native debug APK, release APK and release AAB built |
| Kotlin DSL, AGP 9.2.1 fork / Gradle 9.4.1 | Native debug APK, release APK and release AAB built |
| Both samples | All four default ABIs compiled; ARM64 library present in APKs/AABs |
| Signing | Debug APK signatures verified; release APK alignment/signatures and strict AAB signatures verified |
| AGP 8.12.3 fork / Gradle 8.13 | Unchanged Zyntax JNI source compiled with packaged NDK and explicit NDK directory |
| AGP 8.12.3 and 8.13.0 forks / Gradle 8.14.3 | Complete unchanged Zyntax 0.9.4 DevDebug self-build, native compilation/stripping, signing and APK checks passed |
| Same toolchain, DevRelease | R8, resource shrinking, test-signed APK/AAB, mapping and Bundletool validation passed |

JDK 21.0.12 ran Gradle. Signing keys stayed outside projects under `~/.secrets`.
No generated Zyntax APK was installed or published. The first JNI check used a
private minimal library fixture; the later full-project result is recorded below.

Sample inputs:

- [Groovy DSL](https://github.com/zyntax-projects/android-groovy-dsl-empty-activity/tree/1cded402eca4650883be6c3f210fabe7a712fb3c).
- [Kotlin DSL](https://github.com/zyntax-projects/android-kotlin-dsl-empty-activity/tree/9ed243f589835293c09ddd468f567eac85754463).

Device copies use compile SDK 37 for their declared AndroidX dependencies and
the requested small C++/CMake addition, with `ndkVersion = 29.0.14206865`.
Native CMake selection uses `cmake.dir`; AGP fork selection is explicit through
the documented init script. No desktop host-directory aliases or binary edits.

## Missing-NDK sync diagnostics

On 9 September 2026, the `-zyntax.2` AGP source builds passed for 8.12.3, 8.13.0
and 9.2.1. Each used fresh fork-qualified work directories and executed nine
tasks; upstream plugin versions and notices were preserved. The local runtime
JARs have unique entry paths and these SHA-256 identities:

| Fork | Runtime JAR SHA-256 |
| --- | --- |
| 8.12.3-zyntax.2 | `ed39858233b46c2ef83cd186aa4d7e43e5771005fec8de21ab4af711f4be930d` |
| 8.13.0-zyntax.2 | `6357de2fb09a8a80ae5e680257279e9f1955c7aa906436f0802989a3ad9b3631` |
| 9.2.1-zyntax.2 | `d2eb6ee6420672446d0eb08f094227a26548a86af4ea488032ff564921484cab` |

One corrected USB run passed all four configuration-only cases in **261.869s**
(`OK (1 test)`). It selected the 8.12.3 fork explicitly with the native-verified
Android Gradle `8.14.3-android-1-20260909081124+0000` and app-private Java 21.
An isolated SDK copied genuine platform 36 and build-tools 35.0.0; downloads
were disabled and no Gradle build task was requested.

- A later DSL finalizer selected NDK 29.0.14206865. V2 sync returned exact
  `MISSING_SDK_PACKAGE` data `ndk;29.0.14206865`, a real SDK boot classpath and
  an absent native model. The only other issue was a platform-tools warning.
- STANDARD configuration failed through the existing reporter. The private
  check required the public `BuildActionFailureException` plus the exact typed
  AGP Problems event. Only this diagnostic operation enabled AGP's existing
  experimental Problems reporting; ordinary V2 cases did not use that flag.
- An empty SDK-managed NDK directory retained its blocking native-configuration
  error. A missing explicit custom path likewise stayed blocking and produced
  no SDK NDK installation request. Neither was treated as install-only setup.

Original and copied SDK file hashes remained unchanged. The deliberately empty
NDK directory stayed empty; no packages or native models were fabricated. The
private Gradle daemon stopped, and USB transfer resources were removed.

Private evidence: `native-requirements.nf1mxudb/evidence` under the app-home
build-check cache; harness log `run-4698908419010670703/output.log`.
The tested input ZIP SHA-256 is
`443149e36826d0fb9f1d4deafa008b62cdce06e4cb8ddf56b9ed4df94e0af9b0`.
The initial run passed missing-NDK sync but expected the wrong Tooling API
exception wrapper in STANDARD mode; only the private assertion was corrected.
The AGP candidate bytes were unchanged between runs. This verifies the scoped
8.12.3 diagnostic contract, not CMake discovery, complete setup or native builds
with the new revision. These new AGP artifacts are not published.

## Finalized CMake settings

The `-zyntax.3` AGP and public builder-model source builds passed for all three
exact releases: 8.12.3 in 2m34s, 8.13.0 in 2m20s and 9.2.1 in 3m8s, with 18 tasks
executed each. One shared build recipe prepares and publishes both source modules
to a local Maven repository. Their paired publications are now shipped in APT
package `zyntax-agp` `1.0.0-3`.

| Fork | AGP runtime SHA-256 | Model runtime SHA-256 |
| --- | --- | --- |
| 8.12.3-zyntax.3 | `b60fc043ac09a82b1023eaca6559b79a86853f270dc343c4879ecc734fceb658` | `1ee1d2cd7ef76bef773dc85fee3f828f9ee2cb1dc0811c846005265d5c757e0a` |
| 8.13.0-zyntax.3 | `078ab089730f7d3bc6b0d0c775098032800cd828d9a217b6453ce53e057f0995` | `3dc17f3432dbffdf32357aa16728e3513e77086fa6e6c8537e47940c2b84ad28` |
| 9.2.1-zyntax.3 | `4c188a8c4d3e83db3fa85ff26d4fbf201936019ea0a7341158da4bfe8c3a6943` | `6a2220523c5346838de219597236d9150217a77b146600cbdbcc265b6c2d0346` |

Archive checks found unique entries, no overlapping runtime classes, unchanged
upstream NOTICE bytes and complete original source coverage. Public signature
comparisons retained all original model classes/methods; only `CmakeOptions` and
`AndroidDsl.getCmake()` were added. POM/module metadata selects one exact owned
model and excludes the original peer. The model's Kotlin bytecode is JVM11 like
its Java classes; upstream already declared a JVM11 module minimum.

The package archive check verified all 24 Maven artifacts, 96 checksum sidecars,
six notices, prepared sources and provenance. Signed live indexes verified, and
the 30,243,960-byte package downloaded from `pkg.zyntax.app` matched SHA-256
`507c3c8e14bf342e2308e1829ec153aff471c42e03caed4b096672286f26292b`.
This publication check does not add a device native-build result.

The corrected USB invocation passed in **242.804s / OK (1 test)**. Its two
scalar-only model actions used the exact 8.12.3 candidate, previously verified
Android Gradle provider and app-private Java21. Four library modules exercised
later DSL finalizers: raw `3.31.6`, raw `3.30.5+`, omitted version, and removal of
the CMake project path. Non-null CMake objects reported source default `3.22.1`;
the no-CMake object stayed null. The second action added only a root `cmake.dir`
pointing to an absent private path with spaces, and every applicable model
reported that exact path without creating it.

Variants were disabled through the public selector/Action callback. No native
model or build task was requested, no CMake executable ran and no package was
installed. Both actions retained genuine SDK boot classpaths and had no blocking
sync issues. Original/copied SDK file hashes matched; the isolated Gradle daemon
stopped and transfer resources were removed. App/SDK and user projects were unchanged.

Evidence: `cmake-requirements.js6c6ljh/evidence` under the private app-home cache,
harness `run-1867549174630434634/output.log`. Frozen input ZIP: 19,377,456 bytes,
SHA-256 `a47ed33d8c7cbcd8452ef30d4648c345693635fd805df59b0b51a1c863d2c7bc`.
The initial invocation failed before model retrieval because the private Groovy
fixture omitted the callback's required selector. Only that fixture call was
corrected; the AGP/model binaries were unchanged. This proves model-data transport,
not CMake validation, native package availability, automatic setup or native builds.

## Zyntax DevDebug self-build

The unchanged Zyntax 0.9.4 project at commit `58c36d7` completed on-device
`npm ci`, `npm run build:dev`, Capacitor sync and `:app:assembleDevDebug`.
Gradle completed 165 tasks in 10m 17s; the USB build check passed in 635.517s.
The original root AGP 8.12.3 and Capacitor modules' AGP 8.13.0 requests used their
exact forks through the explicit selector. The build retained wrapper 8.14.3,
JDK 21.0.12, SDK 36 and build-tools 35.0.0, with NDK package
`29.0.14206865-2` and the explicit native AAPT2 override.

The APK is 42,573,320 bytes, SHA-256
`2f9cd8f1c2f69de7962060476b4f493bd72893e8a17fe4b82d5dec239ad4c170`.
Native build/strip tasks, the expected single signing certificate, ZIP integrity,
16 KB ZIP alignment, Dev flavor marker, all three JNI libraries, ARM64 ABI and
version checks passed. The debug signing key remained outside the project under
`~/.secrets`. App source, private keys and the APK are not distributed here.

Native AAPT2 `2.20-android-16.0.0_r4` emitted nonfatal resource-name warnings.
A separate 1.525s APK inspection found all 295 warned IDs among 1,487 resource
definitions and resolved all 12 manifest resource references. The APK was not
installed; this verifies the build and packaged resources, not UI behavior.
DevDebug does not exercise R8 shrinking or obfuscation.

## R8-enabled DevRelease self-build

The same unchanged tracked source completed `:app:assembleDevRelease` and
`:app:bundleDevRelease` with R8 and resource shrinking enabled. A separate
test-only init script accepted only those two tasks and selected the existing
debug/test keystore outside the project; no production signing key was used.
The build completed 289 tasks in 10m 34s (USB check: 649.089s).

| Output | Bytes | SHA-256 |
| --- | ---: | --- |
| DevRelease APK | 36468082 | `880da2f013c42374a7a70b29c9da4742ecdc82f2596a63ba92f1898a99252f20` |
| DevRelease AAB | 37971318 | `70ddca871bc76e420e9674f3b1b81e5691bd62d0d40cf9870c716ecf6316eb9d` |
| R8 mapping | 19610496 | `4a58a7d78d04751ea58e21afd611ddbd90e7863cea0ab5ba6218404831979d35` |

DEX decreased from 16,155,288 debug bytes to 2,441,276 release bytes (84.9%).
APK and AAB DEX contents matched; the AAB contained the exact R8 mapping.
APK signature, non-debuggable Dev metadata, ARM64/native packaging, ZIP integrity
and 16 KB ZIP alignment checks passed. Strict AAB signature verification passed.

Jarsigner reported that the late ZIP manifest cannot be discovered by a streaming
`JarInputStream`. The archive was not reordered or re-signed: the resolved AGP
Bundletool 1.18.1 validator accepted it, and verifying `JarFile` reads confirmed
all 476 payload entries had the expected single signing certificate. The AAB
hash stayed unchanged. This follow-up passed in the same USB check as two
successful nested project-model imports (205.204s total).

No generated APK/AAB was installed or published, and no app/SDK source changed.
These checks validate build/signature/package output, not optimized-app runtime
behavior or Play acceptance. Source, signing inputs and generated app artifacts
are not included in this public repository.

## Distribution audit

The native-build distribution preserves Google's original notices and target
runtime bytes, LLVM's license with exceptions, zlib and Zstandard license texts,
the modified NDK source diff and exact source inputs. The release excludes
debugger servers, Make, Python and Yasm; these are not silently bundled.
AGP artifacts preserve upstream notices and include prepared source JARs.
The review found no additional redistribution blocker for this scope; it is not
a legal guarantee or a relicensing of upstream software.

## Release artifacts

The native-only assembly excludes the debugger servers found in the unpublished
first package candidate. This changes package contents, not compiler binaries.

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `ndk-r29-native.tar.xz` | 202273968 | `bb1087fd9dbba8c9100e1e6f090bc930cc6a322542ef91132fb38bdd6724ed05` |
| `zyntax-ndk-29.0.14206865_29.0.14206865-2_aarch64.deb` | 171543804 | `00b247fd0960b12ac72cbc2689cc76f1aef8d9ae2e0bb01152175d5bc8820533` |
| `zyntax-agp_1.0.0-2_all.deb` | 29865140 | `08a0ec3a129363be6af2d49b7290e90b537cbf91302baa424950b809dedd1032` |

Assembly source: [84bcfff](https://github.com/amitkhare/zyntax-ndk-r29/commit/84bcfff).
The `.deb` records the full commit and archive checksum in package provenance.
NDK package revision 2 and AGP package 1.0.0-1 passed USB installation after
refreshing signed indexes. The installed AGP 8.12.3 rebuilt the actual JNI
component; AGP 9.2.1 rebuilt all four sample native ABIs with the installed NDK.
The installed NDK was checked for absence of debugger servers. AGP package
1.0.0-2 adds exact 8.13.0 from source commit
[`b4da5cd`](https://github.com/amitkhare/zyntax-ndk-r29/commit/b4da5cd60c8aff9c3abe921c0ddb831b02413da5)
and passed the full-project USB check above. It contains the three exact fork
versions and their source JARs.

Both packages are published at [pkg.zyntax.app](https://pkg.zyntax.app/dists/stable/main/binary-aarch64/Packages).
Live `Release`/`InRelease` signatures, all package indexes and all five indexed
package-object sizes passed verification. The final USB check refreshed signed
indexes and freshly downloaded `zyntax-agp=1.0.0-2`; its SHA-256 matched the
device-tested package above. The installed version and 8.13.0 JAR hash also matched.
This check passed in 8.635s; the already-installed identical package was not
reinstalled. Earlier NDK and AGP installation checks verified the compiler and
preserved existing Go and termux-exec package bytes. The superseded unpublished
candidate was excluded.

LLDB remains a separate roadmap item. The full Zyntax DevDebug self-build is
complete; SDK/build-tools installation and private signing configuration were
explicit build inputs rather than bundled package contents.
