import TouhouFormal.ANM.Entry
import TouhouFormal.TH08.Wire

namespace TouhouFormal.TH08.ANM

def entryEvidence : List TouhouFormal.SourceRef :=
  [ { path := "reference/th08/src/AnmManager.hpp"
      startLine := 227
      endLine := 249
      claim := "AnmRawEntry stores counts, metadata, nextOffset, and a fixed 0x40-byte entry header." },
    { path := "reference/th08/src/AnmManager.cpp"
      startLine := 2354
      endLine := 2384
      claim := "ReadAnmEntries totals entries, scripts, and sprites while walking nextOffset until zero." },
    { path := "reference/th08/src/AnmManager.cpp"
      startLine := 2400
      endLine := 2414
      claim := "Postload walks the same nextOffset chain and advances curEntry by nextOffset." } ]

def entryShape : TouhouFormal.ANM.EntryShape :=
  { title := TouhouFormal.TH08.title
    fixedEntryBytes := 0x40
    numSpritesOffset := 0
    numSpritesWidth := .i32
    numScriptsOffset := 4
    numScriptsWidth := .i32
    nextOffsetOffset := 0x38
    nextOffsetWidth := .u32
    embedsSpriteScriptTables := false
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

end TouhouFormal.TH08.ANM
