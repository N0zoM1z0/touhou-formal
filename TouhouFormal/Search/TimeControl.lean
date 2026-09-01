import TouhouFormal.ECL.TimeControl
import TouhouFormal.TH06.Wire
import TouhouFormal.TH07.Wire
import TouhouFormal.TH08.Wire

namespace TouhouFormal.Search.TimeControl

open TouhouFormal.ECL

def timeControlOpcodeCount (shape : HeaderShape) : Nat :=
  match shape.rawInstrShape with
  | none => 0
  | some rawShape => rawShape.timeControlOps.length

def outcomeEffect?
    (result : Except TouhouFormal.Fault RawTimeControlOutcome) :
    Option RawTimeControlEffect :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.effect

def outcomePrepared?
    (result : Except TouhouFormal.Fault RawTimeControlOutcome) :
    Option RawTimeControlPrepared :=
  match result with
  | .error _ => none
  | .ok outcome => outcome.prepared

def outcomeWrites?
    (result : Except TouhouFormal.Fault RawTimeControlOutcome) :
    Option (List RawTimeControlWrite) :=
  (outcomeEffect? result).map (fun effect => effect.writes)

def outcomeOrdinaryAdvanceOnly?
    (result : Except TouhouFormal.Fault RawTimeControlOutcome) :
    Option Bool :=
  (outcomeEffect? result).map (fun effect => effect.ordinaryAdvanceOnly)

def outcomeIntResolution?
    (result : Except TouhouFormal.Fault RawTimeControlOutcome) :
    Option RawTimeControlIntResolution :=
  (outcomePrepared? result).bind
    (fun prepared =>
      prepared.intResolution.map
        (fun input => input.resolution))

def mkPrefix (opcode : Int) (operandMask : Option Int := none) :
    RawInstrPrefix :=
  { fileOffset := 0
    time := 10
    opcode := opcode
    nextOffset := 16
    difficultyMask := some 1
    operandMask := operandMask }

def th06NoOpOutcome : Except TouhouFormal.Fault RawTimeControlOutcome :=
  rawTimeControlStep
    TouhouFormal.TH06.headerShape
    10 1 0 8 64
    (mkPrefix TouhouFormal.TH06.eclOpcodeNoOp)
    { runtime := { contextTime := 10 } }

def th06TimeSetOutcome : Except TouhouFormal.Fault RawTimeControlOutcome :=
  rawTimeControlStep
    TouhouFormal.TH06.headerShape
    10 1 0 8 64
    (mkPrefix TouhouFormal.TH06.eclOpcodeTimeSet)
    { intInput := { rawValue := -10001, hostValue := 5 }
      runtime := { contextTime := 10 } }

def th07SetWaitOutcome : Except TouhouFormal.Fault RawTimeControlOutcome :=
  rawTimeControlStep
    TouhouFormal.TH07.headerShape
    10 1 0 8 64
    (mkPrefix TouhouFormal.TH07.eclOpcodeSetWaitTimer (some 1))
    { intInput := { rawValue := 10000, hostValue := 12 }
      runtime := { contextTime := 10, contextWaitTimer := 0 } }

def th07AddTimeOutcome : Except TouhouFormal.Fault RawTimeControlOutcome :=
  rawTimeControlStep
    TouhouFormal.TH07.headerShape
    10 1 0 8 64
    (mkPrefix TouhouFormal.TH07.eclOpcodeAddTime (some 1))
    { intInput := { rawValue := 10001, hostValue := -3 }
      runtime := { contextTime := 10 } }

def th07SetScriptWaitRawOutcome :
    Except TouhouFormal.Fault RawTimeControlOutcome :=
  rawTimeControlStep
    TouhouFormal.TH07.headerShape
    10 1 0 8 64
    (mkPrefix TouhouFormal.TH07.eclOpcodeSetScriptWaitTime (some 0))
    { intInput := { rawValue := 4, hostValue := 99 }
      runtime := { contextTime := 10, stageScriptWaitTime := 1 } }

def th08SetSecondaryTimeOutcome :
    Except TouhouFormal.Fault RawTimeControlOutcome :=
  rawTimeControlStep
    TouhouFormal.TH08.headerShape
    10 1 0 8 64
    (mkPrefix TouhouFormal.TH08.eclOpcodeSetSecondaryTime (some 1))
    { intInput := { rawValue := 10000, hostValue := 7 }
      runtime := { contextTime := 10, contextSecondaryTime := 0 } }

def th08NoOpOutcome : Except TouhouFormal.Fault RawTimeControlOutcome :=
  rawTimeControlStep
    TouhouFormal.TH08.headerShape
    10 1 0 8 64
    (mkPrefix TouhouFormal.TH08.eclOpcodeNoOp (some 0))
    { runtime := { contextTime := 10 } }

