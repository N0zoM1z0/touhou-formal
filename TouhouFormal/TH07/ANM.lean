import TouhouFormal.ANM.Entry
import TouhouFormal.TH07.Wire

namespace TouhouFormal.TH07.ANM

def entryEvidence : List TouhouFormal.SourceRef :=
  [ { path := "reference/th07/src/th07/AnmManager.hpp"
      startLine := 214
      endLine := 236
      claim := "AnmRawEntry stores counts, metadata, nextOffset, sprite offsets, and scripts." },
    { path := "reference/th07/src/th07/AnmManager.cpp"
      startLine := 402
      endLine := 428
      claim := "LoadAnms walks entries until nextOffset is zero, advancing entry by nextOffset." } ]

def entryShape : TouhouFormal.ANM.EntryShape :=
  { title := TouhouFormal.TH07.title
    fixedEntryBytes := 0xb8
    numSpritesOffset := 0
    numSpritesWidth := .i32
    numScriptsOffset := 4
    numScriptsWidth := .i32
    nextOffsetOffset := 0x38
    nextOffsetWidth := .i32
    embedsSpriteScriptTables := true
    chainPolicy := .nextOffsetUntilZero
    evidence := entryEvidence }

def nextEntryBytes : TouhouFormal.Bytes :=
  (TouhouFormal.zeroBytes 0x38 ++ TouhouFormal.leU32Bytes 0x40).toArray

theorem next_entry_decodes :
    TouhouFormal.ANM.decodeEntryHeader entryShape nextEntryBytes 0 =
      .ok
        { fileOffset := 0
          numSprites := 0
          numScripts := 0
          nextOffset := 0x40 } := by
  rfl

theorem next_entry_cursor_advances :
    ( { fileOffset := 0
        numSprites := 0
        numScripts := 0
        nextOffset := 0x40 } : TouhouFormal.ANM.EntryHeader ).nextCursor =
      some 0x40 := by
  rfl

end TouhouFormal.TH07.ANM
