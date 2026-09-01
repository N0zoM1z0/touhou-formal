import TouhouFormal.Core.Evidence
import TouhouFormal.ECL.Profile

namespace TouhouFormal.TH07

def title : String := "TH07"

def rawHeaderFixedPrefixBytes : Nat := 0x44
def timelinePointerCount : Nat := 16
def timelineInstrFixedSize : Nat := 0x20
def eclOpcodeJump : Int := 2
def eclOpcodeDecJump : Int := 3
def eclOpcodeJumpIfEq : Int := 28
def eclOpcodeJumpIfEqFloat : Int := 29
def eclOpcodeJumpIfNeq : Int := 30
def eclOpcodeJumpIfNeqFloat : Int := 31
def eclOpcodeJumpIfLt : Int := 32
def eclOpcodeJumpIfLtFloat : Int := 33
def eclOpcodeJumpIfLeq : Int := 34
def eclOpcodeJumpIfLeqFloat : Int := 35
def eclOpcodeJumpIfGt : Int := 36
def eclOpcodeJumpIfGtFloat : Int := 37
def eclOpcodeJumpIfGeq : Int := 38
def eclOpcodeJumpIfGeqFloat : Int := 39
def eclOpcodeSetInt : Int := 4
def eclOpcodeSetFloat : Int := 5
def eclOpcodeRand : Int := 6
def eclOpcodeRandAdd : Int := 7
def eclOpcodeRandFloat : Int := 8
def eclOpcodeRandFloatAdd : Int := 9
def eclOpcodeRandSign : Int := 10
def eclOpcodeRandSignFloat : Int := 11
def eclOpcodeIntAdd : Int := 12
def eclOpcodeIntSub : Int := 13
def eclOpcodeIntMul : Int := 14
def eclOpcodeIntDiv : Int := 15
def eclOpcodeIntMod : Int := 16
def eclOpcodeInc : Int := 17
def eclOpcodeDec : Int := 18
def eclOpcodeFloatAdd : Int := 19
def eclOpcodeFloatSub : Int := 20
def eclOpcodeFloatMul : Int := 21
def eclOpcodeFloatDiv : Int := 22
def eclOpcodeFloatMod : Int := 23
def eclOpcodeSin : Int := 24
def eclOpcodeCos : Int := 25
def eclOpcodeAtan2 : Int := 26
def eclOpcodeNormalizeAngle : Int := 40
def eclOpcodeGetBossInt : Int := 43
def eclOpcodeGetBossFloat : Int := 44
def eclOpcodeSubCall : Int := 41
def eclOpcodeSubRet : Int := 42
def eclOpcodeSetPosition : Int := 46
def eclOpcodeSetAxisSpeed : Int := 47
def eclOpcodeSetAngularVelocity : Int := 48
def eclOpcodeSetMoveSpeed : Int := 49
def eclOpcodeSetMoveAcceleration : Int := 50
def eclOpcodeRandomFloatBetween : Int := 51
def eclOpcodeGetExitAngle : Int := 52
def eclOpcodeMoveAtPlayer : Int := 53
def eclOpcodeMoveDirectionTimed : Int := 54
def eclOpcodeMovePositionTimed : Int := 55
def eclOpcodeMoveOrbit : Int := 56
def eclOpcodeSetOrbitRadius : Int := 57
def eclOpcodeSetOrbitAngle : Int := 58
def eclOpcodeSetMoveTimerPolar : Int := 59
def eclOpcodeSetMoveTimerOrbit : Int := 60
def eclOpcodeSetMoveTimerInterpolation : Int := 61
def eclOpcodeSetMovementBounds : Int := 62
def eclOpcodeDisableMovementBounds : Int := 63
def eclOpcodeSpawnBulletPatternFirst : Int := 64
def eclOpcodeSpawnBulletPatternLast : Int := 72
def eclOpcodeSetShootInterval : Int := 73
def eclOpcodeSetRandomShootInterval : Int := 74
def eclOpcodeDisableShooting : Int := 75
def eclOpcodeEnableShooting : Int := 76
def eclOpcodeSpawnPreviousPattern : Int := 77
def eclOpcodeSetShootOffset : Int := 78
def eclOpcodeSetAnm : Int := 95
def eclOpcodeSetMoveAnm : Int := 96
def eclOpcodeSetSubAnm : Int := 97
def eclOpcodeSetDeathAnm : Int := 98
def eclOpcodeSetHitboxSize : Int := 101
def eclOpcodeSetGrazeSize : Int := 153
def eclOpcodeSetContactHitbox : Int := 102
def eclOpcodeSetCanBeDamaged : Int := 103
def eclOpcodeSetHittable : Int := 104
def eclOpcodeSetDeathType : Int := 106
def eclOpcodeSetDeathCallbackSub : Int := 107
def eclOpcodeSetInterrupt : Int := 108
def eclOpcodeRunInterrupt : Int := 109
def eclOpcodeSetLife : Int := 110
def eclOpcodeSetTimer : Int := 111
def eclOpcodeSetLifeCallbackThreshold : Int := 112
def eclOpcodeSetLifeCallbackSub : Int := 113
def eclOpcodeSetTimerCallbackThreshold : Int := 114
def eclOpcodeSetTimerCallbackSub : Int := 115
def eclOpcodeSetCanDie : Int := 116
def eclOpcodeSetCallStackDisabled : Int := 130
def eclOpcodeBindTimerCallbackToDeath : Int := 133
def eclOpcodeSetPeriodicCallback : Int := 144
def eclOpcodeSetLifeCallback : Int := 148
def eclOpcodeRandomExitAngle : Int := 155
def eclOpcodeSetVmAutoRotate : Int := 120
def eclOpcodeSetPrimaryVmInterrupt : Int := 128
def eclOpcodeSetVmInterrupt : Int := 129
def eclOpcodeSetPrimaryVmRotZ : Int := 150
def enemyAnmScriptBase : Int := 0x900
def secondaryAnmVmCount : Nat := 2

