import TouhouFormal.Core.Evidence
import TouhouFormal.ECL.Profile

namespace TouhouFormal.TH06

def title : String := "TH06"

def rawHeaderSize : Nat := 0x10
def timelinePointerCount : Nat := 3
def timelineInstrFixedSize : Nat := 0x1c
def eclOpcodeJump : Int := 2
def eclOpcodeJumpDec : Int := 3
def eclOpcodeJumpLss : Int := 29
def eclOpcodeJumpLeq : Int := 30
def eclOpcodeJumpEqu : Int := 31
def eclOpcodeJumpGre : Int := 32
def eclOpcodeJumpGeq : Int := 33
def eclOpcodeJumpNeq : Int := 34
def eclOpcodeCall : Int := 35
def eclOpcodeRet : Int := 36
def eclOpcodeCallLss : Int := 37
def eclOpcodeCallLeq : Int := 38
def eclOpcodeCallEqu : Int := 39
def eclOpcodeCallGre : Int := 40
def eclOpcodeCallGeq : Int := 41
def eclOpcodeCallNeq : Int := 42

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
    { path := "reference/th06/src/EclManager.cpp"
      startLine := 130
      endLine := 139
      claim := "JUMPDEC decrements the counter slot and falls through to JUMP only while the decremented counter is positive." },
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
                  { ranges := [ { first := -10025, last := -10001 } ]
                    exclusions := [] } }
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
          intDivisorHazards :=
            [ { opcode := 16
                kind := .div
                divisorOperandIndex := 2 },
              { opcode := 17
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
