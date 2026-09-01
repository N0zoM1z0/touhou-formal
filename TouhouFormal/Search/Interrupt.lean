import TouhouFormal.ECL.Interrupt
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.Interrupt

open TouhouFormal.ECL

def interruptOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.interruptOps.length

def outcomeEffect?
    (result : Except TouhouFormal.Fault RawInterruptOutcome) :
    Option RawInterruptEffect :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.effect

def outcomeAction?
    (result : Except TouhouFormal.Fault RawInterruptOutcome) :
    Option RawInterruptAction :=
  match result with
  | .error _ => none
  | .ok outcome => some outcome.action

def outcomeFault?
    (result : Except TouhouFormal.Fault RawInterruptOutcome) :
    Option TouhouFormal.Fault :=
  match result with
  | .error fault => some fault
  | .ok outcome => outcome.fault

def intTable (count : Nat) (head : Int) : Array Int :=
  match count with
  | 0 => #[]
  | count + 1 => (head :: List.replicate count 0).toArray

def th06SetTablePrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH06.eclOpcodeSetInterrupt
    nextOffset := 20
    difficultyMask := some 1
    operandMask := none }

def th06SetTableOobOutcome : Except TouhouFormal.Fault RawInterruptOutcome :=
  rawInterruptStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 64
    th06SetTablePrefix
    { inputs := [{ rawValue := 4 }, { rawValue := 8 }] }

def th06RunPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH06.eclOpcodeRunInterrupt
    nextOffset := 16
    difficultyMask := some 1
    operandMask := none }

def th06DisabledStackRunOutcome : Except TouhouFormal.Fault RawInterruptOutcome :=
  rawInterruptStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 64
    th06RunPrefix
    { inputs := [{ rawValue := 0 }]
      table := intTable 8 0
      stackDepth := 0
      stackDisabledBefore := true
      subOffsets := #[100] }

def th06SubTableFaultOutcome : Except TouhouFormal.Fault RawInterruptOutcome :=
  rawInterruptStep
    TouhouFormal.TH06.headerShape
    0 1 0 8 64
    th06RunPrefix
    { inputs := [{ rawValue := 0 }]
      table := intTable 8 2
      stackDepth := 0
      stackDisabledBefore := false
      subOffsets := #[100] }

def th07RunPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeRunInterrupt
    nextOffset := 16
    difficultyMask := some 1
    operandMask := some 0 }

def th07TableReadFaultOutcome : Except TouhouFormal.Fault RawInterruptOutcome :=
  rawInterruptStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    th07RunPrefix
    { inputs := [{ rawValue := 32 }]
      table := intTable 32 0
      stackDepth := 0
      stackDisabledBefore := false
      subOffsets := #[100] }

def th07SetStackDisabledPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH07.eclOpcodeSetCallStackDisabled
    nextOffset := 16
    difficultyMask := some 1
    operandMask := some 0 }

def th07SetStackDisabledOutcome : Except TouhouFormal.Fault RawInterruptOutcome :=
  rawInterruptStep
    TouhouFormal.TH07.headerShape
    0 1 0 8 64
    th07SetStackDisabledPrefix
    { inputs := [{ rawValue := 3 }] }

def th08SetTablePrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeSetInterrupt
    nextOffset := 20
    difficultyMask := some 1
    operandMask := some 0 }

def th08SetTableOutcome : Except TouhouFormal.Fault RawInterruptOutcome :=
  rawInterruptStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08SetTablePrefix
    { inputs := [{ rawValue := 0xffff }, { rawValue := 0 }] }

def th08RunPrefix : RawInstrPrefix :=
  { fileOffset := 0
    time := 0
    opcode := TouhouFormal.TH08.eclOpcodeRunInterrupt
    nextOffset := 16
    difficultyMask := some 1
    operandMask := some 0 }

