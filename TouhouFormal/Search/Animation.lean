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

def th07AutoRotateOutcome : Except TouhouFormal.Fault RawAnimationOutcome :=
  rawAnimationStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH07.eclOpcodeSetVmAutoRotate (some 1))
    { intInputs := [ { rawValue := 3 } ] }

def th08SequentialOutcome : Except TouhouFormal.Fault RawAnimationOutcome :=
  rawAnimationStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH08.eclOpcodeSetAlternateAnmSequential (some 1))
    { intInputs := [ { rawValue := 10000, hostValue := 32766 } ] }

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

def th08RotationOutcome : Except TouhouFormal.Fault RawAnimationOutcome :=
  rawAnimationStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    (mkPrefix TouhouFormal.TH08.eclOpcodeSetPrimaryVmRotZ (some 1))
    { floatInputs := [ { rawValue := 1176272896, hostValue := 123 } ] }

theorem th06_animation_profile_count :
    animationOpcodeCount TouhouFormal.TH06.headerShape = 5 := by
  rfl

theorem th07_animation_profile_count :
    animationOpcodeCount TouhouFormal.TH07.headerShape = 6 := by
  rfl

theorem th08_animation_profile_count :
    animationOpcodeCount TouhouFormal.TH08.headerShape = 10 := by
  rfl

theorem th06_set_anm_adds_enemy_script_base :
    (outcomeEffect? th06SetAnmOutcome).bind (fun effect => effect.hostCall) =
      some
        { bank := .primary
          target := .primary
          scriptId := 0x100 + 12 } := by
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

theorem th07_auto_rotate_truncates_raw_byte_to_bitfield :
    (outcomeEffect? th07AutoRotateOutcome).bind
      (fun effect => effect.autoRotateWrite) = some 1 := by
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

theorem th08_primary_rotation_resolves_float_operand :
    (outcomeEffect? th08RotationOutcome).bind
      (fun effect => effect.primaryRotationZWrite) = some 123 := by
  rfl

end TouhouFormal.Search.Animation
