import TouhouFormal.ECL.OrbitMovement
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.OrbitMovement

open TouhouFormal.ECL

def floatSelectorBits : Int := 1176256512

def orbitMovementOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.orbitMovementOps.length

def outcomeEffect?
    (result : Except TouhouFormal.Fault RawOrbitMovementOutcome) :
    Option RawMovementEffect :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.effect

def outcomePrepared?
    (result : Except TouhouFormal.Fault RawOrbitMovementOutcome) :
    Option RawOrbitMovementPrepared :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.prepared

def th07OrbitPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeMoveOrbit
    nextOffset := 44
    difficultyMask := some 1
    operandMask := some 255 }

def th07OrbitOutcome : Except TouhouFormal.Fault RawOrbitMovementOutcome :=
  rawOrbitMovementStep
    TouhouFormal.TH07.headerShape 0 1 0 8 80 th07OrbitPrefix
    { slots :=
        [ { rawValue := 10000, hostValues := [30] },
          { rawValue := floatSelectorBits, hostValues := [101] },
          { rawValue := floatSelectorBits, hostValues := [102] },
          { rawValue := floatSelectorBits, hostValues := [103] },
          { rawValue := floatSelectorBits, hostValues := [104] },
          { rawValue := floatSelectorBits, hostValues := [105] },
          { rawValue := floatSelectorBits, hostValues := [106] },
          { rawValue := floatSelectorBits, hostValues := [107] } ] }

def th07TimerPrefix (opcode : Int) : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := opcode
    nextOffset := 16
    difficultyMask := some 1
    operandMask := some 1 }

def th07TimerOutcome (opcode : Int) :
    Except TouhouFormal.Fault RawOrbitMovementOutcome :=
  rawOrbitMovementStep
    TouhouFormal.TH07.headerShape 0 1 0 8 64 (th07TimerPrefix opcode)
    { slots := [{ rawValue := 10000, hostValues := [12] }] }

def th08OrbitPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeMoveOrbit
    nextOffset := 40
    difficultyMask := some 1
    operandMask := some 127 }

def th08OrbitOutcome : Except TouhouFormal.Fault RawOrbitMovementOutcome :=
  rawOrbitMovementStep
    TouhouFormal.TH08.headerShape 0 1 0 8 80 th08OrbitPrefix
    { slots :=
        [ { rawValue := 10000, hostValues := [20] },
          { rawValue := floatSelectorBits, hostValues := [201] },
          { rawValue := floatSelectorBits, hostValues := [202] },
          { rawValue := floatSelectorBits, hostValues := [203] },
          { rawValue := floatSelectorBits, hostValues := [204] },
          { rawValue := floatSelectorBits, hostValues := [205] },
          { rawValue := floatSelectorBits, hostValues := [206] } ] }

def th08OrbitFromPositionPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeMoveOrbitFromPosition
    nextOffset := 28
    difficultyMask := some 1
    operandMask := some 15 }

def th08OrbitFromPositionOutcome :
    Except TouhouFormal.Fault RawOrbitMovementOutcome :=
  rawOrbitMovementStep
    TouhouFormal.TH08.headerShape 0 1 0 8 64 th08OrbitFromPositionPrefix
    { slots :=
        [ { rawValue := 10000, hostValues := [15] },
          { rawValue := floatSelectorBits, hostValues := [301] },
          { rawValue := floatSelectorBits, hostValues := [302] },
          { rawValue := floatSelectorBits, hostValues := [303] } ]
      positionBefore := { x := 11, y := 12, z := 13 } }

def th08OrbitVelocitiesPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeSetOrbitVelocities
    nextOffset := 24
    difficultyMask := some 1
    operandMask := some 7 }

def th08OrbitVelocitiesOutcome :
    Except TouhouFormal.Fault RawOrbitMovementOutcome :=
  rawOrbitMovementStep
    TouhouFormal.TH08.headerShape 0 1 0 8 64 th08OrbitVelocitiesPrefix
    { slots :=
        [ { rawValue := 10000, hostValues := [9] },
          { rawValue := floatSelectorBits, hostValues := [401] },
          { rawValue := floatSelectorBits, hostValues := [402] } ] }

theorem th06_orbit_movement_profile_count :
    orbitMovementOpcodeCount TouhouFormal.TH06.headerShape = 0 := by
  rfl

theorem th07_orbit_movement_profile_count :
    orbitMovementOpcodeCount TouhouFormal.TH07.headerShape = 6 := by
  rfl

theorem th08_orbit_movement_profile_count :
    orbitMovementOpcodeCount TouhouFormal.TH08.headerShape = 3 := by
  rfl

theorem th07_full_orbit_preserves_source_read_order_and_all_writes :
    (outcomePrepared? th07OrbitOutcome).map
      (fun prepared =>
        (prepared.reads.map (fun read => read.resolution.value),
          prepared.effect.interpolationOriginWrite,
          prepared.effect.orbitAngleWrite,
          prepared.effect.orbitAngularVelocityWrite,
          prepared.effect.orbitRadiusWrite,
          prepared.effect.radialVelocityWrite)) =
      some
        ([30, 101, 102, 103, 104, 105, 106, 107],
          some { x := 101, y := 102, z := 103 },
          some 104, some 105, some 106, some 107) := by
  rfl

theorem th07_timer_opcodes_share_one_transition_with_profiled_modes :
    ((outcomeEffect?
        (th07TimerOutcome TouhouFormal.TH07.eclOpcodeSetMoveTimerPolar)).bind
          (fun effect => effect.modeWrite),
      (outcomeEffect?
        (th07TimerOutcome TouhouFormal.TH07.eclOpcodeSetMoveTimerOrbit)).bind
          (fun effect => effect.modeWrite),
      (outcomeEffect?
        (th07TimerOutcome
          TouhouFormal.TH07.eclOpcodeSetMoveTimerInterpolation)).bind
          (fun effect => effect.modeWrite)) =
      (some .polar, some .orbit, some .interpolation) := by
  rfl

theorem th07_orbit_timer_resets_subframe_and_history :
    (outcomeEffect?
      (th07TimerOutcome TouhouFormal.TH07.eclOpcodeSetMoveTimerOrbit)).bind
        (fun effect => effect.movementTimerStateWrite) =
      some { current := 12, subFrameBits := 0, previous := -999 } := by
  rfl

theorem th08_full_orbit_writes_only_origin_xy :
    (outcomeEffect? th08OrbitOutcome).map
      (fun effect =>
        (effect.interpolationOriginWrite,
          effect.interpolationOriginXYWrite,
          effect.modeWrite)) =
      some (none, some { x := 201, y := 202 }, some .orbit) := by
  rfl

theorem th08_orbit_from_position_copies_full_origin_and_zeros_radius :
    (outcomeEffect? th08OrbitFromPositionOutcome).map
      (fun effect =>
        (effect.interpolationOriginWrite,
          effect.orbitRadiusWrite,
          effect.movementDurationWrite)) =
      some (some { x := 11, y := 12, z := 13 }, some 0, some 15) := by
  rfl

theorem th08_orbit_velocity_update_preserves_angle_and_radius :
    (outcomeEffect? th08OrbitVelocitiesOutcome).map
      (fun effect =>
        (effect.orbitAngleWrite,
          effect.orbitAngularVelocityWrite,
          effect.orbitRadiusWrite,
          effect.radialVelocityWrite)) =
      some (none, some 401, none, some 402) := by
  rfl

end TouhouFormal.Search.OrbitMovement
