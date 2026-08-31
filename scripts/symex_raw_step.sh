#!/usr/bin/env bash
set -euo pipefail

title="${1:-th08}"
active_mask="${2:-1}"
override_mask="${3:-0}"

while IFS= read -r path_name; do
  status="$(
    lake exe symex query "$title" "$path_name" "$active_mask" "$override_mask" |
      z3 -in |
      sed -n '1p'
  )"
  echo "$title,$path_name,$active_mask,$override_mask,$status"
done < <(lake exe symex list-paths)
