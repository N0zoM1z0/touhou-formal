import TouhouFormal.ECL.Callback
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.Callback

open TouhouFormal.ECL

def callbackConfigOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.callbackConfigOps.length

def outcomeEffect?
    (result : Except TouhouFormal.Fault RawCallbackConfigOutcome) :
    Option RawCallbackConfigEffect :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.effect

def outcomeAction?
    (result : Except TouhouFormal.Fault RawCallbackConfigOutcome) :
    Option RawCallbackConfigAction :=
  match result with
  | .error _ => none
  | .ok outcome => some outcome.action

def outcomeFault?
    (result : Except TouhouFormal.Fault RawCallbackConfigOutcome) :
    Option TouhouFormal.Fault :=
  match result with
  | .error fault => some fault
  | .ok outcome => outcome.fault

def th06TimerThresholdPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH06.eclOpcodeSetTimerCallbackThreshold
    nextOffset := 16
    difficultyMask := some 1
    operandMask := none }

def th06TimerThresholdOutcome :
    Except TouhouFormal.Fault RawCallbackConfigOutcome :=
  rawCallbackConfigStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 64
    th06TimerThresholdPrefix
    { slots := [{ rawValue := 120 }] }

def th07DeathPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeSetDeathCallbackSub
    nextOffset := 16
    difficultyMask := some 1
    operandMask := some 0 }

def th07DeathOutcome : Except TouhouFormal.Fault RawCallbackConfigOutcome :=
  rawCallbackConfigStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    th07DeathPrefix
    { slots := [{ rawValue := 0x1ff }] }

def th07LifePairPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeSetLifeCallback
    nextOffset := 24
    difficultyMask := some 1
    operandMask := some 7 }

def th07LifePairPartialFaultOutcome :
    Except TouhouFormal.Fault RawCallbackConfigOutcome :=
  rawCallbackConfigStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    th07LifePairPrefix
    { slots :=
        [ { rawValue := 10000, hostValues := [1, 4] },
          { rawValue := 10001, hostValues := [500] },
          { rawValue := 10002, hostValues := [9] } ] }

def th07PeriodicPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeSetPeriodicCallback
    nextOffset := 20
    difficultyMask := some 1
    operandMask := some 3 }

def th07PeriodicOutcome : Except TouhouFormal.Fault RawCallbackConfigOutcome :=
  rawCallbackConfigStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    th07PeriodicPrefix
    { slots :=
        [ { rawValue := 10000, hostValues := [30] },
          { rawValue := 10001, hostValues := [12] } ] }

def th08DeathPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeSetDeathCallbackSub
    nextOffset := 16
    difficultyMask := some 1
    operandMask := none }

def th08SuppressedDeathOutcome :
    Except TouhouFormal.Fault RawCallbackConfigOutcome :=
  rawCallbackConfigStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08DeathPrefix
    { presentationWritesAllowed := false }

def th08SignedDeathOutcome :
    Except TouhouFormal.Fault RawCallbackConfigOutcome :=
  rawCallbackConfigStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08DeathPrefix
    { slots := [{ rawValue := 0xffff }] }

def th08LifePairPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeSetLifeCallback
    nextOffset := 24
    difficultyMask := some 1
    operandMask := some 3 }

def th08SuppressedLifePairOutcome :
    Except TouhouFormal.Fault RawCallbackConfigOutcome :=
  rawCallbackConfigStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08LifePairPrefix
    { slots :=
        [ { rawValue := 10000, hostValues := [2] },
          { rawValue := 10001, hostValues := [700] } ]
      presentationWritesAllowed := false }

def th08TimerPairPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeSetTimerCallback
    nextOffset := 20
    difficultyMask := some 1
    operandMask := some 1 }

def th08SuppressedTimerPairOutcome :
    Except TouhouFormal.Fault RawCallbackConfigOutcome :=
  rawCallbackConfigStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08TimerPairPrefix
    { slots := [{ rawValue := 10000, hostValues := [900] }]
      presentationWritesAllowed := false }

def th08BindPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeBindTimerCallbackToDeath
    nextOffset := 12
    difficultyMask := some 1
    operandMask := some 0 }

