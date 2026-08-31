import TouhouFormal.Core.Evidence
import TouhouFormal.ECL.Profile

namespace TouhouFormal.TH07

def title : String := "TH07"

def rawHeaderFixedPrefixBytes : Nat := 0x44
def timelinePointerCount : Nat := 16
def timelineInstrFixedSize : Nat := 0x20

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
      claim := "CallEclSub reads this->subTable[subId] without checking subId." } ]

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
          nextOffsetOffset := 6
          nextOffsetWidth := .i16
          difficultyMaskOffset := some 9
          difficultyMaskWidth := some .u8
          operandMaskOffset := some 10
          operandMaskWidth := some .u16 }
    evidence := eclEvidence }

theorem headerShape_timelineTableEnd :
    headerShape.timelineTableEnd = rawHeaderFixedPrefixBytes := by
  rfl

theorem headerShape_loaderTimelineSlots :
    headerShape.loaderTimelineSlots = timelinePointerCount := by
  rfl

end TouhouFormal.TH07
