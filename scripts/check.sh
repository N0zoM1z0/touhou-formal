#!/usr/bin/env bash
set -euo pipefail

lake build
lake exe check

solver_output="$(mktemp)"
trap 'rm -f "$solver_output"' EXIT

lake exe th06_smt th06-sub-oob | z3 -in | tee "$solver_output"
grep -q '^sat$' "$solver_output"
