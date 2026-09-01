import TouhouFormal.ECL.BulletPattern
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.BulletPattern

open TouhouFormal.ECL

def f32ZeroBits : Int := 0
def f32OneBits : Int := 0x3f800000
def f32TwoBits : Int := 0x40000000
def f32NegativeOneBits : Int := 0xbf800000
def f32QuietNaNBits : Int := 0x7fc00000

def bulletPatternOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape =>
      (rawShape.bulletPatternFamilies.map
        RawBulletPatternFamilyShape.opcodeCount).sum

def bulletPatternAimMode? (shape : HeaderShape) (opcode : Int) : Option Int :=
  match shape.rawInstrShape with
  | none => none
  | some rawShape =>
      (rawShape.findBulletPatternFamily? opcode).map
        RawBulletPatternFamilyMatch.aimMode

def outcomeEffect?
    (result : Except TouhouFormal.Fault RawBulletPatternOutcome) :
    Option RawBulletPatternEffect :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.effect

def outcomeDescriptor?
    (result : Except TouhouFormal.Fault RawBulletPatternOutcome) :
    Option RawBulletPatternDescriptor :=
  (outcomeEffect? result).bind RawBulletPatternEffect.descriptorWrite

def baseOperands : RawBulletPatternOperands :=
  { bulletType := { rawValue := 0, hostValue := 0 }
    color := { rawValue := 0, hostValue := 0 }
    count1 := { rawValue := 1, hostValue := 1 }
    count2 := { rawValue := 1, hostValue := 1 }
    speed1 := { rawValue := f32OneBits, hostValue := f32OneBits }
    speed2 := { rawValue := f32OneBits, hostValue := f32OneBits }
    primaryAngle := { rawValue := 0, hostValue := 0 }
    angleStep := { rawValue := 0, hostValue := 0 }
    transformFlagsRaw := 0
    floatResults :=
      { position := { x := 10, y := 20, z := 30 }
        normalizedPrimaryAngleBits := 0
        rankedSpeed1Bits := f32OneBits
        rankedSpeed2Bits := f32OneBits } }

def th06SuppressedPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH06.eclOpcodeSpawnBulletPatternFirst
    nextOffset := 44
    difficultyMask := some 1
    operandMask := none }

def th06SuppressedOperands : RawBulletPatternOperands :=
  { bulletType := { rawValue := 10000, hostValue := 99 }
    color := { rawValue := -10001, hostValue := 7 }
    count1 := { rawValue := -10001, hostValue := -4 }
    count2 := { rawValue := 2, hostValue := 99 }
    speed1 := { rawValue := f32ZeroBits, hostValue := f32ZeroBits }
    speed2 := { rawValue := f32OneBits, hostValue := f32OneBits }
    primaryAngle := { rawValue := 1176272896, hostValue := f32OneBits }
    angleStep := { rawValue := f32OneBits, hostValue := f32OneBits }
    transformFlagsRaw := 0x12345678
    floatResults :=
      { position := { x := 10, y := 20, z := 30 }
        normalizedPrimaryAngleBits := f32TwoBits
        rankedSpeed1Bits := f32NegativeOneBits
        rankedSpeed2Bits := f32NegativeOneBits }
    runtime :=
      { shootingGateEnabled := true
        rank := 32
        count2Low := 1
        count2High := 3 } }

def th06SuppressedOutcome : Except TouhouFormal.Fault RawBulletPatternOutcome :=
  rawBulletPatternStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 128
    th06SuppressedPrefix
    th06SuppressedOperands

def th07DeadPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeSpawnBulletPatternFirst
    nextOffset := 44
    difficultyMask := some 1
    operandMask := none }

def th07DeadOutcome : Except TouhouFormal.Fault RawBulletPatternOutcome :=
  rawBulletPatternStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 128
    th07DeadPrefix
    { baseOperands with runtime := { enemyLife := 0 } }

def th07SpellcardPrefix : RawInstrPrefix :=
  { th07DeadPrefix with
    opcode := TouhouFormal.TH07.eclOpcodeSpawnBulletPatternLast
    operandMask := some 0 }

