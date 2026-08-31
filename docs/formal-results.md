# Formal Results

This file tracks model-backed results that are strong enough to keep as project
outputs. A result must name its oracle and whether it is a counterexample,
control, or retail-validation candidate.

## ECL subTable lookup

| ID | Kind | Oracle | Status |
| --- | --- | --- | --- |
| `TH06-ECL-SUBTABLE-ARG0-256` | counterexample | `arg0 = 256`, `subCount = 1` reaches `CallEclSub` and reads outside `subTable` | Lean theorem, SMT `sat`, Wine retail confirmation: `retail-frame-stall` |
| `TH07-ECL-SUBTABLE-NEGATIVE` | counterexample | `subId = -1`, `subCount = 1` is unsafe under unchecked policy | Lean theorem, SMT `sat`, retail candidate |
| `TH08-ECL-SUBTABLE-NEGATIVE` | negative control | `subId = -1` returns before table lookup | Lean theorem, SMT `unsat` for counterexample query |
| `TH08-ECL-SUBTABLE-POSITIVE-OOB` | counterexample | `subId = 256`, `subCount = 1` is unsafe under TH08's nonnegative path | Lean theorem, SMT `sat`, retail candidate |
| `ECL-SUBTABLE-BOUNDED-SWEEP` | finite formal search | one shared sweep over `subCount ∈ {1,2}` and `subId ∈ {-1,0,1,256}` finds TH06/TH07 unchecked negative faults and TH08's first nonnegative OOB fault | Lean theorem |

Formal value: this separates two inputs that ordinary fuzzing can easily group
together as "bad sub ids." The source-backed model proves that TH07 and TH08
have different negative-id semantics.

Retail value: the TH06 case is no longer only a model result. The formal witness
has been lowered into a one-field `ecldata5.ecl` mutation and confirmed against
the extracted original game under Wine; see `docs/retail-validation.md`.

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
| `TH08-ECL-JUMP-MINUS-ONE` | cursor counterexample | low opcode 4 uses raw i32 operand 1 as a relative displacement; `-1` jumps before the buffer | Lean theorem, SMT `sat`, retail candidate |
| `ECL-TIMELINE-SIZE-WIDTH-SWEEP` | finite formal search | shared profile-derived boundary samples show TH06/TH07 signed `i16 size` admits `-1` before-buffer and `0` non-progress; TH08 unsigned `u8 size` removes the single-field negative case but still admits `0` non-progress and `255` at/past-end | Lean theorem, SMT `sat`/`unsat` controls |
| `ECL-RAW-NEXTOFFSET-WIDTH-SWEEP` | finite formal search | shared profile-derived boundary samples show TH06/TH07/TH08 raw `nextOffset : i16` all admit before-buffer, non-progress, and at/past-end cursor transfers | Lean theorem, SMT `sat` controls |
| `ECL-JUMP-CURSOR-SWEEP` | finite formal search | shared classifier separates `-1` before-buffer, `0` non-progress, in-bounds positive offsets, and at-end/past-end targets for TH06/TH07/TH08 jump fixtures | Lean theorem |

Formal value: fuzzing can observe hangs or divergent traces, but bounded formal
models can state the responsible invariant directly: a transition must either
halt, fault, yield, or move the instruction cursor. The original VM permits
non-moving and before-buffer transitions.

The size/nextOffset sweeps are deliberately generated from the shared profile
widths (`i16` versus `u8`) instead of title-local fixtures. That makes the TH08
timeline difference a modeled semantic delta rather than a hand-written
exception.

## Difficulty mask execution

| ID | Kind | Oracle | Status |
| --- | --- | --- | --- |
| `ECL-RAW-DIFFICULTY-OVERRIDE-DELTA` | semantic counterexample | `instructionMask = 1`, `activeMask = 1`, `overrideMask = 2` executes under TH06/TH07-style active-bit intersection but is skipped by TH08 raw ECL's contains-`active|override` rule; `instructionMask = 3` is the TH08 positive control | Lean theorem, SMT `sat` witness |

Formal value: this is not an out-of-bounds case. It is a behavioral equivalence
counterexample between superficially similar difficulty-mask fields. Random
fuzzing tends to report this as ordinary trace divergence, while the formal
model names the exact missing bit condition that makes TH08 raw ECL stricter
when `enemy->eclDifficultyMaskOverride` is nonzero.

## Raw ECL symbolic execution baseline

| ID | Kind | Oracle | Status |
| --- | --- | --- | --- |
| `ECL-RAW-STEP-SYMEX-BASELINE` | symbolic execution baseline | profile-driven raw ECL single-step executor enumerates time-gate, difficulty-skip, ordinary-advance, fixed-jump, and VM-error paths, then emits SMT path constraints for Z3 | Lean model, Z3-backed `symex` executable, check-script witnesses |
| `ECL-RAW-STEP-WITNESS-MATERIALIZATION` | solver-to-fixture bridge | Z3 `get-value` witnesses are encoded into raw ECL bytes by Lean using `HeaderShape.rawInstrShape`, decoded again, and replayed through `rawStep`; accepted fixtures must report `matchesPath=true` | TH08 all-path smoke covers 14 path classes under `activeMask=1`, `overrideMask=2`; single fixed-hex regression for TH08 `jumped-before-buffer` |

Formal value: this is the baseline the project should compare fuzzing against.
The executor is not given a concrete bug. It enumerates source-backed path
classes from the shared raw ECL step skeleton and asks Z3 whether each class is
reachable under a title profile and difficulty environment. Current regression
witnesses include TH06 ordinary-advance before-buffer, TH07 VM-error, TH08
fixed-jump before-buffer, TH08 difficulty-skip in-bounds under override, and
TH08 ordinary-advance non-progress.

The materializer is intentionally not a retail oracle. It proves that a solver
witness is byte-realizable under the modeled raw instruction shape and that the
same shared concrete step classifies it consistently. The next validation layer
must splice these bytes into a real ECL/DAT context and observe the retail game.

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
