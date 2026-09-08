#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR=${SOURCE_DIR:-/work/src/llvm-project}
NDK_DIR=${NDK_DIR:-/work/ndk/android-ndk-r29}
BUILD_DIR=${BUILD_DIR:-/work/build}
INSTALL_DIR=${INSTALL_DIR:-/work/install/linux-aarch64}
BUILD_JOBS=${BUILD_JOBS:-2}
ANDROID_API=24

[[ $BUILD_JOBS =~ ^[1-9][0-9]*$ ]] || { echo 'BUILD_JOBS must be positive.' >&2; exit 1; }
grep -qx 'Pkg.Revision = 29.0.14206865' "$NDK_DIR/source.properties"
test -f "$SOURCE_DIR/llvm/CMakeLists.txt"
test -f /work/src/zlib/CMakeLists.txt
test -f /work/src/zstd/build/cmake/CMakeLists.txt

host_build="$BUILD_DIR/llvm-host"
android_build="$BUILD_DIR/llvm-android"
deps_build="$BUILD_DIR/llvm-deps"
deps_install="$deps_build/install"
projects='clang;clang-tools-extra;lld'
common=(
  -G Ninja
  -DCMAKE_BUILD_TYPE=Release
  -DLLVM_ENABLE_PROJECTS="$projects"
  -DLLVM_INCLUDE_TESTS=OFF
  -DLLVM_INCLUDE_BENCHMARKS=OFF
  -DLLVM_INCLUDE_EXAMPLES=OFF
  -DLLVM_INCLUDE_DOCS=OFF
  -DCLANG_INCLUDE_TESTS=OFF
  -DLLVM_PARALLEL_COMPILE_JOBS="$BUILD_JOBS"
  -DLLVM_PARALLEL_LINK_JOBS=1
  -DLLVM_PARALLEL_TABLEGEN_JOBS=1
)

# Source generators execute on the Linux build host, never on the Android target.
cmake -S "$SOURCE_DIR/llvm" -B "$host_build" "${common[@]}" \
  -DLLVM_TARGETS_TO_BUILD=Native
cmake --build "$host_build" --parallel "$BUILD_JOBS" --target \
  llvm-tblgen clang-tblgen clang-tidy-confusable-chars-gen

android=(
  -G Ninja
  -DCMAKE_BUILD_TYPE=Release
  -DCMAKE_TOOLCHAIN_FILE="$NDK_DIR/build/cmake/android.toolchain.cmake"
  -DANDROID_ABI=arm64-v8a
  -DANDROID_PLATFORM="android-$ANDROID_API"
  -DANDROID_STL=c++_static
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON
)

# Compression libraries are target libraries, not libraries from the build host.
cmake -S /work/src/zlib -B "$deps_build/zlib" "${android[@]}" \
  -DCMAKE_INSTALL_PREFIX="$deps_install" -DZLIB_BUILD_EXAMPLES=OFF
cmake --build "$deps_build/zlib" --parallel "$BUILD_JOBS" --target install
cmake -S /work/src/zstd/build/cmake -B "$deps_build/zstd" "${android[@]}" \
  -DCMAKE_INSTALL_PREFIX="$deps_install" \
  -DZSTD_BUILD_SHARED=OFF -DZSTD_BUILD_STATIC=ON \
  -DZSTD_BUILD_PROGRAMS=OFF -DZSTD_BUILD_TESTS=OFF
cmake --build "$deps_build/zstd" --parallel "$BUILD_JOBS" --target install

# Static C++/compression libraries keep the package self-contained; libc remains
# dynamically linked so normal Android process launch and child execution work.
cmake -S "$SOURCE_DIR/llvm" -B "$android_build" "${common[@]}" "${android[@]}" \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
  -DCMAKE_EXE_LINKER_FLAGS=-pie \
  -DLLVM_TARGETS_TO_BUILD='AArch64;ARM;BPF;RISCV;WebAssembly;X86' \
  -DLLVM_DEFAULT_TARGET_TRIPLE="aarch64-linux-android$ANDROID_API" \
  -DLLVM_NATIVE_TOOL_DIR="$host_build/bin" \
  -DLLVM_TABLEGEN="$host_build/bin/llvm-tblgen" \
  -DCLANG_TABLEGEN="$host_build/bin/clang-tblgen" \
  -DCLANG_TIDY_CONFUSABLE_CHARS_GEN="$host_build/bin/clang-tidy-confusable-chars-gen" \
  -DLLVM_BUILD_STATIC=OFF -DBUILD_SHARED_LIBS=OFF \
  -DLLVM_BUILD_LLVM_DYLIB=OFF -DLLVM_LINK_LLVM_DYLIB=OFF \
  -DLLVM_ENABLE_PIC=ON \
  -DLLVM_ENABLE_ZLIB=FORCE_ON -DLLVM_ENABLE_ZSTD=FORCE_ON \
  -DLLVM_USE_STATIC_ZSTD=ON \
  -DZLIB_LIBRARY="$deps_install/lib/libz.a" \
  -DZLIB_INCLUDE_DIR="$deps_install/include" \
  -Dzstd_LIBRARY="$deps_install/lib/libzstd.a" \
  -Dzstd_INCLUDE_DIR="$deps_install/include" \
  -DLLVM_ENABLE_TERMINFO=OFF -DLLVM_ENABLE_LIBEDIT=OFF \
  -DLLVM_ENABLE_LIBXML2=OFF -DLLVM_ENABLE_CURL=OFF \
  -DLLVM_VERSION_SUFFIX= \
  '-DCLANG_VENDOR=Android (r563880c; Android AArch64 host)' \
  -DCLANG_REPOSITORY_STRING=https://android.googlesource.com/toolchain/llvm-project
cmake --build "$android_build" --parallel "$BUILD_JOBS"
cmake --install "$android_build" --strip
