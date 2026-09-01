# Symbolic Execution Effectiveness

This note answers the narrow question: what does the current Lean + SMT
symbolic execution baseline cover, where does it fail to cover, and is it
already better than the previous fuzzing lane?

Short answer: it is already better than fuzzing for the modeled VM-core
dispatch skeleton, the first shared opcode-body slice, the integer resolver,
the integer binary-op slice, the TH07/TH08 boss integer/float-read slices, and
the CALL/RET/conditional-CALL slices. It also now source-models several
gameplay-effect opcode families in Lean, including bullet-control host effects,
time/wait controls, enemy lifecycle spawn/remove requests, item/drop requests,
laser-spawn descriptors, laser slot controls, animation controls, and primary
bullet patterns, but those families are not yet dedicated SMT/materializer
lanes. It is not yet better than fuzzing for the full ECL/ANM VM, because full
BulletManager/EnemyManager/ItemManager runtime behavior, full ANM execution,
and multi-context scheduling are not modeled yet.

## Reproducible evaluation

The current evaluation entry point is:

```bash
python3 scripts/evaluate_symex_effectiveness.py
```

To include the full Lean/SMT regression before the queue evaluation:

```bash
python3 scripts/evaluate_symex_effectiveness.py --run-check
```

The script reruns `scripts/symex_candidate_queue.py` and
`scripts/symex_body_candidate_queue.py` and
`scripts/symex_int_resolver_queue.py`,
`scripts/symex_int_binary_candidate_queue.py`,
`scripts/symex_boss_int_candidate_queue.py`,
`scripts/symex_boss_float_candidate_queue.py`,
`scripts/symex_callret_candidate_queue.py`, and
`scripts/symex_condcall_candidate_queue.py`, summarizes path coverage, reads
the local reference source tree for opcode-surface counts, reads DanmakuFuzz's
retained finding-status manifest, and folds in retained retail validation
summaries from `retail_validation/` when present.

The current manual verification run on 2026-09-01 executed:

```bash
lake build
lake exe check > /tmp/touhou_check_item.txt
./scripts/check.sh > /tmp/touhou_full_check_item.txt
python3 scripts/evaluate_symex_effectiveness.py \
  > /tmp/touhou_effectiveness_item.json
```

All completed successfully on the raw-step, raw-body, resolver,
integer-binary, boss-int, boss-float, CALL/RET, and conditional-CALL model.
When previous queue results should be reused instead of recomputed, the
equivalent assessment is:

```bash
python3 scripts/evaluate_symex_effectiveness.py \
  --queue-json /tmp/raw_queue.json \
  --body-queue-json /tmp/body_queue.json \
  --resolver-queue-json /tmp/resolver_queue.json \
  --int-binary-queue-json /tmp/int_binary_queue.json \
  --boss-int-queue-json /tmp/boss_queue.json \
  --boss-float-queue-json /tmp/boss_float_queue.json \
  --callret-queue-json /tmp/callret_queue.json \
  --condcall-queue-json /tmp/condcall_queue.json
```

The cost is mostly process startup: the current queues launch
Lean/Z3/materialization once per candidate.

## Raw-step symbolic coverage

The implemented symbolic executor enumerates the shared raw ECL single-step
skeleton:

1. time-gate yield;
2. difficulty-mask skip;
3. executing ordinary advance;
4. executing fixed jump;
5. explicit VM error via the source-backed unimplemented opcode;
6. cursor classification after skip/advance/jump.

Each cursor-moving action is split into:

- before-buffer;
- non-progress;
- in-bounds;
- at-or-past-end.

That gives 14 path classes:

```text
yielded
skipped-before-buffer
skipped-non-progress
skipped-in-bounds
skipped-at-or-past-end
advanced-before-buffer
advanced-non-progress
advanced-in-bounds
advanced-at-or-past-end
jumped-before-buffer
jumped-non-progress
jumped-in-bounds
jumped-at-or-past-end
vm-error
```

The default queue covers five title/difficulty environments:

- TH06 active bit 0;
- TH06 retail Lunatic bit 3;
- TH07 active bit 0;
- TH08 active bit 0;
- TH08 active bit 0 plus override bit 1.

Observed result:

