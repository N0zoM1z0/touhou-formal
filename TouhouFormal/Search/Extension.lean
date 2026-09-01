import TouhouFormal.ECL.Extension
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.Extension

open TouhouFormal.ECL

def extensionOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.extensionOps.length

def outcomeEffect?
    (result : Except TouhouFormal.Fault RawExtensionOutcome) :
    Option RawExtensionEffect :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.effect

def outcomeFault?
    (result : Except TouhouFormal.Fault RawExtensionOutcome) :
    Option TouhouFormal.Fault :=
  match result with
  | .error fault => some fault
  | .ok outcome => outcome.fault

def preparedReadCount
    (result : Except TouhouFormal.Fault RawExtensionOutcome) : Nat :=
  match result with
  | .error _ => 0
  | .ok outcome =>
      match outcome.prepared with
      | none => 0
      | some prepared => prepared.reads.length

def th06CallPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH06.eclOpcodeExtensionCall
    nextOffset := 16
    difficultyMask := some 1 }

def th06Index17Outcome : Except TouhouFormal.Fault RawExtensionOutcome :=
  rawExtensionStep
    TouhouFormal.TH06.headerShape 0 1 0 8 64 th06CallPrefix
    { inputs := [ { rawValue := 17 } ] }

def th07InstallPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeSetExtension
    nextOffset := 16
    difficultyMask := some 1
    operandMask := some 1 }

def th07SecondRead24Outcome :
    Except TouhouFormal.Fault RawExtensionOutcome :=
  rawExtensionStep
    TouhouFormal.TH07.headerShape 0 1 0 8 64 th07InstallPrefix
    { inputs :=
        [ { rawValue := 10000, hostValue := 0 },
          { rawValue := 10000, hostValue := 24 } ] }

def th08InstallPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeSetExtension
    nextOffset := 16
    difficultyMask := some 1
    operandMask := some 0 }

def th08NegativeClearOutcome :
    Except TouhouFormal.Fault RawExtensionOutcome :=
  rawExtensionStep
    TouhouFormal.TH08.headerShape 0 1 0 8 64 th08InstallPrefix
    { inputs := [ { rawValue := -1 } ] }

def th08CallPrefix : RawInstrPrefix :=
  { th08InstallPrefix with opcode := TouhouFormal.TH08.eclOpcodeRunExtension }

def th08Index31Outcome : Except TouhouFormal.Fault RawExtensionOutcome :=
  rawExtensionStep
    TouhouFormal.TH08.headerShape 0 1 0 8 64 th08CallPrefix
    { inputs := [ { rawValue := 31 } ] }

theorem th06_extension_profile_count :
    extensionOpcodeCount TouhouFormal.TH06.headerShape = 2 := by
  rfl

theorem th07_extension_profile_count :
    extensionOpcodeCount TouhouFormal.TH07.headerShape = 2 := by
  rfl

theorem th08_extension_profile_count :
    extensionOpcodeCount TouhouFormal.TH08.headerShape = 2 := by
  rfl

theorem th06_index_17_is_oob :
    (outcomeFault? th06Index17Outcome).map (fun fault => fault.kind) =
      some .outOfBoundsRead := by
  rfl

theorem th07_install_repeats_resolver_read :
    preparedReadCount th07SecondRead24Outcome = 2 := by
  rfl

theorem th07_second_index_24_is_oob_without_install :
    ((outcomeEffect? th07SecondRead24Outcome).map
      (fun effect =>
        (effect.guardIndex, effect.tableIndex,
          effect.callbackInstalled, effect.perFrameInstructionStored)),
      (outcomeFault? th07SecondRead24Outcome).map (fun fault => fault.kind)) =
      (some (some 0, some 24, false, false), some .outOfBoundsRead) := by
  rfl

theorem th08_negative_index_clears_without_second_read :
    ((outcomeEffect? th08NegativeClearOutcome).map
      (fun effect => effect.callbackCleared),
      preparedReadCount th08NegativeClearOutcome) = (some true, 1) := by
  rfl

theorem th08_index_31_calls_extension :
    (outcomeEffect? th08Index31Outcome).map
      (fun effect => (effect.tableIndex, effect.calledNow)) =
      some (some 31, true) := by
  rfl

end TouhouFormal.Search.Extension
