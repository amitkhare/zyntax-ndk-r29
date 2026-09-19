#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/release-common.bash"
ndk="$(cd "${1:?Pass the assembled NDK directory}" && pwd -P)"
host="$ndk/toolchains/llvm/prebuilt/linux-arm64"
readelf=${READELF:-$NDK_DIR/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-readelf}

grep -qx "Pkg.Revision = $NDK_REVISION" "$ndk/source.properties"
cmp <(release_config tools) "$ndk/build-tools.txt"
cmp <(release_config json) "$ndk/release.json"
test -d "$host/sysroot/usr/include"
test -d "$host/lib/clang/$CLANG_MAJOR/lib/linux"
test ! -e "$ndk/toolchains/llvm/prebuilt/linux-x86_64"
test -z "$(find "$host" -name lldb-server -print -quit)"
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
done < <(release_config tools)

# Host executable dependencies must be Android platform libraries. Shared Python
# and Make are used explicitly by scripts; no bundled desktop executable exists.
for binary in "$host/bin/"*; do
    test -e "$binary" || { echo "Broken tool link: $binary" >&2; exit 1; }
    if [[ $(head -c 2 "$binary") == '#!' ]]; then
        head -n 1 "$binary" | grep -qx '#!/usr/bin/env bash'
    fi
done
printf 'Android ARM64 host ELF and entrypoint checks passed. Device checks still required.\n'
