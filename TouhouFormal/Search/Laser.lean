import TouhouFormal.ECL.Laser
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.Laser

open TouhouFormal.ECL

def laserOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.laserOps.length

def outcomeEffect?
    (result : Except TouhouFormal.Fault RawLaserOutcome) :
    Option RawLaserEffect :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.effect

def outcomePrepared?
    (result : Except TouhouFormal.Fault RawLaserOutcome) :
    Option RawLaserPrepared :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.prepared

def outcomeAction?
    (result : Except TouhouFormal.Fault RawLaserOutcome) :
    Option RawLaserAction :=
  match result with
  | .error _ => none
  | .ok outcome => some outcome.action

def outcomeFault?
    (result : Except TouhouFormal.Fault RawLaserOutcome) :
    Option TouhouFormal.Fault :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.fault

def mkPrefix (opcode : Int) (operandMask : Option Int := none) : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := opcode
    nextOffset := 24
    difficultyMask := some 1
    operandMask := operandMask }

def th06SetLaserIndexOutcome : Except TouhouFormal.Fault RawLaserOutcome :=
  rawLaserStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH06.eclOpcodeLaserIndex)
    { intInputs := [ { rawValue := -10001, hostValue := 3 } ] }

def th06RotateNullLaserOutcome : Except TouhouFormal.Fault RawLaserOutcome :=
  rawLaserStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH06.eclOpcodeLaserRotate)
    { intInputs := [ { rawValue := 4 } ]
      laserPresent := false }

def th06RotateHighFaultOutcome : Except TouhouFormal.Fault RawLaserOutcome :=
  rawLaserStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH06.eclOpcodeLaserRotate)
    { intInputs := [ { rawValue := 32 } ] }

def th06LaserTestActiveOutcome : Except TouhouFormal.Fault RawLaserOutcome :=
  rawLaserStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH06.eclOpcodeLaserTest)
    { intInputs := [ { rawValue := 2 } ]
      laserPresent := true
      laserInUse := true }

def th06LaserCancelOutcome : Except TouhouFormal.Fault RawLaserOutcome :=
  rawLaserStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH06.eclOpcodeLaserCancel)
    { intInputs := [ { rawValue := 1 } ]
      laserPresent := true
      laserInUse := true
      laserState := 1
      currentWidthBits := 1234 }

def th07AddLaserAngleOutcome : Except TouhouFormal.Fault RawLaserOutcome :=
  rawLaserStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH07.eclOpcodeAddLaserAngle (some 3))
    { intInputs := [ { rawValue := 10000, hostValue := 4 } ]
      floatInputs := [ { rawBits := 1176256512, hostBits := 123 } ] }

def th07HideWarningOutcome : Except TouhouFormal.Fault RawLaserOutcome :=
  rawLaserStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH07.eclOpcodeSetLaserHideWarning (some 3))
    { intInputs :=
        [ { rawValue := 10000, hostValue := 1 },
          { rawValue := 10000, hostValue := 300 } ] }

def th07StopLaserOutcome : Except TouhouFormal.Fault RawLaserOutcome :=
  rawLaserStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH07.eclOpcodeStopLaser (some 1))
    { intInputs := [ { rawValue := 10000, hostValue := 1 } ]
      laserPresent := true
      laserInUse := true
      laserState := 1
      currentWidthBits := 0x3f800000 }

def th07ClearLasersOutcome : Except TouhouFormal.Fault RawLaserOutcome :=
  rawLaserStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH07.eclOpcodeClearLasers)
    {}

def th08TestLaserInUseOutcome : Except TouhouFormal.Fault RawLaserOutcome :=
  rawLaserStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH08.eclOpcodeTestLaserInUse (some 1))
    { intInputs := [ { rawValue := 10000, hostValue := 2 } ]
      laserPresent := true
      laserInUse := true }

def th08SetLaserAngleNullOutcome : Except TouhouFormal.Fault RawLaserOutcome :=
  rawLaserStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH08.eclOpcodeSetLaserAngle (some 3))
    { intInputs := [ { rawValue := 10000, hostValue := 1 } ]
      laserPresent := false }

def th08SetLaserOffsetsNegativeFaultOutcome :
    Except TouhouFormal.Fault RawLaserOutcome :=
  rawLaserStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH08.eclOpcodeSetLaserOffsets (some 7))
    { intInputs := [ { rawValue := 10000, hostValue := -1 } ] }

