import TouhouFormal.Core.Word
import TouhouFormal.ECL.Call
import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

structure RawChildContextIntInput where
  rawValue : Int
  hostValue : Int := 0
deriving Repr, DecidableEq

structure RawChildContextOperands where
  inputs : List RawChildContextIntInput := []
  childSlots : Array Bool := #[]
  allocationSucceeds : Bool := true
  subOffsets : Array Nat := #[]
deriving Repr, DecidableEq

inductive RawChildContextIntResolution where
  | rawI32 (value : Int)
  | intRValue (value : RawIntOperandResolution)
deriving Repr, DecidableEq

def RawChildContextIntResolution.value : RawChildContextIntResolution -> Int
  | .rawI32 value => value
  | .intRValue value => value.value

structure RawChildContextRead where
  occurrence : Nat
  operandIndex : Nat
  resolution : RawChildContextIntResolution
deriving Repr, DecidableEq

structure RawChildContextEffect where
  slotIndex : Option Int := none
  oldBlockFreed : Bool := false
  slotCleared : Bool := false
  subGuardValue : Option Int := none
  allocationRequested : Bool := false
  allocationSucceeded : Bool := false
  allocatedBlockByteCount : Option Nat := none
  blockZeroed : Bool := false
  blockSubIdWrite : Option Int := none
  callSubId : Option Int := none
  targetSubOffset : Option Nat := none
  callWasNegativeNoOp : Bool := false
  contextTimeReset : Bool := false
  secondaryTimeReset : Bool := false
  contextSubIdWrite : Option Int := none
  copiedVariableBytes : Option Nat := none
deriving Repr, DecidableEq

inductive RawChildContextAction where
  | yielded
  | skipped
  | advanced
  | hostFault
  | vmError
deriving Repr, DecidableEq

structure RawChildContextPrepared where
  op : RawChildContextOpShape
  reads : List RawChildContextRead
  effect : RawChildContextEffect
  terminalAction : RawChildContextAction
  hostFault : Option Fault := none
deriving Repr, DecidableEq

structure RawChildContextOutcome where
  action : RawChildContextAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  effect : Option RawChildContextEffect := none
  fault : Option Fault := none
  prepared : Option RawChildContextPrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.childContext"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def missingChildContextInputFault
    (shape : HeaderShape)
    (op : RawChildContextOpShape)
    (occurrence operandIndex : Nat) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.childContext"
    detail :=
      "child-context opcode did not receive read occurrence " ++
        toString occurrence ++ " for operand " ++ toString operandIndex
    index := some op.opcode }

private def malformedChildSlotTableFault
    (shape : HeaderShape)
    (op : RawChildContextOpShape)
    (actual : Nat) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.childContext.slotTable"
    detail :=
      "modeled child-context slot table has " ++ toString actual ++
        " entries, profile requires " ++ toString op.slotCount
    index := some op.opcode
    bound := some op.slotCount }

private def childSlotReadFault
    (shape : HeaderShape)
    (op : RawChildContextOpShape)
    (index : Int) : Fault :=
  { kind := .outOfBoundsRead
    title := shape.title
    component := "EclRun.childContext.slotTable"
    detail :=
      "source reads and then writes the fixed child-context pointer table without checking the resolved slot"
    index := some index
    bound := some op.slotCount }

private def childSlotInBounds (slotCount : Nat) (index : Int) : Bool :=
  decide (0 <= index ∧ index < Int.ofNat slotCount)

private def rawChildContextCursorOutcome
    (action : RawChildContextAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (effect : Option RawChildContextEffect := none)
    (fault : Option Fault := none)
    (prepared : Option RawChildContextPrepared := none) :
    RawChildContextOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some
      (TouhouFormal.classifyCursorTransfer
        rawPrefix.fileOffset rawPrefix.nextCursor bufferSize)
    effect := effect
    fault := fault
    prepared := prepared }

private def resolveChildContextInput
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawChildContextOpShape)
    (operands : RawChildContextOperands)
    (occurrence operandIndex : Nat) : Except Fault RawChildContextRead := do
  let input <-
    match operands.inputs[occurrence]? with
    | none =>
        .error
          (missingChildContextInputFault shape op occurrence operandIndex)
    | some input => .ok input
  let resolution <-
    match op.intPolicy with
    | .rawI32 => .ok (.rawI32 input.rawValue)
    | .intRValue => do
        let value <-
          resolveIntRValue shape rawPrefix operandIndex
            input.rawValue input.hostValue
        .ok (.intRValue value)
  .ok
    { occurrence := occurrence
      operandIndex := operandIndex
      resolution := resolution }

