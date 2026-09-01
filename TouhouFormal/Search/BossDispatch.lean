import TouhouFormal.ECL.BossDispatch
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.BossDispatch

open TouhouFormal.ECL

def bossDispatchOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.bossDispatchOps.length

def outcomeEffect?
    (result : Except TouhouFormal.Fault RawBossDispatchOutcome) :
    Option RawBossDispatchEffect :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.effect

def outcomeFault?
    (result : Except TouhouFormal.Fault RawBossDispatchOutcome) :
    Option TouhouFormal.Fault :=
  match result with
  | .error fault => some fault
  | .ok outcome => outcome.fault

def preparedReadCount
    (result : Except TouhouFormal.Fault RawBossDispatchOutcome) : Nat :=
  match result with
  | .error _ => 0
  | .ok outcome =>
      outcome.prepared.map (fun prepared => prepared.reads.length) |>.getD 0

def callPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeCallBossSub
    nextOffset := 20
    difficultyMask := some 1
    operandMask := some 1 }

def pendingPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeSetBossPendingSub
    nextOffset := 20
    difficultyMask := some 1
    operandMask := some 3 }

def absentBosses : Array Bool :=
  #[false, false, false, false, false, false, false, false]

def firstBossPresent : Array Bool :=
  #[true, false, false, false, false, false, false, false]

def th08CallIndex8Outcome :
    Except TouhouFormal.Fault RawBossDispatchOutcome :=
  rawBossDispatchStep TouhouFormal.TH08.headerShape 0 1 0 8 64 callPrefix
    { intInputs := [ { rawValue := 10000, hostValue := 8 } ]
      bossSlots := absentBosses }

def th08CallNullOutcome :
    Except TouhouFormal.Fault RawBossDispatchOutcome :=
  rawBossDispatchStep TouhouFormal.TH08.headerShape 0 1 0 8 64 callPrefix
    { intInputs := [ { rawValue := 10000, hostValue := 0 } ]
      bossSlots := absentBosses }

