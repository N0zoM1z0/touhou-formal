# Symbolic Execution Effectiveness

This note answers the narrow question: what does the current Lean + SMT
symbolic execution baseline cover, where does it fail to cover, and is it
already better than the previous fuzzing lane?

Short answer: it is already better than fuzzing for the modeled VM-core
dispatch skeleton and the first shared opcode-body slice. It is not yet better
than fuzzing for the full ECL/ANM VM, because most opcode bodies and host-game
side effects are not modeled yet.

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
`scripts/symex_body_candidate_queue.py`, summarizes path coverage, reads the
local reference source tree for opcode-surface counts, reads DanmakuFuzz's
retained finding-status manifest, and folds in retained retail validation
summaries from `../retail_validation` when present.

The manual verification run on 2026-08-31 executed:

```bash
./scripts/check.sh
python3 scripts/evaluate_symex_effectiveness.py > /tmp/touhou_symex_effectiveness_full.json
```

Both completed successfully on the current raw-step plus raw-body model. When a
previous queue result should be reused instead of recomputed, the equivalent
assessment is:

```bash
python3 scripts/evaluate_symex_effectiveness.py \
  --queue-json /tmp/raw_queue.json \
  --body-queue-json /tmp/body_queue.json
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
- Integer div/mod zero-divisor hazard: source-backed div/mod opcodes and
  divisor operand slots are recorded in `RawInstrShape.intDivisorHazards`.

The first body baseline intentionally constrains `operandMask = 0`, i.e. the
immediate/raw operand branch. This keeps witnesses byte-realizable without
inventing symbolic host variables. Resolver-backed operands are the next layer,
not silently approximated here.

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
int-divisor-zero
```

Observed result:

| Metric | Result |
| --- | --- |
| environments | 5 |
| modeled body path classes | 9 |
| candidates | 45 |
| solver status | 45 `sat` |
| Lean byte materialization/replay | 45 `matchesPath=true` |
| all modeled body paths covered per environment | yes |

Risk split:

| Risk class | Count | Interpretation |
| --- | ---: | --- |
| `arithmetic-fault` | 5 | integer div/mod reaches zero divisor |
| `cursor-underflow` | 10 | body-level cursor is negative |
| `cursor-out-of-range` | 10 | body-level cursor is at/past raw buffer |
| `liveness` | 10 | body-level cursor does not move |
| `reachable-control-path` | 10 | in-bounds controls |

This is a real expansion beyond the dispatch skeleton. The new `int-divisor-zero`
paths are body-level formal findings: they are produced by shared opcode-family
semantics and profile data, not by a hand-selected TH06 mutation.

## What this does not cover yet

The current executor still does not cover the full game semantics of each
instruction. It now covers dispatch, `JUMP`, `JUMPDEC`, and immediate integer
div/mod divisor hazards, but not most body internals.

Source opcode surface from the local reference clones:

| Title | Source surface | Currently opcode-specific | Not-yet-modeled lower bound |
| --- | ---: | --- | ---: |
| TH06 | 136 `ECL_OPCODE_*` symbols | `UNIMP`, `JUMP`, `JUMPDEC`, `MATHINTDIV`, `MATHINTMOD` | 131 |
| TH07 | 159 raw opcode symbols, approximate source enum slice | `UNIMP`, `JUMP`, `DEC_JUMP`, `DIV`, `MOD` | 154 |
| TH08 | 91 numeric low-run `case` labels | `case 1`, `case 4`, `case 5`, `case 13`, `case 14`, `case 23`, `case 24` | 84 |

The lower bound is intentionally conservative. `JUMPDEC` and integer div/mod
zero-divisor hazards are now modeled; "ordinary advance" for the remaining
opcodes still does not prove their internal branches.

Not covered:

- conditional jumps, `CALL`, `RET`, callback stacks;
- TH07/TH08 operand-mask branches into variable reads/writes;
- resolver-driven integer divide/modulo by zero, float division/fmod edge cases,
  overflow, and other C/C++ arithmetic hazards;
- bullet, laser, enemy, item, ANM, sound, and callback side effects;
- timeline-to-enemy spawning and multi-context scheduling;
- full ANM script execution;
- TH07/TH08 retail DAT lowering and Wine validation.

Why those branches are not covered:

- they need a symbolic host state, not just raw bytes;
- operand flags can turn the same raw field into an immediate, local variable,
  global variable, enemy field, player-derived value, or RNG-derived value;
- `CALL`/`RET` and callbacks need bounded stack/context semantics;
- gameplay-visible effects need object invariants for bullets, lasers, enemies,
  items, resources, and render state;
- retail validation needs title-specific archive adapters and stage-selection
  harnesses, which currently exist only for TH06.

So the current coverage claim is strong but scoped:

```text
complete for the implemented raw-step abstraction;
complete for the first implemented raw-body abstraction;
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
- every default TH06/TH07/TH08 environment covers all 9 modeled body path
  classes;
- solver witnesses are materialized into bytes by Lean using shared profile
  offsets, then replay-checked;
- the body queue finds immediate integer div/mod zero-divisor paths for all
  default environments;
- TH08's difficulty override rule is captured as a semantic delta, not as a
  random trace divergence;
- the TH06 `jumped-before-buffer` symbolic witness has been lowered into a
  reachable stage-5 retail mutation and confirmed as `crash-dialog` in 2/2 Wine
  attempts.

Fuzz is still better outside the current formal model:

- gameplay side effects are currently observed much more easily than modeled;
- DanmakuFuzz already has TH06 headless/retail oracle infrastructure;
- fuzz campaigns naturally prioritize retail-visible behavior, while the formal
  queue currently returns many reachable but not-yet-retail-ranked candidates;
- ANM runtime crash families are not yet reproduced by the formal ANM model,
  which only covers entry headers and next-offset shape.

## Current verdict

For the implemented VM-core skeleton and the first shared body slice, Lean +
SMT is already better than fuzzing: it gives exhaustive path-class coverage,
satisfiable/unsatisfiable controls, concrete counterexample bytes, and shared
TH06/TH07/TH08 semantics.

For the whole VM, it is not yet better. The model has to move down one layer
into opcode bodies and bounded multi-step execution before we can honestly say
formal is finding classes that DanmakuFuzz cannot find in practice.

The next technically useful targets are:

1. add symbolic operand resolver semantics;
2. add bounded multi-step contexts for conditional jumps, `CALL`, and `RET`;
3. extend arithmetic hazards beyond immediate integer div/mod zero;
4. lower the top raw-step queue entries into TH06 retail batches;
5. add TH07/TH08 archive adapters so the same shared witnesses can be validated
   without TH06-specific mutation code.
