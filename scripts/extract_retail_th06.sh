#!/usr/bin/env bash
set -euo pipefail

archive="${1:-/home/yann/yann/touhou/formal/game_exe/[th06] 东方红魔乡 (日文版).rar}"
destination="${2:-/home/yann/yann/touhou/formal/retail_extract/th06-20260831-unar}"

if [ -e "$destination" ] && [ -n "$(find "$destination" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
  echo "destination already exists and is not empty: $destination" >&2
  echo "pass a fresh destination path to avoid mixing retail validation inputs" >&2
  exit 1
fi

mkdir -p "$destination"
unar -f -o "$destination" "$archive"

echo "$destination/th06"
