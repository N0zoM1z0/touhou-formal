import TouhouFormal.Core.Word
import TouhouFormal.ECL.EnemyState
import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

structure RawCallbackConfigOperandSlot where
  rawValue : Int
  /-- One value per source read; a singleton is reused for stable host state. -/
  hostValues : List Int := [0]
deriving Repr, DecidableEq

structure RawCallbackConfigOperands where
  slots : List RawCallbackConfigOperandSlot := []
  deathCallbackSubBefore : Int := -1
  presentationWritesAllowed : Bool := true
deriving Repr, DecidableEq

inductive RawCallbackConfigIntResolution where
  | rawI32 (value : Int)
  | rawU8 (value : Int)
  | rawU16ToI16 (value : Int)
  | intRValue (value : RawIntOperandResolution)
deriving Repr, DecidableEq

def RawCallbackConfigIntResolution.value :
    RawCallbackConfigIntResolution -> Int
  | .rawI32 value | .rawU8 value | .rawU16ToI16 value => value
  | .intRValue value => value.value

structure RawCallbackConfigRead where
  operandIndex : Nat
  occurrence : Nat
  resolution : RawCallbackConfigIntResolution
deriving Repr, DecidableEq

structure RawCallbackIndexedWrite where
  index : Int
  value : Int
deriving Repr, DecidableEq

structure RawCallbackConfigEffect where
  deathCallbackSubWrite : Option Int := none
  lifeThresholdWrites : List RawCallbackIndexedWrite := []
  lifeSubWrites : List RawCallbackIndexedWrite := []
  timerThresholdWrite : Option Int := none
  timerSubWrite : Option Int := none
  periodicIntervalWrite : Option RawEnemyTimerWrite := none
  periodicSubWrite : Option Int := none
  periodicCounterWrite : Option RawEnemyTimerWrite := none
  savePeriodicContextArgs : Bool := false
  bossTimerWrite : Option RawEnemyTimerWrite := none
  suppressedByPresentationPolicy : Bool := false
deriving Repr, DecidableEq

structure RawCallbackConfigPrepared where
  op : RawCallbackConfigOpShape
  reads : List RawCallbackConfigRead
  effect : RawCallbackConfigEffect
  hostFault : Option Fault := none
deriving Repr, DecidableEq

inductive RawCallbackConfigAction where
  | yielded
  | skipped
  | advanced
  | hostFault
  | vmError
deriving Repr, DecidableEq

structure RawCallbackConfigOutcome where
  action : RawCallbackConfigAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  effect : Option RawCallbackConfigEffect := none
  fault : Option Fault := none
  prepared : Option RawCallbackConfigPrepared := none
deriving Repr, DecidableEq

private def resetCallbackTimerWrite : RawEnemyTimerWrite :=
  { current := 0, subFrameBits := 0, previous := -999 }

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.callbackConfig"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def missingCallbackOperandFault
    (shape : HeaderShape)
    (op : RawCallbackConfigOpShape)
    (operandIndex : Nat) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.callbackConfig"
    detail :=
      "callback opcode " ++ op.kind.name ++
        " did not receive operand slot " ++ toString operandIndex
    index := some op.opcode }

private def callbackLifeIndexFault
    (shape : HeaderShape)
    (index : Int)
    (bound : Nat) : Fault :=
  { kind := .outOfBoundsWrite
    title := shape.title
    component := "EclRun.callbackConfig.lifeCallbacks"
    detail := "source writes a life callback array without checking its index"
    index := some index
    bound := some bound }

private def rawCallbackConfigCursorOutcome
    (action : RawCallbackConfigAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (effect : Option RawCallbackConfigEffect := none)
    (fault : Option Fault := none)
    (prepared : Option RawCallbackConfigPrepared := none) :
    RawCallbackConfigOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some
      (TouhouFormal.classifyCursorTransfer
        rawPrefix.fileOffset rawPrefix.nextCursor bufferSize)
    effect := effect
    fault := fault
    prepared := prepared }

private def callbackHostValue
    (slot : RawCallbackConfigOperandSlot)
    (occurrence : Nat) : Int :=
  slot.hostValues[occurrence]?.getD (slot.hostValues.head?.getD 0)

