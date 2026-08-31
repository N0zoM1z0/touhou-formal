import TouhouFormal.ANM.Profile

namespace TouhouFormal.ANM

structure EntryHeader where
  fileOffset : Nat
  numSprites : Int
  numScripts : Int
  nextOffset : Int
deriving Repr, DecidableEq

def EntryHeader.nextCursor (entry : EntryHeader) : Option Int :=
  if entry.nextOffset = 0 then
    none
  else
    some (Int.ofNat entry.fileOffset + entry.nextOffset)

private def negativeCursorFault (shape : EntryShape) (bytes : TouhouFormal.Bytes)
    (cursor : Int) : Fault :=
  Fault.outOfBoundsRead
    shape.title
    "AnmManager.entry.cursor"
    "ANM entry cursor moved before the beginning of the ANM buffer"
    cursor
    bytes.size

def decodeEntryHeader (shape : EntryShape) (bytes : TouhouFormal.Bytes) (fileOffset : Nat) :
    Except Fault EntryHeader := do
  let numSprites <-
    TouhouFormal.readScalar
      shape.title
      "AnmManager.entry.numSprites"
      bytes
      (fileOffset + shape.numSpritesOffset)
      shape.numSpritesWidth
  let numScripts <-
    TouhouFormal.readScalar
      shape.title
      "AnmManager.entry.numScripts"
      bytes
      (fileOffset + shape.numScriptsOffset)
      shape.numScriptsWidth
  let nextOffset <-
    TouhouFormal.readScalar
      shape.title
      "AnmManager.entry.nextOffset"
      bytes
      (fileOffset + shape.nextOffsetOffset)
      shape.nextOffsetWidth
  pure
    { fileOffset := fileOffset
      numSprites := numSprites
      numScripts := numScripts
      nextOffset := nextOffset }

def decodeEntryHeaderAtCursor (shape : EntryShape) (bytes : TouhouFormal.Bytes)
    (cursor : Int) : Except Fault EntryHeader :=
  if cursor < 0 then
    .error (negativeCursorFault shape bytes cursor)
  else
    decodeEntryHeader shape bytes cursor.toNat

end TouhouFormal.ANM
