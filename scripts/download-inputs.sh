#!/usr/bin/env bash
set -euo pipefail

manifest=${1:?Pass the checksum-pinned source manifest}
downloads=${2:?Pass the download cache directory}
mkdir -p "$downloads"
while IFS=$'\t' read -r name checksum url; do
    [[ $name != */* && $name != .* && $checksum =~ ^[0-9a-f]{64}$ && $url == https://* ]]
    archive="$downloads/$name"
    if [[ ! -f "$archive" ]]; then
        curl --fail --location --proto '=https' --proto-redir '=https' \
            --retry 2 --output "$archive.part" "$url"
        printf '%s  %s\n' "$checksum" "$archive.part" | sha256sum --check --status
        mv "$archive.part" "$archive"
    fi
    printf '%s  %s\n' "$checksum" "$archive" | sha256sum --check
done < "$manifest"
