import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

structure RawExtensionIntInput where
  rawValue : Int
  hostValue : Int := 0
deriving Repr, DecidableEq

structure RawExtensionOperands where
  inputs : List RawExtensionIntInput := []
deriving Repr, DecidableEq

inductive RawExtensionIndexResolution where
  | rawI32 (value : Int)
  | intRValue (value : RawIntOperandResolution)
deriving Repr, DecidableEq

def RawExtensionIndexResolution.value : RawExtensionIndexResolution -> Int
  | .rawI32 value => value
  | .intRValue value => value.value

structure RawExtensionIndexRead where
  occurrence : Nat
  operandIndex : Nat := 0
  resolution : RawExtensionIndexResolution
deriving Repr, DecidableEq

structure RawExtensionEffect where
  guardIndex : Option Int := none
  tableIndex : Option Int := none
  calledNow : Bool := false
  callbackInstalled : Bool := false
  perFrameInstructionStored : Bool := false
  callbackCleared : Bool := false
deriving Repr, DecidableEq

inductive RawExtensionAction where
  | yielded
  | skipped
  | advanced
  | hostFault
  | vmError
deriving Repr, DecidableEq

structure RawExtensionPrepared where
  op : RawExtensionOpShape
  reads : List RawExtensionIndexRead
  effect : RawExtensionEffect
  terminalAction : RawExtensionAction
  hostFault : Option Fault := none
deriving Repr, DecidableEq

structure RawExtensionOutcome where
  action : RawExtensionAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  effect : Option RawExtensionEffect := none
  fault : Option Fault := none
  prepared : Option RawExtensionPrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.extension"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def missingExtensionInputFault
    (shape : HeaderShape)
    (op : RawExtensionOpShape)
    (occurrence : Nat) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.extension"
    detail :=
      "extension opcode " ++ op.kind.name ++
        " did not receive index-read occurrence " ++ toString occurrence
    index := some op.opcode }

private def extensionTableReadFault
    (shape : HeaderShape)
    (op : RawExtensionOpShape)
    (index : Int) : Fault :=
  { kind := .outOfBoundsRead
    title := shape.title
    component := "EclRun.extension.callbackTable"
    detail :=
      "source indexes the fixed ECL extension callback table without checking the index"
    index := some index
    bound := some op.tableEntryCount }

private def extensionIndexInBounds
    (entryCount : Nat)
    (index : Int) : Bool :=
  decide (0 <= index && index < Int.ofNat entryCount)

private def rawExtensionCursorOutcome
    (action : RawExtensionAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (effect : Option RawExtensionEffect := none)
    (fault : Option Fault := none)
    (prepared : Option RawExtensionPrepared := none) : RawExtensionOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some
      (TouhouFormal.classifyCursorTransfer
        rawPrefix.fileOffset rawPrefix.nextCursor bufferSize)
    effect := effect
    fault := fault
    prepared := prepared }

private def resolveExtensionIndex
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawExtensionOpShape)
    (operands : RawExtensionOperands)
    (occurrence : Nat) : Except Fault RawExtensionIndexRead := do
  let input <-
    match operands.inputs[occurrence]? with
    | none => .error (missingExtensionInputFault shape op occurrence)
    | some input => .ok input
  let resolution <-
    match op.intPolicy with
    | .rawI32 => .ok (.rawI32 input.rawValue)
    | .intRValue => do
        let value <-
          resolveIntRValue shape rawPrefix 0 input.rawValue input.hostValue
        .ok (.intRValue value)
  .ok
    { occurrence := occurrence
      resolution := resolution }

private def extensionFaultPrepared
    (op : RawExtensionOpShape)
    (reads : List RawExtensionIndexRead)
    (effect : RawExtensionEffect)
    (fault : Fault) : RawExtensionPrepared :=
  { op := op
    reads := reads
    effect := effect
    terminalAction := .hostFault
    hostFault := some fault }

private def prepareExtensionCall
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawExtensionOpShape)
    (operands : RawExtensionOperands) : Except Fault RawExtensionPrepared := do
  let indexRead <- resolveExtensionIndex shape rawPrefix op operands 0
  let index := indexRead.resolution.value
  let reads := [indexRead]
  let baseEffect : RawExtensionEffect := { tableIndex := some index }
  if !extensionIndexInBounds op.tableEntryCount index then
    let fault := extensionTableReadFault shape op index
    .ok (extensionFaultPrepared op reads baseEffect fault)
  else
    let effect : RawExtensionEffect :=
      { baseEffect with calledNow := true }
    .ok
      { op := op
        reads := reads
        effect := effect
        terminalAction := .advanced }

private def prepareExtensionInstall
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawExtensionOpShape)
    (operands : RawExtensionOperands) : Except Fault RawExtensionPrepared := do
  let guardRead <- resolveExtensionIndex shape rawPrefix op operands 0
  let guardIndex := guardRead.resolution.value
  if guardIndex < 0 then
    let effect : RawExtensionEffect :=
      { guardIndex := some guardIndex
        callbackCleared := true }
    .ok
      { op := op
        reads := [guardRead]
        effect := effect
        terminalAction := .advanced }
  else
    let tableRead <-
      if op.repeatIndexReadOnInstall then
        resolveExtensionIndex shape rawPrefix op operands 1
      else
        .ok guardRead
    let tableIndex := tableRead.resolution.value
    let reads :=
      if op.repeatIndexReadOnInstall then
        [guardRead, tableRead]
      else
        [guardRead]
    let baseEffect : RawExtensionEffect :=
      { guardIndex := some guardIndex
        tableIndex := some tableIndex }
    if !extensionIndexInBounds op.tableEntryCount tableIndex then
      let fault := extensionTableReadFault shape op tableIndex
      .ok (extensionFaultPrepared op reads baseEffect fault)
    else
      let effect : RawExtensionEffect :=
        { baseEffect with
          callbackInstalled := true
          perFrameInstructionStored := true }
      .ok
        { op := op
          reads := reads
          effect := effect
          terminalAction := .advanced }

def rawExtensionPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawExtensionOpShape)
    (operands : RawExtensionOperands) : Except Fault RawExtensionPrepared :=
  match op.kind with
  | .callNow => prepareExtensionCall shape rawPrefix op operands
  | .installPerFrame => prepareExtensionInstall shape rawPrefix op operands

def rawExtensionStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawExtensionOperands) : Except Fault RawExtensionOutcome :=
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
          .ok (rawExtensionCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok (rawExtensionCursorOutcome .vmError rawPrefix bufferSize)
        else
          match rawShape.findExtensionOp? rawPrefix.opcode with
          | none =>
              .ok (rawExtensionCursorOutcome .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <-
                rawExtensionPrepare shape rawPrefix op operands
              .ok
                (rawExtensionCursorOutcome prepared.terminalAction
                  rawPrefix bufferSize (some prepared.effect)
                  prepared.hostFault (some prepared))

end TouhouFormal.ECL
