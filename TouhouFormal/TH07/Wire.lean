import TouhouFormal.Core.Evidence
import TouhouFormal.ECL.Profile

namespace TouhouFormal.TH07

def title : String := "TH07"

def rawHeaderFixedPrefixBytes : Nat := 0x44
def timelinePointerCount : Nat := 16

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
    expectedVersion := none
    fixedHeaderBytes := rawHeaderFixedPrefixBytes
    timelineSlots := timelinePointerCount
    subTableField := "subTable[]"
    negativeSubIdPolicy := .unchecked
    evidence := eclEvidence }

end TouhouFormal.TH07