| Metric | Result |
| --- | --- |
| environments | 5 |
| modeled path classes | 14 |
| candidates | 70 |
| solver status | 70 `sat` |
| Lean byte materialization/replay | 70 `matchesPath=true` |
| all modeled paths covered per environment | yes |

Action split:

| Raw-step action | Count |
| --- | ---: |
| `yielded` | 5 |
| `skipped` | 20 |
| `advanced` | 20 |
| `jumped` | 20 |
| `vm-error` | 5 |

Risk split:

| Risk class | Count | Interpretation |
| --- | ---: | --- |
| `cursor-underflow` | 15 | next cursor is negative |
| `cursor-out-of-range` | 15 | next cursor is at/past available raw buffer |
| `liveness` | 15 | step leaves the raw cursor unchanged |
| `explicit-vm-error` | 5 | modeled `UNIMP`/equivalent VM error path |
| `reachable-control-path` | 15 | in-bounds control cases |
| `time-gate-control` | 5 | time mismatch yield controls |

This is the part that fuzzing cannot guarantee cheaply. A random or
mutation-based campaign can eventually stumble into many of these classes, but
it usually cannot say "these are all path classes in the current abstraction,
and every title/profile environment has a byte-realizable witness for each."
Here the statement is direct: Lean emits the path constraints, Z3 solves them,
and Lean replays the concrete bytes back through the same shared semantics.

## Raw-body symbolic coverage

The next modeled layer covers source-backed opcode body families that are shared
enough across TH06/TH07/TH08 to keep in one semantics:

- `JUMPDEC`: decrement operand slot 2; if the decremented value is positive,
  jump by the same target-time/displacement operand slots as `JUMP`; otherwise
  advance by `nextOffset`.
- Integer conditional jumps: TH06 uses the previous compare register; TH07 and
  TH08 compare operand-resolved integer slots 0 and 1, then jump by raw slots 2
  and 3 when the condition holds.
- Integer div/mod zero-divisor hazard: source-backed div/mod opcodes and
  divisor operand slots are recorded in `RawInstrShape.intDivisorHazards`.

The div/mod hazard baseline still constrains the divisor to the immediate/raw
operand branch. Conditional jumps use the shared integer resolver abstraction,
where a known selector reads from symbolic host state and an unknown selector
falls through to the raw operand as in the source.

The body path classes are:

```text
decjump-taken-before-buffer
decjump-taken-non-progress
decjump-taken-in-bounds
decjump-taken-at-or-past-end
decjump-not-taken-before-buffer
decjump-not-taken-non-progress
decjump-not-taken-in-bounds
decjump-not-taken-at-or-past-end
int-condjump-taken-before-buffer
int-condjump-taken-non-progress
int-condjump-taken-in-bounds
int-condjump-taken-at-or-past-end
int-condjump-not-taken-before-buffer
int-condjump-not-taken-non-progress
int-condjump-not-taken-in-bounds
int-condjump-not-taken-at-or-past-end
int-divisor-zero
```

Observed result:

| Metric | Result |
| --- | --- |
| environments | 5 |
| modeled body path classes | 17 |
| candidates | 85 |
| solver status | 85 `sat` |
| Lean byte materialization/replay | 85 `matchesPath=true` |
| all modeled body paths covered per environment | yes |

Risk split:

| Risk class | Count | Interpretation |
| --- | ---: | --- |
| `arithmetic-fault` | 5 | integer div/mod reaches zero divisor |
| `cursor-underflow` | 20 | body-level cursor is negative |
| `cursor-out-of-range` | 20 | body-level cursor is at/past raw buffer |
| `liveness` | 20 | body-level cursor does not move |
| `reachable-control-path` | 20 | in-bounds controls |

This is a real expansion beyond the dispatch skeleton. The new `int-divisor-zero`
paths are body-level formal findings: they are produced by shared opcode-family
semantics and profile data, not by a hand-selected TH06 mutation.

## Integer operand resolver coverage

The shared resolver model covers the integer rvalue branches that condition
jumps and later arithmetic/state opcodes need:

- TH06 has no operand-mask branch at this layer: `GetVar` is always called, and
  unknown selectors return the raw operand by default.
- TH07/TH08 use `operandFlags`/`paramMask` bits: clear bit means raw immediate;
  set bit means selector resolution.
