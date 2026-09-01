# touhou-formal

> If operating systems get formal verification, Gensokyo gets an executable
> specification.
>
> The bullets are already formal. The VM should be, too.

`touhou-formal` is a formal-methods workbench for Touhou script VMs, starting
with the ECL VM family in TH06, TH07, and TH08.

This is not a “write a safer clone of ZUN’s VM” project. The point is sharper:
model the original VM, including its oddities, missing checks, historical
drift, and crashable edges, closely enough that Lean + SMT/symbolic execution
can produce real counterexamples for properties the retail games do not
satisfy.

Fuzzing is still useful. But danmaku scripts have tiny weird gates everywhere:
time checks, difficulty masks, operand flags, subroutine stacks, selector
fallbacks, host-state-dependent operands, and version-specific dispatch. Random
mutation can spend a lot of time proving that fairies still shoot bullets. A
solver can instead ask: “is there any byte-realizable ECL instruction that
passes the VM’s own gates and reaches this exact bad boundary?”

That is the intended loop:

1. recover the original source-backed semantics;
2. encode the shared VM core once;
3. let SMT produce witnesses instead of hand-picking examples;
4. replay the witness through Lean’s executable model;
5. validate high-value counterexamples against retail builds in isolation.

## Current slice

The executable model currently covers these source-backed boundaries:

- TH06 raw bytes flow through the shared ECL loader, timeline-prefix decoder,
  and `CallEclSub` lookup to reproduce the `arg0 = 256` subTable fault.
- TH07 and TH08 reuse the same lookup semantics while preserving their
  negative-sub-id policy difference.
- Loader and cursor checks expose first missing-byte, zero-size, and
  before-buffer boundaries as executable theorems.
- Timeline `size` and raw instruction `nextOffset` cursor sweeps are generated
  from shared profile widths, so TH08's unsigned timeline-size delta is recorded
  without title-local search logic.
- Raw ECL difficulty-mask semantics are modeled as profile policy; TH08's
  override-mask rule is proven distinct from the TH06/TH07 active-bit
  intersection rule.
- Shared integer operand resolution covers TH06's always-`GetVar` behavior and
  TH07/TH08 `operandFlags` mask branches, including known selector fallthrough
  to raw immediates.
- Shared scalar assignment semantics cover `SET_INT`/`SET_FLOAT` across
  TH06/TH07/TH08, including TH06's source-level `SetVar` type guard and the
  TH07/TH08 opcode-specific int/float lvalue split.
- Shared integer unary-update semantics cover `INC`/`DEC`, including TH06's
  direct `GetVar(..., NULL)` pointer write path where unknown outputs update
  the raw operand cell instead of becoming a `SetVar` no-op.
- Shared integer binary-op semantics cover ADD/SUB/MUL/DIV/MOD over
  title-profiled operand layouts, including output lvalue resolution,
  TH08 in-place arithmetic, resolver-driven zero divisors, and signed
  `INT_MIN / -1` idiv overflow.
- Shared float binary-op semantics cover ADD/SUB/MUL/DIV/MOD dispatch,
  title-profiled operand layouts, output lvalue resolution, and resolver
  behavior for TH06/TH07/TH08. Lean records lhs/rhs/result bit patterns; exact
  IEEE-754/fmod solving is a later SMT boundary, not claimed here.
- Shared float-function semantics cover TH06/TH07 `atan2f`, TH08
  `VectorAngle`, TH07/TH08 `sinf`/`cosf`, and angle normalization. The profile
  preserves TH06's unusual `GetVar`-pointer read followed by `SetVar`, while
  transcendental result bits remain an explicit host/SMT float-theory boundary.
- Shared random-value semantics cover integer range/modulo, range-plus-addend,
  repeated-bound float ranges, and parity-selected sign opcodes. Integer results use explicit 32-bit word
  arithmetic; float RNG results stay at the host/SMT boundary. TH06 preserves
  the extra `SetVar` RHS lookup that can reinterpret generated result bits as
  an ECL selector, while TH07 opcode 51 preserves both occurrences of its
  lower-bound resolver read.
