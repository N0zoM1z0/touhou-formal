import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

structure RawCompareRegisterOperands where
  lhsRaw : Int
  rhsRaw : Int
  lhsHost : Int
  rhsHost : Int
  floatOrder : RawFloatOrder := .equal
deriving Repr, DecidableEq

inductive RawCompareOperandResolution where
  | intValue : RawIntOperandResolution -> RawCompareOperandResolution
  | floatValue : RawFloatOperandResolution -> RawCompareOperandResolution
deriving Repr, DecidableEq

def RawCompareOperandResolution.value : RawCompareOperandResolution -> Int
  | .intValue value => value.value
  | .floatValue value => value.value

structure RawCompareRegisterPrepared where
  op : RawCompareRegisterShape
  lhsResolution : RawCompareOperandResolution
  rhsResolution : RawCompareOperandResolution
  compareRegister : Int
deriving Repr, DecidableEq

inductive RawCompareRegisterAction where
  | yielded
  | skipped
  | advanced
  | vmError
deriving Repr, DecidableEq

structure RawCompareRegisterOutcome where
  action : RawCompareRegisterAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  compareRegister : Option Int := none
  prepared : Option RawCompareRegisterPrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.comparison"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def rawCompareRegisterCursorOutcome
    (action : RawCompareRegisterAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (compareRegister : Option Int := none)
    (prepared : Option RawCompareRegisterPrepared := none) :
    RawCompareRegisterOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some
      (TouhouFormal.classifyCursorTransfer
        rawPrefix.fileOffset
        rawPrefix.nextCursor
        bufferSize)
    compareRegister := compareRegister
    prepared := prepared }

private def resolveCompareOperand
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (kind : RawScalarKind)
    (slot : Nat)
    (rawValue hostValue : Int) : Except Fault RawCompareOperandResolution :=
  match kind with
  | .int => do
      let value <- resolveIntRValue shape rawPrefix slot rawValue hostValue
      .ok (.intValue value)
  | .float => do
      let value <- resolveFloatRValue shape rawPrefix slot rawValue hostValue
      .ok (.floatValue value)

private def intCompareRegister (lhs rhs : Int) : Int :=
  if lhs == rhs then 0 else if lhs < rhs then -1 else 1

def rawCompareRegisterPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawCompareRegisterShape)
    (operands : RawCompareRegisterOperands) :
    Except Fault RawCompareRegisterPrepared := do
  let lhs <-
    resolveCompareOperand
      shape
      rawPrefix
      op.scalarKind
      op.lhsOperandIndex
      operands.lhsRaw
      operands.lhsHost
  let rhs <-
    resolveCompareOperand
      shape
      rawPrefix
      op.scalarKind
      op.rhsOperandIndex
      operands.rhsRaw
      operands.rhsHost
  let compareRegister :=
    match op.scalarKind with
    | .int => intCompareRegister lhs.value rhs.value
    | .float => operands.floatOrder.compareRegister
  .ok
    { op := op
      lhsResolution := lhs
      rhsResolution := rhs
      compareRegister := compareRegister }

def rawCompareRegisterStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawCompareRegisterOperands) :
    Except Fault RawCompareRegisterOutcome :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      if currentTime != rawPrefix.time then
        .ok { action := .yielded }
      else do
        let difficultyPass <-
          rawDifficultyPass shape rawShape rawPrefix activeMask overrideMask maxBits
        if !difficultyPass then
          .ok (rawCompareRegisterCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok { action := .vmError }
        else
          match rawShape.findCompareRegisterOp? rawPrefix.opcode with
          | none =>
              .ok (rawCompareRegisterCursorOutcome .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <-
                rawCompareRegisterPrepare shape rawPrefix op operands
              .ok
                (rawCompareRegisterCursorOutcome
                  .advanced
                  rawPrefix
                  bufferSize
                  (some prepared.compareRegister)
                  (some prepared))

end TouhouFormal.ECL