- Known selector sets and explicit exclusions are title-profile data, not
  copied into title-specific symbolic executors.

Observed result:

| Metric | Result |
| --- | --- |
| environments | 3 |
| modeled path families | 3 |
| title-specific candidates | 8 |
| solver status | 8 `sat` |
| Lean byte materialization/replay | 8 `matchesPath=true` |
| all modeled title-specific resolver paths covered | yes |

Risk split:

| Resolver branch | Count | Interpretation |
| --- | ---: | --- |
| `mask-set-known-selector` | 3 | selector reads symbolic host state |
| `mask-set-default-raw` | 3 | mask bit is set, but unknown selector falls through to raw value |
| `mask-clear-raw-immediate` | 2 | TH07/TH08 raw immediate branch |

This is a concrete formal advantage over plain fuzzing: the
mask-set/default-raw branch is semantically distinct from both ordinary
immediate operands and real variable reads, but it can be hard to classify from
runtime traces alone without source-backed path predicates.

## Integer binary arithmetic and lvalue coverage

The integer binary-op model is the first arithmetic slice that combines:

- rvalue resolution;
- lvalue resolution;
- opcode-specific operand layouts;
- arithmetic fault predicates;
- Lean materialization back into concrete raw ECL bytes.

It covers `ADD`, `SUB`, `MUL`, `DIV`, and `MOD` families through one shared
`RawIntBinaryOpShape` profile:

- TH06 `MATHINTADD/SUB/MUL/DIV/MOD`: assign to output slot 0, read slots 1 and
  2, with TH06's typed output classification.
- TH07 `ECL_ADD/SUB/MUL/DIV/MOD`: assign to `GET_INT_PTR(0)`, read
  `GET_INT_VALUE(1)` and `GET_INT_VALUE(2)`.
- TH08 low opcodes `10..14`: in-place arithmetic through `WriteInt(0)` and
  `ReadInt(1)`.
- TH08 low opcodes `20..24`: assign arithmetic through `WriteInt(0)`,
  `ReadInt(1)`, and `ReadInt(2)`.

The symbolic path families are:

```text
int-binary-output-raw-cell
int-binary-output-resolved-host
int-binary-output-default-raw-cell
int-binary-non-int-output
int-binary-divisor-zero-raw-immediate
int-binary-divisor-zero-resolved-host
int-binary-divisor-zero-resolved-default-raw
int-binary-divide-overflow-raw-immediate
int-binary-divide-overflow-resolved-host
int-binary-divide-overflow-resolved-default-raw
```

Feasibility is title-specific:

- TH06 has no raw-cell output path in this integer-output abstraction, but it
  has a `non-int-output` no-op path from typed output classification.
- TH07/TH08 have raw-cell/default-raw output paths through operand masks, but no
  TH06-style non-int-output path.

Observed result:

| Metric | Result |
| --- | --- |
| environments | 5 |
| conceptual path families | 10 |
| title-specific candidates | 39 |
| solver status | 39 `sat` |
| Lean byte materialization/replay | 39 `matchesPath=true` |
| all modeled title-specific paths covered per environment | yes |

Risk split:

| Risk class | Count | Interpretation |
| --- | ---: | --- |
| `arithmetic-overflow` | 13 | signed i32 `INT_MIN / -1` idiv overflow |
| `arithmetic-fault` | 13 | integer div/mod reaches a zero divisor |
| `silent-no-op` | 2 | TH06 typed output classification skips arithmetic |
| `default-raw-self-write` | 3 | unknown lvalue selector writes back into the raw operand cell |
| `raw-operand-self-write` | 3 | masked-off lvalue writes back into the raw operand cell |
| `host-lvalue-write` | 5 | ordinary resolved host-lvalue arithmetic writes |

This is the clearest current example of formal finding paths that fuzzing is
unlikely to enumerate systematically. The solver can ask for "a byte-realizable
instruction where the RHS is not zero in raw bytes but resolves to a host zero,"
or "a div/mod instruction where the resolved operands are exactly
`INT_MIN / -1`." Those are semantic path predicates, not mutation recipes.

## Boss-indexed integer-read coverage

The boss integer-read model covers one larger host-boundary opcode family:

