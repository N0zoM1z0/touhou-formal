import TouhouFormal.ECL.BossLifecycle
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.BossLifecycle

open TouhouFormal.ECL

def bossLifecycleOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.bossLifecycleOps.length

def outcomeEffect?
    (result : Except TouhouFormal.Fault RawBossLifecycleOutcome) :
    Option RawBossLifecycleEffect :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.effect

def outcomeFault?
    (result : Except TouhouFormal.Fault RawBossLifecycleOutcome) :
    Option TouhouFormal.Fault :=
  match result with
  | .error fault => some fault
  | .ok _ => none

def outcomeBossSet?
    (result : Except TouhouFormal.Fault RawBossLifecycleOutcome) :
    Option RawBossSetEffect :=
  (outcomeEffect? result).bind (fun effect => effect.bossSet)

def outcomeBossClear?
    (result : Except TouhouFormal.Fault RawBossLifecycleOutcome) :
    Option RawBossClearEffect :=
  (outcomeEffect? result).bind (fun effect => effect.bossClear)

def outcomeSpellStart?
    (result : Except TouhouFormal.Fault RawBossLifecycleOutcome) :
    Option RawSpellStartEffect :=
  (outcomeEffect? result).bind (fun effect => effect.spellStart)

def outcomeBossGauge?
    (result : Except TouhouFormal.Fault RawBossLifecycleOutcome) :
    Option RawBossGaugeEffect :=
  (outcomeEffect? result).bind (fun effect => effect.bossGauge)

def outcomeLifeMarker?
    (result : Except TouhouFormal.Fault RawBossLifecycleOutcome) :
    Option RawBossLifeMarkerEffect :=
  (outcomeEffect? result).bind (fun effect => effect.lifeMarker)

def outcomeFlag?
    (result : Except TouhouFormal.Fault RawBossLifecycleOutcome) :
    Option RawBossLifecycleFlagEffect :=
  (outcomeEffect? result).bind (fun effect => effect.flagWrite)

def outcomeRunInterrupt?
    (result : Except TouhouFormal.Fault RawBossLifecycleOutcome) :
    Option RawBossRunInterruptEffect :=
  (outcomeEffect? result).bind (fun effect => effect.runInterrupt)

def outcomeStoredVector?
    (result : Except TouhouFormal.Fault RawBossLifecycleOutcome) :
    Option RawSpellcardStoredVectorEffect :=
  (outcomeEffect? result).bind (fun effect => effect.storedVector)

def th06BeginSpellPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH06.eclOpcodeSpellcardStart
    nextOffset := 64
    difficultyMask := some 1
    operandMask := none }

def th06BeginSpellOutcome : Except TouhouFormal.Fault RawBossLifecycleOutcome :=
  rawBossLifecycleStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 128
    th06BeginSpellPrefix
    { intInputs :=
        [ { rawValue := 12 },
          { rawValue := 65535 } ] }

def th07SetBossPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeSetBoss
    nextOffset := 16
    difficultyMask := some 1
    operandMask := some 1 }

def th07SetBossOutcome : Except TouhouFormal.Fault RawBossLifecycleOutcome :=
  rawBossLifecycleStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    th07SetBossPrefix
    { intInputs := [ { rawValue := 10000, hostValue := 7 } ] }

def th07ClearBossPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeSetBoss
    nextOffset := 16
    difficultyMask := some 1
    operandMask := some 1 }

def th07ClearBossOutcome : Except TouhouFormal.Fault RawBossLifecycleOutcome :=
  rawBossLifecycleStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    th07ClearBossPrefix
    { intInputs := [ { rawValue := 10000, hostValue := -1 } ]
      currentBossSlot := 5 }

def th07RunInterruptPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeSetBossRunInterrupt
    nextOffset := 20
    difficultyMask := some 1
    operandMask := some 3 }

