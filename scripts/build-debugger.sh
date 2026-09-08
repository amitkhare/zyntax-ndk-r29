#!/usr/bin/env bash
set -euo pipefail

# Optional stage: run only after build-llvm.sh has installed the native tools.
# TARGET_PREFIX contains the shared package headers/libraries pinned in
# sources-debugger.tsv; none of those packages are copied into the NDK.
: "${TARGET_PREFIX:?Set TARGET_PREFIX to the extracted Android package prefix.}"
: "${HOST_PYTHON:?Set HOST_PYTHON to an absolute Linux build-host Python executable.}"
SOURCE_DIR=${SOURCE_DIR:-/work/src/llvm-project}
SWIG_SOURCE_DIR=${SWIG_SOURCE_DIR:-/work/src/swig}
BUILD_DIR=${BUILD_DIR:-/work/build}
BUILD_JOBS=${BUILD_JOBS:-2}

[[ $BUILD_JOBS =~ ^[1-9][0-9]*$ ]]
[[ $TARGET_PREFIX == /* && $HOST_PYTHON == /* && -x $HOST_PYTHON ]]
command -v bison >/dev/null
pkg-config --exists libpcre2-8
test -f "$BUILD_DIR/llvm-android/install_manifest.txt"
test -f "$BUILD_DIR/llvm-host/CMakeCache.txt"
test -f "$SWIG_SOURCE_DIR/CMakeLists.txt"
grep -q '^#if !defined(_WIN32)$' "$SOURCE_DIR/lldb/include/lldb/Host/Editline.h"

python_include="$TARGET_PREFIX/include/python3.14"
python_library="$TARGET_PREFIX/lib/libpython3.14.so"
python_config="$TARGET_PREFIX/lib/python3.14/_sysconfigdata__android_aarch64-linux-android.py"
python_suffix=.cpython-314-aarch64-linux-android.so
grep -Eq '^#define PY_VERSION[[:space:]]+"3\.14\.6"' "$python_include/patchlevel.h"
grep -Fq "'EXT_SUFFIX': '$python_suffix'" "$python_config"
grep -Fq "'Py_GIL_DISABLED': 0" "$python_config"
for dependency in "$python_library" "$TARGET_PREFIX/include/histedit.h" \
  "$TARGET_PREFIX/lib/libedit.so" "$TARGET_PREFIX/lib/libncursesw.so.6" \
  "$TARGET_PREFIX/lib/libandroid-support.so"; do
  test -f "$dependency"
done

# SWIG runs on the Linux build host; it is never part of the Android package.
swig_build="$BUILD_DIR/swig-host"
swig_install="$swig_build/install"
cmake -S "$SWIG_SOURCE_DIR" -B "$swig_build" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$swig_install" -DWITH_PCRE=ON
cmake --build "$swig_build" --parallel "$BUILD_JOBS" --target install
"$swig_install/bin/swig" -version | grep -q 'SWIG Version 4\.5\.1'

projects='clang;clang-tools-extra;lld;lldb'
host_build="$BUILD_DIR/llvm-host"
android_build="$BUILD_DIR/llvm-android"
cmake -S "$SOURCE_DIR/llvm" -B "$host_build" \
  -DLLVM_ENABLE_PROJECTS="$projects" -DPython3_EXECUTABLE="$HOST_PYTHON" \
  -DLLDB_INCLUDE_TESTS=OFF -DLLDB_ENABLE_SWIG=OFF -DLLDB_ENABLE_PYTHON=OFF \
  -DLLDB_ENABLE_LIBEDIT=OFF -DLLDB_ENABLE_CURSES=OFF -DLLDB_ENABLE_LZMA=OFF \
  -DLLDB_ENABLE_LUA=OFF -DLLDB_ENABLE_LIBXML2=OFF -DLLDB_ENABLE_FBSDVMCORE=OFF
cmake --build "$host_build" --parallel "$BUILD_JOBS" --target lldb-tblgen

# Reuse the completed compiler build and its Android toolchain/target settings.
# Explicit target artifacts prevent CMake from selecting Linux Python libraries.
cmake -S "$SOURCE_DIR/llvm" -B "$android_build" \
  -DLLVM_ENABLE_PROJECTS="$projects" -DLLDB_TABLEGEN_EXE="$host_build/bin/lldb-tblgen" \
  -DLLDB_INCLUDE_TESTS=OFF -DLLDB_ENABLE_SWIG=ON \
  -DSWIG_EXECUTABLE="$swig_install/bin/swig" \
  -DLLDB_ENABLE_PYTHON=ON -DPython3_EXECUTABLE="$HOST_PYTHON" \
  -DPython3_LIBRARIES="$python_library" -DPython3_INCLUDE_DIRS="$python_include" \
  -DPython3_VERSION=3.14.6 -DPython3_RPATH= -DLLDB_EMBED_PYTHON_HOME=OFF \
  -DLLDB_PYTHON_RELATIVE_PATH=lib/python3.14/site-packages \
  -DLLDB_PYTHON_EXE_RELATIVE_PATH=bin/python3.14 \
  -DLLDB_PYTHON_EXT_SUFFIX="$python_suffix" \
  -DLLDB_ENABLE_LIBEDIT=ON -DLibEdit_INCLUDE_DIRS="$TARGET_PREFIX/include" \
  -DLibEdit_LIBRARIES="$TARGET_PREFIX/lib/libedit.so" \
  -DCMAKE_EXE_LINKER_FLAGS="-pie -Wl,-rpath-link,$TARGET_PREFIX/lib" \
  -DCMAKE_SHARED_LINKER_FLAGS="-Wl,-rpath-link,$TARGET_PREFIX/lib" \
  -DLLDB_ENABLE_CURSES=OFF -DLLDB_ENABLE_LZMA=OFF -DLLDB_ENABLE_LUA=OFF \
  -DLLDB_ENABLE_LIBXML2=OFF -DLLDB_ENABLE_FBSDVMCORE=OFF
cmake --build "$android_build" --parallel "$BUILD_JOBS" --target \
  lldb lldb-server lldb-dap lldb-argdumper
for component in lldb lldb-server lldb-dap lldb-argdumper liblldb lldb-python-scripts; do
  cmake --install "$android_build" --strip --component "$component"
done
