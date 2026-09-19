#!/usr/bin/env bash
set -euo pipefail

fixture="$(cd "$(dirname "${BASH_SOURCE[0]}")/native" && pwd)"
: "${NDK_ROOT:?Select the exact installed Android-host NDK}"
: "${CMAKE:?Select the native CMake package executable}"
: "${NINJA:?Select the native Ninja package executable}"
: "${GNUMAKE:?Select the GNU Make package executable}"
: "${NDK_HOST_PYTHON:?Select the Python package executable}"
: "${CHECK_DIR:?Select a new app-private output directory}"
[[ $CHECK_DIR == /* ]]
for tool in "$CMAKE" "$NINJA" "$GNUMAKE" "$NDK_HOST_PYTHON"; do
    [[ $tool == /* && -x $tool ]]
done
ndk_revision=$(sed -n 's/^Pkg.Revision = //p' "$NDK_ROOT/source.properties")
[[ $ndk_revision =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
printf 'NDK %s native C/C++ build check\n' "$ndk_revision"
test ! -e "$CHECK_DIR"
mkdir -p "$CHECK_DIR"
export GNUMAKE NDK_HOST_PYTHON
host="$NDK_ROOT/toolchains/llvm/prebuilt/linux-arm64"
runtime="$host/sysroot/usr/lib/aarch64-linux-android"

"$CMAKE" -S "$fixture" -B "$CHECK_DIR/cmake" -G Ninja \
    -DCMAKE_MAKE_PROGRAM="$NINJA" \
    -DCMAKE_TOOLCHAIN_FILE="$NDK_ROOT/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-24 \
    -DANDROID_STL=c++_shared -DCMAKE_BUILD_TYPE=Release
"$CMAKE" --build "$CHECK_DIR/cmake" --parallel 2
LD_LIBRARY_PATH="$CHECK_DIR/cmake:$runtime${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    "$CHECK_DIR/cmake/ndkprobe-main"

bash "$NDK_ROOT/ndk-build" -j2 NDK_PROJECT_PATH=null \
    "APP_BUILD_SCRIPT=$fixture/Android.mk" "NDK_APPLICATION_MK=$fixture/Application.mk" \
    "NDK_OUT=$CHECK_DIR/ndk/obj" "NDK_LIBS_OUT=$CHECK_DIR/ndk/lib"
LD_LIBRARY_PATH="$CHECK_DIR/ndk/lib/arm64-v8a:$runtime${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    "$CHECK_DIR/cmake/ndkprobe-main"
printf 'NDK %s: CMake and ndk-build C/C++ shared-library/runtime checks passed.\n' "$ndk_revision"
