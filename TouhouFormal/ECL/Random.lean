import TouhouFormal.Core.Word
import TouhouFormal.ECL.Assignment
import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

structure RawRandomOperands where
  outputRaw : Int
  outputIntHostBefore : Int
  outputFloatHostBefore : Int
  valueRaw : Int
  valueHost : Int
  addendRaw : Int := 0
  addendHost : Int := 0
  rngWord : Int
  floatResultBits : Int := 0
  sourceResultHost : Int := 0
deriving Repr, DecidableEq

inductive RawRandomOperandResolution where
  | intValue : RawIntOperandResolution -> RawRandomOperandResolution
  | floatValue : RawFloatOperandResolution -> RawRandomOperandResolution
deriving Repr, DecidableEq

def RawRandomOperandResolution.value : RawRandomOperandResolution -> Int
  | .intValue value => value.value
  | .floatValue value => value.value

structure RawRandomPrepared where
  op : RawRandomOpShape
  output : RawScalarAssignOutput
  valueResolution : RawRandomOperandResolution
  addendResolution : Option RawRandomOperandResolution
  sourceWriteResolution : Option RawIntOperandResolution
  generatedWord : Int
  writtenWord : Int
  positiveSign : Option Bool
deriving Repr, DecidableEq

structure RawRandomResult where
  kind : RawRandomOpKind
  entropyKind : RawRandomEntropyKind
  rngWord : Int
  value : Int
  addend : Option Int
  generatedWord : Int
  writtenWord : Int
  positiveSign : Option Bool
deriving Repr, DecidableEq

inductive RawRandomAction where
  | yielded
  | skipped
  | advanced
  | noWritableOutput
  | vmError
deriving Repr, DecidableEq

structure RawRandomOutcome where
  action : RawRandomAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  writtenKind : Option RawScalarKind := none
  result : Option RawRandomResult := none
  prepared : Option RawRandomPrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.random"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def malformedRandomShapeFault
    (shape : HeaderShape)
    (op : RawRandomOpShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.random"
    detail :=
      "random opcode " ++ op.kind.name ++
        " has an inconsistent addend operand profile"
    index := some op.opcode }

private def rawRandomCursorOutcome
    (action : RawRandomAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (writtenKind : Option RawScalarKind := none)
    (result : Option RawRandomResult := none)
    (prepared : Option RawRandomPrepared := none) : RawRandomOutcome :=
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

private def resolveRandomOperand
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (kind : RawScalarKind)
    (slot : Nat)
    (rawValue hostValue : Int) : Except Fault RawRandomOperandResolution :=
  match kind with
  | .int => do
      let value <-
        resolveIntRValue shape rawPrefix slot rawValue hostValue
      .ok (.intValue value)
  | .float => do
      let value <-
        resolveFloatRValue shape rawPrefix slot rawValue hostValue
      .ok (.floatValue value)

def randomU32InRangeWord (rngWord rangeValue : Int) : Int :=
  let rangeWord := TouhouFormal.toWord32Bits rangeValue
  if rangeWord == 0 then
    0
  else
    TouhouFormal.toWord32Bits rngWord % rangeWord

private def computeRandomWord
    (op : RawRandomOpShape)
    (value : Int)
    (addend : Option Int)
    (operands : RawRandomOperands) : Int :=
  match op.kind with
  | .intRange =>
      randomU32InRangeWord operands.rngWord value
  | .intRangeAdd =>
      TouhouFormal.word32Add
        (randomU32InRangeWord operands.rngWord value)
        (addend.getD 0)
  | .intSign =>
      if TouhouFormal.toWord32Bits operands.rngWord % 2 == 1 then
        TouhouFormal.toWord32Bits value
      else
        TouhouFormal.word32Neg value
  | .floatRange | .floatRangeAdd | .floatSign =>
      TouhouFormal.toWord32Bits operands.floatResultBits

private def randomPositiveSign?
    (kind : RawRandomOpKind)
    (rngWord : Int) : Option Bool :=
  match kind with
  | .intSign | .floatSign =>
      some (TouhouFormal.toWord32Bits rngWord % 2 == 1)
  | _ => none

def rawRandomPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawRandomOpShape)
    (operands : RawRandomOperands) : Except Fault RawRandomPrepared := do
  if op.kind.requiresAddend != op.addendOperandIndex.isSome then
    .error (malformedRandomShapeFault shape op)
  else
    let scalarKind := op.kind.scalarKind
    let valueResolution <-
      resolveRandomOperand
        shape
        rawPrefix
        scalarKind
        op.valueOperandIndex
        operands.valueRaw
        operands.valueHost
    let addendResolution <-
      match op.addendOperandIndex with
      | none => .ok none
      | some slot => do
          let value <-
            resolveRandomOperand
              shape
              rawPrefix
              scalarKind
              slot
              operands.addendRaw
              operands.addendHost
          .ok (some value)
    let addend := addendResolution.map RawRandomOperandResolution.value
    let generatedWord :=
      computeRandomWord op valueResolution.value addend operands
    let sourceWriteResolution <-
      match op.writePolicy with
      | .direct => .ok none
      | .sourceSetVarResolvesResultBits => do
          let value <-
            resolveIntRValue
              shape
              rawPrefix
              0
              (TouhouFormal.word32BitsToInt generatedWord)
              operands.sourceResultHost
          .ok (some value)
    let writtenWord :=
      match sourceWriteResolution with
      | none => generatedWord
      | some value => TouhouFormal.toWord32Bits value.value
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
        addendResolution := addendResolution
        sourceWriteResolution := sourceWriteResolution
        generatedWord := generatedWord
        writtenWord := writtenWord
        positiveSign := randomPositiveSign? op.kind operands.rngWord }

def rawRandomStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawRandomOperands) : Except Fault RawRandomOutcome :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      if currentTime != rawPrefix.time then
        .ok { action := .yielded }
      else do
        let difficultyPass <-
          rawDifficultyPass shape rawShape rawPrefix activeMask overrideMask maxBits
        if !difficultyPass then
          .ok (rawRandomCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok { action := .vmError }
        else
          match rawShape.findRandomOp? rawPrefix.opcode with
          | none => .ok (rawRandomCursorOutcome .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <- rawRandomPrepare shape rawPrefix op operands
              match prepared.output.kind? with
              | none =>
                  .ok
                    (rawRandomCursorOutcome
                      .noWritableOutput
                      rawPrefix
                      bufferSize
                      none
                      none
                      (some prepared))
              | some writtenKind =>
                  let result :=
                    { kind := op.kind
                      entropyKind := op.kind.entropyKind
                      rngWord := TouhouFormal.toWord32Bits operands.rngWord
                      value := prepared.valueResolution.value
                      addend :=
                        prepared.addendResolution.map
                          RawRandomOperandResolution.value
                      generatedWord := prepared.generatedWord
                      writtenWord := prepared.writtenWord
                      positiveSign := prepared.positiveSign }
                  .ok
                    (rawRandomCursorOutcome
                      .advanced
                      rawPrefix
                      bufferSize
                      (some writtenKind)
                      (some result)
                      (some prepared))

end TouhouFormal.ECL
