import TouhouFormal.ECL.Animation
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.Animation

open TouhouFormal.ECL

def animationOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.animationOps.length

def outcomeEffect?
    (result : Except TouhouFormal.Fault RawAnimationOutcome) :
    Option RawAnimationEffect :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.effect

def outcomePrepared?
    (result : Except TouhouFormal.Fault RawAnimationOutcome) :
    Option RawAnimationPrepared :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.prepared

def outcomeAction?
    (result : Except TouhouFormal.Fault RawAnimationOutcome) :
    Option RawAnimationAction :=
  match result with
  | .error _ => none
  | .ok outcome => some outcome.action

def outcomeFault?
    (result : Except TouhouFormal.Fault RawAnimationOutcome) :
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

def th06SetAnmOutcome : Except TouhouFormal.Fault RawAnimationOutcome :=
  rawAnimationStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH06.eclOpcodeAnmSetMain)
    { intInputs := [ { rawValue := 12 } ] }

def th06SetSlotOutcome : Except TouhouFormal.Fault RawAnimationOutcome :=
  rawAnimationStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH06.eclOpcodeAnmSetSlot)
    { intInputs := [ { rawValue := 7 }, { rawValue := 9 } ] }

def th06SetSlotHighFaultOutcome :
    Except TouhouFormal.Fault RawAnimationOutcome :=
  rawAnimationStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH06.eclOpcodeAnmSetSlot)
    { intInputs := [ { rawValue := 8 }, { rawValue := 9 } ] }

def th06PoseOutcome : Except TouhouFormal.Fault RawAnimationOutcome :=
  rawAnimationStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH06.eclOpcodeAnmSetPoses)
    { intInputs :=
        [ { rawValue := 0x0002ffff },
          { rawValue := 0x0002ffff },
          { rawValue := 0x0004fffd },
          { rawValue := 0x0004fffd },
          { rawValue := 0x0000fffb } ] }

def th06DeathOutcome : Except TouhouFormal.Fault RawAnimationOutcome :=
  rawAnimationStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH06.eclOpcodeAnmSetDeath)
    { intInputs :=
        [ { rawValue := 0x00cc7f80 },
          { rawValue := 0x00cc7f80 },
          { rawValue := 0x00cc7f80 } ] }

def th07SetAnmOutcome : Except TouhouFormal.Fault RawAnimationOutcome :=
  rawAnimationStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH07.eclOpcodeSetAnm (some 1))
    { intInputs := [ { rawValue := 10000, hostValue := 7 } ] }

def th07SubAnmPositiveOutcome : Except TouhouFormal.Fault RawAnimationOutcome :=
  rawAnimationStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH07.eclOpcodeSetSubAnm (some 3))
    { intInputs :=
        [ { rawValue := 10000, hostValue := 3 },
          { rawValue := 10000, hostValue := 5 },
          { rawValue := 10000, hostValue := 1 },
          { rawValue := 10000, hostValue := 6 } ] }

def th07SubAnmClearOutcome : Except TouhouFormal.Fault RawAnimationOutcome :=
  rawAnimationStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH07.eclOpcodeSetSubAnm (some 3))
    { intInputs :=
        [ { rawValue := 10000, hostValue := 1 },
          { rawValue := 10000, hostValue := -1 },
          { rawValue := 10000, hostValue := 0 } ] }

def th07AutoRotateOutcome : Except TouhouFormal.Fault RawAnimationOutcome :=
  rawAnimationStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH07.eclOpcodeSetVmAutoRotate (some 1))
    { intInputs := [ { rawValue := 3 } ] }

def th07SecondaryInterruptHighFaultOutcome :
    Except TouhouFormal.Fault RawAnimationOutcome :=
  rawAnimationStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH07.eclOpcodeSetVmInterrupt)
    { intInputs :=
        [ { rawValue := 2 },
          { rawValue := 0x0000ffff } ] }

def th08SequentialOutcome : Except TouhouFormal.Fault RawAnimationOutcome :=
  rawAnimationStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH08.eclOpcodeSetAlternateAnmSequential (some 1))
    { intInputs := [ { rawValue := 10000, hostValue := 32766 } ] }

def th08ExtraRuntimeAlternateOutcome :
    Except TouhouFormal.Fault RawAnimationOutcome :=
  rawAnimationStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH08.eclOpcodeSetExtraAnm (some 3))
    { intInputs :=
        [ { rawValue := 10000, hostValue := 0 },
          { rawValue := 10000, hostValue := 1 },
          { rawValue := 10000, hostValue := 1 },
          { rawValue := 10000, hostValue := 44 } ]
      runtimeAlternateBank := true }

