#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/release-common.bash"
mkdir -p "$release_work_dir/logs"
exec > >(tee -a "$release_work_dir/logs/compiler-build.log") 2>&1
bash "$repo_dir/scripts/prepare-sources.sh"
bash "$repo_dir/scripts/build-llvm.sh"
printf 'Compiler build completed. Distribution assembly and device verification remain.\n'