private def resolveCallbackConfigRead
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawCallbackConfigOpShape)
    (operands : RawCallbackConfigOperands)
    (operandIndex occurrence : Nat) :
    Except Fault RawCallbackConfigRead := do
  let slot <-
    match operands.slots[operandIndex]? with
    | none => .error (missingCallbackOperandFault shape op operandIndex)
    | some slot => .ok slot
  let resolution <-
    match op.intPolicy with
    | .rawI32 => .ok (.rawI32 slot.rawValue)
    | .rawU8 =>
        .ok (.rawU8 (TouhouFormal.truncateUnsignedBits slot.rawValue 8))
    | .rawU16ToI16 =>
        .ok (.rawU16ToI16 (TouhouFormal.word16BitsToInt slot.rawValue))
    | .intRValue => do
        let value <-
          resolveIntRValue shape rawPrefix operandIndex slot.rawValue
            (callbackHostValue slot occurrence)
        .ok (.intRValue value)
  .ok
    { operandIndex := operandIndex
      occurrence := occurrence
      resolution := resolution }

private def callbackIndexInBounds (index : Int) (bound : Nat) : Bool :=
  decide (0 <= index ∧ index < Int.ofNat bound)

private def callbackSingleReadPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawCallbackConfigOpShape)
    (operands : RawCallbackConfigOperands)
    (effectOf : Int -> RawCallbackConfigEffect) :
    Except Fault RawCallbackConfigPrepared := do
  if op.guardAllWritesByPresentation &&
      !operands.presentationWritesAllowed then
    let effect : RawCallbackConfigEffect :=
      { suppressedByPresentationPolicy := true }
    .ok { op := op, reads := [], effect := effect }
  else
    let read <- resolveCallbackConfigRead shape rawPrefix op operands 0 0
    let effect := effectOf read.resolution.value
    .ok { op := op, reads := [read], effect := effect }

private def callbackLifePairPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawCallbackConfigOpShape)
    (operands : RawCallbackConfigOperands) :
    Except Fault RawCallbackConfigPrepared := do
  let thresholdIndexRead <-
    resolveCallbackConfigRead shape rawPrefix op operands 0 0
  let thresholdRead <-
    resolveCallbackConfigRead shape rawPrefix op operands 1 0
  let thresholdIndex := thresholdIndexRead.resolution.value
  let thresholdReads := [thresholdIndexRead, thresholdRead]
  if !callbackIndexInBounds thresholdIndex op.lifeSlotCount then
    let fault := callbackLifeIndexFault shape thresholdIndex op.lifeSlotCount
    .ok
      { op := op
        reads := thresholdReads
        effect := {}
        hostFault := some fault }
  else
    let thresholdWrite : RawCallbackIndexedWrite :=
      { index := thresholdIndex, value := thresholdRead.resolution.value }
    let thresholdEffect : RawCallbackConfigEffect :=
      { lifeThresholdWrites := [thresholdWrite] }
    if op.guardSubWriteByPresentation &&
        !operands.presentationWritesAllowed then
      .ok
        { op := op
          reads := thresholdReads
          effect :=
            { thresholdEffect with
              suppressedByPresentationPolicy := true } }
    else
      let subIndexRead <-
        resolveCallbackConfigRead shape rawPrefix op operands 0 1
      let subRead <-
        resolveCallbackConfigRead shape rawPrefix op operands 2 0
      let subIndex := subIndexRead.resolution.value
      let allReads := thresholdReads ++ [subIndexRead, subRead]
      if !callbackIndexInBounds subIndex op.lifeSlotCount then
        let fault := callbackLifeIndexFault shape subIndex op.lifeSlotCount
        .ok
          { op := op
            reads := allReads
            effect := thresholdEffect
            hostFault := some fault }
      else
        let subWrite : RawCallbackIndexedWrite :=
          { index := subIndex, value := subRead.resolution.value }
        .ok
          { op := op
            reads := allReads
            effect :=
              { thresholdEffect with lifeSubWrites := [subWrite] } }

