#!/usr/bin/env bash
set -euo pipefail

archive_dir="${1:-/home/yann/yann/touhou/formal/game_exe}"

find "$archive_dir" -maxdepth 1 -type f -name '*.rar' -print0 |
  sort -z |
  while IFS= read -r -d '' archive; do
    sha256sum "$archive"
    7z l -slt "$archive" |
      awk '
        /^Path = / {
          path = substr($0, 8)
        }
        /^Size = / {
          size = substr($0, 8)
        }
        /^CRC = / {
          crc = substr($0, 7)
          lower = tolower(path)
          if (lower ~ /\.(exe|dat)$/ || lower ~ /score\.dat$/) {
            printf("  %s size=%s crc=%s\n", path, size, crc)
          }
        }
      '
  done
