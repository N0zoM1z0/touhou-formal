#!/usr/bin/env bash
set -euo pipefail

lake build
lake exe check

solver_output="$(mktemp)"
trap 'rm -f "$solver_output"' EXIT

lake exe smt th06-sub-oob | z3 -in | tee "$solver_output"
grep -q '^sat$' "$solver_output"

lake exe smt th07-negative-oob | z3 -in | tee "$solver_output"
grep -q '^sat$' "$solver_output"

lake exe smt th08-negative-noop-unsat | z3 -in | tee "$solver_output"
grep -q '^unsat$' "$solver_output"

lake exe smt th08-positive-oob | z3 -in | tee "$solver_output"
grep -q '^sat$' "$solver_output"

lake exe smt th06-jump-minus-one-oob | z3 -in | tee "$solver_output"
grep -q '^sat$' "$solver_output"

lake exe smt th07-jump-minus-one-oob | z3 -in | tee "$solver_output"
grep -q '^sat$' "$solver_output"

lake exe smt th08-jump-minus-one-oob | z3 -in | tee "$solver_output"
grep -q '^sat$' "$solver_output"

lake exe smt th06-timeline-size-before-buffer | z3 -in | tee "$solver_output"
grep -q '^sat$' "$solver_output"

lake exe smt th07-timeline-size-before-buffer | z3 -in | tee "$solver_output"
grep -q '^sat$' "$solver_output"

lake exe smt th08-timeline-size-before-buffer-unsat | z3 -in | tee "$solver_output"
grep -q '^unsat$' "$solver_output"

lake exe smt th08-timeline-size-nonprogress | z3 -in | tee "$solver_output"
grep -q '^sat$' "$solver_output"

lake exe smt th06-nextoffset-before-buffer | z3 -in | tee "$solver_output"
grep -q '^sat$' "$solver_output"

lake exe smt th07-nextoffset-before-buffer | z3 -in | tee "$solver_output"
grep -q '^sat$' "$solver_output"

lake exe smt th08-nextoffset-before-buffer | z3 -in | tee "$solver_output"
grep -q '^sat$' "$solver_output"
