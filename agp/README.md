# Android-host Android Gradle Plugin

Whole-module source builds of **AGP 8.12.3, 8.13.0 and 9.2.1**, packaged under distinct
coordinates `app.zyntax.tools.build:gradle:<upstream-version>-zyntax.2`.

**Candidate status: `-zyntax.2` adds typed missing-NDK sync diagnostics. All three
whole-module source builds passed; the four-case missing-NDK check passed on USB
with 8.12.3. The new artifacts are local only, not APT-packaged or published.**

Historical `-zyntax.1` evidence: all three source builds passed. AGP 9.2.1 passed native sample builds;
8.12.3 and 8.13.0 passed the complete unchanged Zyntax DevDebug self-build on USB.
AGP package 1.0.0-2 is published at `pkg.zyntax.app`; signed indexes and downloaded
package bytes were verified on USB. Those results do not validate the new candidate.
See [verification](../docs/verification.md).

The `-zyntax.1` Windows/JDK 21 builds passed on 2026-09-09. The runtime JARs have the same
top-level class names as their exact Google releases: 2,377 for 8.12.3, 2,388 for
8.13.0 and 2,413 for 9.2.1, with no missing, extra or duplicate paths. Their source
archives contain 1,827, 1,835 and 1,826 unique Java/Kotlin files, without binary classes
or duplicate paths. Notices, fork metadata and compiled `linux-arm64` host lookup
are present. This verifies source builds and packaging, not native Android
project builds on a device; the separate USB results are recorded below.

The 8.13.0 audit preserves all 54 exact POM dependencies and all 49 upstream
noncompiled resources: 38 match byte-for-byte, while 11 properties files differ
only in comments, preserving source notices and identical property values.
The whole-module compilation regenerates Kotlin metadata as `gradle-core`;
it does not copy the upstream bundled modules' compiled metadata or classes.
The original and fork are compared for coverage, not byte-for-byte binaries.

The recipe compiles every unique Java/Kotlin source in Google's checksum-pinned
sources JAR, including its bundled module sources and generated protobuf Java.
Identical duplicated generated files are normalized; conflicting copies fail.
The upstream implementation JAR is never a compiler or packaging input.
The compiler uses upstream Kotlin API/language 2.0 and JVM 11 settings, including
its original default-method, lambda and SAM generation, with module name
`gradle-core`. JDK 21 runs the build; it does not raise the output bytecode level.

Google's exact POM supplies the published peer-module dependencies. The eight
omitted `.proto` resources come from the immutable source commit recorded in
`releases.json`; each was verified byte-for-byte against its exact release.
AAPT2 metadata is generated from the exact POM's AAPT2 version. Existing source
notices, plugin descriptors and API version metadata are preserved. The missing
AI-pack descriptor is generated from the upstream plugin declaration.

The version-specific source diffs include native host selection before
compilation: Linux ARM64 selects the real
`linux-arm64` toolchain directory for strip, objcopy and shared libc++. It adds
no architecture aliases, runtime binary modification, app code or fallback.

### Missing-NDK sync diagnostics (candidate)

The same locator change serves all three exact forks. After the existing NDK
lookup/installation path fails, it reports `MISSING_SDK_PACKAGE` through the
existing issue reporter with canonical `ndk;<parsed revision>` data. Normal
evaluation still throws; IDE model-only sync records a blocking issue and uses
the existing absent-native-configuration path. No native model, task data, version,
or installation is fabricated, and upstream `Plugin-Version` remains unchanged.

Earlier invalid-version, custom-path and conflicting-path diagnostics, installer
exceptions, and no-download hypothetical lookups retain their existing behavior.
A corrupt SDK-managed installation can retain a distinct blocking Cxx issue
alongside the unavailable-package issue. Consumers must aggregate project/global
`ProjectSyncIssues` and refuse an install plan containing any other blocking error;
the package data alone is not permission to repair or overwrite an installation.

The fresh Windows/JDK 21 builds passed on 9 September 2026: 8.12.3 in 2m49s,
8.13.0 in 2m11s and 9.2.1 in 2m54s, with all nine tasks executed in each build.
Runtime JARs retain `NOTICE`, exact upstream `Plugin-Version`, distinct fork
metadata and unique entry paths. The source build uses fork-qualified work
directories; verified `-zyntax.1` sources and artifacts were not overwritten.

