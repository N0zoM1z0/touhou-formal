import TouhouFormal.Core.Evidence
import TouhouFormal.ECL.Profile

namespace TouhouFormal.TH07

def title : String := "TH07"

def rawHeaderFixedPrefixBytes : Nat := 0x44
def timelinePointerCount : Nat := 16
def timelineInstrFixedSize : Nat := 0x20
def eclOpcodeJump : Int := 2
def eclOpcodeDecJump : Int := 3

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
      startLine := 70
      endLine := 101
      claim := "Load rebases sixteen timeline pointers and subTable entries for i < subCount." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 106
      endLine := 114
      claim := "CallEclSub reads this->subTable[subId] without checking subId." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 946
      endLine := 954
      claim := "DEC_JUMP decrements operand slot 2 and falls through to JUMP only while the decremented value is positive." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 1035
      endLine := 1037
      claim := "DIV performs integer division by operand slot 2 without a zero-divisor guard." },
    { path := "reference/th07/src/th07/EclManager.cpp"
      startLine := 1043
      endLine := 1045
      claim := "MOD performs integer modulo by operand slot 2 without a zero-divisor guard." } ]

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
          intDivisorHazards :=
            [ { opcode := 15
                kind := .div
                divisorOperandIndex := 2 },
              { opcode := 16
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
