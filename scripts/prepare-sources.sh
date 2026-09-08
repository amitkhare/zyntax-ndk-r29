#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work_dir=${WORK_DIR:-/work}
downloads="$work_dir/downloads"
mkdir -p "$downloads" "$work_dir/src" "$work_dir/ndk"

bash "$repo_dir/scripts/download-inputs.sh" "$repo_dir/sources.tsv" "$downloads"

ndk="$work_dir/ndk/android-ndk-r29"
if [[ ! -d "$ndk" ]]; then
    stage=$(mktemp -d "$work_dir/ndk/.extract-XXXXXX")
    unzip -q "$downloads/android-ndk-r29-linux.zip" -d "$stage"
    mv "$stage/android-ndk-r29" "$ndk"
    rmdir "$stage"
fi
grep -qx 'Pkg.Revision = 29.0.14206865' "$ndk/source.properties"

extract_source() {
    local archive=$1 destination=$2 strip=$3 stage
    [[ ! -d "$destination" ]] || return 0
    stage=$(mktemp -d "$work_dir/src/.extract-XXXXXX")
    tar -xf "$downloads/$archive" --strip-components="$strip" -C "$stage"
    mv "$stage" "$destination"
}
extract_source llvm-android-1dab3288.tar.gz "$work_dir/src/llvm-android" 0
extract_source zlib-1.3.1.tar.gz "$work_dir/src/zlib" 1
extract_source zstd-1.5.6.tar.gz "$work_dir/src/zstd" 1

llvm="$work_dir/src/llvm-project"
if [[ ! -d "$llvm" ]]; then
    stage=$(mktemp -d "$work_dir/src/.llvm-XXXXXX")
    tar -xf "$downloads/llvm-project-386af4a5.tar.gz" --strip-components=1 -C "$stage"
    python3 "$repo_dir/scripts/apply-android-changes.py" \
        "$stage" "$work_dir/src/llvm-android" \
        "$ndk/toolchains/llvm/prebuilt/linux-x86_64/clang_source_info.md"
    mv "$stage" "$llvm"
fi
printf 'Official r29 sources ready: %s\n' "$llvm"
