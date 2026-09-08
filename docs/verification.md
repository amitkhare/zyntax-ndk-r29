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

Final archive/package hashes and signed-repository installation results will
be recorded after release packaging. LLDB and full-app builds remain separate
roadmap items.
