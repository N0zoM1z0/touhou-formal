# Symbolic Execution Baseline

The baseline symbolic executor is SMT-backed and profile-driven. Lean owns the
source-backed VM model and emits SMT-LIB path queries; Z3 solves the path
constraints and returns concrete witnesses.

## Current scope

Current coverage is the raw ECL single-step skeleton shared by TH06, TH07, and
TH08:

1. instruction dispatch is gated by `currentTime == instruction.time`;
2. the title's raw difficulty-mask policy decides execute versus skip;
3. `UNIMP` returns VM error;
4. the profile's fixed jump opcode jumps by its raw displacement operand;
5. all other modeled opcodes advance by `nextOffset`;
6. resulting cursor transfers are classified as before-buffer, non-progress,
   in-bounds, or at/past-end.

This intentionally avoids hand-selecting a suspicious bug site. The executor
enumerates generic path classes and asks Z3 for witnesses.

## Commands

List path classes:

```bash
lake exe symex list-paths
```

Emit and solve one query:

```bash
lake exe symex query th08 jumped-before-buffer 1 0 | z3 -in
```

Emit a value-oriented query for machine parsing:

```bash
lake exe symex query-values th08 jumped-before-buffer 1 0 | z3 -in
```

Run a matrix for one title and difficulty environment:

```bash
./scripts/symex_raw_step.sh th08 1 2
```

Solve one path and materialize it into raw ECL bytes:

```bash
./scripts/symex_materialize_raw_step.py th08 jumped-before-buffer 1 0
```

Materialize a minimal one-sub ECL file rather than only the raw instruction:

```bash
./scripts/symex_materialize_raw_step.py th06 jumped-before-buffer 8 0 --ecl-file
```

Solve and materialize every path class for a title/environment:

```bash
./scripts/symex_materialize_raw_step.py th08 all 1 2
```

Build a sorted candidate queue:

```bash
./scripts/symex_candidate_queue.py
```

The optional numeric arguments are `activeMask` and `overrideMask`; both must fit
in an unsigned byte. `overrideMask` is semantically relevant to TH08 raw ECL and
ignored by the TH06/TH07 active-bit-intersection policy.

## Candidate queue

`scripts/symex_candidate_queue.py` is the current non-manual triage layer. It
uses the materializer for each requested title/environment/path, then ranks
records by generic path properties:

- `cursor-underflow` and `cursor-out-of-range`: high priority;
- `liveness`: high priority;
- `explicit-vm-error`: medium priority;
- in-bounds execution/skip paths: low priority controls;
- time-gate yield: coverage control.

The default matrix currently covers:

- TH06 active bit 0;
- TH06 retail Lunatic bit 3 (`activeMask = 8`);
- TH07 active bit 0;
- TH08 active bit 0;
- TH08 active bit 0 plus override bit 1.

A full default run on 2026-08-31 produced 70 satisfiable candidates:

```text
cursor-underflow: 15
cursor-out-of-range: 15
liveness: 15
reachable-control-path: 15
explicit-vm-error: 5
time-gate-control: 5
```

This is not yet a claim that all 45 high-priority candidates are distinct retail
bugs. It is the formal queue that should replace ad-hoc manual hunting: every
entry has a solver witness, a Lean-materialized byte fixture, and a concrete
`rawStep` replay result.

## Witness materialization

The materialization path is deliberately split by responsibility:

1. Lean emits a profile-derived SMT query for a requested path class.
2. Z3 solves the path and returns fixed witness fields via `get-value`.
3. Python parses the solver values only; it does not contain TH06/TH07/TH08 wire
   offsets.
4. Lean encodes the witness into little-endian raw ECL bytes using the same
   `HeaderShape.rawInstrShape` profile, decodes those bytes back into a raw
   prefix/jump operands, and replays `rawStep`.
5. Optionally, Lean wraps the raw instruction in a minimal one-sub ECL file
   using the same title `HeaderShape`.
6. The script accepts the fixture only when `matchesPath=true`.

For example, the TH08 `jumped-before-buffer` path currently materializes to:

```text
00000000040000000001000000000000ffffffff
```

Decoded under the TH08 profile, this is `time = 0`, `opcode = 4`,
`nextOffset = 0`, `difficultyMask = 1`, `operandFlags = 0`,
`RawInt(0) = 0`, and `RawInt(1) = -1`; replaying the concrete step yields
`action=jumped`, `cursorClass=before-buffer`.

The same path under TH06 with a retail Lunatic active mask (`8`) materializes a
minimal one-sub ECL file:

```text
010000000000000000000000000000001400000000000000020000000008000000000000ffffffff
```

## Baseline interpretation

Representative Z3 witnesses already covered by `scripts/check.sh`:

- TH06 `advanced-before-buffer`: ordinary opcode, executing difficulty mask, and
  `nextOffset = -1`.
- TH07 `vm-error`: executing difficulty mask and `opcode = 1`.
- TH08 `jumped-before-buffer`: `opcode = 4` and `jumpDisplacement = -1`.
- TH08 `skipped-in-bounds` with `activeMask = 1`, `overrideMask = 2`: a
  difficulty-mask skip path where cursor advancement itself is in-bounds.
- TH08 `advanced-non-progress`: executing ordinary opcode with `nextOffset = 0`.

These are not final retail findings by themselves. They are the baseline path
coverage that later bounded opcode semantics, full subroutine state, and
metamorphic checks should reuse. The materialized hex fixtures are the next
bridge into DAT/ECL mutation and Wine validation.

The TH06 `jumped-before-buffer` materialized witness has been taken through that
bridge once: `scripts/retail_confirm_th06_raw_symex.py` splices it into a
reachable stage-5 subroutine entry and the retained 2026-08-31 repeat run
classifies the mutant as `crash-dialog` in 2/2 Wine attempts.
