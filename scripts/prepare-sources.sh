#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/release-common.bash"
downloads="$work_dir/downloads"
source_root="$release_work_dir/src"
mkdir -p "$downloads" "$source_root" "$common_source_dir" "$work_dir/ndk"

# A changed pin cannot reuse a prepared source/build directory for that revision.
manifest=$(release_config json)
if [[ -f "$release_work_dir/release.json" ]]; then
    cmp <(printf '%s\n' "$manifest") "$release_work_dir/release.json" || {
        echo 'Source pins changed; select a fresh WORK_DIR for this revision.' >&2; exit 1;
    }
else
    printf '%s\n' "$manifest" > "$release_work_dir/release.json"
fi
release_config sources > "$release_work_dir/sources.tsv"
bash "$repo_dir/scripts/download-inputs.sh" "$release_work_dir/sources.tsv" "$downloads"

if [[ ! -d "$NDK_DIR" ]]; then
    stage=$(mktemp -d "$work_dir/ndk/.extract-XXXXXX")
    unzip -q "$downloads/$NDK_ARCHIVE" -d "$stage"
    mv "$stage/android-ndk-$NDK_RELEASE" "$NDK_DIR"
    rmdir "$stage"
fi
verify_ndk_revision
desktop="$NDK_DIR/toolchains/llvm/prebuilt/linux-x86_64"
grep -qx "based on $CLANG_REVISION" "$desktop/AndroidVersion.txt"
test -d "$desktop/lib/clang/$CLANG_MAJOR"
while IFS= read -r provenance; do
    test -f "$desktop/$provenance"
done < <(release_config provenance)
# Check the exact host source contract before spending time compiling LLVM.
patch --dry-run --batch --fuzz=0 -p1 -d "$NDK_DIR" < "$repo_dir/$HOST_PATCH"

extract_source() {
    local archive=$1 destination=$2 strip=$3 stage
    [[ ! -d "$destination" ]] || return 0
    stage=$(mktemp -d "$(dirname "$destination")/.extract-XXXXXX")
    tar -xf "$downloads/$archive" --strip-components="$strip" -C "$stage"
    mv "$stage" "$destination"
}
extract_source "$ANDROID_ARCHIVE" "$source_root/llvm-android" 0
extract_source "$ZLIB_ARCHIVE" "$zlib_source" 1
extract_source "$ZSTD_ARCHIVE" "$zstd_source" 1

if [[ ! -d "$SOURCE_DIR" ]]; then
    stage=$(mktemp -d "$source_root/.llvm-XXXXXX")
    tar -xf "$downloads/$LLVM_ARCHIVE" --strip-components=1 -C "$stage"
    python3 "$repo_dir/scripts/apply-android-changes.py" \
        "$stage" "$source_root/llvm-android" "$desktop/clang_source_info.md" \
        --base "$LLVM_BASE" --android-revision "$ANDROID_CHANGES" --svn "$LLVM_SVN" \
        --source-info-sha256 "$SOURCE_INFO_SHA256" --patch-manifest-sha256 "$PATCH_MANIFEST_SHA256"
    mv "$stage" "$SOURCE_DIR"
fi
printf 'Official %s (%s) sources ready: %s\n' "$NDK_RELEASE" "$NDK_REVISION" "$SOURCE_DIR"
