import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

structure RawTimeControlIntInput where
  rawValue : Int := 0
  hostValue : Int := 0
deriving Repr, DecidableEq

structure RawTimeControlRuntime where
  contextTime : Int := 0
  contextWaitTimer : Int := 0
  contextSecondaryTime : Int := 0
  stageScriptWaitTime : Int := 0
deriving Repr, DecidableEq

structure RawTimeControlOperands where
  intInput : RawTimeControlIntInput := {}
  runtime : RawTimeControlRuntime := {}
deriving Repr, DecidableEq

inductive RawTimeControlIntResolution where
  | rawI32 : Int -> RawTimeControlIntResolution
  | intRValue : RawIntOperandResolution -> RawTimeControlIntResolution
deriving Repr, DecidableEq

def RawTimeControlIntResolution.value :
    RawTimeControlIntResolution -> Int
  | .rawI32 value => value
  | .intRValue value => value.value

structure RawTimeControlResolvedIntInput where
  shape : RawTimeControlIntInputShape
  resolution : RawTimeControlIntResolution
deriving Repr, DecidableEq

structure RawTimeControlWrite where
  target : RawTimeControlTarget
  valueBefore : Int
  valueAfter : Int
deriving Repr, DecidableEq

structure RawTimeControlEffect where
  writes : List RawTimeControlWrite := []
  ordinaryAdvanceOnly : Bool := false
deriving Repr, DecidableEq

structure RawTimeControlGateEffect where
  target : RawTimeControlTarget
  timerBefore : Int
  timerAfter : Int
  contextTimeBefore : Int
  /--
  The source decrements context time before leaving the interpreter body; the
  normal frame tail then increments it back.  Both values are recorded because
  future scheduler work needs the pre-tail state, while game-observable script
  time sees the post-tail net effect.
  -/
  contextTimeBeforeTail : Int
  contextTimeAfterTail : Int
deriving Repr, DecidableEq

inductive RawTimeControlAction where
  | yielded
  | skipped
  | advanced
  | waitGate
  | vmError
deriving Repr, DecidableEq

structure RawTimeControlPrepared where
  op : RawTimeControlOpShape
  intResolution : Option RawTimeControlResolvedIntInput := none
  effect : RawTimeControlEffect
deriving Repr, DecidableEq

structure RawTimeControlOutcome where
  action : RawTimeControlAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  effect : Option RawTimeControlEffect := none
  prepared : Option RawTimeControlPrepared := none
deriving Repr, DecidableEq

structure RawTimeControlGateOutcome where
  action : RawTimeControlAction
  bodyMayRun : Bool
  effect : Option RawTimeControlGateEffect := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.timeControl"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def malformedTimeControlShapeFault
    (shape : HeaderShape)
    (op : RawTimeControlOpShape)
    (detail : String) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.timeControl"
    detail := "time-control opcode " ++ op.kind.name ++ ": " ++ detail
    index := some op.opcode }

private def rawTimeControlCursorOutcome
    (action : RawTimeControlAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (effect : Option RawTimeControlEffect := none)
    (prepared : Option RawTimeControlPrepared := none) :
    RawTimeControlOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some
      (TouhouFormal.classifyCursorTransfer
        rawPrefix.fileOffset rawPrefix.nextCursor bufferSize)
    effect := effect
    prepared := prepared }

private def resolveTimeControlIntInput
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (inputShape : RawTimeControlIntInputShape)
    (input : RawTimeControlIntInput) :
    Except Fault RawTimeControlResolvedIntInput := do
  let resolution <-
    match inputShape.policy with
    | .rawI32 => .ok (.rawI32 input.rawValue)
    | .intRValue => do
        let value <-
          resolveIntRValue
            shape
            rawPrefix
            inputShape.operandIndex
            input.rawValue
            input.hostValue
        .ok (.intRValue value)
  .ok { shape := inputShape, resolution := resolution }

private def valueBeforeTarget
    (runtime : RawTimeControlRuntime)
    (target : RawTimeControlTarget) : Int :=
  match target with
  | .contextTime => runtime.contextTime
  | .contextWaitTimer => runtime.contextWaitTimer
  | .contextSecondaryTime => runtime.contextSecondaryTime
  | .stageScriptWaitTime => runtime.stageScriptWaitTime

private def requireTimeControlIntInputShape
    (shape : HeaderShape)
    (op : RawTimeControlOpShape) :
    Except Fault RawTimeControlIntInputShape :=
  match op.intInput with
  | some input => .ok input
  | none =>
      .error
        (malformedTimeControlShapeFault
          shape op "missing integer input shape")

def rawTimeControlPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawTimeControlOpShape)
    (operands : RawTimeControlOperands) :
    Except Fault RawTimeControlPrepared := do
  match op.kind with
  | .noOp =>
      .ok
        { op := op
          intResolution := none
          effect := { ordinaryAdvanceOnly := true } }
  | .addToTime =>
      let inputShape <- requireTimeControlIntInputShape shape op
      let input <-
        resolveTimeControlIntInput
          shape rawPrefix inputShape operands.intInput
      let valueBefore := operands.runtime.contextTime
      let effect :=
        { writes :=
            [ { target := .contextTime
                valueBefore := valueBefore
                valueAfter := valueBefore + input.resolution.value } ] }
      .ok
        { op := op
          intResolution := some input
          effect := effect }
  | .setTimer target =>
      let inputShape <- requireTimeControlIntInputShape shape op
      let input <-
        resolveTimeControlIntInput
          shape rawPrefix inputShape operands.intInput
      let valueBefore := valueBeforeTarget operands.runtime target
      let effect :=
        { writes :=
            [ { target := target
                valueBefore := valueBefore
                valueAfter := input.resolution.value } ] }
      .ok
        { op := op
          intResolution := some input
          effect := effect }

def rawTimeControlStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawTimeControlOperands) :
    Except Fault RawTimeControlOutcome :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      if currentTime != rawPrefix.time then
        .ok { action := .yielded }
      else do
        let difficultyPass <-
          rawDifficultyPass shape rawShape rawPrefix activeMask overrideMask maxBits
        if !difficultyPass then
          .ok (rawTimeControlCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok (rawTimeControlCursorOutcome .vmError rawPrefix bufferSize)
        else
          match rawShape.findTimeControlOp? rawPrefix.opcode with
          | none =>
              .ok (rawTimeControlCursorOutcome .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <-
                rawTimeControlPrepare shape rawPrefix op operands
              .ok
                (rawTimeControlCursorOutcome
                  .advanced
                  rawPrefix
                  bufferSize
                  (some prepared.effect)
                  (some prepared))

def rawTimeControlWaitGate
    (target : RawTimeControlTarget)
    (contextTime timer : Int) :
    RawTimeControlGateOutcome :=
  if decide (0 < timer) then
    { action := .waitGate
      bodyMayRun := false
      effect :=
        some
          { target := target
            timerBefore := timer
            timerAfter := timer - 1
            contextTimeBefore := contextTime
            contextTimeBeforeTail := contextTime - 1
            contextTimeAfterTail := contextTime } }
  else
    { action := .advanced
      bodyMayRun := true
      effect := none }

end TouhouFormal.ECL