The focused 8.12.3 USB check passed in 261.869s: finalized missing-NDK data,
ordinary configuration failure, corrupt SDK-managed NDK and invalid custom path.
Existing SDK inputs retained their hashes; no package was installed. This does
not verify CMake discovery or complete setup. See [the evidence](../docs/verification.md#missing-ndk-sync-diagnostics).

## Build

Requires PowerShell, Git and JDK 21. The shared recipe selects Gradle 8.13 for
AGP 8.12.3 and 8.13.0, and Gradle 9.4.1 for AGP 9.2.1; each download is checked against its
pinned SHA-256. Downloads, extracted sources, caches and output stay
under the ignored repository `.work/agp/` directory. The build uses at most two
workers and a 3 GiB Gradle heap.

Prepared sources, build outputs, project cache, Kotlin state and logs are keyed
by the full fork version. The `-zyntax.2` candidate therefore uses fresh mutable
work paths without overwriting verified `-zyntax.1` artifacts or logs. Exact
checksum-verified inputs/bootstrap distributions and dependency downloads remain
shared; no private recipe copy or manual cache injection is needed.

```powershell
./agp/build.ps1 -JavaHome 'C:/path/to/jdk-21' -UpstreamVersion 8.12.3
./agp/build.ps1 -JavaHome 'C:/path/to/jdk-21' -UpstreamVersion 8.13.0
./agp/build.ps1 -JavaHome 'C:/path/to/jdk-21' -UpstreamVersion 9.2.1
```

Output: `.work/agp/build-<fork-version>/libs/gradle-<fork-version>.jar`, where
`<fork-version>` is, for example, `8.12.3-zyntax.2`. Prepared sources live in
`.work/agp/sources-<fork-version>/`; the log is `.work/agp/build-<fork-version>.log`.
Use `-Task publish` to write a **local** Maven repository under
`.work/agp/build-<fork-version>/repository/`; this does not upload anything.
Unknown upstream versions fail; no version substitutes for another.

This does **not** automatically replace stock AGP in existing projects.
Each artifact retains its exact
upstream API/`Plugin-Version`; Maven coordinates, `Implementation-Version`
and `META-INF/zyntax-agp.properties` identify the fork unambiguously.

## Explicit project selection

The optional `zyntax-agp` APT package installs exact fork versions and their
source JARs under `$PREFIX/share/zyntax-agp/`. It contains one selector and release
map, not a Gradle installation, JDK, global init script or dependency cache.
After configuring the signed Zyntax package repository:

```bash
pkg update
pkg install zyntax-agp zyntax-ndk-29.0.14206865
bash ./gradlew --init-script "$PREFIX/share/zyntax-agp/select-fork.init.gradle" \
  -PzyntaxAgpRepository="$PREFIX/share/zyntax-agp/repository" \
  -PzyntaxNdkDirectory="$PREFIX/opt/android-sdk/ndk/29.0.14206865" \
  :app:externalNativeBuildDebug
```

Use the project's matching JDK and installed Android SDK. For ndk-build, set
`GNUMAKE` and `NDK_HOST_PYTHON` to the installed Make/Python executables. CMake
projects select native CMake/Ninja with the standard `cmake.dir` local property.
Complete APK/AAB builds additionally require compatible Android SDK tools; the
sample checks explicitly selected native AAPT2 with `android.aapt2FromMavenOverride`.
Installing this package does not download an SDK or configure projects.

Invoke Gradle with [select-fork.init.gradle](select-fork.init.gradle) and an
explicit Maven repository directory or HTTPS URI. Keep [releases.json](releases.json)
beside the script. For example, from the project root:

```bash
bash ./gradlew --init-script /path/to/agp/select-fork.init.gradle \
  -PzyntaxAgpRepository=/path/to/maven-repository :app:assembleDebug
```

The script uses Gradle's public `beforeSettings`, `pluginManagement`,
`useVersion` and `useModule` APIs for `plugins {}` requests. It selects the fork
version before its module so repeated root/subproject requests agree with the
plugin already loaded.
It logs each requested AGP version, selected fork coordinate
and repository. Exact versions and public plugin IDs come from `releases.json`,
checked against the source plugin descriptors. Unknown versions and plugins
removed from a selected release fail; unrelated plugin IDs are untouched.
Only our module is resolved from the supplied repository; it is excluded from
other declared repositories. Ordinary content filters allow projects to retain
their own `buildscript.repositories` declarations.

This supports versioned `plugins {}` requests, including version-catalog aliases
and versions declared through `pluginManagement`. For `buildscript` declarations,
public `beforeProject` and classpath `resolutionStrategy.eachDependency` hooks
select the exact fork with `useTarget`, using the same release mapping and logs.
Only `com.android.tools.build:gradle` classpath dependencies are selected;
unrelated dependencies and already-loaded plugin classes are not replaced.
Unversioned child plugin requests retain Gradle's normal inherited-classpath
resolution; the script does not select a new artifact for them.
Do not install the script globally or disable dependency verification. Without
the explicit argument, the project continues to use its normal plugin selection.
This is opt-in fork verification, not a claim that stock AGP supports Android hosts.
For `-zyntax.1`, host-only configuration checks loaded both exact fork artifacts, including a
root version-catalog alias with `apply false` repeated by an application module,
an unversioned child inheriting that plugin, and a root buildscript classpath
applied by a child application. Unsupported versions are rejected. These checks
did not compile an Android project or run native tools.

With `-zyntax.1` on USB, AGP 9.2.1 subsequently built native debug/release APKs and release AABs
for both Groovy and Kotlin DSL sample projects. AGP 8.12.3 compiled the unchanged
Zyntax JNI component in a private minimal library project using buildscript
classpath selection. The later full Zyntax 0.9.4 DevDebug self-build passed with
its original AGP 8.12.3 root and AGP 8.13.0 Capacitor module requests, each selected
through the explicit release map. Gradle 8.14.3, JDK 21.0.12, SDK 36, build-tools
35.0.0, packaged NDK r29 and native AAPT2 produced the signed APK without app or
SDK source changes. Signing keys stayed under `~/.secrets`; the APK was not
installed or published. See [the full build evidence](../docs/verification.md#zyntax-devdebug-self-build).

### Explicit NDK directory

Optionally pass `-PzyntaxNdkDirectory=/absolute/path/to/ndk` to use a packaged NDK
outside the selected SDK. For example, the `.deb` installs under
`$PREFIX/opt/android-sdk/ndk/29.0.14206865`; `ANDROID_HOME` can remain
`$HOME/android-sdk`.

The script reads the directory's `source.properties` and uses the public
`androidComponents.finalizeDsl`/`ndkPath` API for Android application, library,
dynamic-feature and test modules with a declared `externalNativeBuild` CMake or
ndk-build path. Their effective `ndkVersion` must match the selected revision;
mismatches fail without changing that version. Non-native modules retain their
NDK settings, including unused AGP defaults. Omitting the argument leaves NDK
selection unchanged. No symlinks, `ndk.dir`, project-file edits or environment
rewrites are used. For `-zyntax.1`, focused host configuration checks verified the selected
directory, unchanged revision, and rejection of a mismatched revision.

## License and source

AGP remains Apache-2.0 with its original bundled notices. The source change uses
that license; original build infrastructure follows the repository [LICENSE](../LICENSE).
The sources artifact generated by this recipe contains all prepared sources,
resources and source-provenance metadata. No app sources or private keys are used.

Primary inputs: [Google's 8.12.3 sources](https://dl.google.com/dl/android/maven2/com/android/tools/build/gradle/8.12.3/gradle-8.12.3-sources.jar),
[8.12.3 POM](https://dl.google.com/dl/android/maven2/com/android/tools/build/gradle/8.12.3/gradle-8.12.3.pom),
[8.13.0 sources](https://dl.google.com/dl/android/maven2/com/android/tools/build/gradle/8.13.0/gradle-8.13.0-sources.jar),
[8.13.0 POM](https://dl.google.com/dl/android/maven2/com/android/tools/build/gradle/8.13.0/gradle-8.13.0.pom),
[9.2.1 sources](https://dl.google.com/dl/android/maven2/com/android/tools/build/gradle/9.2.1/gradle-9.2.1-sources.jar),
[9.2.1 POM](https://dl.google.com/dl/android/maven2/com/android/tools/build/gradle/9.2.1/gradle-9.2.1.pom).
Source checksums, compiler/dependency versions and immutable proto commits are
recorded in [releases.json](releases.json); shared resource checksums are in
[build.gradle](build.gradle).

AGP 8.13.0's [immutable upstream release metadata](https://android.googlesource.com/platform/tools/base/+/7dee427b8411d0356b29aad83651db2612f9340b/common/release_version.bzl)
and [Maven catalog](https://android.googlesource.com/platform/tools/base/+/7dee427b8411d0356b29aad83651db2612f9340b/bazel/maven/artifacts.bzl)
confirm Kotlin compiler/Gradle plugin 2.2.0, JaCoCo 0.8.13 and Dokka 1.4.32.
Its NDK host-selection and locator sources are identical to 8.12.3, so both use the same
`ndk-host.patch` without an additional version-specific source diff.
