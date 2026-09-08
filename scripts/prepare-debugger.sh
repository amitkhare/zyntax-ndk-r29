#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work_dir=${WORK_DIR:-/work}
downloads="$work_dir/downloads"
target="$work_dir/debugger-target"
swig="$work_dir/src/swig"
manifest="$repo_dir/sources-debugger.tsv"

bash "$repo_dir/scripts/download-inputs.sh" "$manifest" "$downloads"
mkdir -p "$work_dir/src"

if [[ ! -e "$swig" ]]; then
    stage=$(mktemp -d "$work_dir/src/.swig-XXXXXX")
    tar -xf "$downloads/swig-88649f55.tar.gz" --strip-components=1 -C "$stage"
    mv "$stage" "$swig"
fi
test -f "$swig/CMakeLists.txt"

if [[ ! -e "$target" ]]; then
    stage=$(mktemp -d "$work_dir/.debugger-target-XXXXXX")
    while IFS=$'\t' read -r name checksum url; do
        if [[ "$name" == *.deb ]]; then
            dpkg-deb --extract "$downloads/$name" "$stage"
        fi
    done < "$manifest"
    cp "$manifest" "$stage/sources-debugger.tsv"
    mv "$stage" "$target"
fi
cmp "$manifest" "$target/sources-debugger.tsv" || {
    echo 'Debugger input pins changed; use a fresh debugger-target directory.' >&2
    exit 1
}

# Locate the package prefix from the actual payload, not an application ID.
mapfile -d '' -t libraries < <(find "$target" -type f -path '*/lib/libpython3.14.so' -print0)
[[ ${#libraries[@]} == 1 ]] || {
    echo 'Expected one unambiguous Python package prefix.' >&2
    exit 1
}
prefix=${libraries[0]%/lib/libpython3.14.so}
printf '%s\n' "$prefix" > "$target/prefix.txt"
printf 'Debugger inputs ready. TARGET_PREFIX=%q\n' "$prefix"