def th07RunInterruptOutcome :
    Except TouhouFormal.Fault RawBossLifecycleOutcome :=
  rawBossLifecycleStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    th07RunInterruptPrefix
    { intInputs :=
        [ { rawValue := 10000, hostValue := 1 },
          { rawValue := 10001, hostValue := 42 } ]
      bossPointerPresent := false }

def th08SetBossPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeSetBoss
    nextOffset := 16
    difficultyMask := some 1
    operandMask := some 1 }

def th08SetBossSlot8Outcome :
    Except TouhouFormal.Fault RawBossLifecycleOutcome :=
  rawBossLifecycleStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08SetBossPrefix
    { intInputs := [ { rawValue := 10000, hostValue := 8 } ] }

def th08SetBossSlot0Outcome :
    Except TouhouFormal.Fault RawBossLifecycleOutcome :=
  rawBossLifecycleStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08SetBossPrefix
    { intInputs := [ { rawValue := 10000, hostValue := 0 } ] }

def th08ClearBossTruncatedPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeSetBoss
    nextOffset := 16
    difficultyMask := some 1
    operandMask := some 1 }

def th08ClearBossTruncatedOutcome :
    Except TouhouFormal.Fault RawBossLifecycleOutcome :=
  rawBossLifecycleStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08ClearBossTruncatedPrefix
    { intInputs := [ { rawValue := 10000, hostValue := -1 } ]
      currentBossSlot := 300 }

def th08GaugePrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeSetBossGauge
    nextOffset := 28
    difficultyMask := some 1
    operandMask := some 15 }

def th08GaugeZeroMaxLifeOutcome :
    Except TouhouFormal.Fault RawBossLifecycleOutcome :=
  rawBossLifecycleStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08GaugePrefix
    { intInputs :=
        [ { rawValue := 10000, hostValue := 1 },
          { rawValue := 10001, hostValue := 10 },
          { rawValue := 10002, hostValue := 20 },
          { rawValue := 10003, hostValue := 3 } ]
      maxLife := 0 }

def th08EffectTrackingNonzeroPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeSetSpellcardEffectTracking
    nextOffset := 28
    difficultyMask := some 1
    operandMask := some 1 }

def th08EffectTrackingNonzeroOutcome :
    Except TouhouFormal.Fault RawBossLifecycleOutcome :=
  rawBossLifecycleStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08EffectTrackingNonzeroPrefix
    { intInputs := [ { rawValue := 10000, hostValue := 1 } ] }

def th08EffectTrackingZeroPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeSetSpellcardEffectTracking
    nextOffset := 28
    difficultyMask := some 1
    operandMask := some 15 }

def th08EffectTrackingZeroOutcome :
    Except TouhouFormal.Fault RawBossLifecycleOutcome :=
  rawBossLifecycleStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08EffectTrackingZeroPrefix
    { intInputs := [ { rawValue := 10000, hostValue := 0 } ]
      floatInputs :=
        [ { rawValue := 1176256512, hostValue := 11 },
          { rawValue := 1176256512, hostValue := 22 },
          { rawValue := 1176256512, hostValue := 33 } ] }

def th08LifeMarkerPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeSetBossLifeMarkerCount
    nextOffset := 16
    difficultyMask := some 1
    operandMask := some 1 }

def th08LifeMarkerOutcome :
    Except TouhouFormal.Fault RawBossLifecycleOutcome :=
  rawBossLifecycleStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08LifeMarkerPrefix
    { intInputs := [ { rawValue := 10000, hostValue := 4 } ] }

theorem th06_boss_lifecycle_profile_count :
    bossLifecycleOpcodeCount TouhouFormal.TH06.headerShape = 5 := by
  rfl

theorem th07_boss_lifecycle_profile_count :
    bossLifecycleOpcodeCount TouhouFormal.TH07.headerShape = 7 := by
  rfl

theorem th08_boss_lifecycle_profile_count :
    bossLifecycleOpcodeCount TouhouFormal.TH08.headerShape = 9 := by
  rfl

