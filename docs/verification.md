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
