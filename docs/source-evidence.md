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
- `reference/th06/src/EclManager.cpp:141`: `SETINT` and `SETFLOAT` both call
  `SetVar` with output slot 0 and raw value slot 1; `SetVar` decides whether
  the output is INT or FLOAT after resolving the output selector.
- `reference/th06/src/EclManager.cpp:150`: the four range-random opcodes
  resolve integer or float range/addend operands, obtain a random value, and
  pass the local result through `SetVar`.
- `reference/th06/src/Rng.hpp:28`: u32 range generation uses unsigned modulo
  and returns zero for range zero; float range generation multiplies a
  zero-to-one sample by the requested range.
- `reference/th06/src/EclManager.cpp:215`: `CMPINT` and `CMPFLOAT` update the
  context compare register.
- `reference/th06/src/EclManager.cpp:215`: `CMPINT` resolves both inputs with
  `GetVar`; `CMPFLOAT` uses `GetVarFloat` and maps the unordered case to `1`
  because both equality and less-than tests are false.
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
- `reference/th06/src/EclManager.cpp:316`: immediate movement handlers resolve
  position/velocity/speed fields through `GetVarFloat`, except
  `MOVEATPLAYER`'s angle offset, which is added as a raw float word.
- `reference/th06/src/EclManager.cpp:612`: movement bounds are copied directly
  from four raw float fields and toggle `shouldClampPos`.
- `reference/th06/src/EclManager.cpp:622`: opcodes 49/50 sample an angle from
  two raw fields. Opcode 50 sequentially reflects it at the rectangular
  margins and uses the generated angle in its right-positive subtraction.
- `reference/th06/src/EnemyEclInstr.cpp:41`: `MoveDirTime` resolves only its
  angle operand, computes a half-duration polar delta, snapshots position, and
  starts interpolation mode; `MovePosTime` and `MoveTime` share the same timer
  and origin writes with their distinct input sources.
- `reference/th06/src/EclManager.cpp:560`: opcodes 52 through 64 reuse those
  three helpers and select easing values 0 through 4 from consecutive opcode
  ranges.
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
- `reference/th06/src/EclManager.cpp:187`: `MATHINC` and `MATHDEC` call
  `GetVar` with `valueType = NULL` and directly increment/decrement the
  returned pointer, so they bypass `SetVar`'s INT/FLOAT output type guard.
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
- `reference/th06/src/EnemyEclInstr.cpp:395`: `MathAtan2` accepts only a
  FLOAT-classified output and computes `atan2f(slot4 - slot2, slot3 - slot1)`
  from four `GetVarFloat` inputs.
- `reference/th06/src/EclManager.cpp:145`: `MATHNORMANGLE` reads slot 0 through
  `GetVar`, interprets the pointed-to bits as f32, and writes the normalized
  result through `SetVar`.
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

- `reference/th07/src/th07/EclManager.cpp:1051`: `ECL_SIN` and `ECL_COS`
  resolve float slot 1 and write `sinf`/`cosf` to float slot 0; `ECL_ATAN2`
  uses the same four-slot delta layout as TH06.
- `reference/th07/src/th07/EclManager.cpp:963`: `ECL_NORMALIZE_ANGLE` resolves
  float slot 0 for both its read and write.
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
- `reference/th07/src/th07/EclManager.cpp:956`: `ECL_SET_INT` writes
  `GET_INT_PTR(enemy, 0)` from `GET_INT_VALUE(enemy, 1)`, while
  `ECL_SET_FLOAT` writes `GET_FLOAT_PTR(enemy, 0)` from
  `GET_FLOAT_VALUE(enemy, 1)`.
- `reference/th07/src/th07/EclManager.cpp:967`: TH07 implements integer and
  float range/random-add opcodes plus integer/float sign opcodes selected by
  the low bit of `GetRandomU16()`.
- `reference/th07/src/th07/Rng.hpp:16`: integer range generation is unsigned
  u32 modulo with a zero-range special case; float range generation multiplies
  a float sample by the range.
- `reference/th07/src/th07/EclManager.cpp:995`: `ECL_INC` and `ECL_DEC`
  update `GET_INT_PTR(enemy, 0)` in place by `+1` or `-1`.
- `reference/th07/src/th07/EclManager.cpp:952`: `ECL_JUMP` sets context time
  from `args[0].i` and advances by `args[1].i`.
- `reference/th07/src/th07/EclManager.cpp:1098`: six interleaved float
  conditional jumps resolve float slots 0 and 1 and share the integer branch
  family's raw target-time and displacement operands in slots 2 and 3.
