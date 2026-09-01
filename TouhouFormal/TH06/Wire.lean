import TouhouFormal.Core.Evidence
import TouhouFormal.ECL.Profile

namespace TouhouFormal.TH06

def title : String := "TH06"

def rawHeaderSize : Nat := 0x10
def timelinePointerCount : Nat := 3
def timelineInstrFixedSize : Nat := 0x1c
def eclOpcodeJump : Int := 2
def eclOpcodeJumpDec : Int := 3
def eclOpcodeSetInt : Int := 4
def eclOpcodeSetFloat : Int := 5
def eclOpcodeSetIntRand : Int := 6
def eclOpcodeSetIntRandMin : Int := 7
def eclOpcodeSetFloatRand : Int := 8
def eclOpcodeSetFloatRandMin : Int := 9
def eclOpcodeJumpLss : Int := 29
def eclOpcodeJumpLeq : Int := 30
def eclOpcodeJumpEqu : Int := 31
def eclOpcodeJumpGre : Int := 32
def eclOpcodeJumpGeq : Int := 33
def eclOpcodeJumpNeq : Int := 34
def eclOpcodeMathIntAdd : Int := 13
def eclOpcodeMathIntSub : Int := 14
def eclOpcodeMathIntMul : Int := 15
def eclOpcodeMathIntDiv : Int := 16
def eclOpcodeMathIntMod : Int := 17
def eclOpcodeMathInc : Int := 18
def eclOpcodeMathDec : Int := 19
def eclOpcodeMathFloatAdd : Int := 20
def eclOpcodeMathFloatSub : Int := 21
def eclOpcodeMathFloatMul : Int := 22
def eclOpcodeMathFloatDiv : Int := 23
def eclOpcodeMathFloatMod : Int := 24
def eclOpcodeMathAtan2 : Int := 25
def eclOpcodeMathNormAngle : Int := 26
def eclOpcodeCmpInt : Int := 27
def eclOpcodeCmpFloat : Int := 28
def eclOpcodeCall : Int := 35
def eclOpcodeRet : Int := 36
def eclOpcodeCallLss : Int := 37
def eclOpcodeCallLeq : Int := 38
def eclOpcodeCallEqu : Int := 39
def eclOpcodeCallGre : Int := 40
def eclOpcodeCallGeq : Int := 41
def eclOpcodeCallNeq : Int := 42
def eclOpcodeMovePosition : Int := 43
def eclOpcodeMoveAxisVelocity : Int := 44
def eclOpcodeMoveVelocity : Int := 45
def eclOpcodeMoveAngularVelocity : Int := 46
def eclOpcodeMoveSpeed : Int := 47
def eclOpcodeMoveAcceleration : Int := 48
def eclOpcodeMoveRandom : Int := 49
def eclOpcodeMoveRandomInBounds : Int := 50
def eclOpcodeMoveAtPlayer : Int := 51
def eclOpcodeMoveDirTimeFirst : Int := 52
def eclOpcodeMoveDirTimeLast : Int := 55
def eclOpcodeMovePositionTimeFirst : Int := 56
def eclOpcodeMovePositionTimeLast : Int := 60
def eclOpcodeMoveCurrentTimeFirst : Int := 61
def eclOpcodeMoveCurrentTimeLast : Int := 64
def eclOpcodeMoveBoundsSet : Int := 65
def eclOpcodeMoveBoundsDisable : Int := 66
def eclOpcodeSpawnBulletPatternFirst : Int := 67
def eclOpcodeSpawnBulletPatternLast : Int := 75
def eclOpcodeSetShootInterval : Int := 76
def eclOpcodeSetRandomShootInterval : Int := 77
def eclOpcodeDisableShooting : Int := 78
def eclOpcodeEnableShooting : Int := 79
def eclOpcodeSpawnPreviousPattern : Int := 80
def eclOpcodeSetShootOffset : Int := 81
def eclOpcodeLaserCreate : Int := 85
def eclOpcodeLaserCreateAimed : Int := 86
def eclOpcodeLaserIndex : Int := 87
def eclOpcodeLaserRotate : Int := 88
def eclOpcodeLaserRotateFromPlayer : Int := 89
def eclOpcodeLaserOffset : Int := 90
def eclOpcodeLaserTest : Int := 91
def eclOpcodeLaserCancel : Int := 92
def eclOpcodeAnmSetMain : Int := 97
def eclOpcodeAnmSetPoses : Int := 98
def eclOpcodeAnmSetSlot : Int := 99
def eclOpcodeAnmSetDeath : Int := 100
def eclOpcodeSetHitbox : Int := 103
def eclOpcodeSetCollidable : Int := 104
def eclOpcodeSetDamageable : Int := 105
def eclOpcodeSetDeathMode : Int := 107
def eclOpcodeSetDeathCallbackSub : Int := 108
def eclOpcodeSetInterrupt : Int := 109
def eclOpcodeRunInterrupt : Int := 110
def eclOpcodeSetLife : Int := 111
def eclOpcodeSetBossTimer : Int := 112
def eclOpcodeSetLifeCallbackThreshold : Int := 113
def eclOpcodeSetLifeCallbackSub : Int := 114
def eclOpcodeSetTimerCallbackThreshold : Int := 115
def eclOpcodeSetTimerCallbackSub : Int := 116
def eclOpcodeSetInteractable : Int := 117
def eclOpcodeAnmFlagRotation : Int := 120
def eclOpcodeAnmInterruptMain : Int := 128
def eclOpcodeAnmInterruptSlot : Int := 129
def eclOpcodeSetCallStackDisabled : Int := 130
def eclOpcodeBindTimerCallbackToDeath : Int := 133
def eclOpcodeLaserClearAll : Int := 134
def enemyAnmScriptBase : Int := 0x100
def secondaryAnmVmCount : Nat := 8
def laserSlotCount : Nat := 32

