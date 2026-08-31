import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

def int32Min : Int := -2147483648
def int32Max : Int := 2147483647

structure RawIntBinaryOpOperands where
  outputRaw : Int
  outputHostBefore : Int
  lhsRaw : Int
  rhsRaw : Int
  lhsHost : Int
  rhsHost : Int
deriving Repr, DecidableEq

structure RawIntBinaryOpPrepared where
  op : RawIntBinaryOpShape
  output : RawIntLValueResolution
  lhsResolution : Option RawIntOperandResolution := none
  rhsResolution : Option RawIntOperandResolution := none
  lhsValue : Option Int := none
  rhsValue : Option Int := none
deriving Repr, DecidableEq

inductive RawIntBinaryOpAction where
  | yielded
  | skipped
  | advanced
  | nonIntOutput
  | vmError
deriving Repr, DecidableEq

structure RawIntBinaryOpOutcome where
  action : RawIntBinaryOpAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  result : Option Int := none
  prepared : Option RawIntBinaryOpPrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.arithmetic"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def divideByZeroFault
    (shape : HeaderShape)
    (op : RawIntBinaryOpShape) : Fault :=
  { kind := .divideByZero
    title := shape.title
    component := "EclRun.arithmetic.intBinary"
    detail :=
      "source integer " ++ op.kind.name ++
        " opcode reads a zero RHS/divisor from operand index " ++
        toString op.rhsOperandIndex
    index := some op.opcode }

private def signedDivideOverflowFault
    (shape : HeaderShape)
    (op : RawIntBinaryOpShape) : Fault :=
  { kind := .arithmeticOverflow
    title := shape.title
    component := "EclRun.arithmetic.intBinary"
    detail :=
      "source integer " ++ op.kind.name ++
        " opcode reaches signed i32 divide overflow: INT_MIN / -1"
    index := some op.opcode }

private def rawIntBinaryCursorOutcome
    (action : RawIntBinaryOpAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (result : Option Int := none)
    (prepared : Option RawIntBinaryOpPrepared := none) : RawIntBinaryOpOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some (TouhouFormal.classifyCursorTransfer rawPrefix.fileOffset rawPrefix.nextCursor bufferSize)
    result := result
    prepared := prepared }

private def RawIntBinaryOpKind.evalUnchecked
    (kind : RawIntBinaryOpKind)
    (lhs rhs : Int) : Int :=
  match kind with
  | .add => lhs + rhs
  | .sub => lhs - rhs
  | .mul => lhs * rhs
  | .div => lhs / rhs
  | .mod => lhs % rhs

def rawIntBinaryPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawIntBinaryOpShape)
    (operands : RawIntBinaryOpOperands) :
    Except Fault RawIntBinaryOpPrepared := do
  let output <-
    resolveIntLValue
      shape
      rawPrefix
      op.outputOperandIndex
      operands.outputRaw
      operands.outputHostBefore
  if output.kind == .nonIntOutput then
    .ok
      { op := op
        output := output
        lhsResolution := none
        rhsResolution := none
        lhsValue := none
        rhsValue := none }
  else
    let (lhsResolution, lhsValue) <-
      match op.mode with
      | .assign => do
          let lhs <-
            resolveIntRValue
              shape
              rawPrefix
              op.lhsOperandIndex
              operands.lhsRaw
              operands.lhsHost
          .ok (some lhs, lhs.value)
      | .updateInPlace =>
          match output.valueBefore with
          | some value => .ok (none, value)
          | none =>
              .error
                { kind := .invalidInstruction
                  title := shape.title
                  component := "EclRun.arithmetic.intBinary"
                  detail := "in-place integer opcode has no writable output value" }
    let rhs <-
      resolveIntRValue
        shape
        rawPrefix
        op.rhsOperandIndex
        operands.rhsRaw
        operands.rhsHost
    .ok
      { op := op
        output := output
        lhsResolution := lhsResolution
        rhsResolution := some rhs
        lhsValue := some lhsValue
        rhsValue := some rhs.value }

def rawIntBinaryStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawIntBinaryOpOperands) :
    Except Fault RawIntBinaryOpOutcome :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      if currentTime != rawPrefix.time then
        .ok { action := .yielded }
      else do
        let difficultyPass <- rawDifficultyPass shape rawShape rawPrefix activeMask overrideMask maxBits
        if !difficultyPass then
          .ok (rawIntBinaryCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok { action := .vmError }
        else
          match rawShape.findIntBinaryOp? rawPrefix.opcode with
          | none =>
              .ok (rawIntBinaryCursorOutcome .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <- rawIntBinaryPrepare shape rawPrefix op operands
              if prepared.output.kind == .nonIntOutput then
                .ok
                  (rawIntBinaryCursorOutcome
                    .nonIntOutput
                    rawPrefix
                    bufferSize
                    none
                    (some prepared))
              else
                match prepared.lhsValue, prepared.rhsValue with
                | some lhs, some rhs =>
                    if op.kind.isDivisorHazard && rhs == 0 then
                      .error (divideByZeroFault shape op)
                    else if op.kind.isDivisorHazard && lhs == int32Min && rhs == -1 then
                      .error (signedDivideOverflowFault shape op)
                    else
                      .ok
                        (rawIntBinaryCursorOutcome
                          .advanced
                          rawPrefix
                          bufferSize
                          (some (op.kind.evalUnchecked lhs rhs))
                          (some prepared))
                | _, _ =>
                    .error
                      { kind := .invalidInstruction
                        title := shape.title
                        component := "EclRun.arithmetic.intBinary"
                        detail := "integer binary opcode reached without resolved operands" }

end TouhouFormal.ECL
