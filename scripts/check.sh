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

python3 scripts/symex_materialize_raw_step.py th06 jumped-before-buffer 8 0 --ecl-file | tee "$solver_output"
grep -q '"matchesPath": "true"' "$solver_output"
grep -q '"eclFileHex": "010000000000000000000000000000001400000000000000020000000008000000000000ffffffff"' "$solver_output"

python3 scripts/symex_materialize_raw_step.py th08 all 1 2 > "$solver_output"
python3 -m json.tool "$solver_output" >/dev/null
python3 -c 'import json,sys; xs=json.load(open(sys.argv[1])); assert len(xs) == 14; assert all(r["status"] == "sat" and r["fixture"]["matchesPath"] == "true" for r in xs)' "$solver_output"

python3 scripts/symex_candidate_queue.py --env th06:8:0:retail-lunatic-bit3 --path jumped-before-buffer > "$solver_output"
python3 -m json.tool "$solver_output" >/dev/null
python3 -c 'import json,sys; data=json.load(open(sys.argv[1])); assert data["candidateCount"] == 1; c=data["candidates"][0]; assert c["risk"]["class"] == "cursor-underflow"; assert c["nextAction"].startswith("retained Wine confirmation exists")' "$solver_output"

python3 scripts/symex_materialize_body_step.py th08 all 1 2 > "$solver_output"
python3 -m json.tool "$solver_output" >/dev/null
python3 -c 'import json,sys; xs=json.load(open(sys.argv[1])); assert len(xs) == 17; assert all(r["status"] == "sat" and r["fixture"]["matchesPath"] == "true" for r in xs); assert any(r["path"] == "int-divisor-zero" and r["fixture"]["faultKind"] == "divide-by-zero" for r in xs); assert any(r["path"].startswith("int-condjump-") for r in xs)' "$solver_output"

python3 scripts/symex_body_candidate_queue.py --env th06:8:0:retail-lunatic-bit3 --path int-divisor-zero > "$solver_output"
python3 -m json.tool "$solver_output" >/dev/null
python3 -c 'import json,sys; data=json.load(open(sys.argv[1])); assert data["candidateCount"] == 1; c=data["candidates"][0]; assert c["risk"]["class"] == "arithmetic-fault"; assert c["fixture"]["faultKind"] == "divide-by-zero"' "$solver_output"

lake exe symex query-int-resolver th06 raw-immediate 0 | z3 -in | tee "$solver_output"
grep -q '^unsat$' "$solver_output"

python3 scripts/symex_materialize_int_resolver.py th07 all 0 > "$solver_output"
python3 -m json.tool "$solver_output" >/dev/null
python3 -c 'import json,sys; xs=json.load(open(sys.argv[1])); assert len(xs) == 3; assert all(r["status"] == "sat" and r["fixture"]["matchesPath"] == "true" for r in xs); assert {r["path"] for r in xs} == {"raw-immediate", "resolved-host", "resolved-default-raw"}' "$solver_output"

python3 scripts/symex_materialize_int_resolver.py th06 all 0 > "$solver_output"
python3 -m json.tool "$solver_output" >/dev/null
python3 -c 'import json,sys; xs=json.load(open(sys.argv[1])); assert len(xs) == 2; assert all(r["status"] == "sat" and r["fixture"]["matchesPath"] == "true" for r in xs); assert {r["path"] for r in xs} == {"resolved-host", "resolved-default-raw"}' "$solver_output"

python3 scripts/symex_int_resolver_queue.py > "$solver_output"
python3 -m json.tool "$solver_output" >/dev/null
python3 -c 'import json,sys; data=json.load(open(sys.argv[1])); assert data["candidateCount"] == 8; assert all(c["status"] == "sat" and c["fixture"]["matchesPath"] == "true" for c in data["candidates"]); assert {(c["title"], c["path"]) for c in data["candidates"]} == {("th06", "resolved-host"), ("th06", "resolved-default-raw"), ("th07", "raw-immediate"), ("th07", "resolved-host"), ("th07", "resolved-default-raw"), ("th08", "raw-immediate"), ("th08", "resolved-host"), ("th08", "resolved-default-raw")}' "$solver_output"