- `reference/th07/src/th07/EclManager.cpp:1218`: immediate movement handlers
  resolve position, axis velocity, angular velocity, speed, acceleration, and
  player-relative operands; axis velocity additionally writes `atan2f(y, x)`.
- `reference/th07/src/th07/EclManager.cpp:1573`: movement bounds resolve four
  float operands and toggle `hasMovementBounds`.
- `reference/th07/src/th07/EclManager.cpp:1587`: opcode 51 resolves upper
  operand 2 and lower operand 1 for the RNG range, then resolves lower operand
  1 again for the addition. Opcode 52 selects a player-side exit cone,
  reflects it at the rectangular margins, and in the right-positive branch
  subtracts `enemy->angle` rather than `exitAngle`.
- `reference/th07/src/th07/EclManager.cpp:1965`: opcode 155 selects its exit
  cone using player/enemy X plus fixed 96/288 inner-arena thresholds.
- `reference/th07/src/th07/EclManager.cpp:576`: timed direction and position
  helpers resolve duration/speed operands at every macro occurrence, snapshot
  the origin, install three-bit easing/mode state, and optionally mirror the
  interpolation delta's X component.
- `reference/th07/src/th07/EclManager.cpp:1538`: timed direction takes a
  nonpositive-duration polar fast path and resolves duration again for its
  timer write; opcodes 54 and 55 otherwise call the shared helpers.
- `reference/th07/src/th07/EclManager.cpp:1557`: opcodes 56 through 61 write
  orbit origin/angle/radius state or select polar, orbit, and interpolation
  movement modes while assigning the shared movement timer.
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
- `reference/th08/src/EclRunLow.inl:244`: TH08 low opcode 6 writes
  `WriteInt(..., 0)` from `ReadInt(..., 1)`, while low opcode 7 writes
  `WriteFloat(..., 0)` from resolved/raw float operand slot 1.
- `reference/th08/src/EclRunLow.inl:252`: low opcodes 8 and 9 multiply resolved
  integer/float slot 1 by a sign selected from `GetRandomU16()` parity.
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
- `reference/th08/src/EclRunLow.inl:333`: TH08 low opcodes 30 and 31 increment
  or decrement `WriteInt(..., 0)` in place.
- `reference/th08/src/EclRunLow.inl:335`: TH08 low opcodes 32 and 33 apply
  `sinf`/`cosf` to float slot 1, while opcode 34 calls `VectorAngle` on the same
  four-slot coordinate deltas used by the older `atan2f` opcodes.
- `reference/th08/src/EclRunLow.inl:353`: low opcode 37 normalizes float slot 0
  in place through `AddNormalizeAngle`.
- `reference/th08/src/EclDependencies.cpp:99`: low opcode 67 and high opcode
  178 derive an angle in host code and then share immediate/timed polar
  displacement writes; neither handler reads a bytecode angle operand.
- `reference/th08/src/EclRunHigh.inl:882`: high opcode 169 reuses TH07's
  fixed-cone arena-exit condition and writes a float lvalue.
- `reference/th08/src/EclRunLow.inl:571`: opcodes 72 through 74 initialize or
  partially update orbit motion. Opcode 72 writes only origin X/Y, while
  opcode 73 snapshots the full current position and sets radius to zero.
- `reference/th08/src/EclRunLow.inl:694`: TH08 low opcode 86 writes slot 0
  from raw slot 1 when `operandFlags & 2U` is clear, otherwise it resolves slot
  1 against `g_EnemyManager.bosses[ReadInt(..., 2)]`.
- `reference/th08/src/EclRunLow.inl:703`: the adjacent float boss-read opcode
  checks the boss pointer before resolving, unlike integer opcode 86.
- `reference/th08/src/EnemyManager.hpp:447`: TH08 stores eight boss pointers in
  `bosses[8]`.
- `reference/th08/src/EclRunLow.inl:166`: TH08 conditional jump helper sets time
  from operand 2 and jumps by operand 3 when the branch is taken.
- `reference/th08/src/EclRunLow.inl:140`: the same helper interleaves six
  `ReadFloat` predicates with the six integer predicates for opcodes 40 through
  51.
- `reference/th08/src/EclRunLow.inl:415`: low opcodes 52 and 53 call
  `CallSubOnEnemy` and `PopEclContext`.
- `reference/th08/src/EclRunLow.inl:496`: low opcode 63 writes resolved X/Y,
  forces position Z to zero, and clamps; opcodes 65, 68, 70, and 71 implement
  normalized polar/player-relative motion and scalar movement writes with
  distinct mode/timer updates.