def th08SpecialPrimaryOutcome : Except TouhouFormal.Fault RawAnimationOutcome :=
  rawAnimationStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH08.eclOpcodePlaySpecialAnm (some 0))
    { runtimeSpecialScript := 44
      runtimeAlternateBank := false }

def th08SpecialAlternateOutcome : Except TouhouFormal.Fault RawAnimationOutcome :=
  rawAnimationStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH08.eclOpcodePlaySpecialAnm (some 0))
    { runtimeSpecialScript := -3
      runtimeAlternateBank := true }

def th08InterruptOutcome : Except TouhouFormal.Fault RawAnimationOutcome :=
  rawAnimationStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH08.eclOpcodeSetPrimaryVmInterrupt (some 1))
    { intInputs := [ { rawValue := 10000, hostValue := 65535 } ] }

def th08SecondaryInterruptOutcome : Except TouhouFormal.Fault RawAnimationOutcome :=
  rawAnimationStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH08.eclOpcodeSetSecondaryVmInterrupt)
    { intInputs :=
        [ { rawValue := 1 },
          { rawValue := 0x0000ffff } ] }

def th08SecondaryInterruptNegativeFaultOutcome :
    Except TouhouFormal.Fault RawAnimationOutcome :=
  rawAnimationStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH08.eclOpcodeSetSecondaryVmInterrupt)
    { intInputs :=
        [ { rawValue := -1 },
          { rawValue := 0 } ] }

def th08RotationOutcome : Except TouhouFormal.Fault RawAnimationOutcome :=
  rawAnimationStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH08.eclOpcodeSetPrimaryVmRotZ (some 1))
    { floatInputs := [ { rawValue := 1176272896, hostValue := 123 } ] }

def th08DeathOutcome : Except TouhouFormal.Fault RawAnimationOutcome :=
  rawAnimationStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH08.eclOpcodeSetDeathAnm)
    { intInputs :=
        [ { rawValue := 0x00aa7f80 },
          { rawValue := 0x00aa7f80 },
          { rawValue := 0x00aa7f80 } ] }

theorem th06_animation_profile_count :
    animationOpcodeCount TouhouFormal.TH06.headerShape = 7 := by
  rfl

theorem th07_animation_profile_count :
    animationOpcodeCount TouhouFormal.TH07.headerShape = 8 := by
  rfl

theorem th08_animation_profile_count :
    animationOpcodeCount TouhouFormal.TH08.headerShape = 14 := by
  rfl

theorem th06_set_anm_adds_enemy_script_base :
    (outcomeEffect? th06SetAnmOutcome).bind (fun effect => effect.hostCall) =
      some
        { bank := .primary
          target := .primary
          scriptId := 0x100 + 12 } := by
  rfl

theorem th06_set_slot_targets_secondary_vm_and_adds_base :
    (outcomeEffect? th06SetSlotOutcome).bind (fun effect => effect.hostCall) =
      some
        { bank := .primary
          target := .secondary 7
          scriptId := 0x100 + 9 } := by
  rfl

theorem th06_set_slot_high_index_diagnoses_then_faults :
    (outcomeAction? th06SetSlotHighFaultOutcome,
      (outcomeEffect? th06SetSlotHighFaultOutcome).bind
        (fun effect => effect.secondarySlotDiagnostic),
      (outcomeFault? th06SetSlotHighFaultOutcome).map
        (fun fault => (fault.kind, fault.index, fault.bound))) =
      (some .hostFault,
        some { slot := 8, bound := 8 },
        some (.outOfBoundsWrite, some 8, some 8)) := by
  rfl

theorem th06_pose_reads_packed_signed_i16_fields :
    (outcomeEffect? th06PoseOutcome).bind
      (fun effect => effect.movementScriptsWrite) =
      some
        { defaultScript := -1
          farLeft := 2
          farRight := -3
          left := 4
          right := -5
          flags := 255 } := by
  rfl

theorem th06_death_copies_three_raw_bytes :
    (outcomeEffect? th06DeathOutcome).bind
      (fun effect => effect.deathScriptsWrite) =
      some { first := 128, second := 127, third := 204 } := by
  rfl

theorem th07_set_anm_uses_resolved_operand_and_title_base :
    (outcomePrepared? th07SetAnmOutcome).bind
      (fun prepared => prepared.scriptResolution) =
      some
        { source := .intRValue 0
          value := 7
          base := 0x900
          scriptId := 0x900 + 7 } := by
  rfl

