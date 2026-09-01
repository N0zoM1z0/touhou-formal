import TouhouFormal.ECL.Misc
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.Misc

open TouhouFormal.ECL

def miscOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.miscOps.length

def outcomeEffect?
    (result : Except TouhouFormal.Fault RawMiscOutcome) :
    Option RawMiscEffect :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.effect

def outcomeFault?
    (result : Except TouhouFormal.Fault RawMiscOutcome) :
    Option TouhouFormal.Fault :=
  match result with
  | .error fault => some fault
  | .ok outcome => outcome.fault

def preparedIntReadCount
    (result : Except TouhouFormal.Fault RawMiscOutcome) : Nat :=
  match result with
  | .error _ => 0
  | .ok outcome => outcome.prepared.map (fun value => value.intResolutions.length) |>.getD 0

def miscPrefix (opcode operandMask : Int) : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := opcode
    nextOffset := 32
    difficultyMask := some 1
    operandMask := some operandMask }

def th06UnpauseOutcome : Except TouhouFormal.Fault RawMiscOutcome :=
  rawMiscStep TouhouFormal.TH06.headerShape 0 1 0 8 64
    (miscPrefix TouhouFormal.TH06.eclOpcodeStandardUnpause 0) {}

def th06InvisibleOutcome : Except TouhouFormal.Fault RawMiscOutcome :=
  rawMiscStep TouhouFormal.TH06.headerShape 0 1 0 8 64
    (miscPrefix TouhouFormal.TH06.eclOpcodeEnemyInvisible 0)
    { intInputs := [ { rawValue := 3 } ] }

def th06DebugOutcome : Except TouhouFormal.Fault RawMiscOutcome :=
  rawMiscStep TouhouFormal.TH06.headerShape 0 1 0 8 64
    (miscPrefix TouhouFormal.TH06.eclOpcodeDebugWatch 0) {}

def th07ProjectileOutcome : Except TouhouFormal.Fault RawMiscOutcome :=
  rawMiscStep TouhouFormal.TH07.headerShape 0 1 0 8 64
    (miscPrefix TouhouFormal.TH07.eclOpcodeSetIsProjectile 0)
    { intInputs := [ { rawValue := 3 } ] }

def th07TrailZeroStrideOutcome : Except TouhouFormal.Fault RawMiscOutcome :=
  rawMiscStep TouhouFormal.TH07.headerShape 0 1 0 8 64
    (miscPrefix TouhouFormal.TH07.eclOpcodeSetTrail 0)
    { intInputs :=
        [ { rawValue := 8 }, { rawValue := 65535 },
          { rawValue := 65534 }, { rawValue := 65536 } ] }

def th07InvincibilityTimerOutcome : Except TouhouFormal.Fault RawMiscOutcome :=
  rawMiscStep TouhouFormal.TH07.headerShape 0 1 0 8 64
    (miscPrefix TouhouFormal.TH07.eclOpcodeSetInvincibilityTimer 1)
    { intInputs := [ { rawValue := 10000, hostValue := 42 } ] }

def th08TrailOutcome : Except TouhouFormal.Fault RawMiscOutcome :=
  rawMiscStep TouhouFormal.TH08.headerShape 0 1 0 8 64
    (miscPrefix TouhouFormal.TH08.eclOpcodeSetTrail 0)
    { intInputs :=
        [ { rawValue := 8 }, { rawValue := 65535 },
          { rawValue := 65534 }, { rawValue := 2 } ] }

def th08StagePauseOutcome : Except TouhouFormal.Fault RawMiscOutcome :=
  rawMiscStep TouhouFormal.TH08.headerShape 0 1 0 8 64
    (miscPrefix TouhouFormal.TH08.eclOpcodeConfigurePause 0)
    { gameFlagsBefore := 0, currentStage := 6 }

def th08SpellPauseOutcome : Except TouhouFormal.Fault RawMiscOutcome :=
  rawMiscStep TouhouFormal.TH08.headerShape 0 1 0 8 64
    (miscPrefix TouhouFormal.TH08.eclOpcodeConfigurePause 0)
    { gameFlagsBefore := 0x4000, currentSpellCardNumber := 0x90 }

def th08MinimumDistanceOutcome : Except TouhouFormal.Fault RawMiscOutcome :=
  rawMiscStep TouhouFormal.TH08.headerShape 0 1 0 8 64
    (miscPrefix TouhouFormal.TH08.eclOpcodeSetMinimumPlayerDistance 1)
    { floatInputs :=
        [ { rawValue := 1176256512, hostValue := 1065353216 } ]
      minimumDistanceSquaredBits := 1073741824 }

def th08Clock11Outcome : Except TouhouFormal.Fault RawMiscOutcome :=
  rawMiscStep TouhouFormal.TH08.headerShape 0 1 0 8 64
    (miscPrefix TouhouFormal.TH08.eclOpcodeAdvanceClock 0)
    { clockBits := 11 }

def th08Clock255Outcome : Except TouhouFormal.Fault RawMiscOutcome :=
  rawMiscStep TouhouFormal.TH08.headerShape 0 1 0 8 64
    (miscPrefix TouhouFormal.TH08.eclOpcodeAdvanceClock 0)
    { clockBits := 255 }

