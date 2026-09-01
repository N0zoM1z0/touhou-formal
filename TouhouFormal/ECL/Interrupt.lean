import TouhouFormal.Core.Word
import TouhouFormal.ECL.Call
import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

structure RawInterruptIntInput where
  rawValue : Int
  hostValue : Int := 0
deriving Repr, DecidableEq

structure RawInterruptOperands where
  inputs : List RawInterruptIntInput := []
  table : Array Int := #[]
  stackDepth : Int := 0
  stackDisabledBefore : Bool := false
  subOffsets : Array Nat := #[]
deriving Repr, DecidableEq

inductive RawInterruptIntResolution where
  | rawI32 (value : Int)
  | rawU8 (value : Int)
  | intRValue (value : RawIntOperandResolution)
deriving Repr, DecidableEq

def RawInterruptIntResolution.value : RawInterruptIntResolution -> Int
  | .rawI32 value | .rawU8 value => value
  | .intRValue value => value.value

structure RawInterruptInputRead where
  operandIndex : Nat
  resolution : RawInterruptIntResolution
deriving Repr, DecidableEq

structure RawInterruptTableWrite where
  index : Int
  subId : Int
deriving Repr, DecidableEq

structure RawInterruptEffect where
  tableWrite : Option RawInterruptTableWrite := none
  stackDisabledWrite : Option Bool := none
  runIndexWrite : Option Int := none
  returnCursorWrite : Option Int := none
  stackContextWriteIndex : Option Int := none
  calledSubId : Option Int := none
  targetSubOffset : Option Nat := none
  stackDepthWrite : Option Int := none
  stackAdvancedWithoutSave : Bool := false
  runIndexCleared : Bool := false
deriving Repr, DecidableEq

inductive RawInterruptAction where
  | yielded
  | skipped
  | advanced
  | interruptEntered
  | interruptNoOp
  | hostFault
  | vmError
deriving Repr, DecidableEq

structure RawInterruptPrepared where
  op : RawInterruptOpShape
  reads : List RawInterruptInputRead
  effect : RawInterruptEffect
  terminalAction : RawInterruptAction
  hostFault : Option Fault := none
deriving Repr, DecidableEq

structure RawInterruptOutcome where
  action : RawInterruptAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  effect : Option RawInterruptEffect := none
  fault : Option Fault := none
  prepared : Option RawInterruptPrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.interrupt"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def missingCallRetShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.interrupt"
    detail := "interrupt entry requires the title's CALL stack shape" }

private def missingInterruptInputFault
    (shape : HeaderShape)
    (op : RawInterruptOpShape)
    (operandIndex : Nat) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.interrupt"
    detail :=
      "interrupt opcode " ++ op.kind.name ++
        " did not receive operand slot " ++ toString operandIndex
    index := some op.opcode }

private def malformedInterruptTableFault
    (shape : HeaderShape)
    (op : RawInterruptOpShape)
    (actual : Nat) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.interrupt.table"
    detail :=
      "modeled host table has " ++ toString actual ++
        " entries, profile requires " ++ toString op.tableEntryCount
    index := some op.opcode
    bound := some op.tableEntryCount }

private def interruptTableWriteFault
    (shape : HeaderShape)
    (op : RawInterruptOpShape)
    (index : Int) : Fault :=
  { kind := .outOfBoundsWrite
    title := shape.title
    component := "EclRun.interrupt.tableWrite"
    detail := "source writes the interrupt subroutine table without checking its index"
    index := some index
    bound := some op.tableEntryCount }

private def interruptTableReadFault
    (shape : HeaderShape)
    (op : RawInterruptOpShape)
    (index : Int) : Fault :=
  { kind := .outOfBoundsRead
    title := shape.title
    component := "EclRun.interrupt.tableRead"
    detail := "source reads the interrupt subroutine table without checking its index"
    index := some index
    bound := some op.tableEntryCount }

private def interruptStackWriteFault
    (shape : HeaderShape)
    (callRet : RawCallRetShape)
    (stackDepth : Int) : Fault :=
  { kind := .outOfBoundsWrite
    title := shape.title
    component := "EclRun.interrupt.stackSave"
    detail := "interrupt entry saves the advanced ECL context before its table lookup"
    index := some stackDepth
    bound := some callRet.stackEntryCount }

private def interruptIndexInBounds (entryCount : Nat) (index : Int) : Bool :=
  decide (0 <= index ∧ index < Int.ofNat entryCount)

private def rawInterruptCursorOutcome
    (action : RawInterruptAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (effect : Option RawInterruptEffect := none)
    (fault : Option Fault := none)
    (prepared : Option RawInterruptPrepared := none) : RawInterruptOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some
      (TouhouFormal.classifyCursorTransfer
        rawPrefix.fileOffset rawPrefix.nextCursor bufferSize)
    effect := effect
    fault := fault
    prepared := prepared }

private def resolveInterruptInput
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawInterruptOpShape)
    (operands : RawInterruptOperands)
    (operandIndex : Nat) : Except Fault RawInterruptInputRead := do
  let input <-
    match operands.inputs[operandIndex]? with
    | none => .error (missingInterruptInputFault shape op operandIndex)
    | some input => .ok input
  let resolution <-
    match op.intPolicy with
    | .rawI32 => .ok (.rawI32 input.rawValue)
    | .rawU8 =>
        .ok (.rawU8 (TouhouFormal.truncateUnsignedBits input.rawValue 8))
    | .intRValue => do
        let value <-
          resolveIntRValue shape rawPrefix operandIndex
            input.rawValue input.hostValue
        .ok (.intRValue value)
  .ok { operandIndex := operandIndex, resolution := resolution }