def th07SpellcardOutcome : Except TouhouFormal.Fault RawBulletPatternOutcome :=
  rawBulletPatternStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 128
    th07SpellcardPrefix
    { baseOperands with
      count1 := { rawValue := 0, hostValue := 99 }
      count2 := { rawValue := -2, hostValue := 99 }
      speed1 := { rawValue := f32NegativeOneBits, hostValue := 0 }
      speed2 := { rawValue := f32NegativeOneBits, hostValue := 0 }
      primaryAngle := { rawValue := f32TwoBits, hostValue := 0 }
      floatResults :=
        { position := { x := 1, y := 2, z := 3 }
          normalizedPrimaryAngleBits := 99
          rankedSpeed1Bits := f32OneBits
          rankedSpeed2Bits := f32OneBits }
      runtime :=
        { enemyLife := 1
          spellcardActive := true
          rank := 32
          count1Low := 10
          count1High := 20
          count2Low := 10
          count2High := 20 } }

def th08DeferredPrefix : RawInstrPrefix :=
  { fileOffset := 40
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeSpawnBulletPatternFirst
    nextOffset := 44
    difficultyMask := some 1
    operandMask := none }

def th08DeferredOutcome : Except TouhouFormal.Fault RawBulletPatternOutcome :=
  rawBulletPatternStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 80
    th08DeferredPrefix
    { baseOperands with
      runtime := { enemyLife := 1, shootingGateEnabled := true } }

def th08AlignmentFilteredOutcome :
    Except TouhouFormal.Fault RawBulletPatternOutcome :=
  rawBulletPatternStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 128
    { th08DeferredPrefix with fileOffset := 0 }
    { baseOperands with
      transformFlagsRaw := 0x8000
      runtime := { enemyLife := 1, enemyYoukaiAligned := false } }

def th08DistanceFilteredOutcome :
    Except TouhouFormal.Fault RawBulletPatternOutcome :=
  rawBulletPatternStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 128
    { th08DeferredPrefix with fileOffset := 0 }
    { baseOperands with
      runtime :=
        { enemyLife := 1
          minimumPlayerDistancePositive := true
          playerInsideMinimumDistance := true } }

def th08SpawnPrefix : RawInstrPrefix :=
  { th08DeferredPrefix with
    fileOffset := 0
    opcode := TouhouFormal.TH08.eclOpcodeSpawnBulletPatternLast
    operandMask := some 0 }

def th08SpawnOutcome : Except TouhouFormal.Fault RawBulletPatternOutcome :=
  rawBulletPatternStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 128
    th08SpawnPrefix
    { baseOperands with
      bulletType := { rawValue := 0xffff, hostValue := 0 }
      count1 := { rawValue := 32767, hostValue := 0 }
      speed1 := { rawValue := f32NegativeOneBits, hostValue := 0 }
      speed2 := { rawValue := f32OneBits, hostValue := 0 }
      floatResults :=
        { position := { x := 4, y := 5, z := 6 }
          normalizedPrimaryAngleBits := 0
          rankedSpeed1Bits := f32NegativeOneBits
          rankedSpeed2Bits := f32QuietNaNBits }
      runtime :=
        { enemyLife := 1
          rank := 0
          count1Low := 1
          count1High := 1 } }

theorem signed_word16_round_trip_negative_one :
    TouhouFormal.word16BitsToInt 0xffff = -1 := by
  rfl

theorem f32_negative_one_is_below_minimum_speed :
    TouhouFormal.f32LessThanBits
      f32NegativeOneBits bulletPatternMinimumSpeedBits = true := by
  rfl

theorem f32_nan_does_not_trigger_ordered_clamp :
    TouhouFormal.f32LessThanBits
      f32QuietNaNBits bulletPatternMinimumSpeedBits = false := by
  rfl

theorem rank_integer_scaling_uses_c_truncation_toward_zero :
    bulletPatternRankIntAdjustment 1 0 (-1) = 0 := by
  rfl

theorem th06_bullet_pattern_profile_count :
    bulletPatternOpcodeCount TouhouFormal.TH06.headerShape = 9 := by
  rfl

