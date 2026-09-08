#!/usr/bin/env bash
set -euo pipefail

mkdir -p /work/logs
exec > >(tee -a /work/logs/compiler-build.log) 2>&1
bash /port/scripts/prepare-sources.sh
bash /port/scripts/build-llvm.sh
printf 'Compiler build completed. Distribution assembly and device verification remain.\n'
