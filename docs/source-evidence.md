# Source Evidence

This file records the initial source facts used by the first model. Paths are
relative to `/home/yann/yann/touhou/formal`.

## TH06

- `reference/th06/src/EclManager.hpp:65`: `EclTimelineInstr` stores `i16 time`,
  `i16 arg0`, `i16 opCode`, `i16 size`, then timeline args.
- `reference/th06/src/EclManager.hpp:340`: `EclRawHeader` stores `i16 subCount`,
  `i16 mainCount`, three timeline offsets, and a flexible `subOffsets` table.
- `reference/th06/src/EclManager.hpp:326`: `EclRawInstr` stores `i32 time`,
  `i16 opCode`, `i16 offsetToNext`, difficulty skip byte, and raw args.
- `reference/th06/src/EclManager.cpp:54`: loader rebases `timelineOffsets[0]`.
- `reference/th06/src/EclManager.cpp:56`: `subTable` points at `subOffsets[0]`.
- `reference/th06/src/EclManager.cpp:57`: loader rebases `subTable[idx]` for
  `idx < subCount`, without validating the whole file length here.
- `reference/th06/src/EclManager.cpp:78`: `CallEclSub` assigns
  `ctx->currentInstr = this->subTable[subId]` directly.
- `reference/th06/src/EclManager.hpp:349`: `ECL_OPCODE_JUMP` is the opcode after
  `NOP` and `UNIMP`, so its numeric value is 2.
- `reference/th06/src/EclManager.cpp:128`: raw `ECL_OPCODE_UNIMP` returns
  `ZUN_ERROR`.
- `reference/th06/src/EclManager.cpp:136`: `ECL_OPCODE_JUMP` sets the context
  time from `args.jump.time` and advances the instruction pointer by
  `args.jump.offset`.
- `reference/th06/src/EclManager.cpp:120`: raw ECL skips an instruction when
  `skipForDifficulty & (1 << g_GameManager.difficulty)` is zero, so execution
  uses active-bit intersection.
- `reference/th06/src/EnemyManager.cpp:177`: timeline dispatch switches on
  `timelineInstr->opCode`.
- `reference/th06/src/EnemyManager.cpp:183`: spawn opcode 0 passes
  `timelineInstr->arg0` to `SpawnEnemy`.
- `reference/th06/src/EnemyManager.cpp:330`: after handling or skipping a
  timeline instruction, the pointer advances by `timelineInstr->size`.
- `reference/th06/src/EnemyManager.cpp:110`: `SpawnEnemy` calls
  `g_EclManager.CallEclSub(&newEnemy->currentContext, eclSubId)`.

## TH07

- `reference/th07/src/th07/EclManager.hpp:277`: `EclRawHeader` stores
  `subCount`, `timelineCount`, sixteen timeline pointers, and `subTable[]`.
- `reference/th07/src/th07/EclManager.hpp:291`: `EclRawInstr` stores `u32 time`,
  `i16 id`, `i16 size`, difficulty skip byte, `u16 paramMask`, and args.
- `reference/th07/src/th07/EclManager.hpp:317`: `EclTimelineInstr` stores
  `i16 time`, `i16 arg0`, `i16 opcode`, `i16 size`, and six argument slots.
- `reference/th07/src/th07/EclManager.hpp:95`: `ECL_JUMP` is explicitly assigned
  opcode 2, while `ECL_DEC_JUMP` is 3.
- `reference/th07/src/th07/EclManager.hpp:93`: `ECL_UNIMP` is opcode 1.
- `reference/th07/src/th07/EclManager.cpp:106`: `CallEclSub` reads
  `this->subTable[subId]` directly.
- `reference/th07/src/th07/EclManager.cpp:941`: raw `ECL_UNIMP` returns
  `ZUN_ERROR`.
- `reference/th07/src/th07/EclManager.cpp:952`: `ECL_JUMP` sets context time
  from `args[0].i` and advances by `args[1].i`.
- `reference/th07/src/th07/EclManager.cpp:935`: raw ECL skips an instruction
  when `skipInstrOnDifficulty & g_GameManager.difficultyMask` is zero, so
  execution uses active-bit intersection.
- `reference/th07/src/th07/EnemyManager.cpp:364`: timeline pointer advancement
  also uses `timelineInstr->size`.

## TH08

- `reference/th08/src/EclManager.hpp:181`: `EclRawHeader` stores version,
  `subCount`, `timelineCount`, sixteen timeline offsets, and `subOffsets[1]`.
- `reference/th08/src/EclManager.hpp:147`: `EclRawInstruction` stores
  `i32 time`, `i16 opcode`, `i16 nextOffset`, difficulty byte, `u16
  operandFlags`, and operands.
