import TouhouFormal.Core.Word
import TouhouFormal.ECL.Call
import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

structure RawBossDispatchIntInput where
  rawValue : Int := 0
  hostValue : Int := 0
deriving Repr, DecidableEq

structure RawBossDispatchOperands where
  intInputs : List RawBossDispatchIntInput := []
  bossSlots : Array Bool := #[]
  targetStackDepth : Int := 0
  targetStackDisabled : Bool := false
  targetSubOffsets : Array Nat := #[]
deriving Repr, DecidableEq

inductive RawBossDispatchIntResolution where
  | rawI32 (value : Int)
  | intRValue (value : RawIntOperandResolution)
deriving Repr, DecidableEq

def RawBossDispatchIntResolution.value :
    RawBossDispatchIntResolution -> Int
  | .rawI32 value => value
  | .intRValue resolution => resolution.value

structure RawBossDispatchRead where
  operandIndex : Nat
  policy : RawBossDispatchIntPolicy
  resolution : RawBossDispatchIntResolution
deriving Repr, DecidableEq

structure RawBossDispatchEffect where
  guardBossIndex : Option Int := none
  targetBossIndex : Option Int := none
  nullGuardSkippedBody : Bool := false
  targetInstructionAdvanced : Bool := false
  stackDepthBefore : Option Int := none
  stackWriteIndex : Option Int := none
  stackSaved : Bool := false
  rawSubId : Option Int := none
  hostSubId : Option Int := none
  targetSubOffset : Option Nat := none
  negativeSubIdNoOp : Bool := false
  callParameterCopyBytes : Option Nat := none
  stackDepthAfter : Option Int := none
  pendingSubWrite : Option Int := none
deriving Repr, DecidableEq

inductive RawBossDispatchAction where
  | yielded
  | skipped
  | advanced
  | hostFault
  | vmError
deriving Repr, DecidableEq

structure RawBossDispatchPrepared where
  op : RawBossDispatchOpShape
  reads : List RawBossDispatchRead := []
  effect : RawBossDispatchEffect
  hostFault : Option Fault := none
deriving Repr, DecidableEq

structure RawBossDispatchOutcome where
  action : RawBossDispatchAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  effect : Option RawBossDispatchEffect := none
  fault : Option Fault := none
  prepared : Option RawBossDispatchPrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.bossDispatch"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def malformedBossDispatchFault
    (shape : HeaderShape)
    (op : RawBossDispatchOpShape)
    (detail : String) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.bossDispatch"
    detail := op.kind.name ++ ": " ++ detail
    index := some op.opcode }

private def bossSlotFault
    (shape : HeaderShape)
    (op : RawBossDispatchOpShape)
    (index : Int) : Fault :=
  { kind := .outOfBoundsRead
    title := shape.title
    component := "EclRun.bossDispatch.bosses"
    detail :=
      "source indexes the fixed boss-pointer table without an opcode-level bounds check"
    index := some index
    bound := some op.bossSlotCount }

private def bossNullFault
    (shape : HeaderShape)
    (op : RawBossDispatchOpShape)
    (index : Int) : Fault :=
  { kind := .nullDereference
    title := shape.title
    component := "EclRun.bossDispatch.bosses"
    detail :=
      "source dereferences the selected boss pointer after the relevant guard"
    index := some index
    bound := some op.bossSlotCount }

private def callStackWriteFault
    (shape : HeaderShape)
    (op : RawBossDispatchOpShape)
    (depth : Int) : Fault :=
  { kind := .outOfBoundsWrite
    title := shape.title
    component := "EclRun.bossDispatch.callStack"
    detail :=
      "CallSubOnEnemy saves the target context before checking its depth increment guard"
    index := some depth
    bound := some op.callStackEntryCount }

private def malformedBossTableFault
    (shape : HeaderShape)
    (op : RawBossDispatchOpShape)
    (actual : Nat) : Fault :=
  malformedBossDispatchFault shape op
    ("modeled boss table has " ++ toString actual ++
      " entries; expected " ++ toString op.bossSlotCount)

