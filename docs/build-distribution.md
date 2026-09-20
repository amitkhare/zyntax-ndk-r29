# Android-host NDK build tools

For Android ARM64 hosts (API 24 or newer). The exact NDK revision is recorded
in `source.properties` and `release.json`; install different revisions side by
side instead of changing an existing project's declared version.

This distribution contains Clang, LLD, the LLVM build utilities listed in
`build-tools.txt`, the official Android target headers/libraries, and the NDK's
CMake and `ndk-build` support. The real host directory is `linux-arm64`.
Official target/API compiler driver scripts and target artifacts are preserved.

This is a **native build distribution**, not the complete desktop NDK bundle.
It does not contain LLDB, desktop profiling/shader tools, a bundled Python or
GNU Make. No placeholders or alternate executable lookup are provided.
Debugger support has a separate source-build stage.

## Dependencies

Install Bash, GNU Make and Python in the Android userspace. Select the package
executables explicitly with `GNUMAKE` and `NDK_HOST_PYTHON` before `ndk-build`.
Projects using x86 `.asm` sources also select the Yasm package executable through
`NDK_HOST_YASM`; ordinary C/C++ builds do not need it.
Use a native Android CMake and Ninja for CMake projects. Termux CMake also reads
the host's `$PREFIX/include/android/api-level.h` during system detection, before
loading the selected NDK toolchain. Install its normal `ndk-sysroot` header
package when using this NDK compiler without Termux Clang; the NDK's target
sysroot does not replace that host prerequisite.

Keep the NDK and executable build outputs inside the host application's allowed
executable storage (Zyntax's app-private `files` tree, including its home and
projects directories). An application cache directory may store downloaded
archives, but it is not an executable installation location.

SDK/Gradle/JDK selection
is outside this toolchain; existing projects must select an Android-host-capable
Android Gradle Plugin to use this NDK's actual host directory.

The NDK does not modify projects, install app components, or choose signing keys.
Installing this toolchain does not change the app or SDK.

## License and provenance

`NOTICE`, `NOTICE.toolchain`, `notices/` and the toolchain's own notice preserve
upstream licenses. Original port infrastructure is Apache-2.0; that does not
relicense the included components. LLVM uses Apache-2.0 with LLVM exceptions;
the linked compression libraries retain their zlib/BSD licensing terms.

`sources.tsv` records exact input URLs and SHA-256 checksums. The toolchain's
`clang_source_info.md` and the original XML manifests listed in `release.json`
identify that exact compiler's sources. Build instructions and source changes
are maintained publicly at
<https://github.com/amitkhare/zyntax-ndk-r29>.

Packaging checks are not evidence of successful compilation on a device.
Only a release with recorded device results is suitable for publication.
