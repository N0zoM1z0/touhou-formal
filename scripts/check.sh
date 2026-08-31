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

lake exe smt th08-raw-difficulty-override-delta | z3 -in | tee "$solver_output"
grep -q '^sat$' "$solver_output"

lake exe symex query th06 advanced-before-buffer 1 0 | z3 -in | tee "$solver_output"
grep -q '^sat$' "$solver_output"

lake exe symex query th07 vm-error 1 0 | z3 -in | tee "$solver_output"
grep -q '^sat$' "$solver_output"

lake exe symex query th08 jumped-before-buffer 1 0 | z3 -in | tee "$solver_output"
grep -q '^sat$' "$solver_output"

lake exe symex query th08 skipped-in-bounds 1 2 | z3 -in | tee "$solver_output"
grep -q '^sat$' "$solver_output"

lake exe symex query th08 advanced-non-progress 1 0 | z3 -in | tee "$solver_output"
grep -q '^sat$' "$solver_output"

python3 scripts/symex_materialize_raw_step.py th08 jumped-before-buffer 1 0 | tee "$solver_output"
grep -q '"matchesPath": "true"' "$solver_output"
grep -q '"hex": "00000000040000000001000000000000ffffffff"' "$solver_output"

python3 scripts/symex_materialize_raw_step.py th08 all 1 2 > "$solver_output"
python3 -m json.tool "$solver_output" >/dev/null
python3 -c 'import json,sys; xs=json.load(open(sys.argv[1])); assert len(xs) == 14; assert all(r["status"] == "sat" and r["fixture"]["matchesPath"] == "true" for r in xs)' "$solver_output"

python3 scripts/symex_candidate_queue.py --env th06:8:0:retail-lunatic-bit3 --path jumped-before-buffer > "$solver_output"
python3 -m json.tool "$solver_output" >/dev/null
python3 -c 'import json,sys; data=json.load(open(sys.argv[1])); assert data["candidateCount"] == 1; c=data["candidates"][0]; assert c["risk"]["class"] == "cursor-underflow"; assert c["nextAction"].startswith("retained Wine confirmation exists")' "$solver_output"
