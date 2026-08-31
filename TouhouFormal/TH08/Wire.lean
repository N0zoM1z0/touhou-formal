import TouhouFormal.Core.Evidence
import TouhouFormal.ECL.Profile

namespace TouhouFormal.TH08

def title : String := "TH08"

def rawHeaderFixedPrefixBytes : Nat := 0x48
def expectedEclVersion : Nat := 0x800
def timelineOffsetCount : Nat := 16
def timelineInstrFixedSize : Nat := 0x24

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
      claim := "CallEclSub returns success for negative sub ids and otherwise reads this->subTable[subId]." },
    { path := "reference/th08/src/EnemyManager.hpp"
      startLine := 419
      endLine := 431
      claim := "EclTimelineInstruction stores i32 time, i16 opcode, u8 size, u8 difficultyMask, and seven i32/f32 args." },
    { path := "reference/th08/src/EnemyTimeline.cpp"
      startLine := 120
      endLine := 230
      claim := "Timeline spawn opcodes pass args.ints[0] into SpawnEnemy1, which then calls CallEclSub." } ]

def headerShape : TouhouFormal.ECL.HeaderShape :=
  { title := title
    hasVersionField := true
    versionOffset := some 0
    expectedVersion := some expectedEclVersion
    subCountOffset := 4
    timelineCountOffset := 6
    timelineTableOffset := 8
    fixedHeaderBytes := rawHeaderFixedPrefixBytes
    timelineSlots := timelineOffsetCount
    loaderTimelineSlots := timelineOffsetCount
    subTableField := "subOffsets[1]"
    negativeSubIdPolicy := .noOp
    timelineShape :=
      some
        { fixedSize := timelineInstrFixedSize
          timeOffset := 0
          timeWidth := .i32
          opcodeOffset := 4
          opcodeWidth := .i16
          sizeOffset := 6
          sizeWidth := .u8
          firstArgOffset := some 8
          firstArgWidth := some .i32 }
    evidence := eclEvidence }

end TouhouFormal.TH08
