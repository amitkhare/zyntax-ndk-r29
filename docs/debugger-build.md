# Optional Android-host debugger build

**Prepared, not compiled or device-verified.** This stage is independent of the
first native-build distribution. It builds genuine LLDB, LLDB Server, LLDB DAP
and the Python API; no placeholder or external-debugger launcher is shipped.

## Prepare inputs

Use the same Linux build environment and `/work` volume as the compiler build.
The host needs `bison`, `libpcre2-dev`, CMake, Ninja, Python 3 and `dpkg-deb`.
Preparation may run while the compiler builds; it does not modify LLVM sources
or configure either LLVM build directory.

```bash
bash /port/scripts/prepare-debugger.sh
```

Every cached/downloaded archive is checked against `sources-debugger.tsv`.
SWIG source is extracted to `/work/src/swig`. Shared Android package payloads
are staged under `/work/debugger-target`; the script discovers exactly one
Python prefix and records it in `/work/debugger-target/prefix.txt`. There are no
hardcoded application paths. Repeated preparation verifies input checksums and
reuses the same extracted inputs. Changed package pins require a fresh target
directory; changed SWIG pins require fresh SWIG sources.

Pinned build inputs are SWIG 4.5.1 (official source commit
`88649f559942c29a228fa783dd01581e217bcb20`), Python `3.14.6-1`, libedit
`20260512-3.1-0`, ncurses `6.6.20260307+really6.5.20250830` and
libandroid-support `29-1`. Their URLs and SHA-256 values are in the manifest.

## Build after the compiler finishes

Wait for `build-llvm.sh` to complete and install its outputs. **Apply this source
patch once, before the first debugger build against that prepared LLVM tree.**
It allows LLDB to include the selected Android libedit headers; it does not
modify the NDK's target sysroot or the compiler driver.

```bash
patch --batch --fuzz=0 -p1 -d /work/src/llvm-project \
  < /port/patches/lldb-android-libedit.patch
export TARGET_PREFIX="$(< /work/debugger-target/prefix.txt)"
export HOST_PYTHON=/usr/bin/python3
bash /port/scripts/build-debugger.sh
```

To resume a debugger build, run `build-debugger.sh` again, not the patch command.
The script reuses the completed compiler build directories. `HOST_PYTHON` and
source-built SWIG run only on the Linux build host. Target LLDB links the shared
Android Python/libedit libraries explicitly; it does not discover host Python
libraries or copy the dependency packages into the NDK.

The confirmed Python ABI is normal-GIL CPython 3.14, with SONAME
`libpython3.14.so` and suffix `.cpython-314-aarch64-linux-android.so`. A future
debugger `.deb` must declare `python (>= 3.14.6-1)`, `python (<< 3.15)`, `libedit`,
`ncurses` and `libandroid-support`; APT resolves Python's other dependencies.
Python minor-ABI changes require rebuilding the debugger.

## Publication boundary

The stage installs LLDB tools/library and Python API into the compiler install
prefix, but the native-build assembly allowlist does not include them. Debugger
packaging must wait for successful compilation, ELF/dependency checks and one
focused Android runtime/debugging check. Lua, curses UI, LZMA, XML and FreeBSD
core-dump integrations are disabled in this initial optional configuration.

Do not ship the desktop NDK's `lldb.sh`, its Python runtime or build-host SWIG.
Preserve LLVM's Apache-2.0/LLVM-exception notices and SWIG's generated-support
copyright/licence notices. The separately installed packages keep their own
licences; building the debugger does not relicense those dependencies.
