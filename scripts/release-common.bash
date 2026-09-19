#!/usr/bin/env bash
# Shared exact-release paths and source pins. Source from Bash with set -euo pipefail.
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work_dir=${WORK_DIR:-/work}
release_environment=$(python3 "$repo_dir/scripts/release-config.py" "${NDK_RELEASE:-r29}" environment)
while IFS=$'\t' read -r key value; do
    [[ $key =~ ^[A-Z][A-Z0-9_]+$ && -n $value ]] || { echo 'Invalid release environment.' >&2; exit 1; }
    printf -v "$key" '%s' "$value"
done <<< "$release_environment"
unset release_environment key value
export NDK_RELEASE
release_work_dir="$work_dir/releases/$NDK_REVISION"
common_source_dir="$work_dir/src/common"
NDK_DIR=${NDK_DIR:-$work_dir/ndk/android-ndk-$NDK_RELEASE}
SOURCE_DIR=${SOURCE_DIR:-$release_work_dir/src/llvm-project}
BUILD_DIR=${BUILD_DIR:-$release_work_dir/build}
INSTALL_DIR=${INSTALL_DIR:-$release_work_dir/install/linux-aarch64}
OUTPUT_DIR=${OUTPUT_DIR:-$release_work_dir/dist/android-ndk-$NDK_RELEASE}
zlib_source="$common_source_dir/${ZLIB_ARCHIVE%.tar.gz}-$ZLIB_SHA256"
zstd_source="$common_source_dir/${ZSTD_ARCHIVE%.tar.gz}-$ZSTD_SHA256"

release_config() {
    python3 "$repo_dir/scripts/release-config.py" "$NDK_RELEASE" "$1"
}

verify_ndk_revision() {
    grep -qx "Pkg.Revision = $NDK_REVISION" "$NDK_DIR/source.properties"
}