def th08CallStackFaultOutcome :
    Except TouhouFormal.Fault RawBossDispatchOutcome :=
  rawBossDispatchStep TouhouFormal.TH08.headerShape 0 1 0 8 64 callPrefix
    { intInputs :=
        [ { rawValue := 10000, hostValue := 0 }, { rawValue := 0 } ]
      bossSlots := firstBossPresent
      targetStackDepth := 16
      targetSubOffsets := #[100] }

def th08CallNegativeSubOutcome :
    Except TouhouFormal.Fault RawBossDispatchOutcome :=
  rawBossDispatchStep TouhouFormal.TH08.headerShape 0 1 0 8 64 callPrefix
    { intInputs :=
        [ { rawValue := 10000, hostValue := 0 }, { rawValue := 65535 } ]
      bossSlots := firstBossPresent
      targetStackDepth := 0
      targetSubOffsets := #[100] }

def th08CallSubTableFaultOutcome :
    Except TouhouFormal.Fault RawBossDispatchOutcome :=
  rawBossDispatchStep TouhouFormal.TH08.headerShape 0 1 0 8 64 callPrefix
    { intInputs :=
        [ { rawValue := 10000, hostValue := 0 }, { rawValue := 2 } ]
      bossSlots := firstBossPresent
      targetStackDepth := 0
      targetSubOffsets := #[100] }

def th08PendingGuardNullOutcome :
    Except TouhouFormal.Fault RawBossDispatchOutcome :=
  rawBossDispatchStep TouhouFormal.TH08.headerShape 0 1 0 8 64 pendingPrefix
    { intInputs := [ { rawValue := 10000, hostValue := 0 } ]
      bossSlots := absentBosses }

def th08PendingChangedIndexOutcome :
    Except TouhouFormal.Fault RawBossDispatchOutcome :=
  rawBossDispatchStep TouhouFormal.TH08.headerShape 0 1 0 8 64 pendingPrefix
    { intInputs :=
        [ { rawValue := 10000, hostValue := 0 },
          { rawValue := 10000, hostValue := 1 } ]
      bossSlots := firstBossPresent }

def th08PendingSignedStoreOutcome :
    Except TouhouFormal.Fault RawBossDispatchOutcome :=
  rawBossDispatchStep TouhouFormal.TH08.headerShape 0 1 0 8 64 pendingPrefix
    { intInputs :=
        [ { rawValue := 10000, hostValue := 0 },
          { rawValue := 10000, hostValue := 0 },
          { rawValue := 10001, hostValue := 65535 } ]
      bossSlots := firstBossPresent }

theorem th06_has_no_boss_dispatch_opcode :
    bossDispatchOpcodeCount TouhouFormal.TH06.headerShape = 0 := by
  rfl

theorem th07_has_no_boss_dispatch_opcode :
    bossDispatchOpcodeCount TouhouFormal.TH07.headerShape = 0 := by
  rfl

theorem th08_boss_dispatch_profile_count :
    bossDispatchOpcodeCount TouhouFormal.TH08.headerShape = 2 := by
  rfl

theorem th08_call_index_fault_suppresses_sub_read :
    ((outcomeFault? th08CallIndex8Outcome).map (fun fault => fault.kind),
      preparedReadCount th08CallIndex8Outcome) =
      (some .outOfBoundsRead, 1) := by
  rfl

theorem th08_call_null_fault_suppresses_sub_read :
    ((outcomeFault? th08CallNullOutcome).map (fun fault => fault.kind),
      preparedReadCount th08CallNullOutcome) =
      (some .nullDereference, 1) := by
  rfl

theorem th08_call_stack_fault_preserves_target_advance :
    ((outcomeFault? th08CallStackFaultOutcome).map (fun fault => fault.kind),
      (outcomeEffect? th08CallStackFaultOutcome).map
        (fun effect =>
          (effect.targetInstructionAdvanced, effect.stackDepthBefore,
            effect.stackSaved))) =
      (some .outOfBoundsWrite, some (true, some 16, false)) := by
  rfl

theorem th08_call_negative_i16_sub_is_noop_but_copies_parameters :
    (outcomeEffect? th08CallNegativeSubOutcome).map
      (fun effect =>
        (effect.rawSubId, effect.hostSubId, effect.negativeSubIdNoOp,
          effect.callParameterCopyBytes, effect.stackDepthAfter)) =
      some (some 65535, some (-1), true, some 0x20, some 1) := by
  rfl

theorem th08_call_subtable_fault_preserves_stack_save :
    ((outcomeFault? th08CallSubTableFaultOutcome).map (fun fault => fault.kind),
      (outcomeEffect? th08CallSubTableFaultOutcome).map
        (fun effect =>
          (effect.targetInstructionAdvanced, effect.stackSaved,
            effect.callParameterCopyBytes))) =
      (some .outOfBoundsRead, some (true, true, none)) := by
  rfl

theorem th08_pending_null_guard_suppresses_repeated_reads :
    ((outcomeEffect? th08PendingGuardNullOutcome).map
      (fun effect => effect.nullGuardSkippedBody),
      preparedReadCount th08PendingGuardNullOutcome) =
      (some true, 1) := by
  rfl

theorem th08_pending_repeated_index_can_select_a_null_boss :
    ((outcomeFault? th08PendingChangedIndexOutcome).map
      (fun fault => fault.kind),
      preparedReadCount th08PendingChangedIndexOutcome,
      (outcomeEffect? th08PendingChangedIndexOutcome).map
        (fun effect => (effect.guardBossIndex, effect.targetBossIndex))) =
      (some .nullDereference, 2, some (some 0, some 1)) := by
  rfl

theorem th08_pending_sub_store_truncates_to_signed_i16 :
    (outcomeEffect? th08PendingSignedStoreOutcome).map
      (fun effect =>
        (effect.rawSubId, effect.hostSubId, effect.pendingSubWrite)) =
      some (some 65535, some (-1), some (-1)) := by
  rfl

end TouhouFormal.Search.BossDispatch
