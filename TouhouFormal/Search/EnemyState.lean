import TouhouFormal.ECL.EnemyState
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.EnemyState

open TouhouFormal.ECL

def enemyStateOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.enemyStateOps.length

def outcomeAction? (result : Except TouhouFormal.Fault RawEnemyStateOutcome) :
    Option RawEnemyStateAction :=
  match result with
  | .error _ => none
  | .ok outcome => some outcome.action

def outcomeEffect? (result : Except TouhouFormal.Fault RawEnemyStateOutcome) :
    Option RawEnemyStateEffect :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.effect

def fieldValue?
    (effect : RawEnemyStateEffect)
    (field : RawEnemyStateField) : Option Int :=
  (effect.fieldWrites.find? (fun write => write.field == field)).map
    (fun write => write.value)

def th06HitboxPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH06.eclOpcodeSetHitbox
    nextOffset := 24
    difficultyMask := some 1
    operandMask := none }

def th06HitboxOutcome : Except TouhouFormal.Fault RawEnemyStateOutcome :=
  rawEnemyStateStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 64
    th06HitboxPrefix
    { floatInputs :=
        [ { rawValue := 11, hostValue := 101 },
          { rawValue := 12, hostValue := 102 },
          { rawValue := 13, hostValue := 103 } ] }

def th06DeathModePrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH06.eclOpcodeSetDeathMode
    nextOffset := 16
    difficultyMask := some 1
    operandMask := none }

def th06DeathModeOutcome : Except TouhouFormal.Fault RawEnemyStateOutcome :=
  rawEnemyStateStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 64
    th06DeathModePrefix
    { intRaw := 15 }

def th07HitboxPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeSetHitboxSize
    nextOffset := 24
    difficultyMask := some 1
    operandMask := some 7 }

def th07HitboxOutcome : Except TouhouFormal.Fault RawEnemyStateOutcome :=
  rawEnemyStateStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    th07HitboxPrefix
    { floatInputs :=
        [ { rawValue := 1176260608, hostValue := 101 },
          { rawValue := 1176260608, hostValue := 102 },
          { rawValue := 1176260608, hostValue := 103 } ] }

def th07DeathModePrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeSetDeathType
    nextOffset := 16
    difficultyMask := some 1
    operandMask := some 1 }

def th07DeathModeOutcome : Except TouhouFormal.Fault RawEnemyStateOutcome :=
  rawEnemyStateStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    th07DeathModePrefix
    { intRaw := 255, intHost := 0 }

def th08ReplaceFlagsPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeReplaceEnemyFlags
    nextOffset := 16
    difficultyMask := some 1
    operandMask := some 1 }

def th08ReplaceFlagsOutcome : Except TouhouFormal.Fault RawEnemyStateOutcome :=
  rawEnemyStateStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08ReplaceFlagsPrefix
    { intRaw := 10000, intHost := 43 }

def th08DisableCollisionPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeDisableEnemyFlags
    nextOffset := 16
    difficultyMask := some 1
    operandMask := some 0 }

def th08DisableCollisionOutcome : Except TouhouFormal.Fault RawEnemyStateOutcome :=
  rawEnemyStateStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08DisableCollisionPrefix
    { intRaw := 2, alignmentEffectPresent := true }

def th08SuppressedDeathModePrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeSetDeathMode
    nextOffset := 16
    difficultyMask := some 1
    operandMask := some 0 }

def th08SuppressedDeathModeOutcome :
    Except TouhouFormal.Fault RawEnemyStateOutcome :=
  rawEnemyStateStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08SuppressedDeathModePrefix
    { intRaw := 7, presentationWritesAllowed := false }

theorem th06_enemy_state_profile_count :
    enemyStateOpcodeCount TouhouFormal.TH06.headerShape = 5 := by
  rfl

theorem th07_enemy_state_profile_count :
    enemyStateOpcodeCount TouhouFormal.TH07.headerShape = 7 := by
  rfl

theorem th08_enemy_state_profile_count :
    enemyStateOpcodeCount TouhouFormal.TH08.headerShape = 6 := by
  rfl

theorem th06_hitbox_uses_raw_float_bits :
    (outcomeEffect? th06HitboxOutcome).bind
      (fun effect => effect.primaryHitboxWrite) =
      some { x := 11, y := 12, z := some 13 } := by
  rfl

theorem th06_death_mode_truncates_to_three_bits :
    (outcomeEffect? th06DeathModeOutcome).bind
      (fun effect => fieldValue? effect .deathMode) = some 7 := by
  rfl

theorem th07_hitbox_resolves_operand_flags :
    (outcomeEffect? th07HitboxOutcome).bind
      (fun effect => effect.primaryHitboxWrite) =
      some { x := 101, y := 102, z := some 103 } := by
  rfl

theorem th07_death_mode_reads_raw_byte_not_resolved_int :
    (outcomeEffect? th07DeathModeOutcome).bind
      (fun effect => fieldValue? effect .deathMode) = some 7 := by
  rfl

theorem th08_replace_mask_inverts_accepts_damage :
    (outcomeEffect? th08ReplaceFlagsOutcome).bind
      (fun effect => fieldValue? effect .acceptsDamage) = some 0 := by
  rfl

theorem th08_replace_mask_sets_damageable_from_inverted_bit_two :
    (outcomeEffect? th08ReplaceFlagsOutcome).bind
      (fun effect => fieldValue? effect .damageable) = some 1 := by
  rfl

theorem th08_disable_collision_mirrors_alignment_effect :
    (outcomeEffect? th08DisableCollisionOutcome).bind
      (fun effect => effect.alignmentEffectCollisionWrite) = some false := by
  rfl

theorem th08_death_mode_can_be_presentation_suppressed :
    (outcomeEffect? th08SuppressedDeathModeOutcome).map
      (fun effect => effect.suppressedByPresentationPolicy) = some true := by
  rfl

theorem th08_suppressed_death_mode_has_no_field_write :
    (outcomeEffect? th08SuppressedDeathModeOutcome).map
      (fun effect => effect.fieldWrites) = some [] := by
  rfl

end TouhouFormal.Search.EnemyState
