#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/release-common.bash"

verify_ndk_revision
[[ ! -e "$OUTPUT_DIR" ]] || { echo "Output already exists: $OUTPUT_DIR" >&2; exit 1; }
while IFS= read -r tool; do
    test -x "$INSTALL_DIR/bin/$tool"
done < <(release_config tools)

mkdir -p "$(dirname "$OUTPUT_DIR")"
stage=$(mktemp -d "$(dirname "$OUTPUT_DIR")/.assemble-XXXXXX")
source_stage="$stage/source"
output_stage="$stage/android-ndk-$NDK_RELEASE"
desktop_rel=toolchains/llvm/prebuilt/linux-x86_64
host_rel=toolchains/llvm/prebuilt/linux-arm64
mkdir -p "$source_stage/$desktop_rel/bin" "$output_stage/$host_rel/bin"

# Apply source changes to a staging copy, never to the desktop cross-compiler.
cp -a "$NDK_DIR/build" "$NDK_DIR/ndk-build" "$source_stage/"
cp -a "$NDK_DIR/$desktop_rel/bin/clang-tidy.sh" "$source_stage/$desktop_rel/bin/"
patch --batch --fuzz=0 -p1 -d "$source_stage" < "$repo_dir/$HOST_PATCH"
cp -a "$source_stage/build" "$source_stage/ndk-build" "$output_stage/"
cp -a "$NDK_DIR/meta" "$NDK_DIR/sources" "$NDK_DIR/source.properties" \
    "$NDK_DIR/NOTICE" "$NDK_DIR/NOTICE.toolchain" "$NDK_DIR/CHANGELOG.md" "$output_stage/"

host="$output_stage/$host_rel"
while IFS= read -r tool; do
    cp -a "$INSTALL_DIR/bin/$tool" "$host/bin/"
done < <(release_config tools)
# These are the official target/API driver scripts, not architecture aliases.
cp -a "$NDK_DIR/$desktop_rel/bin/"*-clang \
    "$NDK_DIR/$desktop_rel/bin/"*-clang++ "$host/bin/"
cp -a "$source_stage/$desktop_rel/bin/clang-tidy.sh" "$host/bin/"
ln -s ld.lld "$host/bin/ld"

# Keep the official target artifacts byte-for-byte; desktop host libraries and
# executables are not copied. Resource scripts for desktop profiling are omitted.
cp -a "$NDK_DIR/$desktop_rel/sysroot" "$host/"
mkdir -p "$host/lib/clang/$CLANG_MAJOR"
# Target debugger servers are not compiler runtimes and are outside this package.
tar -C "$NDK_DIR/$desktop_rel/lib/clang/$CLANG_MAJOR" --exclude='*/lldb-server' \
    -cf - include lib share | tar -C "$host/lib/clang/$CLANG_MAJOR" -xf -
cp -a "$NDK_DIR/$desktop_rel/NOTICE" "$NDK_DIR/$desktop_rel/AndroidVersion.txt" \
    "$NDK_DIR/$desktop_rel/clang_source_info.md" "$host/"
while IFS= read -r provenance; do
    cp -a "$NDK_DIR/$desktop_rel/$provenance" "$host/"
done < <(release_config provenance)

notices="$output_stage/notices"
mkdir -p "$notices"
cp "$repo_dir/LICENSE" "$notices/port-LICENSE"
cp "$repo_dir/NOTICE.md" "$notices/port-NOTICE.md"
cp "$SOURCE_DIR/llvm/LICENSE.TXT" "$notices/LLVM-LICENSE.TXT"
cp "$zlib_source/LICENSE" "$notices/zlib-LICENSE"
cp "$zstd_source/LICENSE" "$notices/zstd-LICENSE"
release_config sources > "$output_stage/sources.tsv"
release_config tools > "$output_stage/build-tools.txt"
release_config json > "$output_stage/release.json"
cp "$repo_dir/docs/build-distribution.md" "$output_stage/README.md"
cp "$repo_dir/$HOST_PATCH" "$notices/"

bash "$repo_dir/scripts/verify-build-tools.sh" "$output_stage"
mv "$output_stage" "$OUTPUT_DIR"
printf 'Assembled build distribution: %s\n' "$OUTPUT_DIR"
