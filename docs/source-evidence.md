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
- `reference/th06/src/EclManager.cpp:130`: raw `ECL_OPCODE_JUMPDEC` decrements
  its counter slot before deciding whether to jump.
- `reference/th06/src/EclManager.cpp:136`: `ECL_OPCODE_JUMP` sets the context
  time from `args.jump.time` and advances the instruction pointer by
  `args.jump.offset`.
- `reference/th06/src/EclManager.cpp:134`: `ECL_OPCODE_JUMPDEC` falls through to
  the `ECL_OPCODE_JUMP` implementation when the decremented counter remains
  positive; otherwise it only advances normally.
- `reference/th06/src/EclManager.cpp:215`: `CMPINT` and `CMPFLOAT` update the
  context compare register.
- `reference/th06/src/EclManager.cpp:229`: `JUMPLSS`, `JUMPLEQ`, `JUMPEQU`,
  `JUMPGRE`, `JUMPGEQ`, and `JUMPNEQ` branch on the compare register before
  falling into the shared raw jump body.
- `reference/th06/src/EclManager.cpp:249`: `CALL` writes the next instruction
  context to `savedContextStack[stackDepth]` before `CallEclSub`, then only
  increments depth while `stackDepth < 7`.
- `reference/th06/src/EclManager.cpp:266`: `RET` decrements `stackDepth` before
  restoring `savedContextStack[stackDepth]`.
- `reference/th06/src/Enemy.hpp:195`: TH06 stores `savedContextStack[8]` and
  signed `stackDepth`.
- `reference/th06/src/EclManager.hpp:108`: `EclRawInstrCallArgs` stores
  `eclSub`, `var0`, `float0`, `cmpLhs`, and `cmpRhs` as the call-argument
  layout used by both plain and conditional CALL opcodes.
- `reference/th06/src/EclManager.cpp:274`: `CALLLSS`, `CALLLEQ`, `CALLEQU`,
  `CALLGRE`, `CALLGEQ`, and `CALLNEQ` resolve `cmpLhs` with `GetVar`, compare
  it against raw `cmpRhs`, and jump to the same `HANDLE_CALL` body only when
  the condition holds.
- `reference/th06/src/EnemyEclInstr.cpp:100`: `GetVar` resolves known negative
  `EclVarId` selectors and falls through to the operand-cell pointer for
  unknown operands, which reads back as the raw integer in rvalue positions.
- `reference/th06/src/EclManager.cpp:120`: raw ECL skips an instruction when
  `skipForDifficulty & (1 << g_GameManager.difficulty)` is zero, so execution
  uses active-bit intersection.
- `reference/th06/src/EnemyEclInstr.cpp:348`: integer division assigns
  `*outPtr = *lhsPtr / *rhsPtr` without a zero-divisor guard.
- `reference/th06/src/EnemyEclInstr.cpp:372`: integer modulo assigns
  `*outPtr = *lhsPtr % *rhsPtr` without a zero-divisor guard.
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
- `reference/th07/src/th07/EclManager.cpp:946`: raw `ECL_DEC_JUMP` decrements
  operand slot 2 and only falls through into `ECL_JUMP` when the decremented
  value remains positive.
- `reference/th07/src/th07/EclManager.cpp:952`: `ECL_JUMP` sets context time
  from `args[0].i` and advances by `args[1].i`.
- `reference/th07/src/th07/EclManager.cpp:23`: `GET_INT_VALUE` uses `paramMask`
  bit `1 << index` to choose raw operand versus `GetVarValue` resolution.
- `reference/th07/src/th07/EclManager.cpp:116`: `GetVarValue` resolves known
  integer selectors and falls through to the raw operand for default cases.
- `reference/th07/src/th07/EclManager.cpp:268`: `GetVar` records the writable
  lvalue selector subset; unknown selectors fall through to raw-pointer
  behavior in the original C++.
- `reference/th07/src/th07/EclManager.cpp:1092`: `ECL_JUMP_IF_EQUAL`,
  `ECL_JUMP_IF_NOT_EQUAL`, `ECL_JUMP_IF_LOWER_THAN`, `ECL_JUMP_IF_LEQ_THAN`,
  `ECL_JUMP_IF_GREATER_THAN`, and `ECL_JUMP_IF_GEQ_THAN` compare resolved
  integer operands 0 and 1, then jump using raw operands 2 and 3 when taken.