def th08NegativeSubNoOpOutcome : Except TouhouFormal.Fault RawInterruptOutcome :=
  rawInterruptStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08RunPrefix
    { inputs := [{ rawValue := 0 }]
      table := intTable 32 (-1)
      stackDepth := 0
      stackDisabledBefore := false
      subOffsets := #[100] }

def th08TruncatedRunIndexFaultOutcome :
    Except TouhouFormal.Fault RawInterruptOutcome :=
  rawInterruptStep
    TouhouFormal.TH08.headerShape
    0 1 0 8 64
    th08RunPrefix
    { inputs := [{ rawValue := 0xffff }]
      table := intTable 32 0
      stackDepth := 0
      stackDisabledBefore := false
      subOffsets := #[100] }

theorem th06_interrupt_profile_count :
    interruptOpcodeCount TouhouFormal.TH06.headerShape = 3 := by
  rfl

theorem th07_interrupt_profile_count :
    interruptOpcodeCount TouhouFormal.TH07.headerShape = 3 := by
  rfl

theorem th08_interrupt_profile_count :
    interruptOpcodeCount TouhouFormal.TH08.headerShape = 3 := by
  rfl

theorem th06_table_write_checks_source_array_boundary :
    outcomeAction? th06SetTableOobOutcome = some .hostFault ∧
    (outcomeFault? th06SetTableOobOutcome).map
      (fun fault => (fault.kind, fault.index, fault.bound)) =
      some (.outOfBoundsWrite, some 8, some 8) := by
  exact ⟨rfl, rfl⟩

theorem th06_disabled_stack_still_advances_depth :
    (outcomeEffect? th06DisabledStackRunOutcome).map
      (fun effect =>
        (effect.stackContextWriteIndex,
          effect.stackDepthWrite,
          effect.stackAdvancedWithoutSave,
          effect.targetSubOffset)) =
      some (none, some 1, true, some 100) := by
  rfl

theorem th06_subtable_fault_happens_after_context_save :
    outcomeAction? th06SubTableFaultOutcome = some .hostFault ∧
    (outcomeEffect? th06SubTableFaultOutcome).map
      (fun effect =>
        (effect.returnCursorWrite,
          effect.stackContextWriteIndex,
          effect.calledSubId,
          effect.stackDepthWrite,
          effect.runIndexCleared)) =
      some (some 16, some 0, some 2, none, false) := by
  exact ⟨rfl, rfl⟩

theorem th07_table_read_fault_retains_advanced_context_save :
    (outcomeEffect? th07TableReadFaultOutcome).map
      (fun effect =>
        (effect.runIndexWrite,
          effect.returnCursorWrite,
          effect.stackContextWriteIndex)) =
      some (some 32, some 16, some 0) := by
  rfl

theorem th07_stack_disabled_write_truncates_to_one_bit :
    (outcomeEffect? th07SetStackDisabledOutcome).bind
      RawInterruptEffect.stackDisabledWrite = some true := by
  rfl

theorem th08_table_subroutine_write_truncates_to_signed_i16 :
    (outcomeEffect? th08SetTableOutcome).bind RawInterruptEffect.tableWrite =
      some { index := 0, subId := -1 } := by
  rfl

theorem th08_negative_interrupt_sub_uses_call_noop_policy :
    outcomeAction? th08NegativeSubNoOpOutcome = some .interruptNoOp ∧
    (outcomeEffect? th08NegativeSubNoOpOutcome).map
      (fun effect =>
        (effect.calledSubId,
          effect.targetSubOffset,
          effect.stackDepthWrite,
          effect.runIndexCleared)) =
      some (some (-1), none, some 1, true) := by
  exact ⟨rfl, rfl⟩

theorem th08_run_index_is_signed_i16_before_table_read :
    (outcomeFault? th08TruncatedRunIndexFaultOutcome).map
      (fun fault => (fault.kind, fault.index, fault.bound)) =
      some (.outOfBoundsRead, some (-1), some 32) := by
  rfl

end TouhouFormal.Search.Interrupt
