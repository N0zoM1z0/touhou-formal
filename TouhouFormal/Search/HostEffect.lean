import TouhouFormal.ECL.HostEffect
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.HostEffect

open TouhouFormal.ECL

def hostEffectOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.hostEffectOps.length

def outcomeFault?
    (result : Except TouhouFormal.Fault RawHostEffectOutcome) :
    Option TouhouFormal.Fault :=
  match result with
  | .error fault => some fault
  | .ok outcome => outcome.fault

def outcomeEffect?
    (result : Except TouhouFormal.Fault RawHostEffectOutcome) :
    Option RawHostEffect :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.effect

def th06TrackedEffectPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH06.eclOpcodeSpellcardEffect
    nextOffset := 32
    difficultyMask := some 1
    operandMask := none }

def th06TrackedEffectSlot12 :
    Except TouhouFormal.Fault RawHostEffectOutcome :=
  rawHostEffectStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 64
    th06TrackedEffectPrefix
    { intInputs := [ { rawValue := 0 } ]
      floatInputs :=
        [ { rawValue := 1 }, { rawValue := 2 },
          { rawValue := 3 }, { rawValue := 4 } ]
      trackedSlot := 12 }

def th07SpecialPositionPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeSetSpecialEffectPosition
    nextOffset := 28
    difficultyMask := some 1
    operandMask := some 15 }

def th07SpecialPositionNull :
    Except TouhouFormal.Fault RawHostEffectOutcome :=
  rawHostEffectStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    th07SpecialPositionPrefix
    { intInputs := [ { rawValue := 10000, hostValue := 0 } ]
      floatInputs :=
        [ { rawValue := 1176256512, hostValue := 11 },
          { rawValue := 1176256512, hostValue := 22 },
          { rawValue := 1176256512, hostValue := 33 } ]
      specialEffectPresent := false }

def th08TrackedEffectPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeSpawnTrackedEffect
    nextOffset := 28
    difficultyMask := some 1
    operandMask := some 0 }

def th08TrackedEffectSlot24 :
    Except TouhouFormal.Fault RawHostEffectOutcome :=
  rawHostEffectStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08TrackedEffectPrefix
    { floatInputs :=
        [ { rawValue := 1 }, { rawValue := 2 },
          { rawValue := 3 }, { rawValue := 4 } ]
      trackedSlot := 24 }

def th08AlignmentPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeSpawnAlignmentEffect
    nextOffset := 16
    difficultyMask := some 1
    operandMask := some 1 }

def th08AlignmentOutcome :
    Except TouhouFormal.Fault RawHostEffectOutcome :=
  rawHostEffectStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08AlignmentPrefix
    { intInputs := [ { rawValue := 10000, hostValue := 7 } ]
      alignmentEffectPresent := true
      enemyIndexOdd := true
      playerIsYoukai := true }

theorem th06_host_effect_profile_count :
    hostEffectOpcodeCount TouhouFormal.TH06.headerShape = 4 := by
  rfl

theorem th07_host_effect_profile_count :
    hostEffectOpcodeCount TouhouFormal.TH07.headerShape = 6 := by
  rfl

theorem th08_host_effect_profile_count :
    hostEffectOpcodeCount TouhouFormal.TH08.headerShape = 5 := by
  rfl

theorem th06_tracked_effect_slot_12_is_oob :
    (outcomeFault? th06TrackedEffectSlot12).map (fun fault => fault.kind) =
      some .outOfBoundsWrite := by
  rfl

theorem th07_special_position_can_null_deref :
    (outcomeFault? th07SpecialPositionNull).map (fun fault => fault.kind) =
      some .nullDereference := by
  rfl

theorem th08_tracked_effect_slot_24_is_oob :
    (outcomeFault? th08TrackedEffectSlot24).map (fun fault => fault.kind) =
      some .outOfBoundsWrite := by
  rfl

theorem th08_alignment_effect_adds_0x20 :
    ((outcomeEffect? th08AlignmentOutcome).bind
      (fun effect => effect.alignment)).map (fun effect => effect.effectId) =
      some 39 := by
  rfl

end TouhouFormal.Search.HostEffect