private def callbackTimerPairPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawCallbackConfigOpShape)
    (operands : RawCallbackConfigOperands) :
    Except Fault RawCallbackConfigPrepared := do
  let thresholdRead <-
    resolveCallbackConfigRead shape rawPrefix op operands 0 0
  let timerWrite := if op.resetBossTimer then some resetCallbackTimerWrite else none
  let thresholdEffect : RawCallbackConfigEffect :=
    { timerThresholdWrite := some thresholdRead.resolution.value
      bossTimerWrite := timerWrite }
  if op.guardSubWriteByPresentation &&
      !operands.presentationWritesAllowed then
    .ok
      { op := op
        reads := [thresholdRead]
        effect :=
          { thresholdEffect with suppressedByPresentationPolicy := true } }
  else
    let subRead <- resolveCallbackConfigRead shape rawPrefix op operands 1 0
    .ok
      { op := op
        reads := [thresholdRead, subRead]
        effect :=
          { thresholdEffect with timerSubWrite := some subRead.resolution.value } }

private def callbackPeriodicPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawCallbackConfigOpShape)
    (operands : RawCallbackConfigOperands) :
    Except Fault RawCallbackConfigPrepared := do
  let intervalRead <-
    resolveCallbackConfigRead shape rawPrefix op operands 0 0
  let subRead <- resolveCallbackConfigRead shape rawPrefix op operands 1 0
  let effect : RawCallbackConfigEffect :=
    { periodicIntervalWrite :=
        some
          { resetCallbackTimerWrite with
            current := intervalRead.resolution.value }
      periodicSubWrite := some subRead.resolution.value
      periodicCounterWrite := some resetCallbackTimerWrite
      savePeriodicContextArgs := true }
  .ok { op := op, reads := [intervalRead, subRead], effect := effect }

def rawCallbackConfigPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawCallbackConfigOpShape)
    (operands : RawCallbackConfigOperands) :
    Except Fault RawCallbackConfigPrepared :=
  match op.kind with
  | .setDeathSub =>
      callbackSingleReadPrepare shape rawPrefix op operands
        (fun value => { deathCallbackSubWrite := some value })
  | .setLifeThreshold =>
      callbackSingleReadPrepare shape rawPrefix op operands
        (fun value =>
          { lifeThresholdWrites := [{ index := 0, value := value }] })
  | .setLifeSub =>
      callbackSingleReadPrepare shape rawPrefix op operands
        (fun value => { lifeSubWrites := [{ index := 0, value := value }] })
  | .setLifePairIndexed =>
      callbackLifePairPrepare shape rawPrefix op operands
  | .setTimerThreshold =>
      callbackSingleReadPrepare shape rawPrefix op operands
        (fun value =>
          { timerThresholdWrite := some value
            bossTimerWrite :=
              if op.resetBossTimer then some resetCallbackTimerWrite else none })
  | .setTimerSub =>
      callbackSingleReadPrepare shape rawPrefix op operands
        (fun value => { timerSubWrite := some value })
  | .setTimerPair =>
      callbackTimerPairPrepare shape rawPrefix op operands
  | .setPeriodic =>
      callbackPeriodicPrepare shape rawPrefix op operands
  | .bindTimerToDeath =>
      let effect : RawCallbackConfigEffect :=
        { timerSubWrite := some operands.deathCallbackSubBefore
          bossTimerWrite :=
            if op.resetBossTimer then some resetCallbackTimerWrite else none }
      .ok { op := op, reads := [], effect := effect }

def rawCallbackConfigStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawCallbackConfigOperands) :
    Except Fault RawCallbackConfigOutcome :=
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
          .ok (rawCallbackConfigCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok (rawCallbackConfigCursorOutcome .vmError rawPrefix bufferSize)
        else
          match rawShape.findCallbackConfigOp? rawPrefix.opcode with
          | none =>
              .ok (rawCallbackConfigCursorOutcome .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <-
                rawCallbackConfigPrepare shape rawPrefix op operands
              let action :=
                if prepared.hostFault.isSome then
                  RawCallbackConfigAction.hostFault
                else
                  RawCallbackConfigAction.advanced
              .ok
                (rawCallbackConfigCursorOutcome action rawPrefix bufferSize
                  (some prepared.effect) prepared.hostFault (some prepared))

end TouhouFormal.ECL
