import TouhouFormal.ECL.TimedMovement
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.TimedMovement

open TouhouFormal.ECL

def f32ZeroBits : Int := 0
def f32OneBits : Int := 1065353216
def f32TwoBits : Int := 1073741824
def f32ThreeBits : Int := 1077936128
def f32NegativeOneBits : Int := 3212836864
def th06FloatSelectorBits : Int := 3323741184
def th07FloatSelectorBits : Int := 1176256512
def th08FloatSelectorBits : Int := 1176256512

def timedMovementOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape =>
      rawShape.timedMovementFamilies.foldl
        (fun count family =>
          count + (family.lastOpcode - family.firstOpcode + 1).toNat)
        0

def outcomeEffect?
    (result : Except TouhouFormal.Fault RawTimedMovementOutcome) :
    Option RawMovementEffect :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.effect

def outcomePrepared?
    (result : Except TouhouFormal.Fault RawTimedMovementOutcome) :
    Option RawTimedMovementPrepared :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.prepared

def th06PositionPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH06.eclOpcodeMovePositionTimeFirst
    nextOffset := 28
    difficultyMask := some 1
    operandMask := none }

def th06PositionOutcome : Except TouhouFormal.Fault RawTimedMovementOutcome :=
  rawTimedMovementStep
    TouhouFormal.TH06.headerShape 0 1 0 8 64 th06PositionPrefix
    { slots :=
        [ { rawValue := 30 },
          { rawValue := th06FloatSelectorBits, hostValues := [f32OneBits] },
          { rawValue := th06FloatSelectorBits, hostValues := [f32TwoBits] },
          { rawValue := th06FloatSelectorBits, hostValues := [f32ThreeBits] } ]
      floatResults :=
        { effectiveDirectionAngleBits := 0
          playerRelativeAngleBits := 0
          interpolationDelta := { x := 11, y := 22, z := 33 } }
      runtime :=
        { positionBefore := { x := 101, y := 202, z := 303 } } }

def th06CurrentDirectionPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH06.eclOpcodeMoveCurrentTimeLast
    nextOffset := 16
    difficultyMask := some 1
    operandMask := none }

def th06CurrentDirectionOutcome :
    Except TouhouFormal.Fault RawTimedMovementOutcome :=
  rawTimedMovementStep
    TouhouFormal.TH06.headerShape 0 1 0 8 64 th06CurrentDirectionPrefix
    { slots := [{ rawValue := 40 }]
      floatResults :=
        { effectiveDirectionAngleBits := f32OneBits
          playerRelativeAngleBits := 0
          interpolationDelta := { x := 44, y := 55, z := 999 } }
      runtime :=
        { positionBefore := { x := 7, y := 8, z := 9 }
          currentAngle :=
            { rawValue := th06FloatSelectorBits, hostValues := [f32OneBits] }
          currentSpeedBits := f32TwoBits } }

def th07DirectionPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeMoveDirectionTimed
    nextOffset := 28
    difficultyMask := some 1
    operandMask := some 15 }

def th07ImmediateDirectionOutcome :
    Except TouhouFormal.Fault RawTimedMovementOutcome :=
  rawTimedMovementStep
    TouhouFormal.TH07.headerShape 0 1 0 8 64 th07DirectionPrefix
    { slots :=
        [ { rawValue := 10000, hostValues := [0, 9] },
          { rawValue := 10001, hostValues := [7] },
          { rawValue := th07FloatSelectorBits, hostValues := [f32OneBits] },
          { rawValue := th07FloatSelectorBits, hostValues := [f32TwoBits] } ]
      floatResults :=
        { effectiveDirectionAngleBits := f32OneBits
          playerRelativeAngleBits := 0
          interpolationDelta := { x := 0, y := 0, z := 0 } } }

def th07TimedMirroredDirectionOutcome :
    Except TouhouFormal.Fault RawTimedMovementOutcome :=
  rawTimedMovementStep
    TouhouFormal.TH07.headerShape 0 1 0 8 64 th07DirectionPrefix
    { slots :=
        [ { rawValue := 10000, hostValues := [5, 6, 7, 8] },
          { rawValue := 10001, hostValues := [10] },
          { rawValue := th07FloatSelectorBits, hostValues := [f32OneBits] },
          { rawValue := th07FloatSelectorBits,
            hostValues := [f32OneBits, f32TwoBits] } ]
      floatResults :=
        { effectiveDirectionAngleBits := f32OneBits
          playerRelativeAngleBits := 0
          interpolationDelta := { x := f32OneBits, y := f32TwoBits, z := 77 } }
      runtime :=
        { positionBefore := { x := 1, y := 2, z := 3 }
          mirrorX := true } }

