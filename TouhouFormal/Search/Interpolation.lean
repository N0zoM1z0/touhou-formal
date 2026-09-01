import TouhouFormal.ECL.Interpolation
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.Interpolation

open TouhouFormal.ECL

def interpolationOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.interpolationOps.length

def outcomeEffect?
    (result : Except TouhouFormal.Fault RawInterpolationOutcome) :
    Option RawInterpolationEffect :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.effect

def outcomeFault?
    (result : Except TouhouFormal.Fault RawInterpolationOutcome) :
    Option TouhouFormal.Fault :=
  match result with
  | .error fault => some fault
  | .ok outcome => outcome.fault

def th07InterpolationPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeInitInterpolation
    nextOffset := 44
    difficultyMask := some 1
    operandMask := some 14 }

def th07CallbackIndex8Outcome :
    Except TouhouFormal.Fault RawInterpolationOutcome :=
  rawInterpolationStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    th07InterpolationPrefix
    { affectedVariableBits := 1176260608
      intInputs :=
        [ { rawValue := 10000, hostValue := 60 },
          { rawValue := 10001, hostValue := 8 },
          { rawValue := 10002, hostValue := 3 } ] }

def th08InterpolationPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeInstallInterpolation
    nextOffset := 44
    difficultyMask := some 1
    operandMask := some 0 }

def occupiedDifferentSlots : List RawInterpolationSlotObservation :=
  List.replicate 8
    { callbackPresent := true, affectedVariableBits := 0x3F800000 }

def th08NoAvailableSlotOutcome :
    Except TouhouFormal.Fault RawInterpolationOutcome :=
  rawInterpolationStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08InterpolationPrefix
    { affectedVariableBits := 0
      slots := occupiedDifferentSlots }

def th08SignedZeroMatchOutcome :
    Except TouhouFormal.Fault RawInterpolationOutcome :=
  rawInterpolationStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08InterpolationPrefix
    { affectedVariableBits := 0
      intInputs :=
        [ { rawValue := 60 }, { rawValue := 1 }, { rawValue := 2 } ]
      floatInputs :=
        [ { rawValue := 1 }, { rawValue := 2 },
          { rawValue := 3 }, { rawValue := 4 } ]
      slots :=
        [ { callbackPresent := true
            affectedVariableBits := 0x80000000 } ] }

theorem th06_interpolation_profile_count :
    interpolationOpcodeCount TouhouFormal.TH06.headerShape = 0 := by
  rfl

theorem th07_interpolation_profile_count :
    interpolationOpcodeCount TouhouFormal.TH07.headerShape = 1 := by
  rfl

theorem th08_interpolation_profile_count :
    interpolationOpcodeCount TouhouFormal.TH08.headerShape = 1 := by
  rfl

theorem th07_callback_index_8_is_oob :
    (outcomeFault? th07CallbackIndex8Outcome).map (fun fault => fault.kind) =
      some .outOfBoundsRead := by
  rfl

theorem th07_oob_preserves_pre_callback_writes :
    ((outcomeEffect? th07CallbackIndex8Outcome).bind
      (fun effect => effect.slotWrite)).map
        (fun write =>
          (write.timerReset, write.callbackIndex,
            write.callbackInstalled, write.parameterBits)) =
      some (true, 8, false, []) := by
  rfl

theorem th08_full_mismatch_reads_no_operands :
    ((outcomeEffect? th08NoAvailableSlotOutcome).map
      (fun effect => effect.noAvailableSlot)) = some true := by
  rfl

theorem th08_positive_and_negative_zero_select_same_slot :
    ((outcomeEffect? th08SignedZeroMatchOutcome).map
      (fun effect => effect.selectedSlot)) = some (some 0) := by
  rfl

end TouhouFormal.Search.Interpolation