- `reference/th08/src/EclRunLow.inl:617`: low opcodes 75 and 76 resolve four
  movement-bound floats and toggle the bounds flag.
- `reference/th08/src/EclHelpers.cpp:21`: the timed polar and relative-position
  helpers preserve repeated `ReadInt`/`ReadFloat` calls, use different
  position/world-position sources, set interpolation mode/easing/timers, and
  apply mirror-X after delta construction.
- `reference/th08/src/EclRunLow.inl:502`: low opcodes 64, 66, and 69 dispatch
  timed position, absolute direction, and player-directed motion. Opcodes 66
  and 69 have different nonpositive timer writes, and opcode 69's positive
  branch calls the absolute polar helper.
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

## Enemy State Effect Evidence

- `reference/th06/src/EclManager.cpp:668-683` copies three raw float hitbox
  words and assigns raw i32 values into one-bit collision/damage and three-bit
  death-mode fields. `:801-803` does the same for the one-bit interactable
  field.
- `reference/th07/src/th07/EclManager.cpp:1645-1668` resolves the three float
  components of both primary and graze hitboxes, but reads the low raw byte for
  contact, damage, hittable, and death-type bitfields. `:1747-1749` writes the
  raw low byte into `canDie`.
- `reference/th08/src/EclRunLow.inl:633-648` resolves two float operands for
  each XY hitbox and leaves Z untouched.
- `reference/th08/src/EclRunLow.inl:650-688` gives opcodes 79, 80, and 81 three
  distinct mask meanings. Opcode 79 replaces all six flags and inverts the
  first three bits; 80 conditionally disables them; 81 conditionally enables
  them. Collision changes in 80/81 are mirrored into an attached alignment
  effect when one exists.
- `reference/th08/src/EclRunHigh.inl:477-481` gates high opcode 129's raw-byte
  death-mode write on the target's presentation-write condition.
- `reference/th06/src/EclManager.cpp:707-709` writes one raw i32 operand to
  both `life` and `maxLife`; `:785-787` passes a raw i32 to
  `bossTimer.SetCurrent`.
- `reference/th07/src/th07/EclManager.cpp:1693-1704` resolves life through
  `GET_INT_VALUE`, writes `life` and `maxLife`, and clears boss-health slots
  for the primary boss. `:1719-1721` resolves and assigns the enemy timer.
- `reference/th08/src/EclRunHigh.inl:520-531` resolves life into
  `phaseStartingLife`, `life`, and `maxLife`, with the primary-boss gauge side
  effect. `:549` resolves and assigns `bossTimer`.
- `reference/th06/src/ZunTimer.hpp:62-67` and the corresponding TH07/TH08 timer
  assignment operators set `current`, reset `subFrame` to zero, and set
  `previous = -999`.

The shared model therefore emits typed state writes rather than pretending
that the three games expose one uniform cleaned-up enemy API. One-bit and
three-bit target fields explicitly truncate their source values; life and
timer effects retain title-specific operand resolution and secondary writes.

## Enemy Lifecycle Evidence

- `reference/th06/src/EclManager.hpp:252-260` defines the raw enemy-create
  packet as subroutine id, three-float position, i16 life, i16 item drop, and
  i32 score. `reference/th06/src/EclManager.cpp:856-884` resolves only the
  position fields, calls `SpawnEnemy`, and implements kill-all as an inline
  non-boss loop that can enter death callbacks.
- `reference/th06/src/EnemyManager.cpp:92-124` scans the first 256 enemy slots,
  copies the spawn template, applies nonnegative life/item/score overrides,
  calls `CallEclSub`, immediately runs the spawned ECL context, and then
  snapshots item/score/max-life state.
- `reference/th07/src/th07/EclManager.cpp:1828-1858` implements absolute and
  relative enemy spawn only while the parent enemy is alive. Position, life,
  item, and score use `GET_*_VALUE` with `paramMask`; the relative form adds
  the parent enemy position before calling `SpawnEnemyEx`. Opcode 94 calls
  `RemoveAllEnemies(8000, 0)`.
- `reference/th07/src/th07/EnemyManager.cpp:95-135` scans 480 enemy slots,
  calls `CallEclSub`, copies caller `EclContextArgs`, immediately runs the
  spawned ECL context, and stores item drop through an i8 cast.
  `reference/th07/src/th07/EnemyManager.cpp:1459-1520` shows remove-all skips
  inactive/boss enemies, may spawn point items/popups, and may enter death
  callbacks for enemies that cannot die normally.