private def childContextFaultPrepared
    (op : RawChildContextOpShape)
    (reads : List RawChildContextRead)
    (effect : RawChildContextEffect)
    (fault : Fault) : RawChildContextPrepared :=
  { op := op
    reads := reads
    effect := effect
    terminalAction := .hostFault
    hostFault := some fault }

def rawChildContextPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawChildContextOpShape)
    (operands : RawChildContextOperands) :
    Except Fault RawChildContextPrepared := do
  if operands.childSlots.size != op.slotCount then
    .error
      (malformedChildSlotTableFault shape op operands.childSlots.size)
  else
    let slotRead <-
      resolveChildContextInput shape rawPrefix op operands 0
        op.slotOperandIndex
    let slot := slotRead.resolution.value
    let slotEffect : RawChildContextEffect := { slotIndex := some slot }
    if !childSlotInBounds op.slotCount slot then
      let fault := childSlotReadFault shape op slot
      .ok (childContextFaultPrepared op [slotRead] slotEffect fault)
    else
      let occupied := operands.childSlots[slot.toNat]!
      let clearedEffect : RawChildContextEffect :=
        { slotEffect with
          oldBlockFreed := occupied
          slotCleared := true }
      let guardRead <-
        resolveChildContextInput shape rawPrefix op operands 1
          op.subOperandIndex
      let subGuard := guardRead.resolution.value
      let guardEffect : RawChildContextEffect :=
        { clearedEffect with subGuardValue := some subGuard }
      if subGuard < 0 then
        .ok
          { op := op
            reads := [slotRead, guardRead]
            effect := guardEffect
            terminalAction := .advanced }
      else
        let allocationEffect : RawChildContextEffect :=
          { guardEffect with
            allocationRequested := true
            allocationSucceeded := operands.allocationSucceeds }
        if !operands.allocationSucceeds then
          .ok
            { op := op
              reads := [slotRead, guardRead]
              effect := allocationEffect
              terminalAction := .advanced }
        else
          let zeroedEffect : RawChildContextEffect :=
            { allocationEffect with
              allocatedBlockByteCount := some op.blockByteCount
              blockZeroed := true }
          let subRead <-
            if op.repeatSubReadAfterAllocation then
              resolveChildContextInput shape rawPrefix op operands 2
                op.subOperandIndex
            else
              .ok guardRead
          let rawSub := subRead.resolution.value
          let callSub :=
            if op.truncateCallSubToI16 then
              TouhouFormal.word16BitsToInt rawSub
            else
              rawSub
          let reads :=
            if op.repeatSubReadAfterAllocation then
              [slotRead, guardRead, subRead]
            else
              [slotRead, guardRead]
          let beforeCallEffect : RawChildContextEffect :=
            { zeroedEffect with
              blockSubIdWrite := some rawSub
              callSubId := some callSub }
          match lookupSubOffset shape operands.subOffsets callSub with
          | .error fault =>
              .ok
                (childContextFaultPrepared op reads beforeCallEffect fault)
          | .ok target =>
              let effect : RawChildContextEffect :=
                { beforeCallEffect with
                  targetSubOffset := target
                  callWasNegativeNoOp := target.isNone
                  contextTimeReset := target.isSome
                  secondaryTimeReset := target.isSome
                  contextSubIdWrite :=
                    if target.isSome then some callSub else none
                  copiedVariableBytes := some op.copiedVariableBytes }
              .ok
                { op := op
                  reads := reads
                  effect := effect
                  terminalAction := .advanced }

def rawChildContextStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawChildContextOperands) :
    Except Fault RawChildContextOutcome :=
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
          .ok (rawChildContextCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok (rawChildContextCursorOutcome .vmError rawPrefix bufferSize)
        else
          match rawShape.findChildContextOp? rawPrefix.opcode with
          | none =>
              .ok (rawChildContextCursorOutcome .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <-
                rawChildContextPrepare shape rawPrefix op operands
              .ok
                (rawChildContextCursorOutcome prepared.terminalAction
                  rawPrefix bufferSize (some prepared.effect)
                  prepared.hostFault (some prepared))

end TouhouFormal.ECL
