import TouhouFormal.ECL.Shooting
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.Shooting

open TouhouFormal.ECL

def shootingOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.shootingOps.length

def outcomeEffect? (result : Except TouhouFormal.Fault RawShootingOutcome) :
    Option RawShootingEffect :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.effect

def th06ZeroIntervalPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH06.eclOpcodeSetShootInterval
    nextOffset := 16
    difficultyMask := some 1
    operandMask := none }

def th06ZeroIntervalOutcome : Except TouhouFormal.Fault RawShootingOutcome :=
  rawShootingStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 64
    th06ZeroIntervalPrefix
    { intRaw := 0, rank := 32 }

def th07ZeroIntervalPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeSetShootInterval
    nextOffset := 16
    difficultyMask := some 1
    operandMask := some 1 }

def th07ZeroIntervalOutcome : Except TouhouFormal.Fault RawShootingOutcome :=
  rawShootingStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    th07ZeroIntervalPrefix
    { intRaw := 10000, intHost := 0, rank := 32 }

def th08RandomIntervalPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeSetRandomShootInterval
    nextOffset := 16
    difficultyMask := some 1
    operandMask := some 0 }

def th08RandomIntervalOutcome : Except TouhouFormal.Fault RawShootingOutcome :=
  rawShootingStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08RandomIntervalPrefix
    { intRaw := 50, rank := 32, rngWord := 43 }

def th06OffsetPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH06.eclOpcodeSetShootOffset
    nextOffset := 24
    difficultyMask := some 1
    operandMask := none }

def th06OffsetOutcome : Except TouhouFormal.Fault RawShootingOutcome :=
  rawShootingStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 64
    th06OffsetPrefix
    { floatInputs :=
        [ { rawValue := 3323741184, hostValue := 11 },
          { rawValue := 3323741184, hostValue := 12 },
          { rawValue := 3323741184, hostValue := 13 } ] }

def th08OffsetPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeSetShootOffset
    nextOffset := 20
    difficultyMask := some 1
    operandMask := some 3 }

def th08OffsetOutcome : Except TouhouFormal.Fault RawShootingOutcome :=
  rawShootingStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08OffsetPrefix
    { floatInputs :=
        [ { rawValue := 1176272896, hostValue := 21 },
          { rawValue := 1176272896, hostValue := 22 } ] }

def th07DisablePrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeDisableShooting
    nextOffset := 12
    difficultyMask := some 1
    operandMask := some 0 }

def th07DisableOutcome : Except TouhouFormal.Fault RawShootingOutcome :=
  rawShootingStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    th07DisablePrefix
    {}

def th08DisablePrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeDisableShooting
    nextOffset := 12
    difficultyMask := some 1
    operandMask := some 0 }

def th08DisableOutcome : Except TouhouFormal.Fault RawShootingOutcome :=
  rawShootingStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08DisablePrefix
    {}

theorem shoot_interval_rank_zero_uses_upper_endpoint :
    shootIntervalAfterRank 50 0 = 60 := by
  rfl

theorem shoot_interval_rank_32_uses_lower_endpoint :
    shootIntervalAfterRank 50 32 = 40 := by
  rfl

theorem th06_shooting_profile_count :
    shootingOpcodeCount TouhouFormal.TH06.headerShape = 6 := by
  rfl

theorem th07_shooting_profile_count :
    shootingOpcodeCount TouhouFormal.TH07.headerShape = 6 := by
  rfl

theorem th08_shooting_profile_count :
    shootingOpcodeCount TouhouFormal.TH08.headerShape = 6 := by
  rfl

theorem th06_zero_interval_still_resets_timer :
    (outcomeEffect? th06ZeroIntervalOutcome).bind
      (fun effect => effect.shootIntervalTimerWrite) =
      some { current := 0, subFrameBits := 0, previous := -999 } := by
  rfl

theorem th07_zero_interval_leaves_timer_unchanged :
    (outcomeEffect? th07ZeroIntervalOutcome).bind
      (fun effect => effect.shootIntervalTimerWrite) = none := by
  rfl

theorem th08_random_interval_uses_ranked_range :
    (outcomeEffect? th08RandomIntervalOutcome).map
      (fun effect =>
        (effect.shootIntervalWrite, effect.shootIntervalTimerWrite)) =
      some
        (some 40,
          some { current := 3, subFrameBits := 0, previous := -999 }) := by
  rfl

theorem th06_offset_always_resolves_getvarfloat :
    (outcomeEffect? th06OffsetOutcome).bind
      (fun effect => effect.shootOffsetWrite) =
      some { x := 11, y := 12, z := 13 } := by
  rfl

theorem th08_offset_forces_zero_z :
    (outcomeEffect? th08OffsetOutcome).bind
      (fun effect => effect.shootOffsetWrite) =
      some { x := 21, y := 22, z := 0 } := by
  rfl

theorem th07_disable_uses_suppress_spawn_gate :
    (outcomeEffect? th07DisableOutcome).bind
      (fun effect => effect.shootingGateWrite) =
      some { policy := .suppressSpawn, enabled := true } := by
  rfl

theorem th08_disable_uses_defer_pattern_gate :
    (outcomeEffect? th08DisableOutcome).bind
      (fun effect => effect.shootingGateWrite) =
      some { policy := .deferPattern, enabled := true } := by
  rfl

end TouhouFormal.Search.Shooting