def th08DirectionPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeMoveDirectionTimed
    nextOffset := 28
    difficultyMask := some 1
    operandMask := some 15 }

def th08ImmediateDirectionOutcome :
    Except TouhouFormal.Fault RawTimedMovementOutcome :=
  rawTimedMovementStep
    TouhouFormal.TH08.headerShape 0 1 0 8 64 th08DirectionPrefix
    { slots :=
        [ { rawValue := 10000, hostValues := [0, 99] },
          { rawValue := 10001, hostValues := [6] },
          { rawValue := th08FloatSelectorBits, hostValues := [f32OneBits] },
          { rawValue := th08FloatSelectorBits, hostValues := [f32TwoBits] } ]
      floatResults :=
        { effectiveDirectionAngleBits := f32OneBits
          playerRelativeAngleBits := 0
          interpolationDelta := { x := 0, y := 0, z := 0 } } }

def th08PlayerTimedPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeMoveAtPlayerTimed
    nextOffset := 28
    difficultyMask := some 1
    operandMask := some 15 }

def th08ImmediatePlayerDirectionOutcome :
    Except TouhouFormal.Fault RawTimedMovementOutcome :=
  rawTimedMovementStep
    TouhouFormal.TH08.headerShape 0 1 0 8 64 th08PlayerTimedPrefix
    { slots :=
        [ { rawValue := 10000, hostValues := [0, 12] },
          { rawValue := 10001, hostValues := [3] },
          { rawValue := th08FloatSelectorBits, hostValues := [f32OneBits] },
          { rawValue := th08FloatSelectorBits, hostValues := [f32TwoBits] } ]
      floatResults :=
        { effectiveDirectionAngleBits := 111
          playerRelativeAngleBits := 222
          interpolationDelta := { x := 0, y := 0, z := 0 } } }

def th08InterpolatedPlayerDirectionOutcome :
    Except TouhouFormal.Fault RawTimedMovementOutcome :=
  rawTimedMovementStep
    TouhouFormal.TH08.headerShape 0 1 0 8 64 th08PlayerTimedPrefix
    { slots :=
        [ { rawValue := 10000, hostValues := [1, 2, 3, 4] },
          { rawValue := 10001, hostValues := [3] },
          { rawValue := th08FloatSelectorBits, hostValues := [f32OneBits] },
          { rawValue := th08FloatSelectorBits,
            hostValues := [f32OneBits, f32TwoBits] } ]
      floatResults :=
        { effectiveDirectionAngleBits := 111
          playerRelativeAngleBits := 222
          interpolationDelta := { x := 10, y := 20, z := 30 } }
      runtime :=
        { worldPositionBefore := { x := 5, y := 6, z := 7 } } }

def th08PositionPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeMovePositionTimed
    nextOffset := 28
    difficultyMask := some 1
    operandMask := some 15 }

def th08PositionOutcome : Except TouhouFormal.Fault RawTimedMovementOutcome :=
  rawTimedMovementStep
    TouhouFormal.TH08.headerShape 0 1 0 8 64 th08PositionPrefix
    { slots :=
        [ { rawValue := 10000, hostValues := [20] },
          { rawValue := 10001, hostValues := [9] },
          { rawValue := th08FloatSelectorBits, hostValues := [f32OneBits] },
          { rawValue := th08FloatSelectorBits, hostValues := [f32TwoBits] } ]
      floatResults :=
        { effectiveDirectionAngleBits := 0
          playerRelativeAngleBits := 0
          interpolationDelta := { x := 31, y := 32, z := 33 } }
      runtime :=
        { positionBefore := { x := 11, y := 12, z := 13 }
          worldPositionBefore := { x := 21, y := 22, z := 23 } } }

theorem th06_timed_movement_profile_count :
    timedMovementOpcodeCount TouhouFormal.TH06.headerShape = 13 := by
  rfl

theorem th07_timed_movement_profile_count :
    timedMovementOpcodeCount TouhouFormal.TH07.headerShape = 2 := by
  rfl