- `reference/th07/src/th07/EclManager.cpp:1168`: `ECL_SUB_CALL` stores the next
  instruction context at `savedContextStack[stackDepth]` before `CallEclSub`,
  then increments only while `stackDepth < ENEMY_STACK_SIZE`.
- `reference/th07/src/th07/EclManager.cpp:1183`: `ECL_SUB_RET` decrements
  `stackDepth` before restoring `savedContextStack[stackDepth]`.
- `reference/th07/src/th07/EnemyManager.hpp:62`: `ENEMY_STACK_SIZE` is 15 and
  the concrete saved stack stores `ENEMY_STACK_SIZE + 1` contexts.
- `reference/th07/src/th07/EclManager.cpp:1035`: raw `ECL_DIV` divides by
  `GET_INT_VALUE(enemy, 2)` without a zero-divisor guard.
- `reference/th07/src/th07/EclManager.cpp:1043`: raw `ECL_MOD` computes modulo
  by `GET_INT_VALUE(enemy, 2)` without a zero-divisor guard.
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
- `reference/th08/src/EclRunLow.inl:97`: TH08 `ReadInt` uses the corresponding
  `operandFlags` bit to choose raw operand versus `ResolveInt`.
- `reference/th08/src/EclRunLow.inl:112`: TH08 `WriteInt` uses the corresponding
  `operandFlags` bit to choose raw-pointer versus `ResolveIntLValue`.
- `reference/th08/src/EclOperandsInt.cpp:26`: `ResolveInt` resolves known
  integer selectors and falls through to the raw operand for default cases.
- `reference/th08/src/EclOperandsInt.cpp:156`: `ResolveIntLValue` records the
  writable integer selector subset.
- `reference/th08/src/EclRunLow.inl:194`: TH08 low-opcode dispatch keeps both
  raw operand access and `operandFlags`-resolved reads; jump operands below use
  the raw path.
- `reference/th08/src/EclRunLow.inl:233`: TH08 low opcode 5 decrements operand
  slot 2 and only falls through into opcode 4 jump semantics when the
  decremented value remains positive.
- `reference/th08/src/EclRunLow.inl:238`: TH08 low opcode 4 sets context time
  from `RawInt(instruction, 0)` and jumps by `RawInt(instruction, 1)`.
- `reference/th08/src/EclRunLow.inl:223`: TH08 low opcode 1 returns
  `ZUN_ERROR`.
- `reference/th08/src/EclRunLow.inl:276`: TH08 low opcodes 13 and 14 perform
  integer division/modulo with operand slot 1 as divisor and no zero-divisor
  guard.
- `reference/th08/src/EclRunLow.inl:315`: TH08 low opcodes 23 and 24 perform
  integer division/modulo with operand slot 2 as divisor and no zero-divisor
  guard.
- `reference/th08/src/EclRunLow.inl:166`: TH08 conditional jump helper sets time
  from operand 2 and jumps by operand 3 when the branch is taken.
- `reference/th08/src/EclRunLow.inl:415`: low opcodes 52 and 53 call
  `CallSubOnEnemy` and `PopEclContext`.
- `reference/th08/src/EclDependencies.cpp:466`: `CallSubOnEnemy` stores the
  next instruction context at `activeEclCallStack[activeEclCallStackDepth]`
  before `CallEclSub`, then increments only while depth `< 15`.
- `reference/th08/src/EclDependencies.cpp:499`: `PopEclContext` decrements
  `activeEclCallStackDepth`; negative depth indexes
  `childEclBlocks[childContextSlot - 1]`, otherwise it restores
  `activeEclCallStack[depth]`.
- `reference/th08/src/EnemyManager.hpp:211`: TH08 stores
  `mainEclCallStackStorage[16]`, an active call-stack pointer, and signed
  call-stack depths.
- `reference/th08/src/EnemyManager.hpp:289`: TH08 has four `childEclBlocks`
  slots for child context selection.
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