theorem th07_bullet_pattern_profile_count :
    bulletPatternOpcodeCount TouhouFormal.TH07.headerShape = 9 := by
  rfl

theorem th08_bullet_pattern_profile_count :
    bulletPatternOpcodeCount TouhouFormal.TH08.headerShape = 9 := by
  rfl

theorem th06_first_pattern_uses_aim_mode_zero :
    bulletPatternAimMode?
      TouhouFormal.TH06.headerShape
      TouhouFormal.TH06.eclOpcodeSpawnBulletPatternFirst = some 0 := by
  rfl

theorem th08_last_pattern_uses_aim_mode_eight :
    bulletPatternAimMode?
      TouhouFormal.TH08.headerShape
      TouhouFormal.TH08.eclOpcodeSpawnBulletPatternLast = some 8 := by
  rfl

theorem th06_disabled_shooting_keeps_descriptor_write :
    (outcomeEffect? th06SuppressedOutcome).map
      (fun effect =>
        (effect.disposition, effect.descriptorWrite.isSome, effect.spawnCall)) =
      some (.spawnSuppressed, true, false) := by
  rfl

theorem th06_pattern_preserves_raw_type_but_resolves_color :
    (outcomeDescriptor? th06SuppressedOutcome).map
      (fun descriptor => (descriptor.bulletType, descriptor.color)) =
      some (10000, 7) := by
  rfl

theorem th06_pattern_applies_count_clamp_and_i16_write :
    (outcomeDescriptor? th06SuppressedOutcome).map
      (fun descriptor => (descriptor.count1, descriptor.count2)) =
      some (1, 5) := by
  rfl

theorem th06_pattern_normalizes_angle_and_clamps_ranked_speed2 :
    (outcomeDescriptor? th06SuppressedOutcome).map
      (fun descriptor =>
        (descriptor.primaryAngleBits,
          descriptor.speed1Bits,
          descriptor.speed2Bits)) =
      some (f32TwoBits, f32ZeroBits, bulletPatternMinimumSpeedBits) := by
  rfl

theorem th07_dead_gate_precedes_missing_operand_mask_fault :
    (outcomeEffect? th07DeadOutcome).map RawBulletPatternEffect.disposition =
      some .skippedDeadEnemy := by
  rfl

theorem th07_spellcard_skips_rank_and_clamps :
    (outcomeDescriptor? th07SpellcardOutcome).map
      (fun descriptor =>
        (descriptor.count1,
          descriptor.count2,
          descriptor.speed1Bits,
          descriptor.speed2Bits,
          descriptor.primaryAngleBits)) =
      some (0, -2, f32NegativeOneBits, f32NegativeOneBits, f32TwoBits) := by
  rfl

theorem th08_defer_gate_precedes_resolution_and_records_oob_copy :
    ((outcomeEffect? th08DeferredOutcome).bind
      RawBulletPatternEffect.pendingInstructionWrite).map
        (fun pending =>
          (pending.byteCount,
            pending.sourceWithinBuffer,
            pending.rawPrefix.operandMask)) =
      some (0x2c, false, none) := by
  rfl

theorem th08_alignment_filter_precedes_resolution :
    (outcomeEffect? th08AlignmentFilteredOutcome).map
      RawBulletPatternEffect.disposition =
      some .filteredPlayerAlignment := by
  rfl

theorem th08_distance_filter_precedes_resolution :
    (outcomeEffect? th08DistanceFilteredOutcome).map
      RawBulletPatternEffect.disposition =
      some .filteredMinimumPlayerDistance := by
  rfl

theorem th08_descriptor_truncates_type_and_ranked_count_to_i16 :
    (outcomeDescriptor? th08SpawnOutcome).map
      (fun descriptor =>
        (descriptor.bulletType, descriptor.count1, descriptor.aimMode)) =
      some (-1, 1, 8) := by
  rfl

theorem th08_ordered_clamp_preserves_nan_rank_result :
    (outcomeDescriptor? th08SpawnOutcome).map
      (fun descriptor => (descriptor.speed1Bits, descriptor.speed2Bits)) =
      some (bulletPatternMinimumSpeedBits, f32QuietNaNBits) := by
  rfl

end TouhouFormal.Search.BulletPattern