theorem th07_set_sub_anm_keeps_repeated_source_reads_ordered :
    (outcomeEffect? th07SubAnmPositiveOutcome).map
      (fun effect => (effect.secondarySlotDiagnostic, effect.hostCall)) =
      some
        (some { slot := 3, bound := 2 },
          some
            { bank := .primary
              target := .secondary 1
              scriptId := 0x900 + 6 }) := by
  rfl

theorem th07_set_sub_anm_negative_script_clears_target_slot :
    (outcomeEffect? th07SubAnmClearOutcome).map
      (fun effect => (effect.hostCall, effect.secondaryScriptClear)) =
      some
        (none,
          some { slot := 0, scriptIndex := -1 }) := by
  rfl

theorem th07_auto_rotate_truncates_raw_byte_to_bitfield :
    (outcomeEffect? th07AutoRotateOutcome).bind
      (fun effect => effect.autoRotateWrite) = some 1 := by
  rfl

theorem th07_secondary_interrupt_raw_index_faults_without_diagnostic :
    (outcomeAction? th07SecondaryInterruptHighFaultOutcome,
      (outcomeEffect? th07SecondaryInterruptHighFaultOutcome).bind
        (fun effect => effect.secondarySlotDiagnostic),
      (outcomeFault? th07SecondaryInterruptHighFaultOutcome).map
        (fun fault => (fault.kind, fault.index, fault.bound))) =
      (some .hostFault, none,
        some (.outOfBoundsWrite, some 2, some 2)) := by
  rfl

theorem th08_sequential_table_casts_each_script_to_i16 :
    (outcomeEffect? th08SequentialOutcome).map
      (fun effect =>
        (effect.alternateBankFlagWrite, effect.primaryScriptTableWrite)) =
      some
        (some true,
          some
            { idleInitial := 32766
              moveLeft := 32767
              moveRight := -32768
              idleFromLeft := -32767
              idleFromRight := -32766
              special := -32765
              anmDirection := 255 }) := by
  rfl

theorem th08_extra_anm_uses_runtime_bank_before_clearing_flag :
    (outcomeEffect? th08ExtraRuntimeAlternateOutcome).map
      (fun effect => (effect.hostCall, effect.alternateBankFlagWrite)) =
      some
        (some
          { bank := .alternate
            target := .secondary 1
            scriptId := 44 },
          some false) := by
  rfl

theorem th08_special_script_uses_current_primary_bank :
    (outcomeEffect? th08SpecialPrimaryOutcome).bind
      (fun effect => effect.hostCall) =
      some { bank := .primary, target := .primary, scriptId := 44 } := by
  rfl

theorem th08_special_script_uses_current_alternate_bank :
    (outcomeEffect? th08SpecialAlternateOutcome).bind
      (fun effect => effect.hostCall) =
      some { bank := .alternate, target := .primary, scriptId := -3 } := by
  rfl

theorem th08_primary_interrupt_casts_resolved_int_to_i16 :
    (outcomeEffect? th08InterruptOutcome).bind
      (fun effect => effect.primaryPendingInterruptWrite) = some (-1) := by
  rfl

theorem th08_secondary_interrupt_casts_raw_u16_to_i16 :
    (outcomeEffect? th08SecondaryInterruptOutcome).bind
      (fun effect => effect.secondaryPendingInterruptWrite) =
      some { slot := 1, interruptId := -1 } := by
  rfl

theorem th08_secondary_interrupt_negative_index_faults_without_diagnostic :
    (outcomeAction? th08SecondaryInterruptNegativeFaultOutcome,
      (outcomeEffect? th08SecondaryInterruptNegativeFaultOutcome).bind
        (fun effect => effect.secondarySlotDiagnostic),
      (outcomeFault? th08SecondaryInterruptNegativeFaultOutcome).map
        (fun fault => (fault.kind, fault.index, fault.bound))) =
      (some .hostFault, none,
        some (.outOfBoundsWrite, some (-1), some 2)) := by
  rfl

theorem th08_primary_rotation_resolves_float_operand :
    (outcomeEffect? th08RotationOutcome).bind
      (fun effect => effect.primaryRotationZWrite) = some 123 := by
  rfl

theorem th08_death_copies_three_raw_bytes :
    (outcomeEffect? th08DeathOutcome).bind
      (fun effect => effect.deathScriptsWrite) =
      some { first := 128, second := 127, third := 170 } := by
  rfl

end TouhouFormal.Search.Animation
