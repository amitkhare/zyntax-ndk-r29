#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$repo_dir/.work/downloads"

# Docker Desktop bind mounts require native Windows paths when using Git Bash.
docker_root=$repo_dir
if command -v cygpath >/dev/null 2>&1; then
    docker_root=$(cygpath -w "$repo_dir")
fi
export MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='*'

docker build --tag zyntax-ndk-r29-builder "$docker_root"
docker volume create zyntax-ndk-r29-work >/dev/null
docker run --rm --init --name zyntax-ndk-r29-build \
    --mount type=volume,source=zyntax-ndk-r29-work,target=/work \
    --mount "type=bind,source=$docker_root,target=/port,readonly" \
    --mount "type=bind,source=$docker_root/.work/downloads,target=/work/downloads" \
    --env "BUILD_JOBS=${BUILD_JOBS:-2}" \
    zyntax-ndk-r29-builder /port/scripts/build-container.sh
