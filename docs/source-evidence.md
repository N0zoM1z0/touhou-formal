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
- `reference/th06/src/EclManager.cpp:183`: `MATHINTADD` dispatches into the
  shared `MathAdd` helper with output slot 0 and operand slots 1 and 2.
- `reference/th06/src/EclManager.cpp:184`: `MATHFLOATADD` uses the same
  `MathAdd` helper and slot layout as the integer add opcode.
- `reference/th06/src/EclManager.cpp:195`: `MATHINTSUB` dispatches into
  `MathSub` with the same output/lhs/rhs slot layout.
- `reference/th06/src/EclManager.cpp:196`: `MATHFLOATSUB` shares that
  output/lhs/rhs slot layout through `MathSub`.
- `reference/th06/src/EclManager.cpp:199`: `MATHINTMUL` dispatches into
  `MathMul`; the helper performs extra initial lhs/rhs reads before output
  classification, which is a known future precision target.
- `reference/th06/src/EclManager.cpp:200`: `MATHFLOATMUL` dispatches through
  `MathMul`, so the extra initial reads are also a future precision target for
  float multiplication.
- `reference/th06/src/EclManager.cpp:203`: `MATHINTDIV` and `MATHFLOATDIV`
  both use `MathDiv` with output slot 0 and operand slots 1 and 2.
- `reference/th06/src/EclManager.cpp:207`: `MATHINTMOD` and `MATHFLOATMOD`
  both use `MathMod` with output slot 0 and operand slots 1 and 2.
- `reference/th06/src/EnemyEclInstr.cpp:238`: `GetVarFloat` casts the raw f32
  operand to an integer `EclVarId`, delegates to `GetVar`, and falls back to
  the original f32 operand cell only for `GetVar`'s default pointer.
- `reference/th06/src/EnemyEclInstr.cpp:252`: `SetVar` only writes when the
  resolved output is classified as int or float.
- `reference/th06/src/EnemyEclInstr.cpp:272`: integer `MathAdd`, `MathSub`, and
  `MathMul` classify the output, then read lhs/rhs through `GetVar` before
  writing the resolved output.
- `reference/th06/src/EnemyEclInstr.cpp:288`: float `MathAdd`, `MathSub`,
  `MathMul`, `MathDiv`, and `MathMod` write only after the output is classified
  as FLOAT, read lhs/rhs through `GetVarFloat`, and use `fmodf` for float modulo.
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
- `reference/th07/src/th07/EclManager.cpp:1011`: `ECL_ADD`, `ECL_SUB`,
  `ECL_MUL`, `ECL_DIV`, and `ECL_MOD` write `GET_INT_PTR(enemy, 0)` and read
  `GET_INT_VALUE(enemy, 1)`/`GET_INT_VALUE(enemy, 2)`.
- `reference/th07/src/th07/EclManager.hpp:114`: the integer binary arithmetic
  opcodes are numbered `ECL_ADD = 12` through `ECL_MOD = 16`.
- `reference/th07/src/th07/EclManager.hpp:115`: float binary arithmetic opcodes
  are numbered `ECL_ADD_FLOAT = 19` through `ECL_MOD_FLOAT = 23`.
- `reference/th07/src/th07/EclManager.cpp:1015`: `ECL_ADD_FLOAT`,
  `ECL_SUB_FLOAT`, `ECL_MUL_FLOAT`, `ECL_DIV_FLOAT`, and `ECL_MOD_FLOAT` write
  `GET_FLOAT_PTR(enemy, 0)` and read `GET_FLOAT_VALUE(enemy, 1)` and
  `GET_FLOAT_VALUE(enemy, 2)`; float modulo uses `fmodf`.
- `reference/th07/src/th07/EclManager.hpp:112`: `ECL_GET_BOSS_INT` is opcode
  43.
- `reference/th07/src/th07/EclManager.cpp:1001`: `ECL_GET_BOSS_INT` writes
  slot 0 from `GET_INT_VALUE(g_EnemyManager.bosses[GET_INT_VALUE(enemy, 2)],
  1)`, so slot 1's operand mask bit controls whether the boss pointer is
  actually dereferenced.
- `reference/th07/src/th07/EnemyManager.hpp:378`: TH07 stores eight boss
  pointers in `bosses[8]`.
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
- `reference/th08/src/EclRunLow.inl:264`: TH08 low opcodes 10 through 14 update
  `WriteInt(enemy, instruction, 0)` in place using `ReadInt(..., 1)`.
