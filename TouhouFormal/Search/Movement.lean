import TouhouFormal.ECL.Movement
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.Movement

open TouhouFormal.ECL

def f32ZeroBits : Int := 0
def f32OneBits : Int := 1065353216
def f32TwoBits : Int := 1073741824
def f32PiOverFourBits : Int := 1061752795

def movementOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.movementOps.length

def movementKind? (shape : HeaderShape) (opcode : Int) : Option RawMovementOpKind :=
  match shape.rawInstrShape with
  | none => none
  | some rawShape =>
      match rawShape.findMovementOp? opcode with
      | none => none
      | some op => some op.kind

def outcomeAction? (result : Except TouhouFormal.Fault RawMovementOutcome) :
    Option RawMovementAction :=
  match result with
  | .error _ => none
  | .ok outcome => some outcome.action

def outcomeEffect? (result : Except TouhouFormal.Fault RawMovementOutcome) :
    Option RawMovementEffect :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.effect

def outcomeInputBits? (result : Except TouhouFormal.Fault RawMovementOutcome) :
    Option (List Int) :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.prepared.map (fun prepared => prepared.inputBits)

def th06MoveAtPlayerPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH06.eclOpcodeMoveAtPlayer
    nextOffset := 20
    difficultyMask := some 1
    operandMask := none }

def th06MoveAtPlayerOperands : RawMovementOperands :=
  { floatInputs :=
      [ { rawValue := 3323741184, hostValue := f32OneBits },
        { rawValue := 3323741184, hostValue := f32TwoBits } ]
    derivedAngleBits := f32PiOverFourBits }

def th06MoveAtPlayerOutcome : Except TouhouFormal.Fault RawMovementOutcome :=
  rawMovementStep
    TouhouFormal.TH06.headerShape
    0
    1
    0
    8
    64
    th06MoveAtPlayerPrefix
    th06MoveAtPlayerOperands

def th07AxisVelocityPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeSetAxisSpeed
    nextOffset := 24
    difficultyMask := some 1
    operandMask := some 0 }

def th07AxisVelocityOperands : RawMovementOperands :=
  { floatInputs :=
      [ { rawValue := f32OneBits, hostValue := f32OneBits },
        { rawValue := f32OneBits, hostValue := f32OneBits },
        { rawValue := f32ZeroBits, hostValue := f32ZeroBits } ]
    derivedAngleBits := f32PiOverFourBits }

def th07AxisVelocityOutcome : Except TouhouFormal.Fault RawMovementOutcome :=
  rawMovementStep
    TouhouFormal.TH07.headerShape
    0
    1
    0
    8
    64
    th07AxisVelocityPrefix
    th07AxisVelocityOperands

def th08PolarVelocityPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeSetPolarVelocity
    nextOffset := 20
    difficultyMask := some 1
    operandMask := some 0 }

def th08PolarVelocityOperands : RawMovementOperands :=
  { floatInputs :=
      [ { rawValue := f32PiOverFourBits, hostValue := f32PiOverFourBits },
        { rawValue := f32TwoBits, hostValue := f32TwoBits } ]
    derivedAngleBits := f32PiOverFourBits }

def th08PolarVelocityOutcome : Except TouhouFormal.Fault RawMovementOutcome :=
  rawMovementStep
    TouhouFormal.TH08.headerShape
    0
    1
    0
    8
    64
    th08PolarVelocityPrefix
    th08PolarVelocityOperands

def th08PositionPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeSetPosition
    nextOffset := 20
    difficultyMask := some 1
    operandMask := some 0 }

def th08PositionOperands : RawMovementOperands :=
  { floatInputs :=
      [ { rawValue := f32OneBits, hostValue := f32OneBits },
        { rawValue := f32TwoBits, hostValue := f32TwoBits } ] }

def th08PositionOutcome : Except TouhouFormal.Fault RawMovementOutcome :=
  rawMovementStep
    TouhouFormal.TH08.headerShape
    0
    1
    0
    8
    64
    th08PositionPrefix
    th08PositionOperands

theorem th06_movement_profile_count :
    movementOpcodeCount TouhouFormal.TH06.headerShape = 9 := by
  rfl

theorem th07_movement_profile_count :
    movementOpcodeCount TouhouFormal.TH07.headerShape = 8 := by
  rfl

theorem th08_movement_profile_count :
    movementOpcodeCount TouhouFormal.TH08.headerShape = 7 := by
  rfl

theorem th06_move_at_player_preserves_raw_angle_offset :
    outcomeInputBits? th06MoveAtPlayerOutcome =
      some [3323741184, f32TwoBits] := by
  rfl

theorem th06_move_at_player_advances :
    outcomeAction? th06MoveAtPlayerOutcome = some .advanced := by
  rfl

theorem th07_axis_velocity_records_derived_angle :
    (outcomeEffect? th07AxisVelocityOutcome).bind (fun effect => effect.angleWrite) =
      some f32PiOverFourBits := by
  rfl

theorem th07_axis_velocity_selects_axis_mode :
    (outcomeEffect? th07AxisVelocityOutcome).bind (fun effect => effect.modeWrite) =
      some .axis := by
  rfl

theorem th08_polar_velocity_resets_duration :
    (outcomeEffect? th08PolarVelocityOutcome).bind
      (fun effect => effect.movementDurationWrite) = some 0 := by
  rfl

theorem th08_polar_velocity_resets_timer :
    (outcomeEffect? th08PolarVelocityOutcome).bind
      (fun effect => effect.movementTimerWrite) = some 0 := by
  rfl

theorem th08_position_forces_zero_z :
    (outcomeEffect? th08PositionOutcome).bind (fun effect => effect.positionWrite) =
      some { x := f32OneBits, y := f32TwoBits, z := f32ZeroBits } := by
  rfl

theorem th08_position_requests_clamp :
    (outcomeEffect? th08PositionOutcome).map (fun effect => effect.clampPosition) =
      some true := by
  rfl

end TouhouFormal.Search.Movement