def th08BindOutcome : Except TouhouFormal.Fault RawCallbackConfigOutcome :=
  rawCallbackConfigStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08BindPrefix
    { deathCallbackSubBefore := -1 }

theorem th06_callback_config_profile_count :
    callbackConfigOpcodeCount TouhouFormal.TH06.headerShape = 6 := by
  rfl

theorem th07_callback_config_profile_count :
    callbackConfigOpcodeCount TouhouFormal.TH07.headerShape = 8 := by
  rfl

theorem th08_callback_config_profile_count :
    callbackConfigOpcodeCount TouhouFormal.TH08.headerShape = 4 := by
  rfl

theorem th06_timer_threshold_is_raw_and_resets_timer :
    (outcomeEffect? th06TimerThresholdOutcome).map
      (fun effect => (effect.timerThresholdWrite, effect.bossTimerWrite)) =
      some
        (some 120,
          some { current := 0, subFrameBits := 0, previous := -999 }) := by
  rfl

theorem th07_death_callback_zero_extends_raw_byte :
    (outcomeEffect? th07DeathOutcome).bind
      RawCallbackConfigEffect.deathCallbackSubWrite = some 255 := by
  rfl

theorem th07_repeated_rng_index_can_fault_after_threshold_write :
    outcomeAction? th07LifePairPartialFaultOutcome = some .hostFault ∧
    (outcomeEffect? th07LifePairPartialFaultOutcome).map
      (fun effect => (effect.lifeThresholdWrites, effect.lifeSubWrites)) =
      some ([{ index := 1, value := 500 }], []) := by
  exact ⟨rfl, rfl⟩

theorem th07_repeated_rng_index_fault_is_second_array_write :
    (outcomeFault? th07LifePairPartialFaultOutcome).map
      (fun fault => (fault.kind, fault.index, fault.bound)) =
      some (.outOfBoundsWrite, some 4, some 4) := by
  rfl

theorem th07_periodic_callback_resets_counter_and_saves_args :
    (outcomeEffect? th07PeriodicOutcome).map
      (fun effect =>
        (effect.periodicIntervalWrite,
          effect.periodicSubWrite,
          effect.periodicCounterWrite,
          effect.savePeriodicContextArgs)) =
      some
        (some { current := 30, subFrameBits := 0, previous := -999 },
          some 12,
          some { current := 0, subFrameBits := 0, previous := -999 },
          true) := by
  rfl

theorem th08_death_presentation_guard_precedes_operand_read :
    (outcomeEffect? th08SuppressedDeathOutcome).map
      (fun effect =>
        (effect.deathCallbackSubWrite,
          effect.suppressedByPresentationPolicy)) =
      some (none, true) := by
  rfl

theorem th08_death_callback_u16_write_becomes_signed_i16 :
    (outcomeEffect? th08SignedDeathOutcome).bind
      RawCallbackConfigEffect.deathCallbackSubWrite = some (-1) := by
  rfl

theorem th08_life_guard_keeps_threshold_but_suppresses_sub_read :
    (outcomeEffect? th08SuppressedLifePairOutcome).map
      (fun effect =>
        (effect.lifeThresholdWrites,
          effect.lifeSubWrites,
          effect.suppressedByPresentationPolicy)) =
      some ([{ index := 2, value := 700 }], [], true) := by
  rfl

theorem th08_timer_guard_keeps_threshold_and_reset :
    (outcomeEffect? th08SuppressedTimerPairOutcome).map
      (fun effect =>
        (effect.timerThresholdWrite,
          effect.timerSubWrite,
          effect.bossTimerWrite,
          effect.suppressedByPresentationPolicy)) =
      some
        (some 900,
          none,
          some { current := 0, subFrameBits := 0, previous := -999 },
          true) := by
  rfl

theorem th08_bind_preserves_signed_death_sub_and_resets_timer :
    (outcomeEffect? th08BindOutcome).map
      (fun effect => (effect.timerSubWrite, effect.bossTimerWrite)) =
      some
        (some (-1),
          some { current := 0, subFrameBits := 0, previous := -999 }) := by
  rfl

end TouhouFormal.Search.Callback