- TH07 `ECL_GET_BOSS_INT` (`opcode = 43`);
- TH08 low opcode `86`.

Both are represented by one `RawBossIntReadShape` profile. The shared semantics
models:

- output slot 0 lvalue resolution;
- value operand slot 1's mask bit, including the mask-clear branch that bypasses
  the boss table read entirely;
- boss index operand slot 2, resolved through the current enemy's integer
  resolver;
- the fixed `bosses[8]` host array bound;
- null boss pointers for a source-backed dereferencing selector (`10000`);
- in-bounds host and default-raw value reads.

The symbolic path families are:

```text
boss-int-value-raw-no-boss-read
boss-int-index-before-array
boss-int-index-at-or-past-array
boss-int-null-deref
boss-int-value-resolved-host
boss-int-value-resolved-default-raw
```

Observed result:

| Metric | Result |
| --- | --- |
| environments | 3 |
| modeled title-specific candidates | 18 |
| solver status | 18 `sat` |
| Lean byte materialization/replay | 18 `matchesPath=true` |
| all modeled title-specific boss-int paths covered | yes |

Risk split:

| Boss-int branch | Count | Interpretation |
| --- | ---: | --- |
| `boss-index-oob-read` | 6 | resolved boss index is `< 0` or `>= 8` |
| `boss-null-deref` | 3 | boss pointer is null while selector `10000` dereferences it |
| `operand-flag-bypass` | 3 | slot 1 mask bit is clear, so no boss table read occurs |
| `boss-read-default-raw` | 3 | boss table is read, but an unknown value selector falls through to raw |
| `boss-read-host-value` | 3 | ordinary in-bounds host-value control |

This is the current best example of the workflow the project wants: the CE
values are not manually chosen first. The model supplies a title-shared opcode
shape and generic path predicates; Z3 returns `bossIndexRaw = -1`,
`bossIndexRaw = 8`, and `bossPresent = false` witnesses where those path
classes are satisfiable; Lean then encodes those witnesses into 24-byte raw ECL
instructions and replays them.

Retail calibration added on 2026-09-01:

- the TH07/TH08 PBG4/PBGZ archive adapter can replace a single `ecldata1.ecl`
  entry and verify the re-extracted payload;
- the retail lowering now selects an early source-backed timeline-spawned
  subroutine instead of the first same-sized instruction in the file;
- the TH08 normal-difficulty `boss-int-null-deref` witness is retail-confirmed
  as `crash-dialog` with a Wine page fault at `0041F456`;
- the TH07 null/OOB and TH08 OOB runs reached gameplay without a crash in the
  current generic Wine oracle, which is expected for some memory-safety CEs:
  an OOB read is a formal fault even when adjacent mapped state lets retail
  continue.

## Boss-indexed float-read coverage

The boss float-read model is the paired lane for:

- TH07 `ECL_GET_BOSS_FLOAT` (`opcode = 44`);
- TH08 low opcode `87`.

It reuses the same boss slot/index structure as boss-int:

- output slot 0 lvalue resolution;
- value operand slot 1's mask bit;
- boss index operand slot 2 through the integer resolver;
- the fixed `bosses[8]` host array bound.

The float-specific profile adds:

- `RawFloatOperandResolverShape`, whose selector sets are expressed as raw
  IEEE-754 `f32` bit-pattern ranges because the source casts operands with
  `(i32)float` before switching;
- a `RawBossReadNullPolicy` delta: TH07 is `unguarded-deref`, while TH08 is
  `guarded-skip`.

The symbolic path families are:

```text
boss-float-value-raw-no-boss-read
boss-float-index-before-array
boss-float-index-at-or-past-array
boss-float-null-deref
boss-float-null-guarded-skip
boss-float-value-resolved-host
boss-float-value-resolved-default-raw
```

Observed result from `./scripts/check.sh` and
`scripts/evaluate_symex_effectiveness.py` on 2026-09-01:

| Metric | Result |
| --- | --- |
| environments | 3 |
| modeled title-specific candidates | 18 |
| solver status | 18 `sat` queue candidates, plus expected title-specific `unsat` guard controls |
| Lean byte materialization/replay | 18 `matchesPath=true` |
| all modeled title-specific boss-float paths covered | yes |

Risk split:

| Boss-float branch | Count | Interpretation |
| --- | ---: | --- |
| `boss-index-oob-read` | 6 | resolved boss index is `< 0` or `>= 8`; TH08's null guard is reached only after this array read |
| `boss-null-deref` | 1 | TH07 can dereference a null boss pointer through an enemy-dependent float selector |
| `operand-flag-bypass` | 3 | slot 1 mask bit is clear, so no boss table read occurs |
| `boss-read-default-raw` | 3 | boss table is read, but an unknown float selector falls through to raw bits |
| `boss-read-host-value` | 3 | ordinary in-bounds host-value control |
| `boss-null-guarded-skip` | 2 | TH08 positive controls showing the guarded null path skips the write |

The important formal signal is the paired satisfiable/unsatisfiable result:

- TH07 `boss-float-null-deref` is `sat`, while
  `boss-float-null-guarded-skip` is `unsat`;
- TH08 `boss-float-null-deref` is `unsat`, while
  `boss-float-null-guarded-skip` is `sat`.

That is not a hand-picked counterexample. It falls out of one shared
boss-indexed read shape plus a title-profiled null policy.

Retail calibration added on 2026-09-01:

- `scripts/retail_confirm_boss_float_read.py` lowers the same solver witnesses
  into isolated TH07/TH08 `ecldata1.ecl` mutations through the shared boss-read
  retail pipeline;
- TH07 `boss-float-null-deref`, TH07 `boss-float-index-at-or-past-array`, TH08
  `boss-float-null-guarded-skip`, and TH08
  `boss-float-index-at-or-past-array` all reached `game-window-live` in the
  current generic Wine oracle;
- the important retail signal is calibration: TH08's guarded null path behaves
  like a positive control, while OOB/null formal faults do not necessarily
  crash at the selected stage-entry patch site.

## CALL/RET stack coverage

The shared CALL/RET model covers the plain subroutine control-transfer stack
edges:

- CALL saves the return context before calling `CallEclSub`;
- the stack save happens before the increment guard, which creates an
  out-of-bounds write path for abnormal `stackDepth`;
- CALL then follows the title's existing `CallEclSub` subTable lookup policy;
- RET decrements stack depth before restoring;
- TH08 depth underflow uses `childContextSlot - 1` to leave a child context
  instead of restoring from the saved stack.

Observed result:

| Metric | Result |
| --- | --- |
| environments | 5 |
| modeled title-specific candidates | 41 |
| solver status | 41 `sat` |
| Lean byte materialization/replay | 41 `matchesPath=true` |
| all modeled title-specific CALL/RET paths covered | yes |

Risk split:

| CALL/RET branch | Count | Interpretation |
| --- | ---: | --- |
| `call-stack-oob-write` | 10 | CALL writes at invalid stack depth before the guard |
| `call-subtable-oob-read` | 5 | CALL reaches the title's unchecked subTable lookup |
| `ret-stack-oob-read` | 8 | RET restores from an invalid saved-stack index |
| `ret-child-context-oob-read` | 4 | TH08 RET underflow indexes invalid `childEclBlocks` slot |
| `call-negative-no-op` | 2 | TH08 negative subId returns after CALL return-state handling |
| `ret-child-context-exit` | 2 | TH08 valid child-context exit path |
| `callret-control` | 10 | ordinary entered/restored controls |

This is still a one-step stack abstraction. It does not yet prove which stack
depths are reachable from a clean enemy context under bounded multi-step
execution. Its value is that the edge semantics and title deltas are now
explicit, source-backed, and solver-enumerated instead of being found by a
manual crash hunt.

## Conditional CALL coverage

The TH06 conditional CALL model covers the `CALLLSS`, `CALLLEQ`, `CALLEQU`,
`CALLGRE`, `CALLGEQ`, and `CALLNEQ` opcode family:

- the guard resolves `cmpLhs` with the shared integer rvalue resolver;
- the guard compares that value against raw `cmpRhs`;
- false guards fall through by `offsetToNext`;
- true guards reuse the same modeled CALL stack write and `CallEclSub` lookup
  body as plain CALL.

Observed result:

| Metric | Result |
| --- | --- |
| environments | 2 TH06 difficulty environments |
| modeled TH06 path classes | 8 |
| candidates | 16 |
| solver status | 16 `sat` |
| Lean byte materialization/replay | 16 `matchesPath=true` |
| all modeled TH06 conditional-CALL paths covered per environment | yes |

Risk split:

| Conditional-CALL branch | Count | Interpretation |
| --- | ---: | --- |
| `call-stack-oob-write` | 4 | true guard reaches CALL stack write at invalid `stackDepth` |
| `call-subtable-oob-read` | 2 | true guard reaches unchecked `CallEclSub` lookup |
| `condcall-fallthrough-cursor` | 8 | false guard falls through to before-buffer/non-progress/in-bounds/at-past cursor classes |
| `condcall-control` | 2 | ordinary true-guard entered controls |

TH07 and TH08 have no TH06-style conditional-CALL opcode family in this
profile, so their corresponding guarded-CALL queries are explicit unsat
controls rather than missing queue entries.

## What this does not cover yet

The current executor still does not cover the full game semantics of each
instruction. It now covers dispatch, `JUMP`, `JUMPDEC`, integer conditional
jumps, TH06 conditional CALLs, integer rvalue/lvalue resolver branches,
SET_INT/SET_FLOAT scalar assignment, INC/DEC integer unary updates, integer
ADD/SUB/MUL/DIV/MOD single-step behavior, float ADD/SUB/MUL/DIV/MOD
dispatch/resolver/lvalue behavior, scalar float functions, random value
generation, TH06 compare-register production, TH07/TH08 float conditional
jumps, TH07/TH08 boss integer/float reads, immediate and random-direction
movement state writes, timed direction/position interpolation, orbit movement,
enemy hitbox/flag/death-mode/life/timer writes, enemy lifecycle spawn/remove
requests, item/drop requests and state writes, plain CALL/RET stack behavior,
zero divisors, shooting-control state writes, time/wait controls,
bullet-control host effects, laser spawn descriptor construction, primary
bullet-pattern descriptor construction/gates, laser slot controls,
animation-control state writes, callback configuration, interrupt entry, and
signed idiv overflow. Most gameplay host effects and multi-instruction state
composition remain outside the current model.

Source opcode surface from the local reference clones:

| Title | Source surface | Currently opcode-specific | Not-yet-modeled lower bound |
| --- | ---: | --- | ---: |
| TH06 | 136 `ECL_OPCODE_*` symbols | 119: dispatch/control, scalar assignment, random values/directions, integer/float arithmetic, float functions, compare-register producers, CALL/RET, conditional CALL, immediate/timed movement, enemy-state, enemy-lifecycle, item/drop, shooting-control, time/wait controls, bullet-control, laser-spawn descriptors, laser slot controls, animation-control, bullet-pattern, callback configuration, and interrupts | 17 |
| TH07 | 159 `EclOpcode` symbols | 132: dispatch/control, scalar assignment, random values/directions, integer/float arithmetic, float functions and branches, CALL/RET, boss reads, immediate/timed/orbit movement, enemy-state, enemy-lifecycle, item/drop, shooting-control, time/wait controls, bullet-control, laser-spawn descriptors, laser slot controls, animation-control, bullet-pattern, callback configuration, and interrupts | 27 |
| TH08 | 184 numeric `case` labels across the integrated low/high switch | 135: dispatch/control, scalar assignment, random sign/directions, integer/float arithmetic, float functions and branches, CALL/RET, boss reads, immediate/timed/orbit movement, enemy-state, enemy-lifecycle, item/drop, shooting-control, time/wait controls, bullet-control, laser-spawn descriptors, laser slot controls, animation-control, bullet-pattern, callback configuration, and interrupts | 49 |

The report no longer carries a hand-maintained opcode list. It extracts opcode
constants and consecutive family ranges referenced by each Lean `Wire.lean`
profile, maps those numeric values
back to the local source enum or TH08's integrated low/high `case` labels, and computes the
remaining lower bound from the set difference. This makes new profile entries
count automatically and flags unresolved or source-absent profile values.
"Ordinary advance" for the remaining opcodes still does not prove their
internal branches.

Not covered:

- automatic callback trigger execution, periodic scheduling, and child-context
  composition (explicit interrupt entry and callback storage are modeled);