- `reference/th08/src/EclRunLow.inl:291`: TH08 low opcodes 20 through 24 assign
  to `WriteInt(enemy, instruction, 0)` using `ReadInt(..., 1)` and
  `ReadInt(..., 2)`.
- `reference/th08/src/EclRunLow.inl:265`: TH08 low opcodes 15 through 18 update
  `WriteFloat(enemy, instruction, 0)` in place using resolved/raw float operand
  slot 1.
- `reference/th08/src/EclRunLow.inl:281`: TH08 low opcode 19 writes
  `fmodf(slot0, slot1)` back to `WriteFloat(..., 0)`, with operand flags
  applied to both slot 0 and slot 1 reads.
- `reference/th08/src/EclRunLow.inl:292`: TH08 low opcodes 25 through 29 assign
  float arithmetic results to `WriteFloat(..., 0)` using resolved/raw float
  operand slots 1 and 2; opcode 29 uses `fmodf`.
- `reference/th08/src/EclRunLow.inl:694`: TH08 low opcode 86 writes slot 0
  from raw slot 1 when `operandFlags & 2U` is clear, otherwise it resolves slot
  1 against `g_EnemyManager.bosses[ReadInt(..., 2)]`.
- `reference/th08/src/EclRunLow.inl:703`: the adjacent float boss-read opcode
  checks the boss pointer before resolving, unlike integer opcode 86.
- `reference/th08/src/EnemyManager.hpp:447`: TH08 stores eight boss pointers in
  `bosses[8]`.
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
- `reference/th07/src/th07/EnemyManager.cpp:198`: TH07 timeline dispatch spawns
  enemies for opcodes 0 through 7 and uses timeline `arg0` as the ECL sub id.
- `reference/th08/src/EnemyTimeline.cpp:134`: TH08 timeline dispatch spawns
  enemies for opcodes 0, 1, 2, 3, 4, 5, 11, 12, and 15 and uses
  `args.ints[0]` as the ECL sub id after the timeline difficulty-mask gate.
- `reference/th07/src/th07/Supervisor.hpp:65`: TH07 retail cfg has size `0x38`;
  `colorMode16bit`, `windowed`, and `frameskipConfig` are at offsets `0x1e`,
  `0x22`, and `0x23`.
- `reference/th08/src/Supervisor.hpp:62`: TH08 retail cfg has size `0x3c`; the
  same three cfg fields are at offsets `0x1e`, `0x22`, and `0x23`, with opts at
  `0x38`.

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

## Boss Float Read Evidence

The boss-float lane is source-backed by the same host array boundary as
boss-int:

- `reference/th07/src/th07/EclManager.hpp:112-113` assigns
  `ECL_GET_BOSS_INT = 43` and `ECL_GET_BOSS_FLOAT = 44`.
- `reference/th07/src/th07/EclManager.cpp:1006-1010` writes through
  `GET_FLOAT_PTR(enemy, 0)` from
  `GET_FLOAT_VALUE(g_EnemyManager.bosses[GET_INT_VALUE(enemy, 2)], 1)`.
- `reference/th08/src/EclRunLow.inl:703-710` implements low opcode `87` with
  `if (g_EnemyManager.bosses[ReadInt(enemy, instruction, 2)])` before the
  value-resolution dereference.
- `reference/th07/src/th07/EclManager.cpp:327-482` and
  `reference/th08/src/EclOperandsFloat.cpp:23-147` cast float operands to
  integer selector ids and default back to the raw operand when no selector
  matches.
- `reference/th07/src/th07/EclManager.cpp:486-571` and
  `reference/th08/src/EclOperandsFloat.cpp:155-210` provide the writable
  float-lvalue selector subsets.

The model records this as a shared `RawBossFloatReadShape` with the same
`bossSlotCount = 8` index boundary as boss-int, plus a title-specific
`RawBossReadNullPolicy`: TH07 is `unguarded-deref`, TH08 is `guarded-skip`.

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

The TH08 boss-int `boss-int-null-deref` symbolic witness has been lowered into
`th08.dat` and retail-checked under Wine in
`retail_validation/formal-th08-boss-int-boss-int-null-deref-20260901T024506Z`.
The witness bytes are produced by `scripts/symex_materialize_boss_int_read.py`,
placed in an early timeline-spawned subroutine by
`scripts/retail_confirm_boss_int_read.py`, and classified as `crash-dialog`.

The boss-float retail lowering reuses the same archive/ECL patching pipeline
through `scripts/retail_confirm_boss_float_read.py`. Four representative
TH07/TH08 witnesses were lowered on 2026-09-01 and classified as
`game-window-live`; these are retained as calibration artifacts rather than
retail crash confirmations.