- `reference/th08/src/EclRunHigh.inl:83-92` defines the high-opcode spawn
  packet. `reference/th08/src/EclRunHigh.inl:717-779` implements absolute and
  relative spawn with the same parent-life gate and operand-flag resolution as
  TH07, then calls `KillAllNonBossEnemies(8000, 0)` for opcode 95.
- `reference/th08/src/EnemyTimeline.cpp:64-115` shows `SpawnEnemy2` scanning
  480 slots, calling `CallEclSub`, copying the active integer-variable array,
  immediately running the spawned ECL context, and storing item drop through an
  i8 cast. `reference/th08/src/EnemyManager.cpp:1424-1498` adds the TH08
  kill-all differences: noDeath enemies are skipped and parent chains are
  detached.

The shared model treats enemy creation/removal as VM-to-host effects. It
records source-visible arguments, resolver order, truncation, pool size, and
remove-all policy, but it does not yet simulate the entire enemy array,
template copy, spawned-context execution, item creation, or callback scheduler.

## Item/Drop Evidence

- `reference/th06/src/EclManager.cpp:809-824` loops over the raw `setInt`
  operand, starts each item at enemy position, applies two RNG offsets from a
  144-wide range shifted by 72, and chooses power items below player power 128
  or point items otherwise.
- `reference/th06/src/EclManager.cpp:846-847` spawns a single item from the raw
  `dropItem.itemId` field at enemy position.
- `reference/th07/src/th07/EclManager.cpp:1768-1798` resolves item loop counts
  through `GET_INT_VALUE`, applies a 128-wide range shifted by 64, implements a
  point-only loop for opcode 154, and spawns a single resolved item id for
  opcode 124.
- `reference/th08/src/EclRunHigh.inl:639-710` resolves item-drop state fields,
  loop counts, and single item ids through `TH08_ECL_READ_I`. The power-or-point
  and point-only loops use two `GetRandomF32() * 128.0f - 64.0f` offsets, and
  single spawns pass `ITEM_STATE_DEFAULT`.

The model records item/drop requests and field writes rather than simulating
the item pool. This keeps the proof obligation at the VM boundary: operand
resolution, loop count, spread constants, item-selection policy, and TH08 state
fields are source-backed, while actual item allocation and RNG samples remain
host behavior.

## Boss/Spellcard Lifecycle Evidence

- `reference/th06/src/EnemyManager.hpp:40`,
  `reference/th07/src/th07/EnemyManager.hpp:378`, and
  `reference/th08/src/EnemyManager.hpp:447` define `bosses[8]`.
- `reference/th06/src/EclManager.cpp:536-550`,
  `reference/th07/src/th07/EclManager.cpp:1508-1528`, and
  `reference/th08/src/EclRunHigh.inl:426-456` implement boss slot assignment.
  All three write `g_EnemyManager.bosses[slot]` for nonnegative slots without
  an opcode-level upper-bound check. TH08 then stores `enemy->bossSlot` as u8
  and only opens GUI boss presence for slot 0; TH06/TH07 set GUI presence for
  every nonnegative slot. TH07/TH08 hide GUI presence on clear only when the
  stored/current boss slot is below 4.
- `reference/th06/src/EclManager.hpp:228-233`,
  `reference/th07/src/th07/EclManager.cpp:667-692`, and
  `reference/th08/src/EclDependencies.cpp:18-36` define spellcard-start
  argument layout: TH06 has signed i16 sprite/id plus an inline tail name, TH07
  decodes a 48-byte xor-0xaa name and uses signed sprite/unsigned id packed in
  the first operand, and TH08 forwards i16 enemy face, u16 spell number, i32
  bonus, encoded owner/name bytes, and two comment lines.
- `reference/th06/src/EclManager.cpp:710-725` and
  `reference/th07/src/th07/EclManager.cpp:667-692` show the legacy spellcard
  start path: GUI presentation, bullet clear, legacy `spellcardInfo`
  activation, stage timer reset, and bullet-rank reset. TH07 additionally runs
  spellcard background VMs and computes a score-drain rate from
  `timerCallbackThreshold`. `reference/th08/src/EclRunHigh.inl:541-548` and
  `reference/th08/src/EclDependencies.cpp:38-56` show that TH08 delegates the
  opcode boundary to `g_Spellcard.StartSpell`/`EndSpell`.
