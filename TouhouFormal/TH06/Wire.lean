import TouhouFormal.Core.Evidence
import TouhouFormal.ECL.Profile

namespace TouhouFormal.TH06

def title : String := "TH06"

def rawHeaderSize : Nat := 0x10
def timelinePointerCount : Nat := 3
def timelineInstrFixedSize : Nat := 0x1c
def eclOpcodeJump : Int := 2
def eclOpcodeJumpDec : Int := 3

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
