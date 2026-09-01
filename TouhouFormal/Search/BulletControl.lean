import TouhouFormal.ECL.BulletControl
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.BulletControl

open TouhouFormal.ECL

def bulletControlOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.bulletControlOps.length

def outcomeEffect?
    (result : Except TouhouFormal.Fault RawBulletControlOutcome) :
    Option RawBulletControlEffect :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.effect

def outcomePrepared?
    (result : Except TouhouFormal.Fault RawBulletControlOutcome) :
    Option RawBulletControlPrepared :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.prepared

def mkPrefix (opcode : Int) (operandMask : Option Int := none) :
    RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := opcode
    nextOffset := 24
    difficultyMask := some 1
    operandMask := operandMask }

def th06CancelOutcome : Except TouhouFormal.Fault RawBulletControlOutcome :=
  rawBulletControlStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH06.eclOpcodeBulletCancel)
    {}

def th06SoundNegativeOutcome :
    Except TouhouFormal.Fault RawBulletControlOutcome :=
  rawBulletControlStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH06.eclOpcodeBulletSound)
    { intInputs := [ { rawValue := -1 } ] }

def th06RankOutcome : Except TouhouFormal.Fault RawBulletControlOutcome :=
  rawBulletControlStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH06.eclOpcodeBulletRankInfluence)
    { floatInputs :=
        [ { rawBits := 1065353216 },
          { rawBits := 1073741824 } ]
      intInputs :=
        [ { rawValue := 32768 },
          { rawValue := -1 },
          { rawValue := 65535 },
          { rawValue := 2 } ] }

def th07SoundPositiveOutcome :
    Except TouhouFormal.Fault RawBulletControlOutcome :=
  rawBulletControlStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH07.eclOpcodeSetBulletSound (some 3))
    { intInputs :=
        [ { rawValue := 10000, hostValue := 9 },
          { rawValue := 10000, hostValue := 10 },
          { rawValue := 10001, hostValue := 11 } ] }

def th07SoundNegativeOutcome :
    Except TouhouFormal.Fault RawBulletControlOutcome :=
  rawBulletControlStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH07.eclOpcodeSetBulletSound (some 3))
    { intInputs :=
        [ { rawValue := 10000, hostValue := -1 },
          { rawValue := 10001, hostValue := 12 } ] }

def th07RadiusOutcome : Except TouhouFormal.Fault RawBulletControlOutcome :=
  rawBulletControlStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH07.eclOpcodeRemoveBulletsRadius (some 1))
    { floatInputs :=
        [ { rawBits := 1176256512, hostBits := 123 } ] }

def th07RankOutcome : Except TouhouFormal.Fault RawBulletControlOutcome :=
  rawBulletControlStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH07.eclOpcodeSetBulletRankParams (some 63))
    { floatInputs :=
        [ { rawBits := 1176256512, hostBits := 111 },
          { rawBits := 1176256513, hostBits := 222 } ]
      intInputs :=
        [ { rawValue := 10002, hostValue := 32768 },
          { rawValue := 10003, hostValue := 32767 },
          { rawValue := 10004, hostValue := 65535 },
          { rawValue := 10005, hostValue := -32769 } ] }

def th08ClearTransitionOutcome :
    Except TouhouFormal.Fault RawBulletControlOutcome :=
  rawBulletControlStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH08.eclOpcodeClearBulletsForTransition)
    {}

def th08SoundPositiveOutcome :
    Except TouhouFormal.Fault RawBulletControlOutcome :=
  rawBulletControlStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH08.eclOpcodeSetBulletSound (some 3))
    { intInputs :=
        [ { rawValue := 10000, hostValue := 13 },
          { rawValue := 10000, hostValue := 14 },
          { rawValue := 10001, hostValue := 15 } ] }

def th08RankOutcome : Except TouhouFormal.Fault RawBulletControlOutcome :=
  rawBulletControlStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH08.eclOpcodeSetBulletRankInfluence (some 63))
    { floatInputs :=
        [ { rawBits := 1176256512, hostBits := 333 },
          { rawBits := 1176256513, hostBits := 444 } ]
      intInputs :=
        [ { rawValue := 10002, hostValue := -32769 },
          { rawValue := 10003, hostValue := 65535 },
          { rawValue := 10004, hostValue := 32768 },
          { rawValue := 10005, hostValue := 32767 } ] }

