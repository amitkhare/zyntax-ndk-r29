#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
release=${NDK_RELEASE:-r29}
[[ $release =~ ^r[0-9]+[a-z]?$ ]] || { echo 'Invalid NDK release.' >&2; exit 1; }
mkdir -p "$repo_dir/.work/downloads"

# Docker Desktop bind mounts require native Windows paths when using Git Bash.
docker_root=$repo_dir
if command -v cygpath >/dev/null 2>&1; then
    docker_root=$(cygpath -w "$repo_dir")
fi
export MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*'

docker build --tag zyntax-ndk-builder "$docker_root"
# Retain the existing volume; exact revision subdirectories isolate new builds.
docker volume create zyntax-ndk-r29-work >/dev/null
docker run --rm --init --name "zyntax-ndk-$release-build" \
    --mount type=volume,source=zyntax-ndk-r29-work,target=/work \
    --mount "type=bind,source=$docker_root,target=/port,readonly" \
    --mount "type=bind,source=$docker_root/.work/downloads,target=/work/downloads" \
    --env "BUILD_JOBS=${BUILD_JOBS:-2}" \
    --env "NDK_RELEASE=$release" \
    zyntax-ndk-builder /port/scripts/build-container.sh