def eclEvidence : List TouhouFormal.SourceRef :=
  [ { path := "reference/th07/src/th07/EclManager.hpp"
      startLine := 277
      endLine := 285
      claim := "EclRawHeader stores subCount, timelineCount, sixteen timeline pointers, and subTable[]." },
    { path := "reference/th07/src/th07/EclManager.hpp"
      startLine := 291
      endLine := 305
      claim := "EclRawInstr stores time, id, size, difficulty skip byte, paramMask, and variable args." },
    { path := "reference/th07/src/th07/EclManager.hpp"
      startLine := 317
      endLine := 324
      claim := "EclTimelineInstr stores i16 time, arg0, opcode, size, and six AnyArg payload slots." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 23
      endLine := 33
      claim := "GET_INT_VALUE checks paramMask bit idx; a clear bit uses the raw operand and a set bit resolves the var id." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 70
      endLine := 101
      claim := "Load rebases sixteen timeline pointers and subTable entries for i < subCount." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 106
      endLine := 114
      claim := "CallEclSub reads this->subTable[subId] without checking subId." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 116
      endLine := 264
      claim := "GetVarValue resolves known ECL var ids and returns the raw operand value in the default case." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 268
      endLine := 323
      claim := "GetVar returns the raw operand cell when its paramMask bit is clear, maps a smaller writable selector subset when set, and defaults to the raw operand cell." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 1011
      endLine := 1045
      claim := "Integer ADD/SUB/MUL/DIV/MOD write through GET_INT_PTR slot 0 and read operand slots 1 and 2 through GET_INT_VALUE." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 1015
      endLine := 1049
      claim := "Float ADD/SUB/MUL/DIV/MOD write through GET_FLOAT_PTR slot 0 and read operand slots 1 and 2 through GET_FLOAT_VALUE; MOD_FLOAT uses fmodf." },
    { path := "reference/th07/src/th07/EclManager.hpp"
      startLine := 114
      endLine := 123
      claim := "TH07 assigns float arithmetic opcodes ECL_ADD_FLOAT=19 through ECL_MOD_FLOAT=23 alongside integer ADD=12 through MOD=16." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 1051
      endLine := 1062
      claim := "SIN and COS apply sinf/cosf to float slot 1; ATAN2 writes atan2f(slot4 - slot2, slot3 - slot1) to float slot 0." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 963
      endLine := 966
      claim := "NORMALIZE_ANGLE resolves float slot 0 as both input and output and applies AddNormalizeAngle(value, 0)." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 1001
      endLine := 1005
      claim := "ECL_GET_BOSS_INT writes slot 0 from GET_INT_VALUE(g_EnemyManager.bosses[GET_INT_VALUE(enemy, 2)], 1), so slot 1's mask bit decides whether a boss pointer is dereferenced." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 327
      endLine := 482
      claim := "GetFloatVarValue casts the f32 operand to i32, resolves known float selector ids, and returns the raw float operand in the default case." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 486
      endLine := 571
      claim := "GetFloatVar returns the raw f32 operand cell when the mask bit is clear, maps a writable float selector subset when set, and otherwise defaults to the raw f32 operand cell." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 1006
      endLine := 1010
      claim := "ECL_GET_BOSS_FLOAT writes slot 0 from GET_FLOAT_VALUE(g_EnemyManager.bosses[GET_INT_VALUE(enemy, 2)], 1), so it shares boss index semantics with ECL_GET_BOSS_INT but uses float operand resolution." },
    { path := "reference/th07/src/th07/EnemyManager.hpp"
      startLine := 378
      endLine := 378
      claim := "EnemyManager stores eight boss pointers in bosses[8]." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 946
      endLine := 954
      claim := "DEC_JUMP decrements operand slot 2 and falls through to JUMP only while the decremented value is positive." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 956
      endLine := 961
      claim := "SET_INT writes GET_INT_PTR slot 0 from GET_INT_VALUE slot 1, while SET_FLOAT writes GET_FLOAT_PTR slot 0 from GET_FLOAT_VALUE slot 1." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 967
      endLine := 993
      claim := "RAND/RAND_ADD and RAND_FLOAT/RAND_FLOAT_ADD use resolved range/addend operands, while RAND_SIGN/RAND_SIGN_FLOAT multiply slot 1 by a sign selected from GetRandomU16 parity." },
    { path := "reference/th07/src/th07/Rng.hpp"
      startLine := 16
      endLine := 23
      claim := "GetRandomU32InRange uses unsigned modulo with a zero-range result of zero; GetRandomFloatInRange multiplies a float RNG sample by the range." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 995
      endLine := 999
      claim := "INC and DEC update GET_INT_PTR slot 0 in place by +1 or -1." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 1035
      endLine := 1037
      claim := "DIV performs integer division by operand slot 2 without a zero-divisor guard." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 1043
      endLine := 1045
      claim := "MOD performs integer modulo by operand slot 2 without a zero-divisor guard." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 1092
      endLine := 1166
      claim := "Integer JUMP_IF_* opcodes compare resolved operand slots 0 and 1, then taken branches set time from slot 2 and jump by slot 3." } ]
    ++
    [ { path := "reference/th07/src/th07/EclManager.cpp"
        startLine := 1098
        endLine := 1165
        claim := "The six interleaved JUMP_IF_*_FLOAT opcodes compare resolved float slots 0 and 1 and reuse the same raw target-time/displacement jump body." },
      { path := "reference/th07/src/th07/EclManager.cpp"
        startLine := 1218
        endLine := 1249
        claim := "Immediate movement opcodes resolve position, axis velocity, angular velocity, speed, acceleration, and player-relative operands and update the corresponding movement mode." },
      { path := "reference/th07/src/th07/EclManager.cpp"
        startLine := 1538
        endLine := 1571
        claim := "Timed direction/position and orbit opcodes resolve their source operands in handler order, assign movement timers, and select polar, orbit, or interpolation modes." },
      { path := "reference/th07/src/th07/EclManager.cpp"
        startLine := 1573
        endLine := 1584
        claim := "Movement-bound opcodes resolve four float operands and toggle hasMovementBounds." },
      { path := "reference/th07/src/th07/EclManager.cpp"
        startLine := 1587
        endLine := 1637
        claim := "RAND_FLOAT_RANGE resolves upper and lower bounds, including a second lower-bound occurrence, while GET_EXIT_ANGLE selects a player-side random angle and its right-positive reflection subtracts the enemy's old angle." },
      { path := "reference/th07/src/th07/EclManager.cpp"
        startLine := 1965
        endLine := 1979
        claim := "RAND_EXIT_ANGLE selects a left or right random exit cone from player/enemy X and the fixed 96/288 inner-arena thresholds, then writes float operand 0." },
      { path := "reference/th07/src/th07/EclManager.cpp"
        startLine := 1645
        endLine := 1668
        claim := "Hitbox and graze-size opcodes resolve three float operands; contact, damage, hittable, and death-type opcodes assign the raw low byte into one-bit or three-bit fields." },
      { path := "reference/th07/src/th07/EclManager.cpp"
        startLine := 1747
        endLine := 1749
        claim := "ECL_SET_ENEMY_CAN_DIE assigns the raw low byte into the one-bit canDie field." },
      { path := "reference/th07/src/th07/EclManager.cpp"
        startLine := 1693
        endLine := 1704
        claim := "ECL_SET_LIFE resolves operand 0 into life and maxLife and clears all boss-health gauge slots for the primary boss." },
      { path := "reference/th07/src/th07/EclManager.cpp"
        startLine := 1719
        endLine := 1721
        claim := "ECL_SET_TIMER resolves operand 0 and assigns it through ZunTimer's integer assignment operator." },
      { path := "reference/th07/src/th07/EclManager.cpp"
        startLine := 1345
        endLine := 1376
        claim := "Shoot-control opcodes 73 through 78 resolve nonzero intervals before rank scaling, initialize the interval timer immediately or randomly, toggle a suppress-spawn bit, spawn the previous pattern, and resolve three offset floats." },
      { path := "reference/th07/src/th07/EclManager.cpp"
        startLine := 1265
        endLine := 1329
        claim := "Bullet-pattern opcodes 64 through 72 skip dead enemies, derive aim mode from the opcode, resolve packed sprite/color plus count/float operands with their shifted mask bits, omit rank and clamps during spellcards, and let disableBullets suppress only the spawn call." },
      { path := "reference/th07/src/th07/EclManager.cpp"
        startLine := 1197
        endLine := 1216
        claim := "ECL_SET_ANM resolves operand 0, adds ANM_SCRIPT_ENEMY_ARRAY, and runs the primary VM; ECL_SET_SUB_ANM diagnoses only high indexes and still accesses enemy->vms[index]." },
      { path := "reference/th07/src/th07/EclManager.cpp"
        startLine := 1340
        endLine := 1344
        claim := "ECL_SET_DEATH_ANM copies three raw bytes from args[0].c into the death-animation fields." },
      { path := "reference/th07/src/th07/EclManager.cpp"
        startLine := 1637
        endLine := 1644
        claim := "ECL_SET_MOVE_ANM copies five packed i16 movement-animation scripts and sets anmExFlags to 255." },
      { path := "reference/th07/src/th07/EclManager.cpp"
        startLine := 1797
        endLine := 1798
        claim := "ECL_SET_VM_AUTO_ROTATE assigns raw args[0].b[0] into a one-bit primaryVmAutoRotate field." },
      { path := "reference/th07/src/th07/EclManager.cpp"
        startLine := 1861
        endLine := 1865
        claim := "ECL_SET_PRIMARY_VM_INTERRUPT writes a resolved integer into primaryVm.pendingInterrupt; ECL_SET_VM_INTERRUPT indexes the secondary VM array without a bounds check." },
      { path := "reference/th07/src/th07/EclManager.cpp"
        startLine := 1957
        endLine := 1958
        claim := "ECL_SET_PRIMARY_VM_ROT_Z resolves one float operand and writes primaryVm.rotation.z." },
      { path := "reference/th07/src/th07/EclManager.cpp"
        startLine := 1670
        endLine := 1672
        claim := "Opcode 107 zero-extends one raw byte into deathCallbackSub." },
      { path := "reference/th07/src/th07/EclManager.cpp"
        startLine := 1722
        endLine := 1746
        claim := "Callback opcodes resolve life/timer fields, support unchecked four-slot indexed life pairs and periodic callbacks, reset timers, and snapshot periodic ECL arguments." },
      { path := "reference/th07/src/th07/EclManager.cpp"
        startLine := 1895
        endLine := 1898
        claim := "Opcode 133 binds timerCallbackSub to deathCallbackSub and resets the enemy timer." },
      { path := "reference/th07/src/th07/EclManager.cpp"
        startLine := 1673
        endLine := 1691
        claim := "Opcodes 108/109 resolve an unchecked 32-entry interrupt table and enter the selected subroutine after advancing context; noStackRet suppresses the save but not the depth increment." },
      { path := "reference/th07/src/th07/EclManager.cpp"
        startLine := 1881
        endLine := 1883
        claim := "Opcode 130 assigns the raw low byte into the one-bit noStackRet field." },
      { path := "reference/th07/src/th07/EclManager.cpp"
        startLine := 1168
        endLine := 1195
        claim := "SUB_CALL saves the next instruction context at savedContextStack[stackDepth] before CallEclSub and increments depth only while stackDepth < ENEMY_STACK_SIZE; SUB_RET decrements stackDepth before restoring savedContextStack[stackDepth]." },
      { path := "reference/th07/src/th07/EnemyManager.hpp"
        startLine := 62
        endLine := 134
        claim := "ENEMY_STACK_SIZE is 15, and Enemy stores savedContextStack[ENEMY_STACK_SIZE + 1] plus signed stackDepth." } ]