theorem th06_bullet_control_profile_count :
    bulletControlOpcodeCount TouhouFormal.TH06.headerShape = 3 := by
  rfl

theorem th07_bullet_control_profile_count :
    bulletControlOpcodeCount TouhouFormal.TH07.headerShape = 5 := by
  rfl

theorem th08_bullet_control_profile_count :
    bulletControlOpcodeCount TouhouFormal.TH08.headerShape = 3 := by
  rfl

theorem th06_cancel_turns_all_bullets_into_points :
    (outcomeEffect? th06CancelOutcome).bind
      (fun effect => effect.clear) =
      some { mode := .turnAllIntoPoints } := by
  rfl

theorem th06_negative_sound_clears_spawn_sound_flag :
    (outcomeEffect? th06SoundNegativeOutcome).bind
      (fun effect => effect.sound) =
      some
        { target := .enemyBulletProps
          spawnSound := none
          flagMask := 0x200
          flagEnabled := false
          overrideSound := none } := by
  rfl

theorem th06_rank_counts_use_signed_i16_truncation :
    (outcomeEffect? th06RankOutcome).bind
      (fun effect => effect.rankInfluence) =
      some
        { speedLowBits := 1065353216
          speedHighBits := 1073741824
          count1Low := -32768
          count1High := -1
          count2Low := -1
          count2High := 2 } := by
  rfl

theorem th07_sound_positive_repeats_primary_operand_before_override :
    (outcomePrepared? th07SoundPositiveOutcome).map
      (fun prepared =>
        prepared.intResolutions.map
          (fun input => (input.shape.operandIndex, input.resolution.value))) =
      some [(0, 9), (0, 10), (1, 11)] := by
  rfl

theorem th07_sound_positive_sets_override :
    (outcomeEffect? th07SoundPositiveOutcome).bind
      (fun effect => effect.sound) =
      some
        { target := .enemyBulletProps
          spawnSound := some 10
          flagMask := 0x200
          flagEnabled := true
          overrideSound := some 11 } := by
  rfl

theorem th07_sound_negative_skips_repeated_primary_read :
    (outcomePrepared? th07SoundNegativeOutcome).map
      (fun prepared =>
        prepared.intResolutions.map
          (fun input => (input.shape.operandIndex, input.resolution.value))) =
      some [(0, -1), (1, 12)] := by
  rfl

theorem th07_radius_uses_resolved_float_operand :
    (outcomeEffect? th07RadiusOutcome).bind
      (fun effect => effect.clear) =
      some { mode := .removeRadius, radiusBits := some 123 } := by
  rfl

theorem th07_rank_influence_resolves_operands_and_truncates_counts :
    (outcomeEffect? th07RankOutcome).bind
      (fun effect => effect.rankInfluence) =
      some
        { speedLowBits := 111
          speedHighBits := 222
          count1Low := -32768
          count1High := 32767
          count2Low := -1
          count2High := 32767 } := by
  rfl

theorem th08_clear_transition_has_distinct_clear_mode :
    (outcomeEffect? th08ClearTransitionOutcome).bind
      (fun effect => effect.clear) =
      some { mode := .clearForTransition } := by
  rfl

theorem th08_sound_targets_spawn_descriptor :
    (outcomeEffect? th08SoundPositiveOutcome).bind
      (fun effect => effect.sound) =
      some
        { target := .bulletSpawnDescriptor
          spawnSound := some 14
          flagMask := 0x200
          flagEnabled := true
          overrideSound := some 15 } := by
  rfl

theorem th08_sound_positive_repeats_primary_operand_before_override :
    (outcomePrepared? th08SoundPositiveOutcome).map
      (fun prepared =>
        prepared.intResolutions.map
          (fun input => (input.shape.operandIndex, input.resolution.value))) =
      some [(0, 13), (0, 14), (1, 15)] := by
  rfl

theorem th08_rank_influence_resolves_operands_and_truncates_counts :
    (outcomeEffect? th08RankOutcome).bind
      (fun effect => effect.rankInfluence) =
      some
        { speedLowBits := 333
          speedHighBits := 444
          count1Low := 32767
          count1High := -1
          count2Low := -32768
          count2High := 32767 } := by
  rfl

end TouhouFormal.Search.BulletControl
