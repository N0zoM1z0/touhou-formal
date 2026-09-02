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
| `TH06-ECL-JUMP-MINUS-ONE` | cursor counterexample | `ECL_OPCODE_JUMP` with displacement `-1` jumps before the buffer | Lean theorem, SMT `sat`, Wine retail confirmation: `crash-dialog` 2/2 |
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

Retail value: the TH06 jump-before-buffer witness has been generated by the
symbolic executor, materialized into raw ECL bytes, spliced into a reachable
stage-5 subroutine entry, and confirmed twice against retail Wine. Clean
baselines reached `game-window-live`; the mutant reached `crash-dialog` in both
attempts.

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
| `ECL-RAW-STEP-WITNESS-MATERIALIZATION` | solver-to-fixture bridge | Z3 `get-value` witnesses are encoded into raw ECL bytes by Lean using `HeaderShape.rawInstrShape`, decoded again, and replayed through `rawStep`; accepted fixtures must report `matchesPath=true` | TH08 all-path smoke covers 14 path classes under `activeMask=1`, `overrideMask=2`; fixed-hex regressions for TH08 raw instruction and TH06 minimal one-sub ECL file |
| `ECL-RAW-STEP-CANDIDATE-QUEUE` | symbolic triage baseline | default queue solves/materializes raw-step path classes across five title/difficulty environments and ranks them by generic cursor/liveness/VM-error properties | 70 satisfiable materialized candidates on 2026-08-31; 45 high-priority cursor/liveness candidates |
| `ECL-RAW-BODY-JUMPDEC` | symbolic execution baseline | shared body semantics models source-backed `JUMPDEC`: decrement operand slot 2, jump iff the decremented value is positive, otherwise advance | 40 satisfiable materialized `decjump-*` candidates across five title/difficulty environments; taken/not-taken × four cursor classes per environment |
| `ECL-RAW-OPERAND-INT-RESOLVER` | symbolic execution baseline | shared integer rvalue resolver models TH06 always-resolve behavior and TH07/TH08 operand-mask raw/resolve/default-raw branches from title profile selector sets | 8 satisfiable materialized resolver candidates on 2026-08-31; TH06 has 2 feasible branches, TH07/TH08 have 3 each |
| `ECL-RAW-BODY-SCALAR-ASSIGNMENT` | executable model extension | shared scalar assignment semantics model TH06 `SETINT/SETFLOAT` through source `SetVar`, and TH07/TH08 `SET_INT/SET_FLOAT` through opcode-specific int/float lvalue policies | Lean theorems check 2 TH06 opcodes, 2 TH07 opcodes, 2 TH08 low-run opcodes, plus representative TH06 SETFLOAT, TH07 SET_FLOAT, and TH08 SET_INT shared-step controls; no CE or retail mutation generated for this lane yet |
| `ECL-RAW-BODY-INT-UNARY-UPDATE` | executable model extension | shared INC/DEC semantics model TH06 `GetVar(..., NULL)` pointer writes separately from TH07/TH08 int lvalue writes | Lean theorems check 2 TH06 opcodes, 2 TH07 opcodes, 2 TH08 low-run opcodes, plus representative TH06 unknown raw-cell INC, TH07 resolved-host INC, and TH08 raw-cell DEC controls; no CE or retail mutation generated for this lane yet |
| `ECL-RAW-BODY-INT-BINARY-LVALUE` | symbolic execution baseline | shared integer binary-op semantics model ADD/SUB/MUL/DIV/MOD over title-profiled assign/in-place layouts, output lvalue resolution, rvalue resolution, and byte materialization | 39 satisfiable materialized candidates on 2026-08-31 across five title/difficulty environments; all replay with `matchesPath=true` |
| `ECL-RAW-BODY-FLOAT-BINARY-LVALUE` | executable model extension | shared float binary-op semantics model ADD/SUB/MUL/DIV/MOD dispatch over title-profiled assign/in-place layouts, output lvalue resolution, rvalue resolution, and externally supplied result bit patterns | Lean theorems check 5 TH06 opcodes, 5 TH07 opcodes, 10 TH08 low-run opcodes, plus TH06 assign, TH07 assign, and TH08 in-place shared-step controls; no CE or retail mutation generated for this lane yet |
| `ECL-RAW-BODY-FLOAT-FUNCTION` | executable model extension | shared scalar float-function semantics model `sinf`, `cosf`, four-input angle functions, and angle normalization while preserving TH06 `GetVar`/`SetVar` policy and TH08's distinct `VectorAngle` host call | Lean theorems check 2 TH06 opcodes, 4 TH07 opcodes, 4 TH08 low-run opcodes, plus representative TH06 `atan2f`, TH07 `sinf`, and TH08 `VectorAngle` shared-step controls; transcendental result bits remain an explicit host/SMT boundary |
| `ECL-RAW-BODY-RANDOM` | executable model extension | shared random semantics model integer range, range-plus-addend, repeated-bound float ranges, and parity-sign operations with explicit 32-bit words, while float RNG arithmetic remains a supplied result-bit boundary and TH06 retains `SetVar` RHS re-resolution | Lean theorems check 4 TH06 opcodes, 7 TH07 opcodes, 2 TH08 low-run opcodes, zero-range modulo, TH06 source-write policy, both TH07 opcode-51 lower-bound resolver occurrences, float result recording, and TH08 negative-sign word wrap |
| `ECL-RAW-BODY-COMPARE-REGISTER` | executable model extension | shared comparison semantics model TH06 `CMPINT`/`CMPFLOAT` operand resolution and compare-register updates, including the source ternary's unordered-float result | Lean theorems check both TH06 producer opcodes and representative integer-less and float-unordered updates; TH07/TH08 correctly profile no compare-register producer |
| `ECL-RAW-BODY-MOVEMENT-IMMEDIATE` | executable model extension | shared movement effects model position, axis/polar velocity, angular velocity, speed, acceleration, player-relative motion, and bounds without duplicating title state machines | Lean theorems check 9 TH06, 8 TH07, and 7 TH08 opcodes; controls preserve TH06 raw angle-offset policy, TH07 derived axis angle/mode, and TH08 polar timer reset plus forced-zero position Z |
| `ECL-RAW-BODY-RANDOM-DIRECTION` | executable model extension | shared candidate selection and ordered-binary32 boundary reflection semantics model raw range angles, player-side/arena exits, rectangular bounds, and vertical-only correction; host float arithmetic remains explicit | Lean theorems check 2 TH06, 2 TH07, and 3 TH08 profile entries; controls prove TH06 uses the generated candidate in its right-positive reflection while TH07 opcode 52 and TH08 opcode 67 use the old enemy angle, far-right arena selection, NaN-safe guards, exact sign-bit vertical reflection, and automatic composition into timed movement |
| `ECL-RAW-BODY-MOVEMENT-TIMED` | executable model extension | one timed-movement family semantics models direction, host-derived direction, current-direction, player-direction, and position interpolation while retaining per-occurrence resolver reads and explicit binary32 host results | Lean theorems check 13 TH06, 2 TH07, and 5 TH08 opcodes; controls cover opcode-derived versus operand-derived easing, three-bit truncation, mirror-X sign toggling, position/world-position source asymmetry, repeated duration/speed resolution, TH08's two nonpositive timer policies, opcode 69's branch-dependent angle source, and the absence of synthetic angle operand reads for opcodes 67/178 |
| `ECL-RAW-BODY-MOVEMENT-ORBIT` | executable model extension | one shared orbit transition models full orbit initialization, partial radius/angle/velocity updates, and movement-mode timer writes | Lean theorems check 6 TH07 and 3 TH08 opcodes; controls preserve source read order, exact timer subframe/history resets, TH08's X/Y-only opcode-72 origin write, current-position snapshot, zero initial radius, and partial-field preservation |
| `ECL-RAW-BODY-ENEMY-STATE` | executable model extension | shared enemy-state effects model primary/secondary hitboxes, collision/damage/death flags, life, and boss timers while preserving raw/resolved inputs, source bit widths, TH08 mask polarity, alignment-effect mirroring, presentation-write suppression, gauge effects, and timer-history resets | Lean theorems check 7 TH06, 9 TH07, and 8 TH08 opcodes; representative controls cover raw versus resolved hitboxes/life, three-bit truncation, inverted flag masks, alignment mirroring, suppressed high-opcode death-mode writes, TH08 phase-starting life, and exact timer reset fields |
| `ECL-RAW-BODY-ENEMY-LIFECYCLE` | executable model extension | shared enemy-lifecycle effects model absolute/relative spawn requests and non-boss remove-all requests while preserving parent-life gates, operand resolution, host truncation, context-copy policy, pool size, and remove-all loop differences | Lean theorems check 2 TH06, 3 TH07, and 3 TH08 opcodes; controls preserve TH06 raw packet widths and i16 `CallEclSub` truncation, TH07 alive-parent resolved spawn plus dead-parent no-read suppression, TH08 relative-position host boundary/context-int copy, and TH06/TH07/TH08 remove-all policy deltas |
| `ECL-RAW-BODY-ITEM-DROP` | executable model extension | shared item/drop effects model looped and single item spawns plus TH08 item-drop state writes while preserving raw/resolved counts, item ids, spread constants, power-threshold policy, point-only loops, and default item-state use | Lean theorems check 2 TH06, 3 TH07, and 5 TH08 opcodes; controls preserve TH06 raw count with 144/72 spread, raw single item id, TH07 resolved point loop with 128/64 spread, and TH08 resolved item-count fields plus single-spawn default state |
| `ECL-RAW-BODY-BOSS-SPELLCARD-LIFECYCLE` | executable model extension | shared boss/spellcard lifecycle effects model unchecked boss-slot/gauge boundaries, legacy TH06/TH07 spellcard start/end, TH08 `StartSpell`/`EndSpell` host calls, life markers, timeout/survival flags, boss run-interrupt writes, and TH08 spellcard effect/bonus controls | Lean theorems check 5 TH06, 7 TH07, and 9 TH08 opcodes; controls preserve TH08 slot-8 OOB writes, u8 clear-slot truncation, TH07 slot-5 GUI-clear suppression, TH08 maxLife-zero gauge boundary, and conditional vector reads for opcode 164 |
| `ECL-RAW-BODY-NUMERIC-SPECIAL` | executable model extension | shared semantics models self-position transfers, immediate LERP, polar-to-Cartesian writes, and 2D distance with explicit host result bits | Lean theorems check 3 TH06, 2 TH07, and 4 TH08 opcodes; controls preserve TH06 `SetVar`, repeated LERP/polar reads, and Y-before-X output order |
| `ECL-RAW-BODY-INTERPOLATION-SLOT` | executable model extension | shared TH07/TH08 installation semantics scans 8 slots using IEEE float equality and models the fixed callback table as an unsafe host boundary | Lean controls prove no-slot operand suppression, signed-zero equality, callback-index OOB, and partial timer/key/duration/index/easing writes before the fault |
| `ECL-RAW-BODY-BULLET-TRANSFORM` | executable model extension | shared installation semantics models TH07's six-entry legacy bullet-command table and TH08's 18-entry bullet-transform table | Lean controls prove that the unchecked table access occurs after resolving only the index, show indices 6/18 fault before later reads, and retain TH08's 32-bit kind plus transform payload fields for index 17 |
| `ECL-RAW-BODY-HOST-EFFECT` | executable model extension | one shared effect/sound boundary models bullet extras, tracked and one-shot effects, moving particles, positioned sound, global color, special-effect position, and alignment effects while retaining title-profiled operand resolution | Lean theorems check 4 TH06, 6 TH07, and 5 TH08 opcodes; controls expose the 12/24-slot tracked-effect arrays, 28-entry color tables, TH07 null `specialEffect` write, and TH08 alignment interrupt/id-offset branches |
| `ECL-RAW-BODY-SHOOTING-CONTROL` | executable model extension | shared shooting effects model ranked immediate/random intervals, timer initialization, shooting gates, previous-pattern spawn requests, and resolved offsets | Lean theorems check 6 opcodes per title; controls preserve TH06's unconditional zero-interval timer reset, TH07's guarded no-write, TH08 RNG over the ranked interval, C/C++ truncation-toward-zero rank division, suppress-versus-defer gates, and TH08 forced-zero offset Z |
| `ECL-RAW-BODY-TIME-CONTROL` | executable model extension | shared time-control effects model ordinary no-op advance, context-time addition, context wait timers, stage script waits, and TH08 secondary-time waits without merging opcode body effects into the common frame tail | Lean theorems check 2 TH06, 3 TH07, and 3 TH08 opcodes; controls preserve TH06 `GetVar`-backed `TIMESET`, TH07 operand-flag wait/add/script-wait writes, TH08 secondary-time/add-time writes, and the TH07/TH08 wait gate's pre-tail decrement plus post-tail net stall |
| `ECL-RAW-BODY-BULLET-CONTROL` | executable model extension | shared bullet-control effects model all-bullet clearing variants, bullet sound flag/override writes, radius removal, transition clearing, and bullet-rank influence fields | Lean theorems check 3 TH06, 5 TH07, and 5 TH08 opcodes; controls preserve TH06 raw sound/rank operands, TH07/TH08 operand-flag resolution, repeated primary sound reads before override reads, title-specific sound targets, radius resolution, transition clearing, TH08's integer mode-4 clear argument, and signed-i16 rank-count truncation |
| `ECL-RAW-BODY-LASER-SPAWN` | executable model extension | shared laser-spawn effects model fixed/aimed descriptor construction, spawn requests, and unchecked selected-slot pointer writes | Lean theorems check 2 TH06, 2 TH07, and 2 TH08 opcodes; controls preserve TH06/TH07 `EnemyLaserShooter` versus TH08 `BulletSpawnDescriptor`, enemy-position versus world-position sources, shifted TH07/TH08 operand flags, 16-bit sprite/color storage, fixed/aimed encoded values, resolved TH08 width/time fields, and selected-slot OOB writes after spawn requests |
| `ECL-RAW-BODY-LASER-SLOT-CONTROL` | executable model extension | shared laser slot effects model selected-slot writes, unchecked indexed enemy laser pointer-slot reads, angle/position/start-length/offset/hide updates, in-use tests, stop transitions, and clear-all loops | Lean theorems check 7 TH06, 11 TH07, and 11 TH08 opcodes; controls preserve null-pointer guards that suppress later operand reads, high/negative slot OOB faults before later reads, TH06 non-normalized angle add and no stop-width copy, TH07/TH08 normalized angle add and stop-width copy, hide-value u8 truncation, and TH08's inverted in-use test value |
| `ECL-RAW-BODY-ANIMATION-CONTROL` | executable model extension | shared animation-control effects model ECL-to-ANM bridge host calls, packed move/death animation fields, primary script tables, bank flag writes, auto-rotation bitfields, primary/secondary pending interrupts, secondary VM slot host calls/clears, and primary rotation-Z writes | Lean theorems check 7 TH06, 8 TH07, and 14 TH08 opcodes; controls preserve cross-title raw packed byte/i16 extraction, TH06/TH07 enemy ANM script bases, TH07/TH08 resolver-driven script ids and interrupts, TH08 alternate-bank policy, runtime special-script dispatch, i16 script-table truncation, secondary high-index diagnostics, negative/high slot faults, and primary/secondary interrupt truncation |
| `ECL-RAW-BODY-BULLET-PATTERN` | executable model extension | one shared consecutive-family semantics models nine primary aim modes per title, packed type/color resolution, signed-i16 descriptor writes, rank/clamp branches, spawn suppression, and TH08 early filters/deferred copy | Lean theorems cover 27 opcodes and representative gate paths; controls prove TH06 descriptor-before-suppression, TH07 dead/spellcard behavior, TH08 dead/defer/alignment/distance ordering, C-style rank division, i16 wrap-before-clamp, ordered binary32 minimum-speed clamp, and the fixed `0x2c` pending-copy boundary |
| `ECL-RAW-BODY-CALLBACK-CONFIG` | executable model extension | shared effects model death, indexed life, timer, periodic, and death-bound callback configuration while preserving raw widths, operand resolution, timer history, and presentation guards | Lean theorems cover 6 TH06, 8 TH07, and 4 TH08 opcodes; controls include TH07 periodic context snapshots, TH08 partial presentation writes, signed-u16 death sub ids, and a repeated RNG-index path where the threshold write succeeds before the second life-array access faults |
| `ECL-RAW-BODY-INTERRUPT` | executable model extension | shared effects model local interrupt-table writes, immediate interrupt entry, and stack-disable writes while reusing title CALL-stack/subTable facts | Lean theorems cover 3 opcodes per title; controls prove unchecked table read/write faults, advanced-context save before lookup faults, TH08 signed-i16 table/index behavior and negative-sub no-op, and the cross-title depth-without-save asymmetry |
| `ECL-RAW-BODY-EXTENSION-DISPATCH` | symbolic execution baseline | shared semantics models immediate and per-frame EX instruction dispatch over the source's fixed 17/24/32-entry callback tables | 33 satisfiable materialized extension candidates across five default title/difficulty environments; high-priority paths cover callback-table OOB reads, medium paths cover negative-index callback clearing, and controls cover normal call/install behavior; TH06 `install-index-before-array` is an `unsat` control because it reuses one raw-i32 index, while TH07/TH08 can fault on the repeated resolver read |
| `TH08-ECL-CHILD-CONTEXT-INSTALL` | executable model extension | opcode 135 models four-slot child-block replacement, allocation, initialization, subroutine lookup, and state-copy ordering | Lean controls prove slot 4 faults before the sub read, negative sub ids free/clear without allocation, allocation failure suppresses the repeated sub read, `65535` becomes i16 `-1` yet still copies `0x78` bytes, and a positive subTable fault retains the zeroed block/sub-id partial state without copying variables |
| `ECL-RAW-BODY-MISC-STATE` | executable model extension | shared state/control semantics closes the remaining scalar-width, timer, trail, pause, GUI, and signed-clock opcode bodies without flattening their title-specific behavior | Lean controls cover 3 TH06, 8 TH07, and 18 TH08 opcodes, including raw-width stores, signed-byte clock conversion, pause bit transitions, timer writes, and trail initialization's partial divide-by-zero state |
| `TH08-ECL-BOSS-DISPATCH` | executable model extension | opcodes 88/89 model cross-enemy subroutine dispatch through the unchecked eight-entry boss array, including target-context mutation and repeated selector reads | Lean controls expose array OOB/null faults, target stack writes before subroutine-lookup faults, signed-i16 sub ids, 32-byte parameter transfer, and a changing second selector read |
| `TH08-ECL-LINKED-CHILD` | executable model extension | opcodes 90--92 model attachment-chain traversal, child spawn/positioning, effect installation, link writes, and inherited sound/position behavior at explicit host boundaries | Lean controls cover cyclic-chain divergence, null effect results, failed spawns, repeated alignment reads, inherited position, and successful child/link/sound requests |
| `ECL-SOURCE-OPCODE-SURFACE` | coverage assessment | mechanically compares every opcode constant or range referenced by the three Lean wire profiles against the local TH06/TH07 enums and TH08 integrated switch labels | TH06 136/136, TH07 159/159, and TH08 184/184 source labels are assigned to explicit modeled families; no profile constant is unresolved and no profiled opcode is absent from source |
| `ECL-RAW-BODY-INT-RESOLVED-DIVISOR` | symbolic execution finding | integer div/mod RHS can be raw, resolved host state, or default-raw fallback depending on title-specific resolver policy | 13 satisfiable materialized `arithmetic-fault` candidates across the default environments; TH07 and TH08 raw-immediate divisor-zero witnesses lowered into retail DAT mutations and confirmed as `crash-dialog` |
| `ECL-RAW-BODY-INT-IDIV-OVERFLOW` | symbolic execution finding | signed i32 div/mod can reach the machine overflow case `INT_MIN / -1`, not just divisor zero | 13 satisfiable materialized `arithmetic-overflow` candidates across the default environments; TH07 and TH08 raw-immediate `INT_MIN / -1` witnesses lowered into retail DAT mutations and confirmed as `crash-dialog` |
| `ECL-RAW-BODY-BOSS-INT-READ` | symbolic execution finding | TH07 `ECL_GET_BOSS_INT` and TH08 low opcode `86` read `g_EnemyManager.bosses[index]` when the value operand mask bit is set, with no index bound check and no null guard on the integer path | 18 satisfiable materialized boss-int candidates on 2026-08-31; 9 high-priority counterexamples: 6 `bosses[8]` OOB reads and 3 null boss dereferences; TH08 normal-difficulty null-deref and TH07 stage-entry null-deref are retail-confirmed as `crash-dialog`; boss-index OOB DAT mutations are retained as `game-window-live` memory-safety calibrations |
| `ECL-RAW-BODY-BOSS-FLOAT-READ` | symbolic execution finding | TH07 `ECL_GET_BOSS_FLOAT` and TH08 low opcode `87` share the same boss-indexed host array access, but TH08 guards the null boss pointer after the array read while TH07 does not | 18 satisfiable materialized boss-float candidates on 2026-09-01; 7 high-priority counterexamples: 6 `bosses[8]` OOB reads plus 1 TH07 null boss dereference; TH07/TH08 null-policy split is checked by paired `sat`/`unsat` controls; four representative TH07/TH08 witnesses lowered into retail DAT mutations and calibrated as `game-window-live` |
| `ECL-RAW-BODY-INT-COND-JUMP` | symbolic execution baseline | shared body semantics models TH06 compare-register integer jumps and TH07/TH08 operand-resolved integer conditional jumps, split by taken/not-taken and cursor class | 40 satisfiable materialized `int-condjump-*` candidates across five title/difficulty environments |
| `ECL-RAW-BODY-FLOAT-COND-JUMP` | executable model extension | TH07/TH08 direct float branches resolve slots 0/1, apply IEEE ordered/unordered predicates, and reuse raw target-time/displacement transfer | Lean theorems check 6 TH07 and 6 TH08 opcodes, all unordered predicate rules, TH07 unordered `!=` taken, and TH08 false `>=` fallthrough; dedicated solver/materializer coverage is pending |
| `ECL-RAW-CALLRET-STACK` | symbolic execution baseline | shared CALL/RET semantics models save-before-guard CALL stack writes, title-specific subTable lookup policy, decrement-before-restore RET stack reads, and TH08 child-context RET exits | 41 satisfiable materialized CALL/RET candidates on 2026-08-31; TH07 RET-underflow, TH07 `subTable[58]`, and TH08 `subTable[53]` witnesses lowered into retail DAT mutations and confirmed as `crash-dialog`; TH08 top-level child-context RET remains a composed-state follow-up |
| `ECL-RAW-CONDITIONAL-CALL` | symbolic execution baseline | TH06 conditional CALL opcodes resolve `cmpLhs`, compare raw `cmpRhs`, fall through by `offsetToNext` when false, and reuse the shared CALL stack/subTable body when true | 16 satisfiable materialized conditional-CALL candidates across two TH06 difficulty environments; TH07/TH08 are unsat controls for this opcode family |
| `ECL-RAW-BODY-INT-DIVISOR-ZERO` | symbolic execution finding | shared body semantics records source-backed integer div/mod opcodes and divisor operand slots, then searches for immediate/raw zero-divisor paths | 5 satisfiable materialized `divide-by-zero` candidates across five title/difficulty environments |
| `ECL-RAW-STEP-EFFECTIVENESS` | coverage assessment | reruns the raw-step, body, integer resolver, integer-binary, boss-int, boss-float, CALL/RET, conditional-CALL, and extension-dispatch checks, checks modeled path coverage per environment, audits the complete local source opcode surface, and compares the current formal lane against DanmakuFuzz | `docs/effectiveness.md`; raw 70/70 `sat`, body 85/85 `sat`, resolver 8/8 `sat`, int-binary 39/39 `sat`, boss-int 18/18 `sat`, boss-float 18/18 queue candidates `sat`, CALL/RET 41/41 `sat`, conditional-CALL 16/16 `sat`, extension 33/33 `sat`, all materialized candidates `matchesPath=true`, all modeled paths per default environment, and 479/479 source opcode labels explicitly profiled |
| `ECL-SYMEX-CE-CAMPAIGN-20260901` | symbolic counterexample campaign | reran every then-current SMT-backed queue, persisted each full candidate list, and classified high-priority counterexamples by the lane-owned risk/oracle labels | `formal_results/ce_campaigns/2026-09-01-full-symex-ce/summary.json`; 295 candidates, 295/295 `sat`, 295/295 `matchesPath=true`, 191 high-priority counterexamples, and 39 medium-priority semantic surprises |
| `ECL-SYMEX-CE-CAMPAIGN-20260902` | symbolic counterexample campaign | reruns every SMT-backed queue after adding the extension-dispatch lane and persists the full lane queues plus aggregate effectiveness report | `formal_results/ce_campaigns/2026-09-02-extension-symex/summary.json`; 328 candidates, 328/328 `sat`, 328/328 `matchesPath=true`, 209 high-priority counterexamples, 44 medium-priority semantic surprises, and 18 extension callback-table OOB counterexamples |