def headerShape : TouhouFormal.ECL.HeaderShape :=
  { title := title
    hasVersionField := false
    versionOffset := none
    expectedVersion := none
    subCountOffset := 0
    timelineCountOffset := 2
    timelineTableOffset := 4
    fixedHeaderBytes := rawHeaderFixedPrefixBytes
    timelineSlots := timelinePointerCount
    loaderTimelineSlots := timelinePointerCount
    subTableField := "subTable[]"
    negativeSubIdPolicy := .unchecked
    timelineShape :=
      some
        { fixedSize := timelineInstrFixedSize
          timeOffset := 0
          timeWidth := .i16
          opcodeOffset := 4
          opcodeWidth := .i16
          sizeOffset := 6
          sizeWidth := .i16
          firstArgOffset := some 2
          firstArgWidth := some .i16 }
    rawInstrShape :=
      some
        { fixedPrefixBytes := 12
          timeOffset := 0
          timeWidth := .u32
          opcodeOffset := 4
          opcodeWidth := .i16
          unimplementedOpcode := some 1
          nextOffsetOffset := 6
          nextOffsetWidth := .i16
          difficultyMaskOffset := some 9
          difficultyMaskWidth := some .u8
          difficultyMaskPolicy := some .intersectsActive
          operandMaskOffset := some 10
          operandMaskWidth := some .u16
          fixedI32OperandBaseOffset := some 12
          fixedI32OperandStride := 4
          fixedJumpShape :=
            some
              { opcode := eclOpcodeJump
                targetTimeOperandIndex := 0
                displacementOperandIndex := 1 }
          fixedDecJumpShape :=
            some
              { opcode := eclOpcodeDecJump
                targetTimeOperandIndex := 0
                displacementOperandIndex := 1
                counterOperandIndex := 2 }
          intRValueResolver :=
            some
              { maskPolicy := .bitSetMeansResolve
                knownRValueSelectors :=
                  { ranges := [ { first := 10000, last := 10073 } ]
                    exclusions := [10057, 10058, 10059, 10060] }
                knownLValueSelectors :=
                  { ranges :=
                      [ { first := 10000, last := 10003 },
                        { first := 10012, last := 10017 },
                        { first := 10025, last := 10025 },
                        { first := 10027, last := 10027 },
                        { first := 10029, last := 10032 },
                        { first := 10037, last := 10040 },
                        { first := 10070, last := 10071 } ]
                    exclusions := [] } }
          floatRValueResolver :=
            some
              { maskPolicy := .bitSetMeansResolve
                knownRValueSelectors :=
                  { ranges := [ { first := 1176256512, last := 1176332287 } ]
                    exclusions := [] }
                knownLValueSelectors :=
                  { ranges :=
                      [ { first := 1176260608, last := 1176268799 },
                        { first := 1176274944, last := 1176281087 },
                        { first := 1176290304, last := 1176294399 },
                        { first := 1176298496, last := 1176312831 },
                        { first := 1176314880, last := 1176317951 },
                        { first := 1176330240, last := 1176332287 } ]
                    exclusions := [] } }
          intConditionJumps :=
            [ { opcode := eclOpcodeJumpIfEq
                op := .eq
                source := .resolvedOperands
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 2
                displacementOperandIndex := 3 },
              { opcode := eclOpcodeJumpIfNeq
                op := .neq
                source := .resolvedOperands
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 2
                displacementOperandIndex := 3 },
              { opcode := eclOpcodeJumpIfLt
                op := .lt
                source := .resolvedOperands
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 2
                displacementOperandIndex := 3 },
              { opcode := eclOpcodeJumpIfLeq
                op := .le
                source := .resolvedOperands
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 2
                displacementOperandIndex := 3 },
              { opcode := eclOpcodeJumpIfGt
                op := .gt
                source := .resolvedOperands
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 2
                displacementOperandIndex := 3 },
              { opcode := eclOpcodeJumpIfGeq
                op := .ge
                source := .resolvedOperands
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 2
                displacementOperandIndex := 3 } ]
          floatConditionJumps :=
            [ { opcode := eclOpcodeJumpIfEqFloat
                op := .eq
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 2
                displacementOperandIndex := 3 },
              { opcode := eclOpcodeJumpIfNeqFloat
                op := .neq
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 2
                displacementOperandIndex := 3 },
              { opcode := eclOpcodeJumpIfLtFloat
                op := .lt
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 2
                displacementOperandIndex := 3 },
              { opcode := eclOpcodeJumpIfLeqFloat
                op := .le
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 2
                displacementOperandIndex := 3 },
              { opcode := eclOpcodeJumpIfGtFloat
                op := .gt
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 2
                displacementOperandIndex := 3 },
              { opcode := eclOpcodeJumpIfGeqFloat
                op := .ge
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 2
                displacementOperandIndex := 3 } ]
          callRetShape :=
            some
              { callOpcode := eclOpcodeSubCall
                retOpcode := eclOpcodeSubRet
                subIdOperandIndex := 0
                stackEntryCount := 16
                stackIncrementGuardExclusive := 15
                retUnderflowPolicy := .uncheckedSavedContextRead
                childContextSlotCount := 0 }
          scalarAssignments :=
            [ { opcode := eclOpcodeSetInt
                outputPolicy := .intLValue
                rvaluePolicy := .intBits
                outputOperandIndex := 0
                valueOperandIndex := 1 },
              { opcode := eclOpcodeSetFloat
                outputPolicy := .floatLValue
                rvaluePolicy := .floatBits
                outputOperandIndex := 0
                valueOperandIndex := 1 } ]
          randomOps :=
            [ { opcode := eclOpcodeRand
                kind := .intRange
                outputPolicy := .intLValue
                writePolicy := .direct
                outputOperandIndex := 0
                valueOperandIndex := 1 },
              { opcode := eclOpcodeRandAdd
                kind := .intRangeAdd
                outputPolicy := .intLValue
                writePolicy := .direct
                outputOperandIndex := 0
                valueOperandIndex := 1
                addendOperandIndex := some 2 },
              { opcode := eclOpcodeRandFloat
                kind := .floatRange
                outputPolicy := .floatLValue
                writePolicy := .direct
                outputOperandIndex := 0
                valueOperandIndex := 1 },
              { opcode := eclOpcodeRandFloatAdd
                kind := .floatRangeAdd
                outputPolicy := .floatLValue
                writePolicy := .direct
                outputOperandIndex := 0
                valueOperandIndex := 1
                addendOperandIndex := some 2 },
              { opcode := eclOpcodeRandSign
                kind := .intSign
                outputPolicy := .intLValue
                writePolicy := .direct
                outputOperandIndex := 0
                valueOperandIndex := 1 },
              { opcode := eclOpcodeRandSignFloat
                kind := .floatSign
                outputPolicy := .floatLValue
                writePolicy := .direct
                outputOperandIndex := 0
                valueOperandIndex := 1 },
              { opcode := eclOpcodeRandomFloatBetween
                kind := .floatBetween
                outputPolicy := .floatLValue
                writePolicy := .direct
                outputOperandIndex := 0
                valueOperandIndex := 2
                addendOperandIndex := some 1 } ]
          movementOps :=
            [ { opcode := eclOpcodeSetPosition
                kind := .setPosition
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue },
                    { operandIndex := 1, policy := .floatRValue },
                    { operandIndex := 2, policy := .floatRValue } ]
                clampPosition := true },
              { opcode := eclOpcodeSetAxisSpeed
                kind := .setAxisVelocity
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue },
                    { operandIndex := 1, policy := .floatRValue },
                    { operandIndex := 2, policy := .floatRValue } ]
                anglePolicy := .derivedAtan2
                modeUpdate := some .axis },
              { opcode := eclOpcodeSetAngularVelocity
                kind := .setAngularVelocity
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue } ]
                modeUpdate := some .polar },
              { opcode := eclOpcodeSetMoveSpeed
                kind := .setSpeed
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue } ]
                modeUpdate := some .polar },
              { opcode := eclOpcodeSetMoveAcceleration
                kind := .setAcceleration
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue } ]
                modeUpdate := some .polar },
              { opcode := eclOpcodeMoveAtPlayer
                kind := .moveAtPlayer
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue },
                    { operandIndex := 1, policy := .floatRValue } ]
                anglePolicy := .derivedPlayerRelative
                modeUpdate := some .polar },
              { opcode := eclOpcodeSetMovementBounds
                kind := .setBounds
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue },
                    { operandIndex := 1, policy := .floatRValue },
                    { operandIndex := 2, policy := .floatRValue },
                    { operandIndex := 3, policy := .floatRValue } ] },
              { opcode := eclOpcodeDisableMovementBounds
                kind := .disableBounds } ]
          randomDirectionOps :=
            [ { opcode := eclOpcodeGetExitAngle
                generator := .playerSide
                boundaryPolicy := .rectangle .currentEnemyAngle
                outputPolicy := .floatLValue 0 },
              { opcode := eclOpcodeRandomExitAngle
                generator := .arenaExit
                outputPolicy := .floatLValue 0 } ]
          timedMovementFamilies :=
            [ { firstOpcode := eclOpcodeMoveDirectionTimed
                lastOpcode := eclOpcodeMoveDirectionTimed
                kind := .direction
                floatInputs :=
                  [ { role := .angle, operandIndex := 2, policy := .rValue },
                    { role := .speed, operandIndex := 3, policy := .rValue } ]
                durationPolicy := .intRValue
                easingPolicy := .intRValue 1
                nonpositivePolicy := .immediatePolarResolvedTimers
                normalizeDirectionAngle := true
                mirrorDeltaX := true },
              { firstOpcode := eclOpcodeMovePositionTimed
                lastOpcode := eclOpcodeMovePositionTimed
                kind := .position
                floatInputs :=
                  [ { role := .targetX, operandIndex := 2, policy := .rValue },
                    { role := .targetY, operandIndex := 3, policy := .rValue },
                    { role := .targetZ, operandIndex := 4, policy := .rValue } ]
                durationPolicy := .intRValue
                easingPolicy := .intRValue 1
                mirrorDeltaX := true
                zeroVelocity := true } ]
          orbitMovementOps :=
            [ { opcode := eclOpcodeMoveOrbit
                kind := .startFull
                floatInputs :=
                  [ { role := .originX, operandIndex := 1 },
                    { role := .originY, operandIndex := 2 },
                    { role := .originZ, operandIndex := 3 },
                    { role := .angle, operandIndex := 4 },
                    { role := .angularVelocity, operandIndex := 5 },
                    { role := .radius, operandIndex := 6 },
                    { role := .radialVelocity, operandIndex := 7 } ]
                durationOperandIndex := some 0 },
              { opcode := eclOpcodeSetOrbitRadius
                kind := .setRadius
                floatInputs :=
                  [ { role := .radius, operandIndex := 0 },
                    { role := .radialVelocity, operandIndex := 1 } ] },
              { opcode := eclOpcodeSetOrbitAngle
                kind := .setAngle
                floatInputs :=
                  [ { role := .angle, operandIndex := 0 },
                    { role := .angularVelocity, operandIndex := 1 } ] },
              { opcode := eclOpcodeSetMoveTimerPolar
                kind := .setModeTimer .polar
                durationOperandIndex := some 0 },
              { opcode := eclOpcodeSetMoveTimerOrbit
                kind := .setModeTimer .orbit
                durationOperandIndex := some 0 },
              { opcode := eclOpcodeSetMoveTimerInterpolation
                kind := .setModeTimer .interpolation
                durationOperandIndex := some 0 } ]
          enemyStateOps :=
            [ { opcode := eclOpcodeSetHitboxSize
                kind := .setPrimaryHitbox 3
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue },
                    { operandIndex := 1, policy := .floatRValue },
                    { operandIndex := 2, policy := .floatRValue } ] },
              { opcode := eclOpcodeSetGrazeSize
                kind := .setSecondaryHitbox 3
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue },
                    { operandIndex := 1, policy := .floatRValue },
                    { operandIndex := 2, policy := .floatRValue } ] },
              { opcode := eclOpcodeSetContactHitbox
                kind := .setField .contactHitbox
                intInputPolicy := some .rawByte },
              { opcode := eclOpcodeSetCanBeDamaged
                kind := .setField .canBeDamaged
                intInputPolicy := some .rawByte },
              { opcode := eclOpcodeSetHittable
                kind := .setField .hittable
                intInputPolicy := some .rawByte },
              { opcode := eclOpcodeSetDeathType
                kind := .setField .deathMode
                intInputPolicy := some .rawByte },
              { opcode := eclOpcodeSetCanDie
                kind := .setField .canDie
                intInputPolicy := some .rawByte },
              { opcode := eclOpcodeSetLife
                kind := .setLife
                intInputPolicy := some .intRValue
                clearBossGaugeForPrimaryBoss := true },
              { opcode := eclOpcodeSetTimer
                kind := .setTimer
                intInputPolicy := some .intRValue } ]
          shootingOps :=
            [ { opcode := eclOpcodeSetShootInterval
                kind := .setInterval
                intInputPolicy := some .intRValue },
              { opcode := eclOpcodeSetRandomShootInterval
                kind := .setRandomizedInterval
                intInputPolicy := some .intRValue },
              { opcode := eclOpcodeDisableShooting
                kind := .disableShooting },
              { opcode := eclOpcodeEnableShooting
                kind := .enableShooting },
              { opcode := eclOpcodeSpawnPreviousPattern
                kind := .spawnPreviousPattern },
              { opcode := eclOpcodeSetShootOffset
                kind := .setShootOffset
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue },
                    { operandIndex := 1, policy := .floatRValue },
                    { operandIndex := 2, policy := .floatRValue } ] } ]
          animationOps :=
            [ { opcode := eclOpcodeSetAnm
                kind := .setPrimaryScript
                scriptSource := some (.intRValue 0)
                scriptBase := enemyAnmScriptBase
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue } ] },
              { opcode := eclOpcodeSetSubAnm
                kind := .setSecondaryScript
                bankPolicy := .fixed .primary
                secondaryAccess :=
                  some
                    { slotCount := secondaryAnmVmCount
                      slotInput := { operandIndex := 0, policy := .intRValue }
                      scriptInput := { operandIndex := 1, policy := .intRValue }
                      scriptMode := .runWhenNonnegativeElseClear
                      repeatedSlotReadForAccess := true
                      repeatedScriptReadForHostCall := true
                      scriptBase := enemyAnmScriptBase } },
              { opcode := eclOpcodeSetMoveAnm
                kind := .setMovementScripts
                intInputs :=
                  [ { operandIndex := 0, policy := .rawI16, halfIndex := 0 },
                    { operandIndex := 0, policy := .rawI16, halfIndex := 1 },
                    { operandIndex := 1, policy := .rawI16, halfIndex := 0 },
                    { operandIndex := 1, policy := .rawI16, halfIndex := 1 },
                    { operandIndex := 2, policy := .rawI16, halfIndex := 0 } ] },
              { opcode := eclOpcodeSetDeathAnm
                kind := .setDeathScripts
                intInputs :=
                  [ { operandIndex := 0, policy := .rawByte, byteIndex := 0 },
                    { operandIndex := 0, policy := .rawByte, byteIndex := 1 },
                    { operandIndex := 0, policy := .rawByte, byteIndex := 2 } ] },
              { opcode := eclOpcodeSetVmAutoRotate
                kind := .setAutoRotate
                intInputs :=
                  [ { operandIndex := 0, policy := .rawByte } ] },
              { opcode := eclOpcodeSetPrimaryVmInterrupt
                kind := .setPrimaryInterrupt
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue } ] },
              { opcode := eclOpcodeSetVmInterrupt
                kind := .setSecondaryInterrupt
                secondaryAccess :=
                  some
                    { slotCount := secondaryAnmVmCount
                      diagnoseHighOnly := false
                      slotInput := { operandIndex := 0, policy := .rawI32 }
                      interruptInput :=
                        { operandIndex := 1, policy := .rawI16 } } },
              { opcode := eclOpcodeSetPrimaryVmRotZ
                kind := .setPrimaryRotationZ
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue } ] } ]
          bulletPatternFamilies :=
            [ { firstOpcode := eclOpcodeSpawnBulletPatternFirst
                lastOpcode := eclOpcodeSpawnBulletPatternLast
                bulletTypePolicy := .intRValue
                rankPolicy := .unlessSpellcardActive
                skipWhenEnemyDead := true } ]
          callbackConfigOps :=
            [ { opcode := eclOpcodeSetDeathCallbackSub
                kind := .setDeathSub
                intPolicy := .rawU8 },
              { opcode := eclOpcodeSetLifeCallbackThreshold
                kind := .setLifeThreshold },
              { opcode := eclOpcodeSetLifeCallbackSub
                kind := .setLifeSub },
              { opcode := eclOpcodeSetLifeCallback
                kind := .setLifePairIndexed },
              { opcode := eclOpcodeSetTimerCallbackThreshold
                kind := .setTimerThreshold
                resetBossTimer := true },
              { opcode := eclOpcodeSetTimerCallbackSub
                kind := .setTimerSub },
              { opcode := eclOpcodeSetPeriodicCallback
                kind := .setPeriodic },
              { opcode := eclOpcodeBindTimerCallbackToDeath
                kind := .bindTimerToDeath
                resetBossTimer := true } ]
          interruptOps :=
            [ { opcode := eclOpcodeSetInterrupt
                kind := .setTableEntry
                intPolicy := .intRValue
                tableEntryCount := 32 },
              { opcode := eclOpcodeRunInterrupt
                kind := .run
                intPolicy := .intRValue
                tableEntryCount := 32 },
              { opcode := eclOpcodeSetCallStackDisabled
                kind := .setStackDisabled
                intPolicy := .rawU8 } ]
          intUnaryUpdates :=
            [ { opcode := eclOpcodeInc
                kind := .inc
                outputPolicy := .intLValue
                outputOperandIndex := 0 },
              { opcode := eclOpcodeDec
                kind := .dec
                outputPolicy := .intLValue
                outputOperandIndex := 0 } ]
          intBinaryOps :=
            [ { opcode := eclOpcodeIntAdd
                kind := .add
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 },
              { opcode := eclOpcodeIntSub
                kind := .sub
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 },
              { opcode := eclOpcodeIntMul
                kind := .mul
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 },
              { opcode := eclOpcodeIntDiv
                kind := .div
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 },
              { opcode := eclOpcodeIntMod
                kind := .mod
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 } ]
          floatBinaryOps :=
            [ { opcode := eclOpcodeFloatAdd
                kind := .add
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 },
              { opcode := eclOpcodeFloatSub
                kind := .sub
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 },
              { opcode := eclOpcodeFloatMul
                kind := .mul
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 },
              { opcode := eclOpcodeFloatDiv
                kind := .div
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 },
              { opcode := eclOpcodeFloatMod
                kind := .mod
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 } ]
          floatFunctions :=
            [ { opcode := eclOpcodeSin
                kind := .sin
                outputPolicy := .floatLValue
                inputPolicy := .floatRValues
                outputOperandIndex := 0
                inputOperandIndices := [1] },
              { opcode := eclOpcodeCos
                kind := .cos
                outputPolicy := .floatLValue
                inputPolicy := .floatRValues
                outputOperandIndex := 0
                inputOperandIndices := [1] },
              { opcode := eclOpcodeAtan2
                kind := .atan2
                outputPolicy := .floatLValue
                inputPolicy := .floatRValues
                outputOperandIndex := 0
                inputOperandIndices := [1, 2, 3, 4] },
              { opcode := eclOpcodeNormalizeAngle
                kind := .normalizeAngle
                outputPolicy := .floatLValue
                inputPolicy := .floatRValues
                outputOperandIndex := 0
                inputOperandIndices := [0] } ]
          bossIntReads :=
            [ { opcode := eclOpcodeGetBossInt
                outputOperandIndex := 0
                valueOperandIndex := 1
                bossIndexOperandIndex := 2
                bossSlotCount := 8
                nullDerefValueSelectors :=
                  { ranges := [ { first := 10000, last := 10000 } ]
                    exclusions := [] } } ]
          bossFloatReads :=
            [ { opcode := eclOpcodeGetBossFloat
                outputOperandIndex := 0
                valueOperandIndex := 1
                bossIndexOperandIndex := 2
                bossSlotCount := 8
                nullPolicy := .unguardedDeref
                nullDerefValueSelectors :=
                  { ranges := [ { first := 1176260608, last := 1176268799 } ]
                    exclusions := [] } } ]
          intDivisorHazards :=
            [ { opcode := eclOpcodeIntDiv
                kind := .div
                divisorOperandIndex := 2 },
              { opcode := eclOpcodeIntMod
                kind := .mod
                divisorOperandIndex := 2 } ] }
    evidence := eclEvidence }

theorem headerShape_timelineTableEnd :
    headerShape.timelineTableEnd = rawHeaderFixedPrefixBytes := by
  rfl

theorem headerShape_loaderTimelineSlots :
    headerShape.loaderTimelineSlots = timelinePointerCount := by
  rfl

end TouhouFormal.TH07