private def rawBossDispatchCursorOutcome
    (action : RawBossDispatchAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (effect : Option RawBossDispatchEffect := none)
    (fault : Option Fault := none)
    (prepared : Option RawBossDispatchPrepared := none) :
    RawBossDispatchOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some
      (TouhouFormal.classifyCursorTransfer
        rawPrefix.fileOffset rawPrefix.nextCursor bufferSize)
    effect := effect
    fault := fault
    prepared := prepared }

private def inputAt
    (shape : HeaderShape)
    (op : RawBossDispatchOpShape)
    (operands : RawBossDispatchOperands)
    (occurrence operandIndex : Nat) :
    Except Fault RawBossDispatchIntInput :=
  match operands.intInputs[occurrence]? with
  | some input => .ok input
  | none =>
      .error
        (malformedBossDispatchFault shape op
          ("missing integer occurrence " ++ toString occurrence ++
            " for operand slot " ++ toString operandIndex))

private def resolveRead
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawBossDispatchOpShape)
    (operands : RawBossDispatchOperands)
    (occurrence operandIndex : Nat)
    (policy : RawBossDispatchIntPolicy) :
    Except Fault RawBossDispatchRead := do
  let input <- inputAt shape op operands occurrence operandIndex
  let resolution <-
    match policy with
    | .rawI32 => .ok (.rawI32 input.rawValue)
    | .intRValue => do
        let value <-
          resolveIntRValue shape rawPrefix operandIndex
            input.rawValue input.hostValue
        .ok (.intRValue value)
  .ok { operandIndex := operandIndex, policy := policy, resolution := resolution }

private def bossIndexInBounds (op : RawBossDispatchOpShape) (index : Int) : Bool :=
  decide (0 <= index ∧ index < Int.ofNat op.bossSlotCount)

private def bossPresent
    (operands : RawBossDispatchOperands)
    (index : Int) : Bool :=
  operands.bossSlots[index.toNat]!

private def faultPrepared
    (op : RawBossDispatchOpShape)
    (reads : List RawBossDispatchRead)
    (effect : RawBossDispatchEffect)
    (fault : Fault) : RawBossDispatchPrepared :=
  { op := op, reads := reads, effect := effect, hostFault := some fault }

private def prepareCallSubOnBoss
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawBossDispatchOpShape)
    (operands : RawBossDispatchOperands) :
    Except Fault RawBossDispatchPrepared := do
  let indexRead <-
    resolveRead shape rawPrefix op operands 0 op.bossIndexOperandIndex
      op.bossIndexPolicy
  let index := indexRead.resolution.value
  let indexEffect : RawBossDispatchEffect :=
    { guardBossIndex := some index, targetBossIndex := some index }
  if !bossIndexInBounds op index then
    .ok
      (faultPrepared op [indexRead] indexEffect
        (bossSlotFault shape op index))
  else if !bossPresent operands index then
    .ok
      (faultPrepared op [indexRead] indexEffect
        (bossNullFault shape op index))
  else
    let subRead <-
      resolveRead shape rawPrefix op operands 1 op.subIdOperandIndex
        op.subIdPolicy
    let rawSubId := subRead.resolution.value
    let hostSubId :=
      if op.truncateSubIdToI16 then
        TouhouFormal.word16BitsToInt rawSubId
      else
        rawSubId
    let beforeStack : RawBossDispatchEffect :=
      { indexEffect with
        targetInstructionAdvanced := true
        stackDepthBefore := some operands.targetStackDepth
        rawSubId := some rawSubId
        hostSubId := some hostSubId }
    if !operands.targetStackDisabled &&
        !(decide (0 <= operands.targetStackDepth ∧
          operands.targetStackDepth < Int.ofNat op.callStackEntryCount)) then
      .ok
        (faultPrepared op [indexRead, subRead] beforeStack
          (callStackWriteFault shape op operands.targetStackDepth))
    else
      let afterStack : RawBossDispatchEffect :=
        { beforeStack with
          stackWriteIndex :=
            if operands.targetStackDisabled then
              none
            else
              some operands.targetStackDepth
          stackSaved := !operands.targetStackDisabled }
      match lookupSubOffset shape operands.targetSubOffsets hostSubId with
      | .error fault =>
          .ok (faultPrepared op [indexRead, subRead] afterStack fault)
      | .ok target =>
          let depthAfter :=
            if !operands.targetStackDisabled &&
                operands.targetStackDepth <
                  Int.ofNat op.callStackIncrementGuardExclusive then
              operands.targetStackDepth + 1
            else
              operands.targetStackDepth
          .ok
            { op := op
              reads := [indexRead, subRead]
              effect :=
                { afterStack with
                  targetSubOffset := target
                  negativeSubIdNoOp := target.isNone
                  callParameterCopyBytes := some op.callParameterCopyBytes
                  stackDepthAfter := some depthAfter } }