Formal value: this is the baseline the project should compare fuzzing against.
The executor is not given a concrete bug. It enumerates source-backed path
classes from the shared raw ECL step skeleton and asks Z3 whether each class is
reachable under a title profile and difficulty environment. Current regression
witnesses include TH06 ordinary-advance before-buffer, TH07 VM-error, TH08
fixed-jump before-buffer, TH08 difficulty-skip in-bounds under override, and
TH08 ordinary-advance non-progress.

The materializer is intentionally not a retail oracle. It proves that a solver
witness is byte-realizable under the modeled raw instruction shape and that the
same shared concrete step classifies it consistently. The TH06
`jumped-before-buffer` witness now has a separate retail confirmation path; the
remaining path classes still need prioritization and full ECL/DAT validation.

The candidate queue is the current answer to "do not manually find examples
first." It starts from enumerated symbolic path classes, materializes every
satisfiable record, and ranks by a title-independent property of the transition.
Fuzzing can still validate and minimize the resulting cases, but it is no longer
responsible for discovering that those path classes exist.

The current effectiveness assessment is deliberately scoped. Lean + SMT is now
stronger than fuzzing for the implemented raw-step dispatch abstraction, the
first shared body slice, the integer rvalue/lvalue resolver and binary
arithmetic slice, the TH07/TH08 boss integer/float-read slices, the plain
CALL/RET stack plus TH06 conditional-CALL slices, and the extension-dispatch
callback-table slice
because it exhaustively covers all modeled path classes.
Float binary arithmetic is now modeled at the dispatch/resolver/lvalue level,
but it is not yet part of that stronger-than-fuzzing claim because the SMT
float-result relation and path queue have not been added.
Scalar assignment is in the same state: modeled and Lean-checked, but not yet a
solver-ranked finding lane.
Integer unary updates are also modeled and Lean-checked, with the TH06
raw-cell write behavior preserved, but not yet included in a solver-ranked lane.
Animation-control effects are likewise modeled and Lean-checked for primary VM,
secondary VM slot, and script-table behavior, but dedicated solver
materialization for this family remains pending.
Bullet-control effects are now modeled and Lean-checked for clear variants,
sound flags/overrides, and rank influence, but they are also not yet a
solver-ranked lane.
Enemy-lifecycle effects are modeled and Lean-checked for spawn/remove requests,
parent-life gates, relative-position host boundaries, context-copy policy, pool
size, and remove-all loop deltas, but they are not yet a solver-ranked lane.
Item/drop effects are modeled and Lean-checked for looped and single item
requests plus TH08 item-drop state writes, but they are not yet a solver-ranked
lane. Boss/spellcard lifecycle effects are modeled and Lean-checked for
boss-slot writes/clears, spellcard start/end, gauge writes, life markers,
run interrupts, and TH08 spellcard effect/bonus controls, but they are also not
yet a solver-ranked lane.
Laser-spawn descriptors are modeled and Lean-checked through spawn requests and
selected-slot write boundaries, but they likewise do not yet have a dedicated
solver/materializer queue.
The extension-dispatch materializer covers TH06/TH07/TH08 immediate and
per-frame EX callback-table reads, including TH07/TH08 repeated resolver-read
install faults and negative-index callback clears.
It is not yet stronger than fuzzing for the full ECL/ANM runtime. All raw ECL
source opcode bodies are now assigned to executable profile families, but most
families still lack generated solver queues; persistent host-runtime state,
bounded multi-step and multi-context composition, and ANM opcode execution also
remain outside the formal semantics. See
[`docs/effectiveness.md`](effectiveness.md).

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