def isTimelineSpawnOpcode (opcode : Int) : Bool :=
  decide (0 <= opcode /\ opcode <= 7)

def eclEvidence : List TouhouFormal.SourceRef :=
  [ { path := "reference/th06/src/EclManager.hpp"
      startLine := 65
      endLine := 72
      claim := "EclTimelineInstr stores i16 time, i16 arg0, i16 opCode, and i16 size." },
    { path := "reference/th06/src/EclManager.hpp"
      startLine := 340
      endLine := 345
      claim := "EclRawHeader stores subCount, mainCount, timeline offsets, and subOffsets." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 54
      endLine := 61
      claim := "Load rebases timelineOffsets[0] and each subTable entry for idx < subCount." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 78
      endLine := 84
      claim := "CallEclSub reads this->subTable[subId] without checking subId." },
    { path := "reference/th06/src/EnemyEclInstr.cpp"
      startLine := 100
      endLine := 235
      claim := "GetVar switches every raw ECL var id without an operand mask and returns the raw operand pointer for unknown ids." },
    { path := "reference/th06/src/EnemyEclInstr.cpp"
      startLine := 252
      endLine := 269
      claim := "SetVar writes only when GetVar reports an INT or FLOAT output; unknown and read-only outputs become no-ops." },
    { path := "reference/th06/src/EnemyEclInstr.cpp"
      startLine := 272
      endLine := 345
      claim := "MathAdd/MathSub/MathMul first classify the output variable; the integer path reads lhs/rhs through GetVar and writes the resolved output." },
    { path := "reference/th06/src/EnemyEclInstr.cpp"
      startLine := 238
      endLine := 249
      claim := "GetVarFloat casts an f32 operand to an integer EclVarId, delegates to GetVar, and falls back to the original f32 operand cell only when GetVar returns its local default pointer." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 183
      endLine := 209
      claim := "MATHFLOATADD/SUB/MUL/DIV/MOD share the same helper calls and slot layout as the integer math opcodes: output slot 0, lhs slot 1, rhs slot 2." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 187
      endLine := 193
      claim := "MATHINC and MATHDEC call GetVar with valueType NULL and directly increment/decrement the returned pointer, so they do not use SetVar's INT/FLOAT output type guard." },
    { path := "reference/th06/src/EnemyEclInstr.cpp"
      startLine := 288
      endLine := 390
      claim := "The float branches of MathAdd/MathSub/MathMul/MathDiv/MathMod use GetVarFloat for lhs/rhs and write through a FLOAT-classified GetVar output; MathMod uses fmodf." },
    { path := "reference/th06/src/EnemyEclInstr.cpp"
      startLine := 395
      endLine := 411
      claim := "MathAtan2 accepts only a FLOAT-classified output, resolves four float operands, and computes atan2f(slot4 - slot2, slot3 - slot1)." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 145
      endLine := 149
      claim := "MATHNORMANGLE reads output slot 0 through GetVar, normalizes its f32 bit pattern, and writes the result back through SetVar." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 130
      endLine := 139
      claim := "JUMPDEC decrements the counter slot and falls through to JUMP only while the decremented counter is positive." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 141
      endLine := 143
      claim := "SETINT and SETFLOAT both call SetVar with output slot 0 and raw value slot 1; SetVar later decides whether the output is INT or FLOAT." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 150
      endLine := 172
      claim := "SETINTRAND/SETINTRANDMIN and SETFLOATRAND/SETFLOATRANDMIN resolve range/addend operands, obtain RNG values, and pass the local result through SetVar." },
    { path := "reference/th06/src/Rng.hpp"
      startLine := 28
      endLine := 35
      claim := "GetRandomU32InRange uses unsigned modulo with a zero-range result of zero; GetRandomF32InRange multiplies a zero-to-one sample by the range." },
    { path := "reference/th06/src/EnemyEclInstr.cpp"
      startLine := 348
      endLine := 360
      claim := "MathDiv performs integer division by the resolved RHS pointer without a zero-divisor guard." },
    { path := "reference/th06/src/EnemyEclInstr.cpp"
      startLine := 372
      endLine := 384
      claim := "MathMod performs integer modulo by the resolved RHS pointer without a zero-divisor guard." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 215
      endLine := 247
      claim := "CMPINT/CMPFLOAT set compareRegister, and JUMP* opcodes branch on compareRegister while reusing the raw jump operands." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 215
      endLine := 225
      claim := "CMPINT resolves both operands with GetVar; CMPFLOAT resolves both with GetVarFloat, and unordered float comparisons fall through the ternary chain to compareRegister = 1." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 249
      endLine := 272
      claim := "CALL saves the next instruction context at savedContextStack[stackDepth] before CallEclSub and increments depth only while stackDepth < 7; RET decrements stackDepth before restoring from savedContextStack[stackDepth]." },
    { path := "reference/th06/src/EclManager.hpp"
      startLine := 108
      endLine := 115
      claim := "EclRawInstrCallArgs stores eclSub in slot 0, var0 in slot 1, float0 in slot 2, cmpLhs in slot 3, and cmpRhs in slot 4." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 274
      endLine := 302
      claim := "CALLLSS/CALLLEQ/CALLEQU/CALLGRE/CALLGEQ/CALLNEQ resolve cmpLhs with GetVar, compare against raw cmpRhs, and jump to the same HANDLE_CALL body only when the condition holds." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 316
      endLine := 356
      claim := "Immediate movement opcodes set position, axis/polar velocity, angular velocity, speed, acceleration, and player-relative movement with title-specific GetVarFloat use and movement-mode writes." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 612
      endLine := 620
      claim := "Movement-bound opcodes copy four raw float fields and toggle the shouldClampPos flag without resolving those bounds through GetVarFloat." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 622
      endLine := 657
      claim := "MOVERAND samples between two raw angle fields; MOVERANDINBOUND then reflects the generated angle at four movement-bound margins, using that candidate in the right-positive subtraction." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 668
      endLine := 683
      claim := "Enemy hitbox opcode 103 copies three raw float fields, while opcodes 104, 105, and 107 assign raw i32 values into one-bit collision/damage and three-bit death-mode fields." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 801
      endLine := 803
      claim := "Enemy opcode 117 assigns its raw i32 operand into the one-bit isInteractable field." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 707
      endLine := 709
      claim := "Enemy opcode 111 copies one raw i32 operand into both life and maxLife." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 785
      endLine := 787
      claim := "Enemy opcode 112 passes one raw i32 operand to bossTimer.SetCurrent." },
    { path := "reference/th06/src/ZunTimer.hpp"
      startLine := 62
      endLine := 67
      claim := "ZunTimer.SetCurrent writes current, resets subFrame to zero, and sets previous to -999." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 428
      endLine := 454
      claim := "Shoot-control opcodes 76 through 81 use a raw interval plus rank scaling, immediate/random timer initialization, a suppress-spawn bit, explicit previous-pattern spawn, and three GetVarFloat-resolved offset components." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 357
      endLine := 410
      claim := "Bullet-pattern opcodes 67 through 75 share one descriptor body: the opcode delta selects aim mode, counts and floats always use GetVar/GetVarFloat, rank adjustment and minimum-speed clamps always run, angle1 is normalized, and shootingDisabled suppresses only the final spawn call." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 485
      endLine := 534
      claim := "Laser slot opcodes set the selected laser index, mutate indexed lasers after an unchecked pointer-slot read, test active status into compareRegister, stop active lasers by state/timer writes, and clear all 32 enemy laser slots." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 304
      endLine := 317
      claim := "ANMSETMAIN adds ANM_SCRIPT_ENEMY_START to one raw i32 script id and runs the primary VM; ANMSETSLOT diagnoses only high slot indexes and still accesses enemy->vms[vmIdx]." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 422
      endLine := 426
      claim := "ANMSETDEATH copies three raw byte fields into the enemy death-animation slots." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 660
      endLine := 667
      claim := "ANMSETPOSES copies five packed i16 pose scripts and then sets anmExFlags to 0xff." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 826
      endLine := 828
      claim := "ANMFLAGROTATION assigns one raw i32 operand into a one-bit rotateAnm field." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 896
      endLine := 900
      claim := "ANMINTERRUPTMAIN writes the raw i32 operand into primaryVm.pendingInterrupt; ANMINTERRUPTSLOT indexes the secondary VM array without a bounds check." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 685
      endLine := 686
      claim := "Opcode 108 copies one raw i32 into deathCallbackSub." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 788
      endLine := 800
      claim := "Opcodes 113 through 116 write raw life/timer callback threshold and subroutine fields; setting the timer threshold also resets bossTimer." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 919
      endLine := 922
      claim := "Opcode 133 binds timerCallbackSub to deathCallbackSub and resets bossTimer." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 688
      endLine := 705
      claim := "Opcodes 109/110 write the unchecked eight-entry interrupt table and enter its selected subroutine after advancing/saving context; stack depth increments even when the disable-save flag is set." },
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 905
      endLine := 907
      claim := "Opcode 130 assigns one raw i32 into the one-bit disableCallStack field." },
    { path := "reference/th06/src/Enemy.hpp"
      startLine := 195
      endLine := 197
      claim := "Enemy stores currentContext, savedContextStack[8], and signed stackDepth." },
    { path := "reference/th06/src/EnemyManager.cpp"
      startLine := 177
      endLine := 292
      claim := "Timeline opcodes 0 through 7 call SpawnEnemy with timelineInstr->arg0 when no boss is present." },
    { path := "reference/th06/src/EnemyManager.cpp"
      startLine := 92
      endLine := 125
      claim := "SpawnEnemy passes eclSubId directly to g_EclManager.CallEclSub." } ]