def th08StopLaserOutcome : Except TouhouFormal.Fault RawLaserOutcome :=
  rawLaserStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH08.eclOpcodeStopLaser (some 1))
    { intInputs := [ { rawValue := 10000, hostValue := 3 } ]
      laserPresent := true
      laserInUse := true
      laserState := 0
      currentWidthBits := 0x40000000 }

theorem th06_laser_profile_count :
    laserOpcodeCount TouhouFormal.TH06.headerShape = 7 := by
  rfl

theorem th07_laser_profile_count :
    laserOpcodeCount TouhouFormal.TH07.headerShape = 11 := by
  rfl

theorem th08_laser_profile_count :
    laserOpcodeCount TouhouFormal.TH08.headerShape = 11 := by
  rfl

theorem th06_laser_index_resolves_through_getvar :
    (outcomeEffect? th06SetLaserIndexOutcome).bind
      (fun effect => effect.selectedSlotWrite) = some 3 := by
  rfl

theorem th06_null_laser_guard_precedes_float_read :
    (outcomePrepared? th06RotateNullLaserOutcome).map
      (fun prepared => (prepared.floatResolutions.length,
        prepared.effect.angleWrite)) =
      some (0, none) := by
  rfl

theorem th06_laser_high_index_faults_before_float_read :
    (outcomeAction? th06RotateHighFaultOutcome,
      (outcomePrepared? th06RotateHighFaultOutcome).map
        (fun prepared => prepared.floatResolutions.length),
      (outcomeFault? th06RotateHighFaultOutcome).map
        (fun fault => (fault.kind, fault.index, fault.bound))) =
      (some .hostFault, some 0,
        some (.outOfBoundsRead, some 32, some 32)) := by
  rfl

theorem th06_laser_test_active_sets_compare_register_zero :
    (outcomeEffect? th06LaserTestActiveOutcome).bind
      (fun effect => effect.testWrite) =
      some { target := .compareRegister, value := 0 } := by
  rfl

theorem th06_laser_cancel_does_not_copy_current_width :
    (outcomeEffect? th06LaserCancelOutcome).bind
      (fun effect => effect.stopWrite) =
      some
        { slot := 1
          stateWrite := 2
          timerWrite := 0
          widthWriteBits := none } := by
  rfl

theorem th07_add_laser_angle_uses_normalized_mode :
    (outcomeEffect? th07AddLaserAngleOutcome).bind
      (fun effect => effect.angleWrite) =
      some
        { slot := 4
          mode := .addNormalized
          operandBits := 123
          playerAngleBits := none } := by
  rfl

theorem th07_laser_hide_warning_truncates_to_u8 :
    (outcomeEffect? th07HideWarningOutcome).bind
      (fun effect => effect.hideWarningWrite) =
      some { slot := 1, value := 44 } := by
  rfl

theorem th07_laser_stop_copies_current_width :
    (outcomeEffect? th07StopLaserOutcome).bind
      (fun effect => effect.stopWrite) =
      some
        { slot := 1
          stateWrite := 2
          timerWrite := 0
          widthWriteBits := some 0x3f800000 } := by
  rfl

theorem th07_clear_lasers_clears_all_slots :
    (outcomeEffect? th07ClearLasersOutcome).bind
      (fun effect => effect.clearAllSlots) = some 32 := by
  rfl

theorem th08_laser_test_active_sets_extra_int_variable :
    (outcomeEffect? th08TestLaserInUseOutcome).bind
      (fun effect => effect.testWrite) =
      some { target := .extraIntVariable 2, value := 1 } := by
  rfl

theorem th08_null_laser_guard_precedes_set_angle_float_read :
    (outcomePrepared? th08SetLaserAngleNullOutcome).map
      (fun prepared => (prepared.floatResolutions.length,
        prepared.effect.angleWrite)) =
      some (0, none) := by
  rfl

theorem th08_negative_laser_slot_faults_before_offset_reads :
    (outcomeAction? th08SetLaserOffsetsNegativeFaultOutcome,
      (outcomePrepared? th08SetLaserOffsetsNegativeFaultOutcome).map
        (fun prepared => prepared.floatResolutions.length),
      (outcomeFault? th08SetLaserOffsetsNegativeFaultOutcome).map
        (fun fault => (fault.kind, fault.index, fault.bound))) =
      (some .hostFault, some 0,
        some (.outOfBoundsRead, some (-1), some 32)) := by
  rfl

theorem th08_laser_stop_copies_current_width :
    (outcomeEffect? th08StopLaserOutcome).bind
      (fun effect => effect.stopWrite) =
      some
        { slot := 3
          stateWrite := 2
          timerWrite := 0
          widthWriteBits := some 0x40000000 } := by
  rfl

end TouhouFormal.Search.Laser
