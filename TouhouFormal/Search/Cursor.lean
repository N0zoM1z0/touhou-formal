import TouhouFormal.Core.Cursor
import TouhouFormal.TH06.Raw
import TouhouFormal.TH07
import TouhouFormal.TH08

namespace TouhouFormal.Search.Cursor

structure CursorSweepCase where
  displacement : Int
  targetCursor : Int
  cursorClass : TouhouFormal.CursorClass
deriving Repr, DecidableEq

def cursorSweep (sourceOffset bufferSize : Nat) (displacements : List Int) :
    List CursorSweepCase :=
  displacements.map fun displacement =>
    { displacement := displacement
      targetCursor := TouhouFormal.relativeCursor sourceOffset displacement
      cursorClass := TouhouFormal.classifyRelativeCursor sourceOffset displacement bufferSize }

def smallDisplacements : List Int :=
  [-1, 0, 1, 12, 24]

def timelineSizeDisplacements (shape : TouhouFormal.ECL.HeaderShape) : List Int :=
  match shape.timelineShape with
  | none => []
  | some timelineShape => timelineShape.sizeWidth.cursorDeltaSamples

def rawNextOffsetDisplacements (shape : TouhouFormal.ECL.HeaderShape) : List Int :=
  match shape.rawInstrShape with
  | none => []
  | some rawShape => rawShape.nextOffsetWidth.cursorDeltaSamples

def timelineSizeSweep (shape : TouhouFormal.ECL.HeaderShape) (bufferSize : Nat) :
    List CursorSweepCase :=
  cursorSweep 0 bufferSize (timelineSizeDisplacements shape)

def rawNextOffsetSweep (shape : TouhouFormal.ECL.HeaderShape) (bufferSize : Nat) :
    List CursorSweepCase :=
  cursorSweep 0 bufferSize (rawNextOffsetDisplacements shape)

def th06JumpSweep : List CursorSweepCase :=
  cursorSweep 0 TouhouFormal.TH06.rawJumpMinusOneInstrBytes.size smallDisplacements

def th07JumpSweep : List CursorSweepCase :=
  cursorSweep 0 TouhouFormal.TH07.rawJumpMinusOneInstrBytes.size smallDisplacements

def th08JumpSweep : List CursorSweepCase :=
  cursorSweep 0 TouhouFormal.TH08.rawJumpMinusOneInstrBytes.size smallDisplacements

def th06TimelineSizeSweep : List CursorSweepCase :=
  timelineSizeSweep
    TouhouFormal.TH06.headerShape
    TouhouFormal.TH06.rawZeroSizeTimelinePrefixBytes.size

def th07TimelineSizeSweep : List CursorSweepCase :=
  timelineSizeSweep
    TouhouFormal.TH07.headerShape
    TouhouFormal.TH07.timelineInstrFixedSize

def th08TimelineSizeSweep : List CursorSweepCase :=
  timelineSizeSweep
    TouhouFormal.TH08.headerShape
    TouhouFormal.TH08.rawTimelinePrefixBytes.size

def th06RawNextOffsetSweep : List CursorSweepCase :=
  rawNextOffsetSweep
    TouhouFormal.TH06.headerShape
    TouhouFormal.TH06.rawZeroNextOffsetInstrPrefixBytes.size

def th07RawNextOffsetSweep : List CursorSweepCase :=
  rawNextOffsetSweep
    TouhouFormal.TH07.headerShape
    TouhouFormal.TH07.rawInstrPrefixBytes.size

def th08RawNextOffsetSweep : List CursorSweepCase :=
  rawNextOffsetSweep
    TouhouFormal.TH08.headerShape
    TouhouFormal.TH08.rawInstrPrefixBytes.size

theorem th06_timeline_size_samples_signed :
    timelineSizeDisplacements TouhouFormal.TH06.headerShape =
      [-1, 0, 1, 12, 24, 32767] := by
  rfl

theorem th07_timeline_size_samples_signed :
    timelineSizeDisplacements TouhouFormal.TH07.headerShape =
      [-1, 0, 1, 12, 24, 32767] := by
  rfl

theorem th08_timeline_size_samples_unsigned :
    timelineSizeDisplacements TouhouFormal.TH08.headerShape =
      [0, 1, 12, 24, 255] := by
  rfl

theorem th06_timeline_size_sweep_expected :
    th06TimelineSizeSweep =
      [ { displacement := -1, targetCursor := -1, cursorClass := .beforeBuffer }
      , { displacement := 0, targetCursor := 0, cursorClass := .nonProgress }
      , { displacement := 1, targetCursor := 1, cursorClass := .inBounds }
      , { displacement := 12, targetCursor := 12, cursorClass := .inBounds }
      , { displacement := 24, targetCursor := 24, cursorClass := .inBounds }
      , { displacement := 32767, targetCursor := 32767, cursorClass := .atOrPastEnd } ] := by
  rfl