private def interruptFaultPrepared
    (op : RawInterruptOpShape)
    (reads : List RawInterruptInputRead)
    (effect : RawInterruptEffect)
    (fault : Fault) : RawInterruptPrepared :=
  { op := op
    reads := reads
    effect := effect
    terminalAction := .hostFault
    hostFault := some fault }

private def prepareInterruptTableWrite
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawInterruptOpShape)
    (operands : RawInterruptOperands) : Except Fault RawInterruptPrepared := do
  let subRead <- resolveInterruptInput shape rawPrefix op operands 0
  let indexRead <- resolveInterruptInput shape rawPrefix op operands 1
  let index := indexRead.resolution.value
  let reads := [subRead, indexRead]
  if !interruptIndexInBounds op.tableEntryCount index then
    let fault := interruptTableWriteFault shape op index
    .ok (interruptFaultPrepared op reads {} fault)
  else
    let rawSub := subRead.resolution.value
    let storedSub :=
      if op.truncateStoredSubToI16 then
        TouhouFormal.word16BitsToInt rawSub
      else
        rawSub
    let effect : RawInterruptEffect :=
      { tableWrite := some { index := index, subId := storedSub } }
    .ok
      { op := op
        reads := reads
        effect := effect
        terminalAction := .advanced }

private def prepareInterruptStackDisabled
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawInterruptOpShape)
    (operands : RawInterruptOperands) : Except Fault RawInterruptPrepared := do
  let read <- resolveInterruptInput shape rawPrefix op operands 0
  let enabled := TouhouFormal.truncateUnsignedBits read.resolution.value 1 == 1
  let effect : RawInterruptEffect :=
    { stackDisabledWrite := some enabled }
  .ok
    { op := op
      reads := [read]
      effect := effect
      terminalAction := .advanced }

private def prepareInterruptRun
    (shape : HeaderShape)
    (rawShape : RawInstrShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawInterruptOpShape)
    (operands : RawInterruptOperands) : Except Fault RawInterruptPrepared := do
  let callRet <-
    match rawShape.callRetShape with
    | none => .error (missingCallRetShapeFault shape)
    | some callRet => .ok callRet
  if operands.table.size != op.tableEntryCount then
    .error (malformedInterruptTableFault shape op operands.table.size)
  else
    let runRead <- resolveInterruptInput shape rawPrefix op operands 0
    let rawRunIndex := runRead.resolution.value
    let runIndex :=
      if op.truncateRunIndexToI16 then
        TouhouFormal.word16BitsToInt rawRunIndex
      else
        rawRunIndex
    let reads := [runRead]
    let baseEffect : RawInterruptEffect :=
      { runIndexWrite := some runIndex
        returnCursorWrite := some rawPrefix.nextCursor }
    if !operands.stackDisabledBefore &&
        !interruptIndexInBounds callRet.stackEntryCount operands.stackDepth then
      let fault := interruptStackWriteFault shape callRet operands.stackDepth
      .ok (interruptFaultPrepared op reads baseEffect fault)
    else
      let effectAfterSave : RawInterruptEffect :=
        { baseEffect with
          stackContextWriteIndex :=
            if operands.stackDisabledBefore then none
            else some operands.stackDepth }
      if !interruptIndexInBounds op.tableEntryCount runIndex then
        let fault := interruptTableReadFault shape op runIndex
        .ok (interruptFaultPrepared op reads effectAfterSave fault)
      else
        let subId := operands.table[runIndex.toNat]!
        let effectBeforeCall : RawInterruptEffect :=
          { effectAfterSave with calledSubId := some subId }
        match lookupSubOffset shape operands.subOffsets subId with
        | .error fault =>
            .ok (interruptFaultPrepared op reads effectBeforeCall fault)
        | .ok targetSubOffset =>
            let stackDepthAfter :=
              if operands.stackDepth <
                  Int.ofNat callRet.stackIncrementGuardExclusive then
                operands.stackDepth + 1
              else
                operands.stackDepth
            let advancedWithoutSave :=
              operands.stackDisabledBefore &&
                stackDepthAfter != operands.stackDepth
            let terminalAction :=
              if targetSubOffset.isSome then
                RawInterruptAction.interruptEntered
              else
                RawInterruptAction.interruptNoOp
            let effect : RawInterruptEffect :=
              { effectBeforeCall with
                targetSubOffset := targetSubOffset
                stackDepthWrite := some stackDepthAfter
                stackAdvancedWithoutSave := advancedWithoutSave
                runIndexCleared := true }
            .ok
              { op := op
                reads := reads
                effect := effect
                terminalAction := terminalAction }

def rawInterruptPrepare
    (shape : HeaderShape)
    (rawShape : RawInstrShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawInterruptOpShape)
    (operands : RawInterruptOperands) : Except Fault RawInterruptPrepared :=
  match op.kind with
  | .setTableEntry =>
      prepareInterruptTableWrite shape rawPrefix op operands
  | .run =>
      prepareInterruptRun shape rawShape rawPrefix op operands
  | .setStackDisabled =>
      prepareInterruptStackDisabled shape rawPrefix op operands

def rawInterruptStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawInterruptOperands) : Except Fault RawInterruptOutcome :=
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
          .ok (rawInterruptCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok (rawInterruptCursorOutcome .vmError rawPrefix bufferSize)
        else
          match rawShape.findInterruptOp? rawPrefix.opcode with
          | none =>
              .ok (rawInterruptCursorOutcome .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <-
                rawInterruptPrepare shape rawShape rawPrefix op operands
              .ok
                (rawInterruptCursorOutcome prepared.terminalAction
                  rawPrefix bufferSize (some prepared.effect)
                  prepared.hostFault (some prepared))

end TouhouFormal.ECL
