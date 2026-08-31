import TouhouFormal.Core.Evidence
import TouhouFormal.ECL.Profile

namespace TouhouFormal.TH08

def title : String := "TH08"

def rawHeaderFixedPrefixBytes : Nat := 0x48
def expectedEclVersion : Nat := 0x800
def timelineOffsetCount : Nat := 16

def eclEvidence : List TouhouFormal.SourceRef :=
  [ { path := "reference/th08/src/EclManager.hpp"
      startLine := 147
      endLine := 156
      claim := "EclRawInstruction stores time, opcode, nextOffset, difficultyMask, operandFlags, and operands." },
    { path := "reference/th08/src/EclManager.hpp"
      startLine := 181
      endLine := 187
      claim := "EclRawHeader stores version, subCount, timelineCount, sixteen timeline offsets, and subOffsets[1]." },
    { path := "reference/th08/src/EclManager.cpp"
      startLine := 38
      endLine := 45
      claim := "Load rejects ECL files whose version is not 0x800." },
    { path := "reference/th08/src/EclManager.cpp"
      startLine := 46
      endLine := 55
      claim := "Load rebases sixteen timeline offsets and subTable entries for index < subCount." },
    { path := "reference/th08/src/EclManager.cpp"
      startLine := 69
      endLine := 84
      claim := "CallEclSub returns success for negative sub ids and otherwise reads this->subTable[subId]." } ]

def headerShape : TouhouFormal.ECL.HeaderShape :=
  { title := title
    hasVersionField := true
    expectedVersion := some expectedEclVersion
    fixedHeaderBytes := rawHeaderFixedPrefixBytes
    timelineSlots := timelineOffsetCount
    subTableField := "subOffsets[1]"
    negativeSubIdPolicy := .noOp
    evidence := eclEvidence }

end TouhouFormal.TH08
