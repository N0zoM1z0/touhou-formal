import TouhouFormal.Core.Cursor
import TouhouFormal.TH06.Raw
import TouhouFormal.TH07

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

def th06JumpSweep : List CursorSweepCase :=
  cursorSweep 0 TouhouFormal.TH06.rawJumpMinusOneInstrBytes.size smallDisplacements

def th07JumpSweep : List CursorSweepCase :=
  cursorSweep 0 TouhouFormal.TH07.rawJumpMinusOneInstrBytes.size smallDisplacements

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

end TouhouFormal.Search.Cursor