- The first gameplay host-effect family covers 24 immediate movement opcodes:
  position, axis/polar velocity, angular velocity, speed, acceleration,
  player-relative motion, and movement bounds. Shared effects retain title
  differences such as TH06's raw player-angle offset/bounds, TH07's derived
  axis angle, and TH08's forced-zero Z plus timer-reset behavior.
- Timed movement adds 20 more opcode bodies through one consecutive-family
  semantics: TH06's opcode-selected easing ranges and TH07/TH08's
  operand-selected direction/position interpolation. The model retains every
  repeated resolver call, three-bit easing writes, mirror-X sign toggling,
  position-versus-world-position origins, and the nonpositive-duration fast
  paths—including exact timer subframe/history resets, TH08's distinct timer
  policies, opcode 69's player-relative/absolute-angle branch split, and the
  host-derived angles used by TH08 opcodes 67 and 178 without inventing
  synthetic bytecode reads.
- Shared orbit semantics adds nine opcode bodies: TH07's full orbit,
  radius/angle updates, and three movement-timer mode setters; plus TH08's
  full orbit, orbit-from-current-position, and velocity update. Profiles retain
  TH08's X/Y-only origin write for opcode 72 and the exact timer reset state.
- Random-direction semantics covers TH06's raw range moves, TH07's two exit
  angle helpers, and their TH08 counterparts. One profile parameter preserves
  whether a right-wall reflection subtracts the generated candidate or the
  enemy's old angle; ordered binary32 guards reject NaNs exactly like the C++
  comparisons. TH08 host-derived directions compose directly into the shared
  timed-movement transition, with a profile-drift check between both stages.
- Shared enemy-state effects cover 24 hitbox, collision/damage flag,
  death-mode, life, and boss-timer opcodes. The model retains TH06/TH07
  bitfield truncation, TH08's inverted replace-mask rules, alignment-effect
  collision mirroring, the high-opcode presentation-write guard, title-specific
  life operand resolution/gauge effects, and exact timer-history reset writes.
- Shared shooting-control effects cover 18 interval, gate, previous-pattern,
  and offset opcodes. One rank-scaling function is reused across all titles,
  while profiles retain TH06's unconditional zero-interval timer reset,
  TH07/TH08's nonzero guard, TH08's defer-versus-suppress gate meaning, and
  TH08's forced-zero offset Z.
- Shared laser slot controls cover 29 cross-title opcodes for selected-slot
  writes, indexed angle/position/start-length/offset/hide updates, active-state
  tests, stop transitions, and clear-all loops. The model preserves unchecked
  enemy laser pointer-slot reads, null-pointer guards that suppress later
  operand reads, TH06's non-normalized angle add, TH07/TH08 stop-width copies,
  and TH08's inverted in-use test value.
- Shared animation-control effects cover the first 28 ECL/ANM bridge opcodes:
  TH06/TH07 primary enemy script selection, packed move/death animation fields,
  raw bitfield auto-rotation, primary VM interrupts, TH07/TH08 primary
  rotation-Z writes, TH08's primary/alternate script-table bank policy, and
  unchecked secondary VM slot accesses. The model records host ANM calls, table
  writes, slot clears, secondary interrupts, high-index diagnostics, and
  negative/high slot faults without executing the ANM VM itself.
- One consecutive-family profile now covers all 27 primary bullet-pattern
  opcodes (nine aim modes per title). The shared effect preserves packed-i16
  type/color reads, shifted resolver bits, i16 count writes, spellcard rank
  bypass, binary32 zero/minimum-speed tests, and descriptor-versus-spawn
  ordering. TH08 additionally exposes dead/defer/alignment/distance exits and
  records its unchecked fixed `0x2c`-byte pending-instruction copy boundary.