- `reference/th06/src/EclManager.cpp:749-783` and
  `reference/th07/src/th07/EclManager.cpp:767-852` gate legacy spellcard-end
  cleanup on active spell state, then deactivate `spellcardInfo` and mark the
  stage inactive. TH07 also removes enemies and plays the spell-end sound.
- `reference/th07/src/th07/EclManager.cpp:1704-1711` and
  `reference/th08/src/EclRunHigh.inl:530-538` write boss gauge slot start/stop
  ratios divided by `enemy->maxLife` and write gauge color. The opcode bodies
  do not bound the gauge index.
- `reference/th06/src/EclManager.cpp:852-854`,
  `reference/th07/src/th07/EclManager.cpp:1824-1826`, and
  `reference/th08/src/EclRunHigh.inl:712-715` write boss life marker counts;
  TH06/TH07 add 1800 to time counters, and TH08 increments one spellcard
  history bonus field by `0x708`.
- `reference/th06/src/EclManager.cpp:923-924`,
  `reference/th07/src/th07/EclManager.cpp:1899-1900`, and
  `reference/th08/src/EclRunHigh.inl:826-830` cover timeout/survival flags.
  TH08 timeout additionally writes `g_Spellcard.scoreLimit = 99999990`.
- `reference/th07/src/th07/EclManager.cpp:1938-1941` reads `bosses[slot]` with
  no opcode-level slot bound check and writes `runInterrupt` only when the boss
  pointer is non-null.
- `reference/th08/src/EclRunHigh.inl:856-862`,
  `reference/th08/src/EclRunHigh.inl:954`, and
  `reference/th08/src/EclRunHigh.inl:972` cover TH08 spellcard effect tracking,
  phase-starting-life, and bonus-update controls. Opcode 164 resolves/stores
  its vector only when the first resolved flag value is zero.

The shared boss/spellcard lifecycle model stays at the VM-to-host boundary:
unchecked boss/gauge slot accesses become formal faults, source-visible
truncation and branch gates are explicit, and deep GUI/Spellcard/Catk scoring
state remains an opaque host subsystem for later modeling.

## Special Numeric and Interpolation Evidence

- `reference/th06/src/EclManager.cpp:174-182` copies enemy X/Y/Z float bits
  through the original `SetVar` destination resolver.
- `reference/th07/src/th07/EclManager.cpp:1064-1089` implements immediate LERP
  with a repeated operand-2 read and installs into the first free or
  same-affected-variable slot among `interps[8]`; the callback index is used
  unchecked against `g_EclInterpFuncs[8]`. `:1959-1964` writes sine/Y before
  cosine/X and repeats the angle/magnitude reads.
- `reference/th08/src/EclRunLow.inl:360-391` dispatches immediate LERP,
  8-slot interpolation installation, two-output polar decomposition, and 2D
  distance. `reference/th08/src/EclDependencies.cpp:353-375` shows the same
  first-free-or-equal selection and unchecked 8-entry callback lookup, while
  `reference/th08/src/EclRunHigh.inl:868-887` repeats polar decomposition.

The model evaluates slot-key equality with IEEE binary32 ordered equality, so
`+0` and `-0` match while NaNs do not. Transcendental, square-root, and fused
arithmetic result bits remain explicit host values, but input resolution and
source write order are executable Lean semantics.

## Bullet Command and Transform Table Evidence

- `reference/th07/src/th07/EclManager.cpp:1330-1339` resolves the command index
  first, indexes `enemy->bulletProps.commands[index]`, and then writes type,
  flag, duration, loop count, speed, and angle. `BulletManager.hpp:65-73` and
  `:110` define the record and its six-entry table.
- `reference/th08/src/EclRunHigh.inl:187-201` likewise indexes
  `bulletProps.transforms[READ_I(0)]` before writing kind, activation policy,
  two integer parameters, and two float parameters. `BulletManager.hpp:115-127`
  and `:180` define the transform record and its 18-entry table.

The shared model makes the fixed table sizes and first-access ordering
executable. An out-of-range index faults before later operands are resolved,
while an in-range entry retains each title's distinct field layout.

- `reference/th08/src/EclRunHigh.inl:832-855` also supplies the remaining
  raw-byte death-animation triple and the world-position radius/mode-4 bullet
  clear calls. These reuse the shared animation and bullet-control semantics;
  mode `4` is retained as an integer host argument rather than collapsed into
  TH07's boolean item-award variants.

## Effect, Particle, and Sound Host-Boundary Evidence

