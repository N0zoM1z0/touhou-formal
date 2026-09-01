import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

structure RawIntUnaryUpdateOperands where
  outputRaw : Int
  outputHostBefore : Int
deriving Repr, DecidableEq

structure RawIntUnaryUpdatePrepared where
  op : RawIntUnaryUpdateShape
  output : RawIntLValueResolution
  valueBefore : Option Int := none
deriving Repr, DecidableEq

inductive RawIntUnaryUpdateAction where
  | yielded
  | skipped
  | advanced
  | noWritableOutput
  | vmError
deriving Repr, DecidableEq

structure RawIntUnaryUpdateOutcome where
  action : RawIntUnaryUpdateAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  result : Option Int := none
  prepared : Option RawIntUnaryUpdatePrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.intUnaryUpdate"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def rawIntUnaryUpdateCursorOutcome
    (action : RawIntUnaryUpdateAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (result : Option Int := none)
    (prepared : Option RawIntUnaryUpdatePrepared := none) : RawIntUnaryUpdateOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some (TouhouFormal.classifyCursorTransfer rawPrefix.fileOffset rawPrefix.nextCursor bufferSize)
    result := result
    prepared := prepared }

def RawIntUnaryUpdateKind.apply (kind : RawIntUnaryUpdateKind) (value : Int) : Int :=
  match kind with
  | .inc => value + 1
  | .dec => value - 1

def rawIntUnaryUpdatePrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawIntUnaryUpdateShape)
    (operands : RawIntUnaryUpdateOperands) :
    Except Fault RawIntUnaryUpdatePrepared := do
  let output <-
    match op.outputPolicy with
    | .intLValue =>
        resolveIntLValue
          shape
          rawPrefix
          op.outputOperandIndex
          operands.outputRaw
          operands.outputHostBefore
    | .sourceGetVarPointer =>
        resolveIntPointerLValue
          shape
          rawPrefix
          op.outputOperandIndex
          operands.outputRaw
          operands.outputHostBefore
  .ok
    { op := op
      output := output
      valueBefore := output.valueBefore }

def rawIntUnaryUpdateStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawIntUnaryUpdateOperands) :
    Except Fault RawIntUnaryUpdateOutcome :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      if currentTime != rawPrefix.time then
        .ok { action := .yielded }
      else do
        let difficultyPass <- rawDifficultyPass shape rawShape rawPrefix activeMask overrideMask maxBits
        if !difficultyPass then
          .ok (rawIntUnaryUpdateCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok { action := .vmError }
        else
          match rawShape.findIntUnaryUpdate? rawPrefix.opcode with
          | none =>
              .ok (rawIntUnaryUpdateCursorOutcome .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <- rawIntUnaryUpdatePrepare shape rawPrefix op operands
              match prepared.valueBefore with
              | none =>
                  .ok
                    (rawIntUnaryUpdateCursorOutcome
                      .noWritableOutput
                      rawPrefix
                      bufferSize
                      none
                      (some prepared))
              | some value =>
                  .ok
                    (rawIntUnaryUpdateCursorOutcome
                      .advanced
                      rawPrefix
                      bufferSize
                      (some (op.kind.apply value))
                      (some prepared))

end TouhouFormal.ECL