def th08AddTimeOutcome : Except TouhouFormal.Fault RawTimeControlOutcome :=
  rawTimeControlStep
    TouhouFormal.TH08.headerShape
    10 1 0 8 64
    (mkPrefix TouhouFormal.TH08.eclOpcodeAddTime (some 1))
    { intInput := { rawValue := 10001, hostValue := -2 }
      runtime := { contextTime := 10 } }

def th07WaitGateOutcome : RawTimeControlGateOutcome :=
  rawTimeControlWaitGate .contextWaitTimer 123 4

def th08SecondaryGateOutcome : RawTimeControlGateOutcome :=
  rawTimeControlWaitGate .contextSecondaryTime 77 1

def nonpositiveGateOutcome : RawTimeControlGateOutcome :=
  rawTimeControlWaitGate .contextWaitTimer 55 0

theorem th06_time_control_profile_count :
    timeControlOpcodeCount TouhouFormal.TH06.headerShape = 2 := by
  rfl

theorem th07_time_control_profile_count :
    timeControlOpcodeCount TouhouFormal.TH07.headerShape = 3 := by
  rfl

theorem th08_time_control_profile_count :
    timeControlOpcodeCount TouhouFormal.TH08.headerShape = 3 := by
  rfl

theorem th06_nop_is_ordinary_advance_only :
    outcomeOrdinaryAdvanceOnly? th06NoOpOutcome = some true := by
  rfl

theorem th08_case3_is_ordinary_advance_only :
    outcomeOrdinaryAdvanceOnly? th08NoOpOutcome = some true := by
  rfl

theorem th06_timeset_resolves_getvar_and_adds_to_context_time :
    (outcomeIntResolution? th06TimeSetOutcome,
      outcomeWrites? th06TimeSetOutcome) =
      (some
        (.intRValue
          { kind := .resolvedHost
            value := 5
            rawValue := -10001
            hostValue := some 5
            selectorKnown := true
            flagEnabled := true }),
        some
          [ { target := .contextTime
              valueBefore := 10
              valueAfter := 15 } ]) := by
  rfl

theorem th07_set_wait_timer_uses_operand_flags :
    (outcomeIntResolution? th07SetWaitOutcome,
      outcomeWrites? th07SetWaitOutcome) =
      (some
        (.intRValue
          { kind := .resolvedHost
            value := 12
            rawValue := 10000
            hostValue := some 12
            selectorKnown := true
            flagEnabled := true }),
        some
          [ { target := .contextWaitTimer
              valueBefore := 0
              valueAfter := 12 } ]) := by
  rfl

theorem th07_add_time_can_move_context_time_backward :
    outcomeWrites? th07AddTimeOutcome =
      some
        [ { target := .contextTime
            valueBefore := 10
            valueAfter := 7 } ] := by
  rfl

theorem th07_script_wait_accepts_raw_immediate_when_flag_clear :
    (outcomeIntResolution? th07SetScriptWaitRawOutcome,
      outcomeWrites? th07SetScriptWaitRawOutcome) =
      (some
        (.intRValue
          { kind := .rawImmediate
            value := 4
            rawValue := 4
            hostValue := none
            selectorKnown := false
            flagEnabled := false }),
        some
          [ { target := .stageScriptWaitTime
              valueBefore := 1
              valueAfter := 4 } ]) := by
  rfl

theorem th08_secondary_time_is_context_wait_timer_alias :
    outcomeWrites? th08SetSecondaryTimeOutcome =
      some
        [ { target := .contextSecondaryTime
            valueBefore := 0
            valueAfter := 7 } ] := by
  rfl

theorem th08_add_time_uses_resolved_operand :
    (outcomeIntResolution? th08AddTimeOutcome,
      outcomeWrites? th08AddTimeOutcome) =
      (some
        (.intRValue
          { kind := .resolvedHost
            value := -2
            rawValue := 10001
            hostValue := some (-2)
            selectorKnown := true
            flagEnabled := true }),
        some
          [ { target := .contextTime
              valueBefore := 10
              valueAfter := 8 } ]) := by
  rfl

theorem wait_gate_decrements_timer_and_pre_tail_time :
    th07WaitGateOutcome =
      { action := .waitGate
        bodyMayRun := false
        effect :=
          some
            { target := .contextWaitTimer
              timerBefore := 4
              timerAfter := 3
              contextTimeBefore := 123
              contextTimeBeforeTail := 122
              contextTimeAfterTail := 123 } } := by
  rfl

theorem secondary_gate_has_same_net_time_stall :
    th08SecondaryGateOutcome =
      { action := .waitGate
        bodyMayRun := false
        effect :=
          some
            { target := .contextSecondaryTime
              timerBefore := 1
              timerAfter := 0
              contextTimeBefore := 77
              contextTimeBeforeTail := 76
              contextTimeAfterTail := 77 } } := by
  rfl

theorem nonpositive_gate_allows_body_dispatch :
    nonpositiveGateOutcome =
      { action := .advanced
        bodyMayRun := true
        effect := none } := by
  rfl

end TouhouFormal.Search.TimeControl