def headerShape : TouhouFormal.ECL.HeaderShape :=
  { title := title
    hasVersionField := false
    versionOffset := none
    expectedVersion := none
    subCountOffset := 0
    timelineCountOffset := 2
    timelineTableOffset := 4
    fixedHeaderBytes := rawHeaderSize
    timelineSlots := timelinePointerCount
    loaderTimelineSlots := 1
    subTableField := "subOffsets[0]"
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
          timeWidth := .i32
          opcodeOffset := 4
          opcodeWidth := .i16
          unimplementedOpcode := some 1
          nextOffsetOffset := 6
          nextOffsetWidth := .i16
          difficultyMaskOffset := some 9
          difficultyMaskWidth := some .u8
          difficultyMaskPolicy := some .intersectsActive
          operandMaskOffset := none
          operandMaskWidth := none
          fixedI32OperandBaseOffset := some 12
          fixedI32OperandStride := 4
          fixedJumpShape :=
            some
              { opcode := eclOpcodeJump
                targetTimeOperandIndex := 0
                displacementOperandIndex := 1 }
          fixedDecJumpShape :=
            some
              { opcode := eclOpcodeJumpDec
                targetTimeOperandIndex := 0
                displacementOperandIndex := 1
                counterOperandIndex := 2 }
          intRValueResolver :=
            some
              { maskPolicy := .noMaskAlwaysResolve
                knownRValueSelectors :=
                  { ranges := [ { first := -10025, last := -10001 } ]
                    exclusions := [] }
                knownLValueSelectors :=
                  { ranges :=
                      [ { first := -10025, last := -10024 },
                        { first := -10022, last := -10022 },
                        { first := -10012, last := -10009 },
                        { first := -10004, last := -10001 } ]
                    exclusions := [] } }
          floatRValueResolver :=
            some
              { maskPolicy := .noMaskAlwaysResolve
                knownRValueSelectors :=
                  { ranges := [ { first := 3323741184, last := 3323766783 } ]
                    exclusions := [] }
                knownLValueSelectors :=
                  { ranges :=
                      [ { first := -10008, last := -10005 },
                        { first := -10017, last := -10015 } ]
                    exclusions := [] } }
          compareRegisterOps :=
            [ { opcode := eclOpcodeCmpInt
                scalarKind := .int
                lhsOperandIndex := 0
                rhsOperandIndex := 1 },
              { opcode := eclOpcodeCmpFloat
                scalarKind := .float
                lhsOperandIndex := 0
                rhsOperandIndex := 1 } ]
          intConditionJumps :=
            [ { opcode := eclOpcodeJumpLss
                op := .lt
                source := .compareRegister
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 0
                displacementOperandIndex := 1 },
              { opcode := eclOpcodeJumpLeq
                op := .le
                source := .compareRegister
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 0
                displacementOperandIndex := 1 },
              { opcode := eclOpcodeJumpEqu
                op := .eq
                source := .compareRegister
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 0
                displacementOperandIndex := 1 },
              { opcode := eclOpcodeJumpGre
                op := .gt
                source := .compareRegister
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 0
                displacementOperandIndex := 1 },
              { opcode := eclOpcodeJumpGeq
                op := .ge
                source := .compareRegister
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 0
                displacementOperandIndex := 1 },
              { opcode := eclOpcodeJumpNeq
                op := .neq
                source := .compareRegister
                lhsOperandIndex := 0
                rhsOperandIndex := 1
                targetTimeOperandIndex := 0
                displacementOperandIndex := 1 } ]
          callRetShape :=
            some
              { callOpcode := eclOpcodeCall
                retOpcode := eclOpcodeRet
                subIdOperandIndex := 0
                stackEntryCount := 8
                stackIncrementGuardExclusive := 7
                retUnderflowPolicy := .uncheckedSavedContextRead
                childContextSlotCount := 0 }
          conditionalCallShapes :=
            [ { opcode := eclOpcodeCallLss
                op := .lt
                lhsOperandIndex := 3
                rhsOperandIndex := 4 },
              { opcode := eclOpcodeCallLeq
                op := .le
                lhsOperandIndex := 3
                rhsOperandIndex := 4 },
              { opcode := eclOpcodeCallEqu
                op := .eq
                lhsOperandIndex := 3
                rhsOperandIndex := 4 },
              { opcode := eclOpcodeCallGre
                op := .gt
                lhsOperandIndex := 3
                rhsOperandIndex := 4 },
              { opcode := eclOpcodeCallGeq
                op := .ge
                lhsOperandIndex := 3
                rhsOperandIndex := 4 },
              { opcode := eclOpcodeCallNeq
                op := .neq
                lhsOperandIndex := 3
                rhsOperandIndex := 4 } ]
          scalarAssignments :=
            [ { opcode := eclOpcodeSetInt
                outputPolicy := .sourceSetVar
                rvaluePolicy := .intBits
                outputOperandIndex := 0
                valueOperandIndex := 1 },
              { opcode := eclOpcodeSetFloat
                outputPolicy := .sourceSetVar
                rvaluePolicy := .intBits
                outputOperandIndex := 0
                valueOperandIndex := 1 } ]
          randomOps :=
            [ { opcode := eclOpcodeSetIntRand
                kind := .intRange
                outputPolicy := .sourceSetVar
                writePolicy := .sourceSetVarResolvesResultBits
                outputOperandIndex := 0
                valueOperandIndex := 1 },
              { opcode := eclOpcodeSetIntRandMin
                kind := .intRangeAdd
                outputPolicy := .sourceSetVar
                writePolicy := .sourceSetVarResolvesResultBits
                outputOperandIndex := 0
                valueOperandIndex := 1
                addendOperandIndex := some 2 },
              { opcode := eclOpcodeSetFloatRand
                kind := .floatRange
                outputPolicy := .sourceSetVar
                writePolicy := .sourceSetVarResolvesResultBits
                outputOperandIndex := 0
                valueOperandIndex := 1 },
              { opcode := eclOpcodeSetFloatRandMin
                kind := .floatRangeAdd
                outputPolicy := .sourceSetVar
                writePolicy := .sourceSetVarResolvesResultBits
                outputOperandIndex := 0
                valueOperandIndex := 1
                addendOperandIndex := some 2 } ]
          movementOps :=
            [ { opcode := eclOpcodeMovePosition
                kind := .setPosition
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue },
                    { operandIndex := 1, policy := .floatRValue },
                    { operandIndex := 2, policy := .floatRValue } ]
                clampPosition := true },
              { opcode := eclOpcodeMoveAxisVelocity
                kind := .setAxisVelocity
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue },
                    { operandIndex := 1, policy := .floatRValue },
                    { operandIndex := 2, policy := .floatRValue } ]
                modeUpdate := some .axis },
              { opcode := eclOpcodeMoveVelocity
                kind := .setPolarVelocity
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue },
                    { operandIndex := 1, policy := .floatRValue } ]
                anglePolicy := .firstInput
                modeUpdate := some .polar },
              { opcode := eclOpcodeMoveAngularVelocity
                kind := .setAngularVelocity
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue } ]
                modeUpdate := some .polar },
              { opcode := eclOpcodeMoveSpeed
                kind := .setSpeed
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue } ]
                modeUpdate := some .polar },
              { opcode := eclOpcodeMoveAcceleration
                kind := .setAcceleration
                floatInputs :=
                  [ { operandIndex := 0, policy := .floatRValue } ]
                modeUpdate := some .polar },
              { opcode := eclOpcodeMoveAtPlayer
                kind := .moveAtPlayer
                floatInputs :=
                  [ { operandIndex := 0, policy := .rawBits },
                    { operandIndex := 1, policy := .floatRValue } ]
                anglePolicy := .derivedPlayerRelative
                modeUpdate := some .polar },
              { opcode := eclOpcodeMoveBoundsSet
                kind := .setBounds
                floatInputs :=
                  [ { operandIndex := 0, policy := .rawBits },
                    { operandIndex := 1, policy := .rawBits },
                    { operandIndex := 2, policy := .rawBits },
                    { operandIndex := 3, policy := .rawBits } ] },
              { opcode := eclOpcodeMoveBoundsDisable
                kind := .disableBounds } ]
          randomDirectionOps :=
            [ { opcode := eclOpcodeMoveRandom
                generator := .operandRange
                floatInputs :=
                  [ { operandIndex := 0, policy := .rawBits },
                    { operandIndex := 1, policy := .rawBits } ]
                outputPolicy := .enemyAngle },
              { opcode := eclOpcodeMoveRandomInBounds
                generator := .operandRange
                floatInputs :=
                  [ { operandIndex := 0, policy := .rawBits },
                    { operandIndex := 1, policy := .rawBits } ]
                boundaryPolicy := .rectangle .candidateAngle
                outputPolicy := .enemyAngle } ]
          timedMovementFamilies :=
            [ { firstOpcode := eclOpcodeMoveDirTimeFirst
                lastOpcode := eclOpcodeMoveDirTimeLast
                kind := .direction
                floatInputs :=
                  [ { role := .angle, operandIndex := 1, policy := .rValue },
                    { role := .speed, operandIndex := 2, policy := .rawBits } ]
                durationPolicy := .rawI32
                easingPolicy := .opcodeOffset 1
                halfDurationDisplacement := true },
              { firstOpcode := eclOpcodeMovePositionTimeFirst
                lastOpcode := eclOpcodeMovePositionTimeLast
                kind := .position
                floatInputs :=
                  [ { role := .targetX, operandIndex := 1, policy := .rValue },
                    { role := .targetY, operandIndex := 2, policy := .rValue },
                    { role := .targetZ, operandIndex := 3, policy := .rValue } ]
                durationPolicy := .rawI32
                easingPolicy := .opcodeOffset 0
                zeroVelocity := true },
              { firstOpcode := eclOpcodeMoveCurrentTimeFirst
                lastOpcode := eclOpcodeMoveCurrentTimeLast
                kind := .currentDirection
                durationPolicy := .rawI32
                easingPolicy := .opcodeOffset 1
                halfDurationDisplacement := true } ]
          enemyStateOps :=
            [ { opcode := eclOpcodeSetHitbox
                kind := .setPrimaryHitbox 3
                floatInputs :=
                  [ { operandIndex := 0, policy := .rawBits },
                    { operandIndex := 1, policy := .rawBits },
                    { operandIndex := 2, policy := .rawBits } ] },
              { opcode := eclOpcodeSetCollidable
                kind := .setField .collidable
                intInputPolicy := some .rawI32 },
              { opcode := eclOpcodeSetDamageable
                kind := .setField .damageable
                intInputPolicy := some .rawI32 },
              { opcode := eclOpcodeSetDeathMode
                kind := .setField .deathMode
                intInputPolicy := some .rawI32 },
              { opcode := eclOpcodeSetInteractable
                kind := .setField .interactable
                intInputPolicy := some .rawI32 },
              { opcode := eclOpcodeSetLife
                kind := .setLife
                intInputPolicy := some .rawI32 },
              { opcode := eclOpcodeSetBossTimer
                kind := .setTimer
                intInputPolicy := some .rawI32 } ]
          shootingOps :=
            [ { opcode := eclOpcodeSetShootInterval
                kind := .setInterval
                intInputPolicy := some .rawI32
                intervalGuardPolicy := .alwaysApplyRank },
              { opcode := eclOpcodeSetRandomShootInterval
                kind := .setRandomizedInterval
                intInputPolicy := some .rawI32
                intervalGuardPolicy := .alwaysApplyRank },
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
          laserOps :=
            [ { opcode := eclOpcodeLaserIndex
                kind := .setSelectedSlot
                intInputs :=
                  [ { operandIndex := 0, policy := .intRValue } ] },
              { opcode := eclOpcodeLaserRotate
                kind := .writeAngle .add
                intInputs :=
                  [ { operandIndex := 0, policy := .rawI32 } ]
                floatInputs :=
                  [ { operandIndex := 1, policy := .floatRValue } ] },
              { opcode := eclOpcodeLaserRotateFromPlayer
                kind := .writeAngle .aimAtPlayer
                intInputs :=
                  [ { operandIndex := 0, policy := .rawI32 } ]
                floatInputs :=
                  [ { operandIndex := 1, policy := .floatRValue } ] },
              { opcode := eclOpcodeLaserOffset
                kind := .writeRelativePosition
                intInputs :=
                  [ { operandIndex := 0, policy := .rawI32 } ]
                floatInputs :=
                  [ { operandIndex := 1, policy := .rawBits },
                    { operandIndex := 2, policy := .rawBits },
                    { operandIndex := 3, policy := .rawBits } ] },
              { opcode := eclOpcodeLaserTest
                kind := .testInUse
                intInputs :=
                  [ { operandIndex := 0, policy := .rawI32 } ] },
              { opcode := eclOpcodeLaserCancel
                kind := .stop
                intInputs :=
                  [ { operandIndex := 0, policy := .rawI32 } ] },
              { opcode := eclOpcodeLaserClearAll
                kind := .clearAll
                slotCount := laserSlotCount } ]
          animationOps :=
            [ { opcode := eclOpcodeAnmSetMain
                kind := .setPrimaryScript
                scriptSource := some (.rawI32 0)
                scriptBase := enemyAnmScriptBase
                intInputs :=
                  [ { operandIndex := 0, policy := .rawI32 } ] },
              { opcode := eclOpcodeAnmSetSlot
                kind := .setSecondaryScript
                secondaryAccess :=
                  some
                    { slotCount := secondaryAnmVmCount
                      slotInput := { operandIndex := 0, policy := .rawI32 }
                      scriptInput := { operandIndex := 1, policy := .rawI32 }
                      scriptBase := enemyAnmScriptBase } },
              { opcode := eclOpcodeAnmSetPoses
                kind := .setMovementScripts
                intInputs :=
                  [ { operandIndex := 0, policy := .rawI16, halfIndex := 0 },
                    { operandIndex := 0, policy := .rawI16, halfIndex := 1 },
                    { operandIndex := 1, policy := .rawI16, halfIndex := 0 },
                    { operandIndex := 1, policy := .rawI16, halfIndex := 1 },
                    { operandIndex := 2, policy := .rawI16, halfIndex := 0 } ] },
              { opcode := eclOpcodeAnmSetDeath
                kind := .setDeathScripts
                intInputs :=
                  [ { operandIndex := 0, policy := .rawByte, byteIndex := 0 },
                    { operandIndex := 0, policy := .rawByte, byteIndex := 1 },
                    { operandIndex := 0, policy := .rawByte, byteIndex := 2 } ] },
              { opcode := eclOpcodeAnmFlagRotation
                kind := .setAutoRotate
                intInputs :=
                  [ { operandIndex := 0, policy := .rawI32 } ] },
              { opcode := eclOpcodeAnmInterruptMain
                kind := .setPrimaryInterrupt
                intInputs :=
                  [ { operandIndex := 0, policy := .rawI32 } ] },
              { opcode := eclOpcodeAnmInterruptSlot
                kind := .setSecondaryInterrupt
                secondaryAccess :=
                  some
                    { slotCount := secondaryAnmVmCount
                      diagnoseHighOnly := false
                      slotInput := { operandIndex := 0, policy := .rawI32 }
                      interruptInput :=
                        { operandIndex := 1, policy := .rawI32 } } } ]
          bulletPatternFamilies :=
            [ { firstOpcode := eclOpcodeSpawnBulletPatternFirst
                lastOpcode := eclOpcodeSpawnBulletPatternLast
                bulletTypePolicy := .rawI16
                normalizePrimaryAngle := true
                rankPolicy := .always } ]
          callbackConfigOps :=
            [ { opcode := eclOpcodeSetDeathCallbackSub
                kind := .setDeathSub
                intPolicy := .rawI32 },
              { opcode := eclOpcodeSetLifeCallbackThreshold
                kind := .setLifeThreshold
                intPolicy := .rawI32 },
              { opcode := eclOpcodeSetLifeCallbackSub
                kind := .setLifeSub
                intPolicy := .rawI32 },
              { opcode := eclOpcodeSetTimerCallbackThreshold
                kind := .setTimerThreshold
                intPolicy := .rawI32
                resetBossTimer := true },
              { opcode := eclOpcodeSetTimerCallbackSub
                kind := .setTimerSub
                intPolicy := .rawI32 },
              { opcode := eclOpcodeBindTimerCallbackToDeath
                kind := .bindTimerToDeath
                intPolicy := .rawI32
                resetBossTimer := true } ]
          interruptOps :=
            [ { opcode := eclOpcodeSetInterrupt
                kind := .setTableEntry
                intPolicy := .rawI32
                tableEntryCount := 8 },
              { opcode := eclOpcodeRunInterrupt
                kind := .run
                intPolicy := .rawI32
                tableEntryCount := 8 },
              { opcode := eclOpcodeSetCallStackDisabled
                kind := .setStackDisabled
                intPolicy := .rawI32 } ]
          intUnaryUpdates :=
            [ { opcode := eclOpcodeMathInc
                kind := .inc
                outputPolicy := .sourceGetVarPointer
                outputOperandIndex := 0 },
              { opcode := eclOpcodeMathDec
                kind := .dec
                outputPolicy := .sourceGetVarPointer
                outputOperandIndex := 0 } ]
          intBinaryOps :=
            [ { opcode := eclOpcodeMathIntAdd
                kind := .add
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 },
              { opcode := eclOpcodeMathIntSub
                kind := .sub
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 },
              { opcode := eclOpcodeMathIntMul
                kind := .mul
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 },
              { opcode := eclOpcodeMathIntDiv
                kind := .div
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 },
              { opcode := eclOpcodeMathIntMod
                kind := .mod
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 } ]
          floatBinaryOps :=
            [ { opcode := eclOpcodeMathFloatAdd
                kind := .add
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 },
              { opcode := eclOpcodeMathFloatSub
                kind := .sub
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 },
              { opcode := eclOpcodeMathFloatMul
                kind := .mul
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 },
              { opcode := eclOpcodeMathFloatDiv
                kind := .div
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 },
              { opcode := eclOpcodeMathFloatMod
                kind := .mod
                mode := .assign
                outputOperandIndex := 0
                lhsOperandIndex := 1
                rhsOperandIndex := 2 } ]
          floatFunctions :=
            [ { opcode := eclOpcodeMathAtan2
                kind := .atan2
                outputPolicy := .floatLValue
                inputPolicy := .floatRValues
                outputOperandIndex := 0
                inputOperandIndices := [1, 2, 3, 4] },
              { opcode := eclOpcodeMathNormAngle
                kind := .normalizeAngle
                outputPolicy := .sourceSetVar
                inputPolicy := .sourceGetVarPointerBits
                outputOperandIndex := 0
                inputOperandIndices := [0] } ]
          intDivisorHazards :=
            [ { opcode := eclOpcodeMathIntDiv
                kind := .div
                divisorOperandIndex := 2 },
              { opcode := eclOpcodeMathIntMod
                kind := .mod
                divisorOperandIndex := 2 } ] }
    evidence := eclEvidence }

theorem headerShape_timelineTableEnd :
    headerShape.timelineTableEnd = rawHeaderSize := by
  rfl

theorem headerShape_loaderTimelineSlots :
    headerShape.loaderTimelineSlots = 1 := by
  rfl

end TouhouFormal.TH06
