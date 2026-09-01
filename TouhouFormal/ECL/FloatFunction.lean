import TouhouFormal.ECL.Assignment
import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

structure RawFloatFunctionInput where
  rawValue : Int
  hostValue : Int
deriving Repr, DecidableEq

structure RawFloatFunctionOperands where
  outputRaw : Int
  outputIntHostBefore : Int
  outputFloatHostBefore : Int
  inputs : List RawFloatFunctionInput
  resultBits : Int
deriving Repr, DecidableEq

inductive RawFloatFunctionInputResolution where
  | floatRValue : RawFloatOperandResolution -> RawFloatFunctionInputResolution
  | sourcePointerBits : RawIntLValueResolution -> RawFloatFunctionInputResolution
deriving Repr, DecidableEq

def RawFloatFunctionInputResolution.bits : RawFloatFunctionInputResolution -> Option Int
  | .floatRValue value => some value.value
  | .sourcePointerBits value => value.valueBefore

structure RawFloatFunctionPrepared where
  op : RawFloatFunctionShape
  output : RawScalarAssignOutput
  inputResolutions : List RawFloatFunctionInputResolution
  inputBits : List Int
deriving Repr, DecidableEq

structure RawFloatFunctionResult where
  kind : RawFloatFunctionKind
  inputBits : List Int
  resultBits : Int
deriving Repr, DecidableEq

inductive RawFloatFunctionAction where
  | yielded
  | skipped
  | advanced
  | noWritableOutput
  | vmError
deriving Repr, DecidableEq

structure RawFloatFunctionOutcome where
  action : RawFloatFunctionAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  writtenKind : Option RawScalarKind := none
  result : Option RawFloatFunctionResult := none
  prepared : Option RawFloatFunctionPrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.floatFunction"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def malformedFloatFunctionOperandsFault
    (shape : HeaderShape)
    (op : RawFloatFunctionShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.floatFunction"
    detail :=
      "float function " ++ op.kind.name ++
        " expects " ++ toString op.inputOperandIndices.length ++
        " input samples"
    index := some op.opcode }

private def rawFloatFunctionCursorOutcome
    (action : RawFloatFunctionAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (writtenKind : Option RawScalarKind := none)
    (result : Option RawFloatFunctionResult := none)
    (prepared : Option RawFloatFunctionPrepared := none) : RawFloatFunctionOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some
      (TouhouFormal.classifyCursorTransfer
        rawPrefix.fileOffset
        rawPrefix.nextCursor
        bufferSize)
    writtenKind := writtenKind
    result := result
    prepared := prepared }

private def resolveFloatFunctionInput
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (policy : RawFloatFunctionInputPolicy)
    (slot : Nat)
    (input : RawFloatFunctionInput) :
    Except Fault RawFloatFunctionInputResolution :=
  match policy with
  | .floatRValues => do
      let value <-
        resolveFloatRValue
          shape
          rawPrefix
          slot
          input.rawValue
          input.hostValue
      .ok (.floatRValue value)
  | .sourceGetVarPointerBits => do
      let value <-
        resolveIntPointerLValue
          shape
          rawPrefix
          slot
          input.rawValue
          input.hostValue
      .ok (.sourcePointerBits value)

def rawFloatFunctionPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawFloatFunctionShape)
    (operands : RawFloatFunctionOperands) :
    Except Fault RawFloatFunctionPrepared := do
  if op.inputOperandIndices.length != operands.inputs.length then
    .error (malformedFloatFunctionOperandsFault shape op)
  else
    let output <-
      resolveScalarOutput
        shape
        rawPrefix
        op.outputPolicy
        op.outputOperandIndex
        operands.outputRaw
        operands.outputIntHostBefore
        operands.outputFloatHostBefore
    let resolutions <-
      (List.zip op.inputOperandIndices operands.inputs).mapM
        (fun (slot, input) =>
          resolveFloatFunctionInput shape rawPrefix op.inputPolicy slot input)
    let bits := resolutions.filterMap RawFloatFunctionInputResolution.bits
    if bits.length != resolutions.length then
      .error (malformedFloatFunctionOperandsFault shape op)
    else
      .ok
        { op := op
          output := output
          inputResolutions := resolutions
          inputBits := bits }

def rawFloatFunctionStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawFloatFunctionOperands) :
    Except Fault RawFloatFunctionOutcome :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      if currentTime != rawPrefix.time then
        .ok { action := .yielded }
      else do
        let difficultyPass <-
          rawDifficultyPass shape rawShape rawPrefix activeMask overrideMask maxBits
        if !difficultyPass then
          .ok (rawFloatFunctionCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok { action := .vmError }
        else
          match rawShape.findFloatFunction? rawPrefix.opcode with
          | none =>
              .ok (rawFloatFunctionCursorOutcome .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <- rawFloatFunctionPrepare shape rawPrefix op operands
              match prepared.output.kind? with
              | none =>
                  .ok
                    (rawFloatFunctionCursorOutcome
                      .noWritableOutput
                      rawPrefix
                      bufferSize
                      none
                      none
                      (some prepared))
              | some kind =>
                  let result :=
                    { kind := op.kind
                      inputBits := prepared.inputBits
                      resultBits := operands.resultBits }
                  .ok
                    (rawFloatFunctionCursorOutcome
                      .advanced
                      rawPrefix
                      bufferSize
                      (some kind)
                      (some result)
                      (some prepared))

end TouhouFormal.ECL