- persistent host-state composition and aliasing across multiple instructions;
- exact signed add/sub/mul overflow behavior, exact IEEE-754 f32 result
  computation, float division/fmod edge cases, and other C/C++ arithmetic
  hazards;
- BulletManager allocation/runtime simulation, TH08 transform-table execution,
  runtime laser simulation, full EnemyManager spawn/removal runtime after the
  VM request boundary, full ItemManager allocation/runtime after the VM request
  boundary, full ANM execution, sound playback, and callback trigger side
  effects;
- timeline-to-enemy spawning and multi-context scheduling;
- full ANM script execution;
- TH07/TH08 retail DAT lowering and Wine validation.

Why those branches are not covered:

- they need a symbolic host state, not just raw bytes;
- operand flags can turn the same raw field into an immediate, local variable,
  global variable, enemy field, player-derived value, or RNG-derived value;
- nested `CALL`/`RET`, interrupts, and callbacks need bounded stack/context
  semantics;
- gameplay-visible effects need object invariants for bullets, lasers, enemies,
  items, resources, and render state;
- retail validation needs title-specific archive adapters and stage-selection
  harnesses, which currently exist only for TH06.

So the current coverage claim is strong but scoped:

```text
complete for the implemented raw-step abstraction;
complete for the first implemented raw-body abstraction;
complete for the implemented integer rvalue resolver abstraction;
complete for the implemented SET_INT/SET_FLOAT scalar-assignment abstraction;
complete for the implemented INC/DEC integer-unary-update abstraction;
complete for the implemented integer binary-op/lvalue abstraction;
complete for the implemented float binary-op dispatch/resolver/lvalue
  abstraction, with result bits supplied by the external float theory boundary;
complete for the implemented TH07/TH08 boss integer-read abstraction;
complete for the implemented plain CALL/RET stack abstraction;
complete for the implemented TH06 conditional-CALL abstraction;
complete for the implemented primary bullet-pattern descriptor/gate
  abstraction, with source-side f32 arithmetic supplied by the explicit host
  boundary;
complete for the implemented time-control abstraction, including no-op body
  advance, resolved context-time additions, stage waits, and TH07/TH08
  pre-body wait gates with net frame stalls;
complete for the implemented bullet-control host-effect abstraction, including
  source-ordered sound reads and signed-i16 rank-count truncation;
complete for the implemented enemy-lifecycle host-effect abstraction,
  including spawn packet order, parent-life gates, relative-position host
  boundary, context-copy policy, pool size, and remove-all loop deltas;
complete for the implemented item/drop host-effect abstraction, including
  raw/resolved counts, item ids, spread constants, power-threshold policy,
  point-only loops, default item state, and TH08 item-drop field writes;
complete for the implemented laser-spawn descriptor abstraction, including
  source-ordered descriptor construction and unchecked selected-slot writes
  after spawn requests;
complete for the implemented laser slot-control abstraction, including
  unchecked enemy laser pointer-slot reads, null guards before later operand
  reads, selected-slot writes, in-use tests, stop transitions, clear-all loops,
  and TH06/TH07/TH08 update-policy deltas;
complete for the implemented animation-control abstraction, including primary
  ANM host calls, packed move/death fields, TH08 script tables, bank flag
  writes, primary/secondary interrupts, secondary slot host calls/clears,
  high-index diagnostics, negative/high slot faults, and primary rotation-Z
  writes;
complete for the implemented callback-configuration abstraction, including
  partial effects before indexed host-write faults;
complete for the implemented explicit interrupt table/entry abstraction,
  including partial context effects before host faults;
incomplete for full ECL/ANM VM opcode semantics.
```

## Comparison against DanmakuFuzz

The prior DanmakuFuzz lane is a serious baseline. Its retained status manifest
was updated on 2026-08-23 and currently records 16 reviewed entries:

| DanmakuFuzz status | Count |
| --- | ---: |
| `confirmed-retail` | 5 |
| `retail-disconfirmed` | 3 |
| `blocked-retail-oracle` | 1 |
| `headless-pending-retail` | 2 |
| `format-observation` | 5 |

The confirmed retail entries include:

- ECL timeline-`arg0` crash/stall basin: 14 promoted payloads, 16/16 retail
  confirmations including a 2/2 repeat for stage5 `arg0=256`;