theorem th06_begin_spell_sign_extends_legacy_i16_id :
    (outcomeSpellStart? th06BeginSpellOutcome).map
      (fun start =>
        (start.spellSprite,
          start.spellId,
          start.bulletClear,
          start.stageState,
          start.resetsBulletRank)) =
      some
        (some 12,
          some (-1),
          some RawBossSpellBulletClear.turnAllIntoPoints,
          some RawBossSpellStageState.running,
          true) := by
  rfl

theorem th07_set_boss_slot_7_still_sets_gui_present :
    (outcomeBossSet? th07SetBossOutcome).map
      (fun set =>
        (set.requestedSlot,
          set.storedBossSlot,
          set.bossPresentWrite,
          set.markerInterrupt)) =
      some (7, 7, some true, some 1) := by
  rfl

theorem th07_clear_boss_slot_5_does_not_hide_gui :
    (outcomeBossClear? th07ClearBossOutcome).map
      (fun clear =>
        (clear.currentBossSlot,
          clear.bossPresentWrite,
          clear.markerInterrupt,
          clear.resetEffectArray)) =
      some (5, none, some 2, true) := by
  rfl

theorem th07_run_interrupt_null_boss_suppresses_write :
    (outcomeRunInterrupt? th07RunInterruptOutcome).map
      (fun write =>
        (write.requestedSlot,
          write.bossPointerPresent,
          write.subId,
          write.writesRunInterrupt)) =
      some (1, false, 42, false) := by
  rfl

theorem th08_set_boss_slot_8_is_oob_write :
    (outcomeFault? th08SetBossSlot8Outcome).map
      (fun fault => (fault.kind, fault.index, fault.bound)) =
      some
        (TouhouFormal.FaultKind.outOfBoundsWrite,
          some 8,
          some 8) := by
  rfl

theorem th08_set_boss_slot_0_opens_primary_gui :
    (outcomeBossSet? th08SetBossSlot0Outcome).map
      (fun set =>
        (set.requestedSlot,
          set.storedBossSlot,
          set.bossPresentWrite,
          set.resetMinimumPlayerDistance)) =
      some (0, 0, some true, true) := by
  rfl

theorem th08_clear_boss_uses_u8_stored_slot_before_array_write :
    (outcomeFault? th08ClearBossTruncatedOutcome).map
      (fun fault => (fault.kind, fault.index, fault.bound)) =
      some
        (TouhouFormal.FaultKind.outOfBoundsWrite,
          some 44,
          some 8) := by
  rfl

theorem th08_boss_gauge_keeps_zero_max_life_boundary :
    (outcomeBossGauge? th08GaugeZeroMaxLifeOutcome).map
      (fun gauge =>
        (gauge.gaugeSlot,
          gauge.startNumerator,
          gauge.stopNumerator,
          gauge.maxLifeDenominator,
          gauge.maxLifeZeroProducesNonfinite,
          gauge.color)) =
      some (1, 10, 20, 0, true, 3) := by
  rfl

theorem th08_effect_tracking_nonzero_does_not_read_vector :
    (outcomeStoredVector? th08EffectTrackingNonzeroOutcome,
      outcomeFlag? th08EffectTrackingNonzeroOutcome) =
      (none,
        some
          { field :=
              RawBossLifecycleFlagField.spellcardEffectTrackingDisabled
            value := 1 }) := by
  rfl

theorem th08_effect_tracking_zero_resolves_stored_vector :
    (outcomeStoredVector? th08EffectTrackingZeroOutcome).map
      (fun vector => (vector.xBits, vector.yBits, vector.zBits)) =
      some (11, 22, 33) := by
  rfl

theorem th08_life_marker_preserves_history_bonus_delta :
    (outcomeLifeMarker? th08LifeMarkerOutcome).map
      (fun marker => (marker.count, marker.historyBonusDelta)) =
      some (4, some 1800) := by
  rfl

end TouhouFormal.Search.BossLifecycle