- Shared callback-configuration effects cover 18 death/life/timer/periodic
  opcodes. They retain raw-width versus resolved operands, exact timer resets,
  TH08 presentation suppression, unchecked four-slot life arrays, and repeated
  index resolution—so an RNG selector can produce a successful threshold write
  followed by a second-index fault instead of being silently memoized.
- Shared interrupt effects cover each title's table-write, immediate-run, and
  stack-disable opcodes. They preserve unchecked table accesses, TH08 signed
  i16 storage, context-advance/save ordering, subTable policy, and the original
  asymmetry where a disabled save still permits stack-depth increment.
- TH07 `ECL_GET_BOSS_INT` and TH08 low opcode `86` are modeled through one
  shared boss-indexed integer-read shape, including operand-flag bypass,
  `bosses[8]` index bounds, null boss pointers, and host/default selector
  resolution.
- The control-flow body includes `JUMPDEC`, integer conditional jumps, TH06
  integer/float compare-register producers, and TH07/TH08 direct float
  conditional jumps. Float ordering explicitly includes IEEE unordered/NaN
  behavior; the older immediate/raw div/mod check remains as a regression
  beside the fuller integer-binary model.
- Plain CALL/RET stack behavior is modeled with shared semantics for stack
  saves/restores, depth guards, subTable lookup, and TH08 child-context RET
  exits.
- TH06 conditional CALL opcodes are modeled as guard predicates that reuse the
  same shared CALL stack/subTable body when taken.
- Raw ECL instruction prefixes and ANM entry headers are decoded through shared
  profile-driven code across TH06/TH07/TH08.

The Lean model treats the first invalid operation as a `Fault`. It does not try
to predict arbitrary C++ undefined behavior after that point.

## Repository layout

- `TouhouFormal/Core/`: byte/scalar reads, faults, evidence, and bounded
  transition-system definitions.
- `TouhouFormal/ECL/`: shared ECL profile, loader, lookup, timeline, and raw
  instruction-prefix semantics.
- `TouhouFormal/ANM/`: shared ANM entry profile and entry-header decoding.
- `TouhouFormal/TH06/`, `TouhouFormal/TH07/`, `TouhouFormal/TH08/`:
  title-specific profile facts, fixtures, and deltas.
- `TouhouFormal/Search/`: bounded checks and SMT bridges.
- `docs/`: modeling policy, source evidence, and roadmap notes.
- `scripts/`: reproducible local checks.

## Commands

```bash
lake build
lake exe check
lake exe smt th06-sub-oob | z3 -in
lake exe smt th08-negative-noop-unsat | z3 -in
lake exe smt th08-timeline-size-before-buffer-unsat | z3 -in
lake exe smt th08-raw-difficulty-override-delta | z3 -in
lake exe symex list-paths
lake exe symex query th08 jumped-before-buffer 1 0 | z3 -in
lake exe symex query-values th08 jumped-before-buffer 1 0 | z3 -in
lake exe symex list-body-paths
lake exe symex query-body-values th08 int-divisor-zero 1 2 | z3 -in
lake exe symex list-int-resolver-paths
lake exe symex query-int-resolver-values th07 resolved-default-raw 0 | z3 -in
lake exe symex list-int-binary-paths
lake exe symex query-int-binary-values th08 int-binary-divide-overflow-resolved-host 1 0 | z3 -in
lake exe symex list-boss-int-paths
lake exe symex query-boss-int-values th08 boss-int-null-deref 1 0 | z3 -in
lake exe symex list-boss-float-paths
lake exe symex query-boss-float-values th07 boss-float-null-deref 1 0 | z3 -in
lake exe symex list-callret-paths
lake exe symex query-callret-values th08 ret-child-index-before-array 1 0 | z3 -in
lake exe symex list-condcall-paths
lake exe symex query-condcall-values th06 condcall-lookup-fault 1 0 | z3 -in
./scripts/symex_raw_step.sh th08 1 2
./scripts/symex_materialize_raw_step.py th08 jumped-before-buffer 1 0
./scripts/symex_materialize_raw_step.py th06 jumped-before-buffer 8 0 --ecl-file
./scripts/symex_candidate_queue.py --env th06:8:0:retail-lunatic-bit3 --path jumped-before-buffer
./scripts/symex_materialize_body_step.py th08 all 1 2
./scripts/symex_body_candidate_queue.py
./scripts/symex_materialize_int_resolver.py th07 all 0
./scripts/symex_int_resolver_queue.py
./scripts/symex_materialize_int_binary.py th08 all 1 0
./scripts/symex_int_binary_candidate_queue.py
./scripts/symex_materialize_boss_int_read.py th08 all 1 0
./scripts/symex_boss_int_candidate_queue.py
./scripts/symex_materialize_boss_float_read.py th08 all 1 0
./scripts/symex_boss_float_candidate_queue.py
./scripts/symex_materialize_callret_step.py th08 all 1 0
./scripts/symex_callret_candidate_queue.py
./scripts/symex_materialize_condcall_step.py th06 all 1 0
./scripts/symex_condcall_candidate_queue.py
python3 scripts/evaluate_symex_effectiveness.py
./scripts/check.sh
./scripts/retail_inventory.sh
./scripts/extract_retail_th06.sh
python3 scripts/retail_confirm_th06_arg0_256.py --prepare-only
python3 scripts/retail_confirm_th06_raw_symex.py --symex-path jumped-before-buffer --prepare-only
python3 scripts/retail_confirm_boss_float_read.py th08 --symex-path boss-float-null-guarded-skip --prepare-only
```

