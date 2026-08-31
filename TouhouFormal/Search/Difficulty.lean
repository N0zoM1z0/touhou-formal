import TouhouFormal.ECL.Difficulty
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.Difficulty

structure RawDifficultyProbe where
  title : String
  instructionMask : Nat
  activeMask : Nat
  overrideMask : Nat
  executes : Option Bool
deriving Repr, DecidableEq

def rawDifficultyProbe
    (shape : TouhouFormal.ECL.HeaderShape)
    (instructionMask activeMask overrideMask maxBits : Nat) : RawDifficultyProbe :=
  { title := shape.title
    instructionMask := instructionMask
    activeMask := activeMask
    overrideMask := overrideMask
    executes :=
      TouhouFormal.ECL.rawInstrShouldExecute?
        shape
        instructionMask
        activeMask
        overrideMask
        maxBits }

def rawDifficultyOverrideDeltaSweep : List RawDifficultyProbe :=
  [ rawDifficultyProbe TouhouFormal.TH06.headerShape 1 1 2 8
  , rawDifficultyProbe TouhouFormal.TH07.headerShape 1 1 2 8
  , rawDifficultyProbe TouhouFormal.TH08.headerShape 1 1 2 8
  , rawDifficultyProbe TouhouFormal.TH08.headerShape 3 1 2 8 ]

theorem th06_raw_difficulty_intersects_active :
    TouhouFormal.ECL.rawInstrShouldExecute? TouhouFormal.TH06.headerShape 1 1 2 8 =
      some true := by
  rfl

theorem th07_raw_difficulty_intersects_active :
    TouhouFormal.ECL.rawInstrShouldExecute? TouhouFormal.TH07.headerShape 1 1 2 8 =
      some true := by
  rfl

theorem th08_raw_difficulty_override_requires_all_bits :
    TouhouFormal.ECL.rawInstrShouldExecute? TouhouFormal.TH08.headerShape 1 1 2 8 =
      some false := by
  rfl

theorem th08_raw_difficulty_override_executes_when_covered :
    TouhouFormal.ECL.rawInstrShouldExecute? TouhouFormal.TH08.headerShape 3 1 2 8 =
      some true := by
  rfl

theorem raw_difficulty_override_delta_sweep_expected :
    rawDifficultyOverrideDeltaSweep =
      [ { title := "TH06", instructionMask := 1, activeMask := 1, overrideMask := 2, executes := some true }
      , { title := "TH07", instructionMask := 1, activeMask := 1, overrideMask := 2, executes := some true }
      , { title := "TH08", instructionMask := 1, activeMask := 1, overrideMask := 2, executes := some false }
      , { title := "TH08", instructionMask := 3, activeMask := 1, overrideMask := 2, executes := some true } ] := by
  rfl

end TouhouFormal.Search.Difficulty
