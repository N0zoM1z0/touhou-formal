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

The first opcode-body layer is also modeled through shared title profiles:

1. `JUMPDEC` decrements operand slot 2, jumps iff the decremented value is
   positive, and otherwise advances by `nextOffset`;
2. integer conditional jumps are profile-backed for TH06's compare-register
   branch opcodes and TH07/TH08's operand-resolved compare opcodes;
3. integer div/mod hazards use source-backed opcode lists and divisor operand
   slots on the immediate/raw branch.

The integer rvalue resolver is modeled as its own shared layer: TH06 always
calls `GetVar`, while TH07/TH08 use operand-mask bits to choose raw immediates
or selector resolution. Known selector ranges, source-backed exclusions, and
default-to-raw fallthrough are title-profile facts.

Plain CALL/RET stack behavior is also modeled as a shared layer. The model
tracks CALL's save-before-guard order, title-specific stack sizes and increment
guards, `CallEclSub` lookup policy, RET's decrement-before-restore order, and
TH08's child-context exit path on RET depth underflow.

TH06 conditional CALL opcodes are modeled as a guarded dispatch layer. The
guard resolves `cmpLhs` through the same integer resolver used elsewhere,
compares it with raw `cmpRhs`, falls through by `offsetToNext` when false, and
reuses the same shared CALL stack/subTable body when true.

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

Emit and solve one body-level query:

```bash
lake exe symex query-body-values th08 int-divisor-zero 1 2 | z3 -in
```

List and solve integer resolver branches:

```bash
lake exe symex list-int-resolver-paths
lake exe symex query-int-resolver-values th07 resolved-default-raw 0 | z3 -in
```

List and solve CALL/RET stack branches:

```bash
lake exe symex list-callret-paths
lake exe symex query-callret-values th08 ret-child-index-before-array 1 0 | z3 -in
```

List and solve TH06 conditional CALL branches:

```bash
lake exe symex list-condcall-paths
lake exe symex query-condcall-values th06 condcall-lookup-fault 1 0 | z3 -in
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

Solve/materialize body-level paths:

```bash
./scripts/symex_materialize_body_step.py th08 all 1 2
./scripts/symex_body_candidate_queue.py
```

Solve/materialize integer resolver paths:

```bash
./scripts/symex_materialize_int_resolver.py th07 all 0
./scripts/symex_int_resolver_queue.py
```

Solve/materialize CALL/RET stack paths:

```bash
./scripts/symex_materialize_callret_step.py th08 all 1 0
./scripts/symex_callret_candidate_queue.py
```

Solve/materialize TH06 conditional CALL paths:

```bash
./scripts/symex_materialize_condcall_step.py th06 all 1 0
./scripts/symex_condcall_candidate_queue.py
```

Evaluate the current formal-vs-fuzz effectiveness baseline:

```bash
python3 scripts/evaluate_symex_effectiveness.py
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

## Body candidate queue

`scripts/symex_body_candidate_queue.py` is the corresponding non-manual triage
layer for the first opcode-body slice. It enumerates these path classes:

- `decjump-taken-*` for four cursor classes;
- `decjump-not-taken-*` for four cursor classes;
- `int-condjump-taken-*` for four cursor classes;
- `int-condjump-not-taken-*` for four cursor classes;
- `int-divisor-zero`.

A full default run on 2026-08-31 produced 85 satisfiable materialized
candidates:

```text
arithmetic-fault: 5
cursor-underflow: 20
cursor-out-of-range: 20
liveness: 20
reachable-control-path: 20
```

All 85 replayed through Lean with `matchesPath=true`. The five
`arithmetic-fault` witnesses are integer div/mod zero-divisor paths: one per
default title/difficulty environment. They are source-backed body-level formal
findings, not yet retail-confirmed cases.

## Integer resolver candidate queue

`scripts/symex_int_resolver_queue.py` enumerates the title-specific rvalue
resolver branches:

- TH06: `resolved-host` and `resolved-default-raw`;
- TH07/TH08: `raw-immediate`, `resolved-host`, and
  `resolved-default-raw`.

A full default run on 2026-08-31 produced 8 satisfiable materialized resolver
candidates:

```text
mask-set-known-selector: 3
mask-set-default-raw: 3
mask-clear-raw-immediate: 2
```

All 8 replayed through Lean with `matchesPath=true`. This confirms a useful
non-fuzzing distinction: an operand-mask bit can be set while the selector still
falls through to raw-value behavior. That branch is easy for random testing to
miss or misclassify because the raw bytes look like a variable reference, but
the source resolver returns the operand unchanged.

## CALL/RET candidate queue

`scripts/symex_callret_candidate_queue.py` enumerates plain CALL/RET stack
branches:

- TH06/TH07: CALL stack-write before/at-past, CALL lookup fault, CALL entered,
  RET stack-read before/at-past, and RET restored;
- TH08: the same CALL cases plus negative-sub no-op, RET stack-read at-past,
  RET restored, child-context exit, and child-index before/at-past.

A full default run on 2026-08-31 produced 41 satisfiable materialized CALL/RET
candidates:

```text
call-stack-oob-write: 10
call-subtable-oob-read: 5
ret-stack-oob-read: 8
ret-child-context-oob-read: 4
call-negative-no-op: 2
ret-child-context-exit: 2
callret-control: 10
```

All 41 replayed through Lean with `matchesPath=true`. Two unsat controls are
now explicit: TH06/TH07 do not have TH08's negative-sub no-op CALL branch, and
TH08 does not restore from `activeEclCallStack[-1]` on RET depth underflow—it
routes into child-context selection instead.

## Conditional CALL candidate queue

`scripts/symex_condcall_candidate_queue.py` enumerates the TH06 `CALLLSS`,
`CALLLEQ`, `CALLEQU`, `CALLGRE`, `CALLGEQ`, and `CALLNEQ` dispatch family.
The profile records only the opcode and operand slots; the path constraints
reuse the shared integer resolver, comparison predicates, `CallEclSub` lookup
policy, and CALL stack body.

The path classes are:

```text
condcall-false-before-buffer
condcall-false-non-progress
condcall-false-in-bounds
condcall-false-at-or-past-end
condcall-stack-write-before-stack
condcall-stack-write-at-or-past-stack
condcall-lookup-fault
condcall-entered
```

A full default run on 2026-08-31 produced 16 satisfiable materialized
conditional-CALL candidates across two TH06 difficulty environments:

```text
call-stack-oob-write: 4
call-subtable-oob-read: 2
condcall-fallthrough-cursor: 8
condcall-control: 2
```

All 16 replayed through Lean with `matchesPath=true`. Explicit unsat controls
also matter: TH06 has no negative-sub no-op conditional CALL path under the
current signed-subId abstraction, and TH07/TH08 have no TH06-style conditional
CALL opcode family in this profile.
