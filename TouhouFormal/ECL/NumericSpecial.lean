import TouhouFormal.ECL.Assignment
import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

structure RawNumericSpecialOutputOperand where
  rawValue : Int := 0
  intHostBefore : Int := 0
  floatHostBefore : Int := 0
deriving Repr, DecidableEq

structure RawNumericSpecialFloatInput where
  rawValue : Int := 0
  hostValue : Int := 0
deriving Repr, DecidableEq

structure RawNumericSpecialOperands where
  outputs : List RawNumericSpecialOutputOperand := []
  floatInputs : List RawNumericSpecialFloatInput := []
  hostResultBits : List Int := []
  enemyPositionXBits : Int := 0
  enemyPositionYBits : Int := 0
  enemyPositionZBits : Int := 0
deriving Repr, DecidableEq

structure RawNumericSpecialResolvedInput where
  operandIndex : Nat
  resolution : RawFloatOperandResolution
deriving Repr, DecidableEq

structure RawNumericSpecialWrite where
  operandIndex : Nat
  output : RawScalarAssignOutput
  resultBits : Int
deriving Repr, DecidableEq

structure RawNumericSpecialEffect where
  kind : RawNumericSpecialOpKind
  inputBits : List Int
  writes : List RawNumericSpecialWrite
deriving Repr, DecidableEq

inductive RawNumericSpecialAction where
  | yielded
  | skipped
  | advanced
  | noWritableOutput
  | vmError
deriving Repr, DecidableEq

structure RawNumericSpecialPrepared where
  op : RawNumericSpecialOpShape
  inputResolutions : List RawNumericSpecialResolvedInput
  effect : RawNumericSpecialEffect
deriving Repr, DecidableEq

structure RawNumericSpecialOutcome where
  action : RawNumericSpecialAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  effect : Option RawNumericSpecialEffect := none
  prepared : Option RawNumericSpecialPrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.numericSpecial"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def malformedNumericSpecialFault
    (shape : HeaderShape)
    (op : RawNumericSpecialOpShape)
    (detail : String) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.numericSpecial"
    detail := "numeric opcode " ++ op.kind.name ++ ": " ++ detail
    index := some op.opcode }

private def expectedOutputCount : RawNumericSpecialOpKind -> Nat
  | .copyHostFloat _ => 1
  | .lerp => 1
  | .polarToCartesian => 2
  | .distance2d => 1

private def expectedInputCount : RawNumericSpecialOpKind -> Nat
  | .copyHostFloat _ => 0
  | .lerp => 4
  | .polarToCartesian => 4
  | .distance2d => 4

private def sourceBits
    (source : RawNumericSpecialSource)
    (operands : RawNumericSpecialOperands) : Int :=
  match source with
  | .enemyPositionX => operands.enemyPositionXBits
  | .enemyPositionY => operands.enemyPositionYBits
  | .enemyPositionZ => operands.enemyPositionZBits

private def rawNumericSpecialCursorOutcome
    (action : RawNumericSpecialAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (effect : Option RawNumericSpecialEffect := none)
    (prepared : Option RawNumericSpecialPrepared := none) :
    RawNumericSpecialOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some
      (TouhouFormal.classifyCursorTransfer
        rawPrefix.fileOffset rawPrefix.nextCursor bufferSize)
    effect := effect
    prepared := prepared }

private def resolveInputsAux
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawNumericSpecialOpShape)
    (operands : RawNumericSpecialOperands) :
    Nat -> List Nat -> Except Fault (List RawNumericSpecialResolvedInput)
  | _, [] => .ok []
  | occurrence, operandIndex :: rest => do
      let input <-
        match operands.floatInputs[occurrence]? with
        | some value => .ok value
        | none =>
            .error
              (malformedNumericSpecialFault shape op
                ("missing float occurrence " ++ toString occurrence ++
                  " for operand slot " ++ toString operandIndex))
      let resolution <-
        resolveFloatRValue shape rawPrefix operandIndex
          input.rawValue input.hostValue
      let tail <-
        resolveInputsAux shape rawPrefix op operands (occurrence + 1) rest
      .ok ({ operandIndex := operandIndex, resolution := resolution } :: tail)

private def resolveOutputsAux
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawNumericSpecialOpShape)
    (operands : RawNumericSpecialOperands) :
    Nat -> List Nat -> List Int -> Except Fault (List RawNumericSpecialWrite)
  | _, [], [] => .ok []
  | occurrence, operandIndex :: restIndices, resultBits :: restResults => do
      let operand <-
        match operands.outputs[occurrence]? with
        | some value => .ok value
        | none =>
            .error
              (malformedNumericSpecialFault shape op
                ("missing output occurrence " ++ toString occurrence ++
                  " for operand slot " ++ toString operandIndex))
      let output <-
        resolveScalarOutput shape rawPrefix op.outputPolicy operandIndex
          operand.rawValue operand.intHostBefore operand.floatHostBefore
      let tail <-
        resolveOutputsAux shape rawPrefix op operands (occurrence + 1)
          restIndices restResults
      .ok
        ({ operandIndex := operandIndex
           output := output
           resultBits := resultBits } :: tail)
  | _, _, _ =>
      .error
        (malformedNumericSpecialFault shape op
          "output/result arity does not match the source operation")

private def outputWritable : RawNumericSpecialWrite -> Bool
  | { output := .none, .. } => false
  | _ => true

def rawNumericSpecialPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawNumericSpecialOpShape)
    (operands : RawNumericSpecialOperands) :
    Except Fault RawNumericSpecialPrepared := do
  if op.outputOperandIndices.length != expectedOutputCount op.kind then
    .error
      (malformedNumericSpecialFault shape op
        "profile output arity does not match the operation")
  else if op.inputOperandIndices.length != expectedInputCount op.kind then
    .error
      (malformedNumericSpecialFault shape op
        "profile input-occurrence arity does not match the operation")
  else
    let inputs <-
      resolveInputsAux shape rawPrefix op operands 0 op.inputOperandIndices
    let results :=
      match op.kind with
      | .copyHostFloat source => [sourceBits source operands]
      | _ => operands.hostResultBits
    if results.length != op.outputOperandIndices.length then
      .error
        (malformedNumericSpecialFault shape op
          "host result count does not match the source write count")
    else
      let writes <-
        resolveOutputsAux shape rawPrefix op operands 0
          op.outputOperandIndices results
      let effect :=
        { kind := op.kind
          inputBits := inputs.map (fun input => input.resolution.value)
          writes := writes }
      .ok { op := op, inputResolutions := inputs, effect := effect }

def rawNumericSpecialStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawNumericSpecialOperands) :
    Except Fault RawNumericSpecialOutcome :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      if currentTime != rawPrefix.time then
        .ok { action := .yielded }
      else do
        let difficultyPass <-
          rawDifficultyPass shape rawShape rawPrefix
            activeMask overrideMask maxBits
        if !difficultyPass then
          .ok (rawNumericSpecialCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok (rawNumericSpecialCursorOutcome .vmError rawPrefix bufferSize)
        else
          match rawShape.findNumericSpecialOp? rawPrefix.opcode with
          | none =>
              .ok
                (rawNumericSpecialCursorOutcome .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <-
                rawNumericSpecialPrepare shape rawPrefix op operands
              let action :=
                if prepared.effect.writes.any outputWritable then
                  RawNumericSpecialAction.advanced
                else
                  RawNumericSpecialAction.noWritableOutput
              .ok
                (rawNumericSpecialCursorOutcome
                  action rawPrefix bufferSize
                  (some prepared.effect) (some prepared))

end TouhouFormal.ECL