- `reference/th06/src/EclManager.cpp:412-421` resolves four integer and four
  float extended-bullet values. `:552-558` indexes both `g_EffectsColor[28]`
  and `enemy->effectArray[12]` without an opcode-level bound check, while
  `:679` and `:804-807` issue raw sound and particle requests.
- `reference/th07/src/th07/EclManager.cpp:1530-1536` performs the analogous
  unchecked `g_BulletColor[28]` and `enemy->effects[24]` accesses. `:1664` and
  `:1750-1763` resolve sound/particle operands, `:1921-1929` writes the global
  effect color multiplier, and `:1947-1954` writes through `specialEffect`
  without a null guard when custom positioning is disabled.
- `reference/th08/src/EclRunHigh.inl:458-476` tracks an effect through the
  unchecked `attachedEffects[24]` index and plays positioned sound. `:614-634`
  resolves ordinary and moving effect requests, while `:936-951` replaces the
  alignment effect, selects interrupt 1/2 from player alignment, and negates
  angular velocity for odd enemy indices.

The shared model records these as typed host requests and stops on the first
modeled unchecked array/table/null boundary. It does not fabricate effect-pool,
audio-device, or renderer behavior after the original C++ operation leaves the
VM boundary.

## Shooting Control Evidence

- `reference/th06/src/EclManager.cpp:428-454` uses raw interval operands,
  always applies `ShootInterval(rank)`, unconditionally resets the immediate
  timer, randomizes the delayed timer only when the adjusted interval is
  nonzero, toggles `shootingDisabled`, spawns the previous pattern, and resolves
  all three offset components through `GetVarFloat`.
- `reference/th07/src/th07/EclManager.cpp:1345-1376` resolves interval operand
  0 and only rank-adjusts or writes the timer when the base is nonzero. Its
  disable flag suppresses pattern spawning, and its offset has three resolved
  components.
- `reference/th08/src/EclRunHigh.inl:210-258` has the same nonzero interval
  guard but computes the shared rank endpoints through
  `ScaleIntBasedOnRank`. Opcodes 107/108 toggle the defer-pattern flag rather
  than TH06/TH07's suppress-spawn flag, and opcode 110 resolves XY while
  forcing offset Z to zero.
- `reference/th06/src/Enemy.hpp:183-191`,
  `reference/th07/src/th07/EnemyManager.hpp:120-128`, and
  `reference/th08/src/GameManager.cpp:188-191` implement the same integer rank
  interpolation: `rank * (lower - upper) / 32 + upper`, with endpoints derived
  from `interval / 5` and `-interval / 5`.

The model shares that interpolation and the u32 RNG range operation but keeps
the timer guard and gate meaning in title profiles.

## Time Control Evidence

- `reference/th06/src/EclManager.hpp:349-352` declares opcode 0 as `NOP`, while
  `reference/th06/src/EclManager.cpp:126-128` begins the switch body at
  `UNIMP`; the no-op path therefore reaches the ordinary post-switch advance.
- `reference/th06/src/EclManager.cpp:842-845` implements `TIMESET` by adding
  the value returned by `EnemyEclInstr::GetVar` to
  `currentContext.time`; `reference/th06/src/EclManager.cpp:1039-1040` then
  records the current instruction and ticks the context timer in the common
  frame tail.
- `reference/th07/src/th07/EclManager.cpp:927-931` gates dispatch when
  `waitTimer > 0` by decrementing both `waitTimer` and context time before
  leaving the body. `reference/th07/src/th07/EclManager.cpp:2242-2243` performs
  the common tail increment, making the script-time effect a net stall.
- `reference/th07/src/th07/EclManager.cpp:943-944` resolves operand 0 into
  `waitTimer`; `reference/th07/src/th07/EclManager.cpp:1814-1822` resolves the
  same operand shape for `ADD_TIME` and `SET_SCRIPT_WAIT_TIME`.
- `reference/th08/src/EclRun.cpp:58-62` has the same gate shape for
  `secondaryTime`; it decrements secondary time and context time, breaks out of
  the dispatch loop, and reaches the common
  `reference/th08/src/EclRun.cpp:185-186` tail increment.
- `reference/th08/src/EclRunLow.inl:226-231` sets `secondaryTime` for opcode 2
  and keeps opcode 3 as an ordinary advance entry.
  `reference/th08/src/EclRunHigh.inl:706-708` resolves operand 0 and adds it
  into the active ECL context time for opcode 146.

The shared model records opcode-body writes separately from the frame-tail
increment. That keeps later multi-context scheduler work honest: a wait gate is
not an opcode dispatch, but it is still a source-backed VM transition that can
block body execution while preserving net script time.