- `reference/th08/src/EclManager.cpp:38`: loader rejects non-`0x800` ECL
  versions.
- `reference/th08/src/EclManager.cpp:69`: `CallEclSub` returns immediately for
  negative sub ids, but still reads `this->subTable[subId]` directly for
  nonnegative ids.
- `reference/th08/src/EnemyManager.hpp:419`: `EclTimelineInstruction` stores
  `i32 time`, `i16 opcode`, `u8 size`, `u8 difficultyMask`, and seven 32-bit
  args; there is no TH06-style top-level `arg0`.
- `reference/th08/src/EnemyTimeline.cpp:120`: TH08 timeline spawn opcodes pass
  `args.ints[0]` into `SpawnEnemy1`, which then calls `CallEclSub`.
- `reference/th08/src/EnemyTimeline.cpp:292`: TH08 advances the timeline cursor
  by `instruction->size`.
- `reference/th08/src/EclRunLow.inl:88`: TH08 `RawInt` reads four-byte raw
  operands at `operands + index * 4`.
- `reference/th08/src/EclRunLow.inl:194`: TH08 low-opcode dispatch keeps both
  raw operand access and `operandFlags`-resolved reads; jump operands below use
  the raw path.
- `reference/th08/src/EclRunLow.inl:238`: TH08 low opcode 4 sets context time
  from `RawInt(instruction, 0)` and jumps by `RawInt(instruction, 1)`.
- `reference/th08/src/EclRunLow.inl:223`: TH08 low opcode 1 returns
  `ZUN_ERROR`.
- `reference/th08/src/EclRunLow.inl:166`: TH08 conditional jump helper sets time
  from operand 2 and jumps by operand 3 when the branch is taken.
- `reference/th08/src/EclRun.cpp:67`: TH08 raw ECL requires
  `instruction->difficultyMask` to contain every bit in
  `g_GameManager.difficultyMask | enemy->eclDifficultyMaskOverride`; otherwise
  it advances without executing the opcode.
- `reference/th08/src/EnemyTimeline.cpp:131`: TH08 timeline ECL still uses the
  active difficulty-mask intersection check and does not include the raw ECL
  override mask.

## DanmakuFuzz Boundary

- `reference/DanmakuFuzz/src/danmakufuzz/ecl_ir/parser.py`: the historical
  parser rejects malformed headers, invalid offsets, overlapping regions, and
  timeline instructions smaller than the fixed prefix. That is useful fuzzing
  infrastructure, but it is not faithful runtime semantics for the original
  ZUN loader.
- `reference/DanmakuFuzz/src/danmakufuzz/ecl_ir/model.py`: its
  `TimelineInstruction` serializes a TH06-style `i16 time/arg0/opcode/size`
  prefix, so the Lean model now represents the corresponding TH08 layout as a
  profile delta instead of copying this old shape globally.

## ANM

- `reference/th06/src/AnmManager.hpp:59`: TH06 `AnmRawEntry` stores counts,
  texture metadata, `nextOffset`, sprite offsets, and embedded scripts; its
  asserted size is `0xb8`.
- `reference/th06/src/AnmManager.cpp:341`: TH06 `LoadAnm` opens one raw entry and
  consumes its sprite/script tables directly.
- `reference/th07/src/th07/AnmManager.hpp:214`: TH07 `AnmRawEntry` has the same
  `nextOffset` offset and embedded sprite/script tables.
- `reference/th07/src/th07/AnmManager.cpp:402`: TH07 `LoadAnms` walks the entry
  chain until `nextOffset == 0`.
- `reference/th08/src/AnmManager.hpp:227`: TH08 `AnmRawEntry` is a compact
  `0x40`-byte header with `nextOffset` and no embedded sprite/script arrays.
- `reference/th08/src/AnmManager.cpp:2354`: TH08 counts entries, scripts, and
  sprites while walking the same `nextOffset` chain.

## Retail Calibration

The TH06 `arg0 = 256` timeline mutation has been retail-checked under Wine in
`retail_validation/formal-th06-stage5-arg0-256-run3-long-probe/source-result/result.json`.
The mutant reaches the formal `CallEclSub` out-of-bounds witness and is
classified as `retail-frame-stall` against a clean `game-window-live` baseline.

The TH06 raw ECL `jumped-before-buffer` symbolic witness has also been
retail-checked under Wine in
`retail_validation/formal-th06-raw-symex-jumped-before-buffer-20260831T111946Z`.
The witness bytes are produced by `scripts/symex_materialize_raw_step.py` and
then spliced into stage 5 subroutine 0 instruction 0 by
`scripts/retail_confirm_th06_raw_symex.py`. Two repeated attempts classified
the mutant as `crash-dialog` against clean `game-window-live` baselines.
