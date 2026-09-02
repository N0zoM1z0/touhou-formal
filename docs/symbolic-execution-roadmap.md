# Symbolic Execution Roadmap

Last updated: 2026-09-02.

This note records the current Lean + SMT boundary so future work can continue
from repository state instead of from chat history.

## Current baseline

The current baseline is a forward model: source-derived Lean semantics define
the raw VM behavior first, and SMT queries enumerate path classes over those
semantics. Counterexamples are accepted only after Z3 returns a witness and Lean
materializes/replays the same byte-realizable raw instruction with
`matchesPath=true`.

As of this update, the SMT-backed lanes cover:

- raw dispatch skeleton: time gate, difficulty gate, advance, jump, VM-error,
  and cursor classes;
- selected raw opcode bodies: decrement jump, integer conditional jump, and
  immediate integer divisor faults;
- integer operand resolver;
- integer binary arithmetic/lvalue hazards;
- boss-indexed integer and float reads;
- CALL/RET and TH06 conditional CALL stack/subtable boundaries;
- extension-dispatch callback-table boundaries.

The latest retained full campaign,
`formal_results/ce_campaigns/2026-09-02-extension-symex/summary.json`, found
328 candidates. All 328 solver witnesses were satisfiable and all 328 Lean
materializations replayed with `matchesPath=true`. The extension lane accounts
for 33 of those candidates: 18 high-priority callback-table OOB reads, 5
medium-priority negative-index callback clears, and 10 normal controls.

## Why this is stronger than fuzzing on the modeled core

Fuzzing has to stumble into the right opcode, operand flags, selector ranges,
host-value assumptions, timing gate, difficulty gate, and table boundary at the
same time. The formal pipeline separates those conditions into explicit
constraints and asks the solver for witnesses.

This is already stronger for modeled one-step VM-core properties:

- cursor safety and progress are enumerated as path classes;
- operand-flag resolver branches are covered directly, including title deltas;
- divide-by-zero and signed `idiv` overflow are found as arithmetic
  preconditions, not as rare runtime crashes;
- boss table OOB/null cases are found without guessing concrete indices;
- CALL/RET stack and subtable hazards are separated from normal controls;
- extension callback-table OOB reads are now generated from the table bound
  rather than handpicked indices.

## Where fuzzing still has the advantage

The current solver does not yet model the whole game runtime. Fuzzing or retail
probes still have an advantage for:

- persistent host state that evolves across frames;
- multi-context scheduling across enemies, children, callbacks, interrupts, and
  per-frame extension installs;
- full ANM script execution and rendering/audio/runtime side effects;
- prioritizing which formally reachable witnesses are visible retail bugs.

The correct claim is therefore narrower: Lean + SMT currently beats fuzzing on
the modeled raw VM-core and selected source-backed opcode boundaries, not yet on
the whole ECL/ANM game runtime.

## Architecture rule for new solver lanes

Do not keep appending new opcode families to the old monolithic
`TouhouFormal/Search/Symbolic.lean`.

The intended structure is:

1. `TouhouFormal/Search/Symbolic/Common.lean` owns shared title/path enums,
   resolver predicates, byte-count helpers, and SMT string helpers.
2. Each new family gets a separate module such as
   `TouhouFormal/Search/Symbolic/Extension.lean`.
3. Python scripts stay lane-specific: one materializer and one candidate queue
   per lane, with `scripts/run_ce_campaign.py` doing only orchestration.

This keeps the core TH06/TH07/TH08 semantics shared while letting
interrupt/callback/ANM-control lanes add their own witnesses and reports without
semantic drift.

## Priority queue

1. Interrupt lane.
   - Already Lean-modeled.
   - High-value paths: unchecked interrupt table read/write, TH08 i16
     truncation, stack-disabled writes, immediate entry with CALL-stack reuse.
   - Required solver state: interrupt index/sub id, stack depth/disabled flag,
     subtable size, and optional stored-sub truncation.
2. Callback-configuration lane.
   - Already Lean-modeled.
   - High-value paths: life-index OOB, repeated RNG/life index reads,
     partial writes before second-read faults, timer/death callback truncation.
   - Required solver state: callback kind, life index, stored sub id, timer
     fields, and callback table/array bounds.
3. ANM-control lane.
   - Already Lean-modeled as an ECL-to-ANM bridge, not as full ANM execution.
   - High-value paths: script-table truncation, negative/high secondary VM
     slot faults, pending interrupt writes, and bank/script-id routing.
   - Required solver state: script id, VM slot, interrupt id/sub id, and
     title-specific bank policy.
4. Bounded multi-step composition.
   - Should come after the one-step lanes above.
   - Purpose: prove which one-step witnesses are reachable from normal stack,
     callback, extension-install, and scheduler states.
5. Retail lowering.
   - Keep separate from modeling.
   - Use solver witnesses to build minimal TH07/TH08 ECL/DAT mutations only
     after the lane semantics and queue are stable.

## Acceptance criteria for each new lane

A new lane is not complete when a theorem exists. It is complete when all of the
following hold:

- Lean semantics are source-profiled and shared across TH06/TH07/TH08 where the
  source behavior is actually shared;
- SMT queries list satisfiable and intentionally unsatisfiable path classes;
- Z3 witnesses are materialized into raw instruction bytes;
- Lean replay validates `matchesPath=true`;
- a candidate queue classifies high/medium/control results;
- `scripts/check.sh` has at least one sat, one important unsat if applicable,
  and one queue-level assertion;
- `scripts/run_ce_campaign.py` and `scripts/evaluate_symex_effectiveness.py`
  include the lane.
