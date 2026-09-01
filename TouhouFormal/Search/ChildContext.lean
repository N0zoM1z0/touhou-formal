import TouhouFormal.ECL.ChildContext
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.ChildContext

open TouhouFormal.ECL

def childContextOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.childContextOps.length

def outcomeEffect?
    (result : Except TouhouFormal.Fault RawChildContextOutcome) :
    Option RawChildContextEffect :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.effect

def outcomeFault?
    (result : Except TouhouFormal.Fault RawChildContextOutcome) :
    Option TouhouFormal.Fault :=
  match result with
  | .error fault => some fault
  | .ok outcome => outcome.fault

def preparedReadCount
    (result : Except TouhouFormal.Fault RawChildContextOutcome) : Nat :=
  match result with
  | .error _ => 0
  | .ok outcome =>
      match outcome.prepared with
      | none => 0
      | some prepared => prepared.reads.length

def th08ChildPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeSetChildContext
    nextOffset := 20
    difficultyMask := some 1
    operandMask := some 3 }

def th08Slot4Outcome : Except TouhouFormal.Fault RawChildContextOutcome :=
  rawChildContextStep
    TouhouFormal.TH08.headerShape 0 1 0 8 64 th08ChildPrefix
    { inputs := [ { rawValue := 4 } ]
      childSlots := #[false, false, false, false] }

def th08NegativeSubOutcome : Except TouhouFormal.Fault RawChildContextOutcome :=
  rawChildContextStep
    TouhouFormal.TH08.headerShape 0 1 0 8 64 th08ChildPrefix
    { inputs := [ { rawValue := 3 }, { rawValue := -1 } ]
      childSlots := #[false, false, false, true] }

def th08AllocationFailureOutcome :
    Except TouhouFormal.Fault RawChildContextOutcome :=
  rawChildContextStep
    TouhouFormal.TH08.headerShape 0 1 0 8 64 th08ChildPrefix
    { inputs := [ { rawValue := 0 }, { rawValue := 0 } ]
      childSlots := #[false, false, false, false]
      allocationSucceeds := false }

def th08TruncatedNegativeSubOutcome :
    Except TouhouFormal.Fault RawChildContextOutcome :=
  rawChildContextStep
    TouhouFormal.TH08.headerShape 0 1 0 8 64 th08ChildPrefix
    { inputs :=
        [ { rawValue := 1 }, { rawValue := 0 }, { rawValue := 65535 } ]
      childSlots := #[false, false, false, false]
      allocationSucceeds := true
      subOffsets := #[100] }

def th08SubTableFaultOutcome :
    Except TouhouFormal.Fault RawChildContextOutcome :=
  rawChildContextStep
    TouhouFormal.TH08.headerShape 0 1 0 8 64 th08ChildPrefix
    { inputs :=
        [ { rawValue := 2 }, { rawValue := 0 }, { rawValue := 2 } ]
      childSlots := #[false, false, false, false]
      allocationSucceeds := true
      subOffsets := #[100] }

theorem th06_has_no_child_context_opcode :
    childContextOpcodeCount TouhouFormal.TH06.headerShape = 0 := by
  rfl

theorem th07_has_no_child_context_opcode :
    childContextOpcodeCount TouhouFormal.TH07.headerShape = 0 := by
  rfl

theorem th08_child_context_profile_count :
    childContextOpcodeCount TouhouFormal.TH08.headerShape = 1 := by
  rfl

theorem th08_slot_4_faults_before_later_reads :
    ((outcomeFault? th08Slot4Outcome).map (fun fault => fault.kind),
      preparedReadCount th08Slot4Outcome) =
      (some .outOfBoundsRead, 1) := by
  rfl

theorem th08_negative_sub_frees_and_clears_without_allocating :
    (outcomeEffect? th08NegativeSubOutcome).map
      (fun effect =>
        (effect.oldBlockFreed, effect.slotCleared,
          effect.allocationRequested)) =
      some (true, true, false) := by
  rfl

theorem th08_allocation_failure_suppresses_second_sub_read :
    ((outcomeEffect? th08AllocationFailureOutcome).map
      (fun effect =>
        (effect.allocationRequested, effect.allocationSucceeded,
          effect.blockZeroed)),
      preparedReadCount th08AllocationFailureOutcome) =
      (some (true, false, false), 2) := by
  rfl

theorem th08_i16_negative_call_still_copies_variable_region :
    (outcomeEffect? th08TruncatedNegativeSubOutcome).map
      (fun effect =>
        (effect.blockSubIdWrite, effect.callSubId,
          effect.callWasNegativeNoOp, effect.copiedVariableBytes)) =
      some (some 65535, some (-1), true, some 0x78) := by
  rfl

theorem th08_subtable_fault_preserves_allocated_partial_block :
    ((outcomeEffect? th08SubTableFaultOutcome).map
      (fun effect =>
        (effect.slotCleared, effect.blockZeroed,
          effect.blockSubIdWrite, effect.copiedVariableBytes)),
      (outcomeFault? th08SubTableFaultOutcome).map (fun fault => fault.kind)) =
      (some (true, true, some 2, none), some .outOfBoundsRead) := by
  rfl

end TouhouFormal.Search.ChildContext