lake exe symex query-callret th06 call-no-op 1 0 | z3 -in | tee "$solver_output"
grep -q '^unsat$' "$solver_output"

lake exe symex query-callret th08 ret-stack-read-before-stack 1 0 | z3 -in | tee "$solver_output"
grep -q '^unsat$' "$solver_output"

python3 scripts/symex_materialize_callret_step.py th08 all 1 0 > "$solver_output"
python3 -m json.tool "$solver_output" >/dev/null
python3 -c 'import json,sys; xs=json.load(open(sys.argv[1])); assert len(xs) == 10; assert all(r["status"] == "sat" and r["fixture"]["matchesPath"] == "true" for r in xs); assert {r["path"] for r in xs} == {"call-stack-write-before-stack", "call-stack-write-at-or-past-stack", "call-lookup-fault", "call-entered", "call-no-op", "ret-stack-read-at-or-past-stack", "ret-restored", "ret-exit-child", "ret-child-index-before-array", "ret-child-index-at-or-past-array"}' "$solver_output"

python3 scripts/symex_materialize_callret_step.py th06 all 1 0 > "$solver_output"
python3 -m json.tool "$solver_output" >/dev/null
python3 -c 'import json,sys; xs=json.load(open(sys.argv[1])); assert len(xs) == 7; assert all(r["status"] == "sat" and r["fixture"]["matchesPath"] == "true" for r in xs); assert "ret-stack-read-before-stack" in {r["path"] for r in xs}' "$solver_output"

python3 scripts/symex_callret_candidate_queue.py > "$solver_output"
python3 -m json.tool "$solver_output" >/dev/null
python3 -c 'import json,sys; data=json.load(open(sys.argv[1])); assert data["candidateCount"] == 41; assert all(c["status"] == "sat" and c["fixture"]["matchesPath"] == "true" for c in data["candidates"])' "$solver_output"

lake exe symex query-condcall th06 condcall-no-op 1 0 | z3 -in | tee "$solver_output"
grep -q '^unsat$' "$solver_output"

lake exe symex query-condcall th07 condcall-entered 1 0 | z3 -in | tee "$solver_output"
grep -q '^unsat$' "$solver_output"

lake exe symex query-condcall th08 condcall-entered 1 0 | z3 -in | tee "$solver_output"
grep -q '^unsat$' "$solver_output"

python3 scripts/symex_materialize_condcall_step.py th06 all 1 0 > "$solver_output"
python3 -m json.tool "$solver_output" >/dev/null
python3 -c 'import json,sys; xs=json.load(open(sys.argv[1])); assert len(xs) == 8; assert all(r["status"] == "sat" and r["fixture"]["matchesPath"] == "true" for r in xs); assert {r["path"] for r in xs} == {"condcall-false-before-buffer", "condcall-false-non-progress", "condcall-false-in-bounds", "condcall-false-at-or-past-end", "condcall-stack-write-before-stack", "condcall-stack-write-at-or-past-stack", "condcall-lookup-fault", "condcall-entered"}' "$solver_output"

python3 scripts/symex_condcall_candidate_queue.py > "$solver_output"
python3 -m json.tool "$solver_output" >/dev/null
python3 -c 'import json,sys; data=json.load(open(sys.argv[1])); assert data["candidateCount"] == 16; assert all(c["status"] == "sat" and c["fixture"]["matchesPath"] == "true" for c in data["candidates"]); assert {c["risk"]["class"] for c in data["candidates"]} == {"call-stack-oob-write", "call-subtable-oob-read", "condcall-fallthrough-cursor", "condcall-control"}' "$solver_output"
