import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

structure RawScalarAssignOperands where
  outputRaw : Int
  outputIntHostBefore : Int
  outputFloatHostBefore : Int
  valueRaw : Int
  valueHost : Int
deriving Repr, DecidableEq

inductive RawScalarAssignOutput where
  | int : RawIntLValueResolution -> RawScalarAssignOutput
  | float : RawFloatLValueResolution -> RawScalarAssignOutput
  | none
deriving Repr, DecidableEq

inductive RawScalarAssignRValue where
  | intBits : RawIntOperandResolution -> RawScalarAssignRValue
  | floatBits : RawFloatOperandResolution -> RawScalarAssignRValue
deriving Repr, DecidableEq

def RawScalarAssignOutput.kind? : RawScalarAssignOutput -> Option RawScalarKind
  | .int _ => some .int
  | .float _ => some .float
  | .none => Option.none

def RawScalarAssignRValue.bits : RawScalarAssignRValue -> Int
  | .intBits value => value.value
  | .floatBits value => value.value

structure RawScalarAssignPrepared where
  op : RawScalarAssignShape
  output : RawScalarAssignOutput
  valueResolution : RawScalarAssignRValue
  valueBits : Int
deriving Repr, DecidableEq

inductive RawScalarAssignAction where
  | yielded
  | skipped
  | advanced
  | noWritableOutput
  | vmError
deriving Repr, DecidableEq

structure RawScalarAssignOutcome where
  action : RawScalarAssignAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  writtenKind : Option RawScalarKind := none
  valueBits : Option Int := none
  prepared : Option RawScalarAssignPrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.assignment"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def rawScalarAssignCursorOutcome
    (action : RawScalarAssignAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (writtenKind : Option RawScalarKind := none)
    (valueBits : Option Int := none)
    (prepared : Option RawScalarAssignPrepared := none) : RawScalarAssignOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some (TouhouFormal.classifyCursorTransfer rawPrefix.fileOffset rawPrefix.nextCursor bufferSize)
    writtenKind := writtenKind
    valueBits := valueBits
    prepared := prepared }

def resolveScalarRValue
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (policy : RawScalarAssignRValuePolicy)
    (operandIndex : Nat)
    (rawValue hostValue : Int) :
    Except Fault RawScalarAssignRValue :=
  match policy with
  | .intBits => do
      let value <-
        resolveIntRValue
          shape
          rawPrefix
          operandIndex
          rawValue
          hostValue
      .ok (.intBits value)
  | .floatBits => do
      let value <-
        resolveFloatRValue
          shape
          rawPrefix
          operandIndex
          rawValue
          hostValue
      .ok (.floatBits value)

def resolveScalarOutput
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (policy : RawScalarAssignOutputPolicy)
    (operandIndex : Nat)
    (rawValue intHostBefore floatHostBefore : Int) :
    Except Fault RawScalarAssignOutput :=
  match policy with
  | .intLValue => do
      let output <-
        resolveIntLValue
          shape
          rawPrefix
          operandIndex
          rawValue
          intHostBefore
      if output.kind == .nonIntOutput then
        .ok .none
      else
        .ok (.int output)
  | .floatLValue => do
      let output <-
        resolveFloatLValue
          shape
          rawPrefix
          operandIndex
          rawValue
          floatHostBefore
      if output.kind == .nonFloatOutput then
        .ok .none
      else
        .ok (.float output)
  | .sourceSetVar => do
      let intOutput <-
        resolveIntLValue
          shape
          rawPrefix
          operandIndex
          rawValue
          intHostBefore
      if intOutput.kind != .nonIntOutput then
        .ok (.int intOutput)
      else
        let floatOutput <-
          resolveFloatLValue
            shape
            rawPrefix
            operandIndex
            rawValue
            floatHostBefore
        if floatOutput.kind != .nonFloatOutput then
          .ok (.float floatOutput)
        else
          .ok .none

def rawScalarAssignPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawScalarAssignShape)
    (operands : RawScalarAssignOperands) :
    Except Fault RawScalarAssignPrepared := do
  let valueResolution <-
    resolveScalarRValue
      shape
      rawPrefix
      op.rvaluePolicy
      op.valueOperandIndex
      operands.valueRaw
      operands.valueHost
  let output <-
    resolveScalarOutput
      shape
      rawPrefix
      op.outputPolicy
      op.outputOperandIndex
      operands.outputRaw
      operands.outputIntHostBefore
      operands.outputFloatHostBefore
  .ok
    { op := op
      output := output
      valueResolution := valueResolution
      valueBits := valueResolution.bits }

def rawScalarAssignStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawScalarAssignOperands) :
    Except Fault RawScalarAssignOutcome :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      if currentTime != rawPrefix.time then
        .ok { action := .yielded }
      else do
        let difficultyPass <- rawDifficultyPass shape rawShape rawPrefix activeMask overrideMask maxBits
        if !difficultyPass then
          .ok (rawScalarAssignCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok { action := .vmError }
        else
          match rawShape.findScalarAssign? rawPrefix.opcode with
          | none =>
              .ok (rawScalarAssignCursorOutcome .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <- rawScalarAssignPrepare shape rawPrefix op operands
              match prepared.output.kind? with
              | none =>
                  .ok
                    (rawScalarAssignCursorOutcome
                      .noWritableOutput
                      rawPrefix
                      bufferSize
                      none
                      none
                      (some prepared))
              | some kind =>
                  .ok
                    (rawScalarAssignCursorOutcome
                      .advanced
                      rawPrefix
                      bufferSize
                      (some kind)
                      (some prepared.valueBits)
                      (some prepared))

end TouhouFormal.ECL
