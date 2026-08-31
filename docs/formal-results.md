# Formal Results

This file tracks model-backed results that are strong enough to keep as project
outputs. A result must name its oracle and whether it is a counterexample,
control, or retail-validation candidate.

## ECL subTable lookup

| ID | Kind | Oracle | Status |
| --- | --- | --- | --- |
| `TH06-ECL-SUBTABLE-ARG0-256` | counterexample | `arg0 = 256`, `subCount = 1` reaches `CallEclSub` and reads outside `subTable` | Lean theorem, SMT `sat`, retail-calibrated seed |
| `TH07-ECL-SUBTABLE-NEGATIVE` | counterexample | `subId = -1`, `subCount = 1` is unsafe under unchecked policy | Lean theorem, SMT `sat`, retail candidate |
| `TH08-ECL-SUBTABLE-NEGATIVE` | negative control | `subId = -1` returns before table lookup | Lean theorem, SMT `unsat` for counterexample query |
| `TH08-ECL-SUBTABLE-POSITIVE-OOB` | counterexample | `subId = 256`, `subCount = 1` is unsafe under TH08's nonnegative path | Lean theorem, SMT `sat`, retail candidate |

Formal value: this separates two inputs that ordinary fuzzing can easily group
together as "bad sub ids." The source-backed model proves that TH07 and TH08
have different negative-id semantics.

## Loader boundary

| ID | Kind | Oracle | Status |
| --- | --- | --- | --- |
| `TH06-ECL-LOADER-7-BYTE` | boundary counterexample | zero-count buffer of 7 bytes faults on first missing timeline-offset byte | Lean theorem |
| `TH06-ECL-LOADER-8-BYTE` | control | zero-count buffer of 8 bytes reaches the modeled loaded-header state | Lean theorem |
| `TH08-ECL-LOADER-71-BYTE` | boundary counterexample | version-correct 71-byte buffer faults on first missing timeline-offset byte | Lean theorem |
| `TH08-ECL-LOADER-72-BYTE` | control | version-correct 72-byte zero-count buffer reaches the modeled loaded-header state | Lean theorem |

Formal value: these are exact first-operation boundaries. A defensive parser
would reject much earlier for policy reasons, but the original loader's actual
read order matters for compatibility and crash triage.

## Cursor liveness and wild jumps

| ID | Kind | Oracle | Status |
| --- | --- | --- | --- |
| `TH06-TIMELINE-SIZE-ZERO` | liveness counterexample | decoded `size = 0` leaves `nextCursor = fileOffset` | Lean theorem, retail candidate |
| `TH06-TIMELINE-SIZE-MINUS-ONE` | cursor counterexample | decoded `size = -1` makes the next decode cursor `-1` | Lean theorem, retail candidate |
| `TH06-ECL-NEXTOFFSET-ZERO` | liveness counterexample | raw instruction `offsetToNext = 0` leaves `nextCursor = fileOffset` | Lean theorem, retail candidate |
| `TH06-ECL-NEXTOFFSET-MINUS-ONE` | cursor counterexample | raw instruction `offsetToNext = -1` makes the next decode cursor `-1` | Lean theorem, retail candidate |
| `TH06-ECL-JUMP-MINUS-ONE` | cursor counterexample | `ECL_OPCODE_JUMP` with displacement `-1` jumps before the buffer | Lean theorem, SMT `sat`, retail candidate |
| `TH07-ECL-JUMP-MINUS-ONE` | cursor counterexample | `ECL_JUMP` with displacement `-1` jumps before the buffer | Lean theorem, SMT `sat`, retail candidate |
| `ECL-JUMP-CURSOR-SWEEP` | finite formal search | shared classifier separates `-1` before-buffer, `0` non-progress, in-bounds positive offsets, and at-end/past-end targets | Lean theorem |

Formal value: fuzzing can observe hangs or divergent traces, but bounded formal
models can state the responsible invariant directly: a transition must either
halt, fault, yield, or move the instruction cursor. The original VM permits
non-moving and before-buffer transitions.

## ANM entry chain

| ID | Kind | Oracle | Status |
| --- | --- | --- | --- |
| `TH06-ANM-SINGLE-ENTRY` | control | TH06 entry profile decodes a zero entry and does not model a loader chain walk | Lean theorem |
| `TH07-ANM-NEXTOFFSET-CHAIN` | control | TH07 entry profile decodes `nextOffset = 0x40` and computes next cursor `0x40` | Lean theorem |
| `TH08-ANM-NEXTOFFSET-CHAIN` | control | TH08 entry profile decodes `nextOffset = 0x40` and computes next cursor `0x40` | Lean theorem |

Formal value: ANM now has the same profile-driven entry point as ECL, but full
ANM script execution remains intentionally out of scope until its opcode
semantics are source-backed.

## Verification command

```bash
./scripts/check.sh
```
