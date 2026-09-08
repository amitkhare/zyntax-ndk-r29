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

JDK 21.0.12 ran Gradle. Signing keys stayed outside projects under `~/.secrets`.
No generated Zyntax APK was published. The JNI check used a private minimal
library fixture: it does **not** prove a full Zyntax Android project build.

Sample inputs:

- [Groovy DSL](https://github.com/zyntax-projects/android-groovy-dsl-empty-activity/tree/1cded402eca4650883be6c3f210fabe7a712fb3c).
- [Kotlin DSL](https://github.com/zyntax-projects/android-kotlin-dsl-empty-activity/tree/9ed243f589835293c09ddd468f567eac85754463).

Device copies use compile SDK 37 for their declared AndroidX dependencies and
the requested small C++/CMake addition, with `ndkVersion = 29.0.14206865`.
Native CMake selection uses `cmake.dir`; AGP fork selection is explicit through
the documented init script. No desktop host-directory aliases or binary edits.

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
| `zyntax-agp_1.0.0-1_all.deb` | 26542684 | `e2bb8718771f34951e640ff5f64582d5bd8b08100f354e172d14e9796624fb9a` |

Assembly source: [84bcfff](https://github.com/amitkhare/zyntax-ndk-r29/commit/84bcfff).
The `.deb` records the full commit and archive checksum in package provenance.
Both final `.deb` files passed USB installation after refreshing signed package
indexes. The installed AGP 8.12.3 rebuilt the actual JNI component; installed
AGP 9.2.1 rebuilt all four sample native ABIs with the installed NDK directory.
The installed NDK was checked for absence of debugger servers.

Both packages are published at [pkg.zyntax.app](https://pkg.zyntax.app/dists/stable/main/binary-aarch64/Packages).
Live `Release`/`InRelease` signatures, all three package-index hashes and all four
package-object sizes passed verification. The USB device then refreshed signed
indexes and downloaded/reinstalled both exact packages from that repository;
installed versions and the compiler were verified. Existing Go and termux-exec
package bytes were preserved. The superseded unpublished candidate was excluded.

LLDB and full-app builds remain separate roadmap items. A full Zyntax Dev APK
self-build also needs its exact SDK/build-tools inputs and explicit private
signing configuration; the native component check does not cover those steps.