`scripts/check.sh` runs the Lean build, executable counterexample check, Z3
controls, and the current raw-ECL symbolic witness materializer. The
materializer solves a path, asks Lean to encode the witness into bytes from the
shared title profile, decodes it again, and checks that the concrete step lands
back in the requested path class. The body materializer does the same for the
first opcode-body layer: `JUMPDEC`, integer conditional jumps, and immediate/raw
integer div/mod zero-divisor faults. The resolver materializer covers integer
rvalue `operandFlags` branches separately from opcode-body effects. The
integer-binary materializer covers title-specific ADD/SUB/MUL/DIV/MOD layouts,
output lvalue resolution, resolver-driven divisor faults, and signed idiv
overflow. Scalar assignment, integer unary updates, float binary arithmetic,
float functions, random-value opcodes, compare-register producers, direct
float conditional jumps, immediate and timed movement effects, enemy-state
effects, shooting-control effects, and animation-control effects currently have Lean
executable controls for profile coverage and shared-step execution, but no dedicated
solver/materializer lane yet. Bullet-pattern, callback-configuration, and
interrupt effects have the same Lean-only status for now. The boss integer-read
materializer covers TH07/TH08
`g_EnemyManager.bosses[index]` reads, including solver-generated out-of-bounds
and null-dereference counterexamples. The boss float-read materializer reuses
that host boundary with float selector bit-pattern ranges and the TH07/TH08
null-policy split. The CALL/RET materializer covers stack write/read faults,
subTable lookup faults, and TH08
child-context RET exits. The conditional-CALL materializer covers TH06
guard-false fallthrough and guard-true reuse of the same CALL stack/subTable
body.
`scripts/evaluate_symex_effectiveness.py` reruns the symbolic candidate queues
and reports which modeled branches are covered versus which source opcode/body
branches remain outside the current semantics. `scripts/retail_inventory.sh` is
read-only and records archive
hashes plus executable/data CRCs before any Wine validation. Retail validation
scripts operate on isolated copies under
`/home/yann/yann/touhou/formal/retail_extract` and
the repository's ignored-by-default `retail_validation/` tree. Small
`result.json` and `report.json` evidence files in that tree are committed;
retail game files, Wine prefixes, screenshots, and mutated payloads are not.

Current retained results are summarized in
[`docs/formal-results.md`](docs/formal-results.md). The current formal-vs-fuzz
coverage assessment is in [`docs/effectiveness.md`](docs/effectiveness.md).