## Bullet Control Evidence

- `reference/th06/src/EclManager.cpp:891-915` clears all bullets into points,
  toggles the enemy bullet-props sound flag from a raw signed sound id, and
  copies raw speed/count rank-influence fields into enemy state.
- `reference/th07/src/th07/EclManager.cpp:1866-1893` removes all bullets with
  item spawning, resolves the primary sound operand once for the branch and
  again for the enabled write, always resolves the override operand, and writes
  resolved rank-influence fields.
- `reference/th07/src/th07/EclManager.cpp:1934-1946` resolves the radius
  operand for radius removal and separately removes all bullets without item
  spawning.
- `reference/th08/src/EclRunHigh.inl:789-817` clears bullets for transition,
  uses the same repeated primary sound read plus override read pattern against
  `bulletSpawnDescriptor`, and stores rank-influence count operands through
  signed-i16 casts.

The shared model keeps these as host effects rather than executing the whole
`BulletManager`. That is enough to lock opcode ordering, operand resolution,
flag toggles, and signed truncation while leaving bullet allocation,
transforms, item spawning, and runtime bullet simulation as later host
boundaries.

## Laser Spawn Evidence

- `reference/th06/src/EclManager.cpp:455-484` copies raw sprite/color/time/flag
  fields and `GetVarFloat`-resolved angle/speed/range fields into
  `enemy->laserProps`, stores type `0` for the aimed opcode and `1` for the
  fixed opcode, calls `SpawnLaserPattern`, and writes the returned pointer into
  `enemy->lasers[enemy->laserStore]`.
- `reference/th07/src/th07/EclManager.cpp:1378-1410` uses the same descriptor
  shape but resolves color through param-mask bit 1, resolves angle through
  start-length through shifted float bits 2 through 6, keeps width/time fields
  raw, sets type `0` only for the moving/aimed opcode, and writes the returned
  pointer into `enemy->lasers[enemy->laserIdx]`.
- `reference/th08/src/EclRunHigh.inl:260-335` writes
  `laserSpawnDescriptor` from `LaserSpawnArgs`, uses `worldPosition +
  shootOffset`, resolves color/floats/times through operandFlags bits 1 through
  10, sets `BULLET_AIM_FAN_AIMED` only for opcode 115, calls
  `SpawnLaserPattern`, and writes the result into
  `laserSlots[selectedLaserSlot]`.
- `reference/th06/src/BulletManager.cpp:560-613`,
  `reference/th07/src/th07/BulletManager.cpp:665-716`, and
  `reference/th08/src/BulletManager.cpp:720-758` consume the descriptor and
  allocate or return a laser pointer. The ECL model currently records that as a
  spawn request rather than simulating the whole manager pool.

The slot write is intentionally modeled after the spawn request. This captures
the source ordering: an invalid selected slot is not a precondition failure
before descriptor construction; it is an unchecked host write boundary reached
after the call to `SpawnLaserPattern`.

## Primary Bullet-Pattern Evidence

- `reference/th06/src/EclManager.cpp:357-410` sends opcodes 67–75 through one
  descriptor body and sets `aimMode = opcode - 67`. Bullet type stays raw;
  counts, color, and float fields use `GetVar`/`GetVarFloat`; count rank/clamps,
  angle normalization, and speed rank/clamps always execute. The shooting flag
  suppresses only the final manager call.
- `reference/th07/src/th07/EclManager.cpp:1265-1329` uses the same nine-mode
  layout at opcodes 64–72, but exits when life is nonpositive. Its packed
  sprite/color occupy mask bits 0/1, counts bits 2/3, speeds bits 4/5, and
  angles bits 6/7. Active spellcards bypass all rank additions and clamps;
  `disableBullets` is checked after descriptor writes.
- `reference/th08/src/EclRunHigh.inl:165-184` exits for dead enemies and, when
  the defer bit is set, copies `sizeof(pendingShotInstruction) = 0x2c` bytes
  from the raw instruction before calling the common dispatcher.
- `reference/th08/src/EclDependencies.cpp:687-780` checks transform alignment
  and squared player distance before resolving operands. It then uses the same
  shifted operand-flag layout and spellcard rank bypass as TH07 before calling
  `SpawnBulletPattern`.
- The descriptor count fields are signed i16 in
  `reference/th06/src/Enemy.hpp`,
  `reference/th07/src/th07/BulletManager.hpp`, and
  `reference/th08/src/BulletManager.hpp`; compound rank writes therefore
  truncate before the source tests `count <= 0`.