private def preparePendingSubOnBoss
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawBossDispatchOpShape)
    (operands : RawBossDispatchOperands) :
    Except Fault RawBossDispatchPrepared := do
  let guardRead <-
    resolveRead shape rawPrefix op operands 0 op.bossIndexOperandIndex
      op.bossIndexPolicy
  let guardIndex := guardRead.resolution.value
  let guardEffect : RawBossDispatchEffect :=
    { guardBossIndex := some guardIndex }
  if !bossIndexInBounds op guardIndex then
    .ok
      (faultPrepared op [guardRead] guardEffect
        (bossSlotFault shape op guardIndex))
  else if !bossPresent operands guardIndex then
    .ok
      { op := op
        reads := [guardRead]
        effect := { guardEffect with nullGuardSkippedBody := true } }
  else
    let targetRead <-
      if op.repeatBossIndexRead then
        resolveRead shape rawPrefix op operands 1 op.bossIndexOperandIndex
          op.bossIndexPolicy
      else
        .ok guardRead
    let targetIndex := targetRead.resolution.value
    let readsBeforeSub :=
      if op.repeatBossIndexRead then [guardRead, targetRead] else [guardRead]
    let targetEffect : RawBossDispatchEffect :=
      { guardEffect with targetBossIndex := some targetIndex }
    if !bossIndexInBounds op targetIndex then
      .ok
        (faultPrepared op readsBeforeSub targetEffect
          (bossSlotFault shape op targetIndex))
    else if !bossPresent operands targetIndex then
      .ok
        (faultPrepared op readsBeforeSub targetEffect
          (bossNullFault shape op targetIndex))
    else
      let subOccurrence := if op.repeatBossIndexRead then 2 else 1
      let subRead <-
        resolveRead shape rawPrefix op operands subOccurrence
          op.subIdOperandIndex op.subIdPolicy
      let rawSubId := subRead.resolution.value
      let hostSubId :=
        if op.truncateSubIdToI16 then
          TouhouFormal.word16BitsToInt rawSubId
        else
          rawSubId
      .ok
        { op := op
          reads := readsBeforeSub ++ [subRead]
          effect :=
            { targetEffect with
              rawSubId := some rawSubId
              hostSubId := some hostSubId
              pendingSubWrite := some hostSubId } }

def rawBossDispatchPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawBossDispatchOpShape)
    (operands : RawBossDispatchOperands) :
    Except Fault RawBossDispatchPrepared := do
  if operands.bossSlots.size != op.bossSlotCount then
    .error (malformedBossTableFault shape op operands.bossSlots.size)
  else
    match op.kind with
    | .callSubOnBoss =>
        prepareCallSubOnBoss shape rawPrefix op operands
    | .setPendingSubOnBoss =>
        preparePendingSubOnBoss shape rawPrefix op operands

def rawBossDispatchStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawBossDispatchOperands) :
    Except Fault RawBossDispatchOutcome :=
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
          .ok (rawBossDispatchCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok (rawBossDispatchCursorOutcome .vmError rawPrefix bufferSize)
        else
          match rawShape.findBossDispatchOp? rawPrefix.opcode with
          | none =>
              .ok (rawBossDispatchCursorOutcome .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <-
                rawBossDispatchPrepare shape rawPrefix op operands
              let action :=
                if prepared.hostFault.isSome then
                  RawBossDispatchAction.hostFault
                else
                  RawBossDispatchAction.advanced
              .ok
                (rawBossDispatchCursorOutcome action rawPrefix bufferSize
                  (some prepared.effect) prepared.hostFault (some prepared))

end TouhouFormal.ECL
