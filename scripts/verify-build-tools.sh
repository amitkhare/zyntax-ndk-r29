#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ndk=${1:?Pass the assembled NDK directory}
host="$ndk/toolchains/llvm/prebuilt/linux-arm64"
readelf=${READELF:-/work/ndk/android-ndk-r29/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-readelf}

grep -qx 'Pkg.Revision = 29.0.14206865' "$ndk/source.properties"
test -d "$host/sysroot/usr/include"
test -d "$host/lib/clang/21/lib/linux"
test ! -e "$ndk/toolchains/llvm/prebuilt/linux-x86_64"
while IFS= read -r tool; do
    binary="$host/bin/$tool"
    test -x "$binary"
    [[ $(realpath "$binary") == "$host/bin/"* ]] || {
        echo "Tool link escapes the packaged bin directory: $tool" >&2; exit 1;
    }
    headers=$("$readelf" --file-header --program-headers "$binary")
    grep -q 'Machine:.*AArch64' <<< "$headers"
    grep -q 'Type:.*DYN' <<< "$headers"
    grep -q 'Requesting program interpreter: /system/bin/linker64' <<< "$headers"
    dynamic=$("$readelf" --dynamic "$binary")
    if grep -E 'RPATH|RUNPATH' <<< "$dynamic" | grep -E '/work/|linux-x86_64'; then
        echo "Build-host library path leaked into $tool" >&2
        exit 1
    fi
    while IFS= read -r library; do
        case "$library" in
            libc.so|libm.so|libdl.so|liblog.so) ;;
            *) echo "Undeclared host library required by $tool: $library" >&2; exit 1;;
        esac
    done < <(sed -n 's/.*(NEEDED).*\[\(.*\)\].*/\1/p' <<< "$dynamic")
done < "$repo_dir/build-tools.txt"

# Host executable dependencies must be Android platform libraries. Shared Python
# and Make are used explicitly by scripts; no bundled desktop executable exists.
for binary in "$host/bin/"*; do
    test -e "$binary" || { echo "Broken tool link: $binary" >&2; exit 1; }
    if [[ $(head -c 2 "$binary") == '#!' ]]; then
        head -n 1 "$binary" | grep -qx '#!/usr/bin/env bash'
    fi
done
printf 'Android ARM64 host ELF and entrypoint checks passed. Device checks still required.\n'