def th08Clock12Outcome : Except TouhouFormal.Fault RawMiscOutcome :=
  rawMiscStep TouhouFormal.TH08.headerShape 0 1 0 8 64
    (miscPrefix TouhouFormal.TH08.eclOpcodeAdvanceClock 0)
    { clockBits := 12 }

theorem th06_misc_profile_count :
    miscOpcodeCount TouhouFormal.TH06.headerShape = 3 := by
  rfl

theorem th07_misc_profile_count :
    miscOpcodeCount TouhouFormal.TH07.headerShape = 8 := by
  rfl

theorem th08_misc_profile_count :
    miscOpcodeCount TouhouFormal.TH08.headerShape = 18 := by
  rfl

theorem th06_unpause_writes_stage_flag :
    (outcomeEffect? th06UnpauseOutcome).map
      (fun effect => effect.stageUnpauseWrite) = some (some 1) := by
  rfl

theorem th06_raw_invisible_store_truncates_to_one_bit :
    (outcomeEffect? th06InvisibleOutcome).map
      (fun effect => effect.intWrites.map (fun write => write.value)) =
      some [1] := by
  rfl

theorem th06_debugwatch_is_an_explicit_zero_read_noop :
    (preparedIntReadCount th06DebugOutcome,
      (outcomeEffect? th06DebugOutcome).map (fun effect => effect.intWrites)) =
      (0, some []) := by
  rfl

theorem th07_projectile_write_also_sets_z_layer :
    (outcomeEffect? th07ProjectileOutcome).map
      (fun effect =>
        effect.intWrites.map (fun write => (write.target, write.value))) =
      some [(.enemyIsProjectile, 1), (.enemyZLayer, 2)] := by
  rfl

theorem th07_trail_zero_stride_fault_preserves_all_stores :
    ((outcomeFault? th07TrailZeroStrideOutcome).map (fun fault => fault.kind),
      (outcomeEffect? th07TrailZeroStrideOutcome).bind (fun effect => effect.trail)) =
      (some .divideByZero,
        some
          { flags := 8
            historyLength := -1
            collisionLength := -2
            sampleStride := 0
            stripInitializationRequested := true }) := by
  rfl

theorem th07_timer_assignment_resets_subframe_and_previous :
    (outcomeEffect? th07InvincibilityTimerOutcome).map
      (fun effect => effect.timerWrites.map
        (fun write => (write.current, write.subFrameBits, write.previous))) =
      some [(42, 0, -999)] := by
  rfl

theorem th08_trail_uses_signed_i16_fields_and_c_division :
    (outcomeEffect? th08TrailOutcome).bind (fun effect => effect.trail) =
      some
        { flags := 8
          historyLength := -1
          collisionLength := -2
          sampleStride := 2
          stripInitializationRequested := true
          stripVertexCount := some 0 } := by
  rfl

theorem th08_stage_six_selects_pause_mode :
    ((outcomeEffect? th08StagePauseOutcome).bind
      (fun effect => effect.pause)).map (fun pause =>
        (pause.gameFlagsAfter, pause.stageSelectedPauseMode,
          pause.spellSelectedPauseMode, pause.enemyPauseTimerFlagSet)) =
      some (0x2080, true, false, true) := by
  rfl

theorem th08_spell_90_selects_pause_mode_when_bit14_is_set :
    ((outcomeEffect? th08SpellPauseOutcome).bind
      (fun effect => effect.pause)).map (fun pause =>
        (pause.gameFlagsAfter, pause.stageSelectedPauseMode,
          pause.spellSelectedPauseMode)) =
      some (0x6080, false, true) := by
  rfl

theorem th08_minimum_distance_records_both_source_writes :
    (outcomeEffect? th08MinimumDistanceOutcome).bind
      (fun effect => effect.minimumDistance) =
      some
        { resolvedDistanceBits := 1065353216
          squaredDistanceBits := 1073741824 } := by
  rfl

theorem th08_clock_11_reaches_12_and_flashes_fast :
    ((outcomeEffect? th08Clock11Outcome).bind
      (fun effect => effect.clock)).map (fun clock =>
        (clock.clockBeforeSigned, clock.clockAfterBits,
          clock.soundId, clock.fastFlash, clock.slowFlash)) =
      some (11, 12, some 0x2d, true, false) := by
  rfl

theorem th08_clock_ff_is_signed_negative_and_wraps_to_zero :
    ((outcomeEffect? th08Clock255Outcome).bind
      (fun effect => effect.clock)).map (fun clock =>
        (clock.clockBeforeSigned, clock.clockAfterBits,
          clock.fastFlash, clock.slowFlash)) =
      some (-1, 0, false, true) := by
  rfl

theorem th08_clock_12_does_not_advance :
    ((outcomeEffect? th08Clock12Outcome).bind
      (fun effect => effect.clock)).map
        (fun clock => (clock.advanced, clock.clockAfterBits, clock.soundId)) =
      some (false, 12, none) := by
  rfl

end TouhouFormal.Search.Misc
