import TouhouFormal.ANM.Entry
import TouhouFormal.TH06.Wire

namespace TouhouFormal.TH06.ANM

def entryEvidence : List TouhouFormal.SourceRef :=
  [ { path := "reference/th06/src/AnmManager.hpp"
      startLine := 59
      endLine := 80
      claim := "AnmRawEntry stores counts, texture metadata, nextOffset, sprite offsets, and scripts." },
    { path := "reference/th06/src/AnmManager.cpp"
      startLine := 341
      endLine := 405
      claim := "LoadAnm opens one raw entry and consumes its sprite/script tables without walking nextOffset." } ]

def entryShape : TouhouFormal.ANM.EntryShape :=
  { title := TouhouFormal.TH06.title
    fixedEntryBytes := 0xb8
    numSpritesOffset := 0
    numSpritesWidth := .i32
    numScriptsOffset := 4
    numScriptsWidth := .i32
    nextOffsetOffset := 0x38
    nextOffsetWidth := .u32
    embedsSpriteScriptTables := true
    chainPolicy := .singleEntry
    evidence := entryEvidence }

def zeroEntryBytes : TouhouFormal.Bytes :=
  (TouhouFormal.zeroBytes 0x3c).toArray

theorem zero_entry_decodes :
    TouhouFormal.ANM.decodeEntryHeader entryShape zeroEntryBytes 0 =
      .ok
        { fileOffset := 0
          numSprites := 0
          numScripts := 0
          nextOffset := 0 } := by
  rfl

end TouhouFormal.TH06.ANM
