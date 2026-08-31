import TouhouFormal.Core.Evidence
import TouhouFormal.ECL.Profile

namespace TouhouFormal.TH06

def title : String := "TH06"

def rawHeaderSize : Nat := 0x10
def timelinePointerCount : Nat := 3
def timelineInstrFixedSize : Nat := 0x1c

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
    expectedVersion := none
    fixedHeaderBytes := rawHeaderSize
    timelineSlots := timelinePointerCount
    subTableField := "subOffsets[0]"
    negativeSubIdPolicy := .unchecked
    evidence := eclEvidence }

end TouhouFormal.TH06