theorem th07_timeline_size_sweep_expected :
    th07TimelineSizeSweep =
      [ { displacement := -1, targetCursor := -1, cursorClass := .beforeBuffer }
      , { displacement := 0, targetCursor := 0, cursorClass := .nonProgress }
      , { displacement := 1, targetCursor := 1, cursorClass := .inBounds }
      , { displacement := 12, targetCursor := 12, cursorClass := .inBounds }
      , { displacement := 24, targetCursor := 24, cursorClass := .inBounds }
      , { displacement := 32767, targetCursor := 32767, cursorClass := .atOrPastEnd } ] := by
  rfl

theorem th08_timeline_size_sweep_expected :
    th08TimelineSizeSweep =
      [ { displacement := 0, targetCursor := 0, cursorClass := .nonProgress }
      , { displacement := 1, targetCursor := 1, cursorClass := .inBounds }
      , { displacement := 12, targetCursor := 12, cursorClass := .inBounds }
      , { displacement := 24, targetCursor := 24, cursorClass := .inBounds }
      , { displacement := 255, targetCursor := 255, cursorClass := .atOrPastEnd } ] := by
  rfl

theorem th06_raw_next_offset_sweep_expected :
    th06RawNextOffsetSweep =
      [ { displacement := -1, targetCursor := -1, cursorClass := .beforeBuffer }
      , { displacement := 0, targetCursor := 0, cursorClass := .nonProgress }
      , { displacement := 1, targetCursor := 1, cursorClass := .inBounds }
      , { displacement := 12, targetCursor := 12, cursorClass := .atOrPastEnd }
      , { displacement := 24, targetCursor := 24, cursorClass := .atOrPastEnd }
      , { displacement := 32767, targetCursor := 32767, cursorClass := .atOrPastEnd } ] := by
  rfl

theorem th07_raw_next_offset_sweep_expected :
    th07RawNextOffsetSweep =
      [ { displacement := -1, targetCursor := -1, cursorClass := .beforeBuffer }
      , { displacement := 0, targetCursor := 0, cursorClass := .nonProgress }
      , { displacement := 1, targetCursor := 1, cursorClass := .inBounds }
      , { displacement := 12, targetCursor := 12, cursorClass := .atOrPastEnd }
      , { displacement := 24, targetCursor := 24, cursorClass := .atOrPastEnd }
      , { displacement := 32767, targetCursor := 32767, cursorClass := .atOrPastEnd } ] := by
  rfl

theorem th08_raw_next_offset_sweep_expected :
    th08RawNextOffsetSweep =
      [ { displacement := -1, targetCursor := -1, cursorClass := .beforeBuffer }
      , { displacement := 0, targetCursor := 0, cursorClass := .nonProgress }
      , { displacement := 1, targetCursor := 1, cursorClass := .inBounds }
      , { displacement := 12, targetCursor := 12, cursorClass := .atOrPastEnd }
      , { displacement := 24, targetCursor := 24, cursorClass := .atOrPastEnd }
      , { displacement := 32767, targetCursor := 32767, cursorClass := .atOrPastEnd } ] := by
  rfl

theorem th06_jump_sweep_expected :
    th06JumpSweep =
      [ { displacement := -1, targetCursor := -1, cursorClass := .beforeBuffer }
      , { displacement := 0, targetCursor := 0, cursorClass := .nonProgress }
      , { displacement := 1, targetCursor := 1, cursorClass := .inBounds }
      , { displacement := 12, targetCursor := 12, cursorClass := .inBounds }
      , { displacement := 24, targetCursor := 24, cursorClass := .atOrPastEnd } ] := by
  rfl

theorem th07_jump_sweep_expected :
    th07JumpSweep =
      [ { displacement := -1, targetCursor := -1, cursorClass := .beforeBuffer }
      , { displacement := 0, targetCursor := 0, cursorClass := .nonProgress }
      , { displacement := 1, targetCursor := 1, cursorClass := .inBounds }
      , { displacement := 12, targetCursor := 12, cursorClass := .inBounds }
      , { displacement := 24, targetCursor := 24, cursorClass := .atOrPastEnd } ] := by
  rfl

theorem th08_jump_sweep_expected :
    th08JumpSweep =
      [ { displacement := -1, targetCursor := -1, cursorClass := .beforeBuffer }
      , { displacement := 0, targetCursor := 0, cursorClass := .nonProgress }
      , { displacement := 1, targetCursor := 1, cursorClass := .inBounds }
      , { displacement := 12, targetCursor := 12, cursorClass := .inBounds }
      , { displacement := 24, targetCursor := 24, cursorClass := .atOrPastEnd } ] := by
  rfl

end TouhouFormal.Search.Cursor