- Stage 6 background ANM crash basin: 3 promoted payloads, 5/5 retail
  confirmations including a 2/2 repeat for `first-sprite-offset-zero`;
- additional confirmed cases such as Stage 4 jump-offset crash, plus
  disconfirmed or observation buckets.

Formal is better in the current slice because it changes the search question:

- fuzz asks "did this campaign happen to find an interesting input?";
- symbolic execution asks "is this semantic path class satisfiable under this
  title profile, and what bytes witness it?"

Concrete advantages already demonstrated:

- no title-specific manual witness is needed for the raw-step queue;
- every default TH06/TH07/TH08 environment covers all 14 modeled path classes;
- every default TH06/TH07/TH08 environment covers all 17 modeled body path
  classes;
- every title-specific integer rvalue resolver branch is solved and replayed;
- every title/environment-specific integer binary arithmetic path is solved and
  replayed, including resolver-driven zero divisors and signed idiv overflow;
- every TH07/TH08 boss integer-read path is solved and replayed, including
  `bosses[8]` underflow/overflow and null boss dereference paths;
- every title/environment-specific plain CALL/RET branch is solved and
  replayed;
- every TH06 conditional-CALL branch in the current guard abstraction is solved
  and replayed;
- solver witnesses are materialized into bytes by Lean using shared profile
  offsets, then replay-checked;
- the body queue finds immediate integer div/mod zero-divisor paths for all
  default environments;
- the integer-binary queue adds 39 non-manual arithmetic/lvalue candidates,
  including 13 `arithmetic-overflow` and 13 `arithmetic-fault` records;
- the boss integer-read queue adds 18 non-manual host-boundary candidates,
  including 9 high-priority OOB/null-deref counterexamples;
- the boss float-read queue adds 18 non-manual host-boundary candidates,
  including 7 high-priority OOB/null-deref counterexamples and TH08
  guarded-skip positive controls, then lowers representative TH07/TH08
  witnesses into isolated retail DAT mutations;
- TH08's difficulty override rule is captured as a semantic delta, not as a
  random trace divergence;
- the TH06 `jumped-before-buffer` symbolic witness has been lowered into a
  reachable stage-5 retail mutation and confirmed as `crash-dialog` in 2/2 Wine
  attempts.
- the TH08 `boss-int-null-deref` symbolic witness has been lowered into a
  reachable stage-1 retail mutation and confirmed as `crash-dialog` under Wine.

Fuzz is still better outside the current formal model:

- gameplay side effects are currently observed much more easily than modeled;
- DanmakuFuzz already has TH06 headless/retail oracle infrastructure;
- fuzz campaigns naturally prioritize retail-visible behavior, while the formal
  queue currently returns many reachable but not-yet-retail-ranked candidates;
- ANM runtime crash families are not yet reproduced by the formal ANM model,
  which only covers entry headers and next-offset shape.

## Current verdict

For the implemented VM-core skeleton, first shared body slice, integer resolver
slice, integer binary-op slice, TH07/TH08 boss integer-read and boss float-read
slices, plain CALL/RET stack slice, and TH06 conditional-CALL slice, Lean + SMT is already
better than fuzzing: it gives exhaustive path-class coverage,
satisfiable/unsatisfiable controls, concrete counterexample bytes, and shared
TH06/TH07/TH08 semantics.

For the whole VM, it is not yet better. The model has to move down one layer
into the remaining opcode bodies, host runtime state, and bounded multi-step
execution before we can honestly say formal is finding classes that
DanmakuFuzz cannot find in practice across the whole VM.

The next technically useful targets are:

1. compose integer lvalue writes with bounded multi-step execution so raw-cell
   and default-raw self-writes can feed later VM transitions;
2. add bounded multi-step reachability for nested `CALL`, `RET`, conditional
   `CALL`, callbacks, and stacked jumps;
3. refine arithmetic to exact machine behavior for signed add/sub/mul overflow
   and float divide/fmod edge cases;
4. lower the boss integer-read OOB/null witnesses into TH07/TH08 retail batches;
5. lower the top raw-step queue entries into TH06 retail batches;
6. add TH07/TH08 archive adapters so the same shared witnesses can be validated
   without TH06-specific mutation code.