The Lean family model retains these ordering boundaries and represents the
fixed TH08 copy span explicitly, including whether its source bytes lie within
the supplied ECL buffer.

## Callback Configuration Evidence

- `reference/th06/src/EclManager.cpp:685-686`, `:788-800`, and `:919-922`
  write raw death/life/timer callback fields; timer-threshold and
  death-bound-timer opcodes reset `bossTimer` through `SetCurrent(0)`.
- `reference/th07/src/th07/EclManager.cpp:1670-1672` zero-extends a raw byte
  into `deathCallbackSub`. Lines `1722-1746` resolve legacy slot-0 life fields,
  an unchecked indexed four-slot life pair, timer fields, and a periodic pair
  that resets its counter and snapshots current ECL arguments. Lines
  `1895-1898` bind timer callback to death and reset the timer.
- `reference/th07/src/th07/EclManager.cpp:245-248` shows that an integer
  resolver input may consume RNG state. Because the indexed life-pair body
  spells out `GET_INT_VALUE(enemy, 0)` for both array writes, those indices are
  distinct reads rather than one guaranteed stable value.
- `reference/th08/src/EclRunHigh.inl:483-488`, `:551-579`, and `:820-825`
  encode raw-u16 death configuration, unchecked indexed life configuration,
  combined timer configuration, and death binding. The presentation guard can
  suppress death or callback-sub writes while threshold writes and timer reset
  still occur.

The Lean outcome carries partial callback writes together with the first
invalid host-array access, which is necessary for repeated resolver reads.

## Interrupt Evidence

- `reference/th06/src/EclManager.cpp:688-705` writes an unchecked eight-entry
  table, advances `currentInstr`, conditionally saves context, reads the table,
  calls the selected subroutine, and increments depth independently of the
  save-disable flag. Lines `905-907` set that one-bit flag from raw i32.
- `reference/th07/src/th07/EclManager.cpp:1673-1691` repeats the same ordering
  with a 32-entry table and resolved operands. `noStackRet` suppresses the save
  but not the depth increment; lines `1881-1883` set it from the raw low byte.
- `reference/th08/src/EclRunHigh.inl:488-520` stores resolved table entries and
  the pending index as signed i16, advances context, conditionally copies the
  stack frame, calls `CallEclSub`, and increments depth. Lines `805-809` set the
  one-bit disable flag from a raw byte.

The shared interrupt effect records writes completed before an unchecked table
or subTable fault and deliberately does not reuse ordinary CALL's differently
guarded depth transition.

## EX Instruction Dispatch Evidence

- `reference/th06/src/EclManager.cpp:26-42` defines `g_EclExInsn[17]`;
  `:829-840` indexes it directly for opcode 121 and installs or clears its
  per-frame callback for opcode 122 using the raw integer field.
- `reference/th07/src/th07/EnemyEclInstr.cpp:15-40` defines
  `g_EclExInstr[24]`; `EclManager.cpp:1799-1812` resolves slot 0 once for the
  sign guard and again for the table access before storing the instruction
  pointer.
- `reference/th08/src/EclGlobals.cpp:65-98` defines `g_EclExInsn[32]`;
  `EclRunHigh.inl:688-704` has the same immediate/install split and repeated
  resolver read as TH07.

The executable model treats each unchecked callback-table lookup as the first
host boundary and records immediate calls or installation writes only after a
valid lookup. Negative install indices clear the callback without reading the
table; the stage-specific callback bodies remain explicit host behavior.

## TH08 Child ECL Block Evidence

- `reference/th08/src/EclRunHigh.inl:580-612` resolves a child slot, reads and
  clears `childEclBlocks[slot]` without a bounds check, conditionally allocates
  and zeroes an `EnemyChildEclBlock`, resolves the sub id again, calls
  `CallEclSub`, and only then copies the active variable region.
- `reference/th08/src/EnemyManager.hpp:288-290` fixes the pointer table at four
  entries. `EclManager.hpp:252-268` gives the block size `0x24b0`, embedded
  context, and 16-frame call stack.
- `reference/th08/src/EclManager.hpp:225-231` places `intVariables` at offset
  `0x18` and `secondaryTime` at `0x90`, making the source `memcpy` span exactly
  `0x78` bytes. `EclManager.cpp:69-81` shows the i16 sub-id boundary and the
  negative-id no-op.

The model preserves allocator failure and all writes before a subTable fault.
The main/child context selection loop in `EclRun.cpp:179-205` is evidence for a
later scheduler transition rather than hidden inside this opcode body.

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
