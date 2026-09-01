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
def eclOpcodeMoveAtPlayer : Int := 51
def eclOpcodeMoveBoundsSet : Int := 65
def eclOpcodeMoveBoundsDisable : Int := 66

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