theorem th08_timed_movement_profile_count :
    timedMovementOpcodeCount TouhouFormal.TH08.headerShape = 3 := by
  rfl

theorem th06_linear_position_sets_easing_origin_and_zero_velocity :
    (outcomeEffect? th06PositionOutcome).map
      (fun effect =>
        (effect.easingWrite, effect.interpolationOriginWrite,
          effect.velocityWrite, effect.movementDurationWrite)) =
      some
        (some 0, some { x := 101, y := 202, z := 303 },
          some { x := 0, y := 0, z := 0 }, some 30) := by
  rfl

theorem th06_current_direction_resolves_state_angle_and_forces_delta_z_zero :
    (outcomePrepared? th06CurrentDirectionOutcome).map
      (fun prepared =>
        (prepared.reads[0]?.map (fun read => read.resolution.value),
          prepared.effect.interpolationDeltaWrite,
          prepared.effect.easingWrite)) =
      some (some f32OneBits, some { x := 44, y := 55, z := 0 }, some 4) := by
  rfl

theorem th07_nonpositive_duration_is_resolved_again_for_timer_write :
    (outcomePrepared? th07ImmediateDirectionOutcome).map
      (fun prepared =>
        (prepared.branch, prepared.reads.map (fun read => read.resolution.value),
          prepared.effect.movementTimerWrite)) =
      some (.immediatePolar, [0, f32OneBits, f32TwoBits, 9], some 9) := by
  rfl

theorem th07_timer_assignment_resets_subframe_and_history :
    (outcomeEffect? th07ImmediateDirectionOutcome).bind
      (fun effect => effect.movementTimerStateWrite) =
      some { current := 9, subFrameBits := 0, previous := -999 } := by
  rfl

theorem th07_timed_direction_preserves_repeated_reads_and_bitfield_easing :
    (outcomePrepared? th07TimedMirroredDirectionOutcome).map
      (fun prepared =>
        (prepared.reads.map (fun read => read.resolution.value),
          prepared.effect.easingWrite,
          prepared.effect.movementDurationWrite)) =
      some
        ([5, f32OneBits, f32OneBits, 6, f32TwoBits, 7, 8, 10],
          some 2, some 8) := by
  rfl

theorem th07_mirror_toggles_only_delta_x_sign_bit :
    (outcomeEffect? th07TimedMirroredDirectionOutcome).bind
      (fun effect => effect.interpolationDeltaWrite) =
      some { x := f32NegativeOneBits, y := f32TwoBits, z := 0 } := by
  rfl

theorem th08_nonpositive_direction_resets_timers_without_second_duration_read :
    (outcomePrepared? th08ImmediateDirectionOutcome).map
      (fun prepared =>
        (prepared.reads.map (fun read => read.resolution.value),
          prepared.effect.movementDurationWrite,
          prepared.effect.movementTimerWrite)) =
      some ([0, f32OneBits, f32TwoBits], some 0, some 0) := by
  rfl

theorem th08_nonpositive_player_move_uses_player_angle_and_second_duration :
    (outcomePrepared? th08ImmediatePlayerDirectionOutcome).map
      (fun prepared =>
        (prepared.effectiveAngleBits,
          prepared.effect.angleWrite,
          prepared.effect.movementTimerWrite)) =
      some (some 222, some 222, some 12) := by
  rfl

theorem th08_positive_player_move_uses_absolute_angle_helper :
    (outcomePrepared? th08InterpolatedPlayerDirectionOutcome).map
      (fun prepared =>
        (prepared.branch, prepared.effectiveAngleBits,
          prepared.effect.angleWrite,
          prepared.effect.movementDurationWrite)) =
      some (.interpolated, some 111, none, some 4) := by
  rfl

theorem th08_relative_move_uses_position_origin_but_profiles_world_delta_base :
    (outcomePrepared? th08PositionOutcome).map
      (fun prepared =>
        (prepared.familyMatch.family.deltaBaseSource,
          prepared.effect.interpolationOriginWrite,
          prepared.effect.interpolationDeltaWrite,
          prepared.effect.easingWrite)) =
      some
        (.worldPosition, some { x := 11, y := 12, z := 13 },
          some { x := 31, y := 32, z := 33 }, some 1) := by
  rfl

end TouhouFormal.Search.TimedMovement
