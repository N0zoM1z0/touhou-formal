import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

structure RawItemIntInput where
  rawValue : Int := 0
  hostValue : Int := 0
deriving Repr, DecidableEq

structure RawItemOperands where
  intInputs : List RawItemIntInput := []
deriving Repr, DecidableEq

inductive RawItemIntResolution where
  | rawI32 : Int -> RawItemIntResolution
  | intRValue : RawIntOperandResolution -> RawItemIntResolution
deriving Repr, DecidableEq

def RawItemIntResolution.value : RawItemIntResolution -> Int
  | .rawI32 value => value
  | .intRValue value => value.value

structure RawItemResolvedIntInput where
  shape : RawItemIntInputShape
  resolution : RawItemIntResolution
deriving Repr, DecidableEq

structure RawItemLoopSpawn where
  kind : RawItemLoopKind
  count : Int
  spreadFullWidth : Int
  spreadHalfWidth : Int
  powerThreshold : Int
  firstPowerItemIsBig : Bool := true
  restPowerItemsAreSmall : Bool := true
deriving Repr, DecidableEq

structure RawItemSingleSpawn where
  itemType : Int
  itemStateDefault : Bool
deriving Repr, DecidableEq

structure RawItemStateWrite where
  itemDropType : Option Int := none
  pointItemDropCount : Option Int := none
  powerOrPointItemDropCount : Option Int := none
deriving Repr, DecidableEq

structure RawItemEffect where
  loopSpawn : Option RawItemLoopSpawn := none
  singleSpawn : Option RawItemSingleSpawn := none
  stateWrite : Option RawItemStateWrite := none
deriving Repr, DecidableEq

inductive RawItemAction where
  | yielded
  | skipped
  | advanced
  | vmError
deriving Repr, DecidableEq

structure RawItemPrepared where
  op : RawItemOpShape
  intResolutions : List RawItemResolvedIntInput := []
  effect : RawItemEffect
deriving Repr, DecidableEq

structure RawItemOutcome where
  action : RawItemAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  effect : Option RawItemEffect := none
  prepared : Option RawItemPrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.item"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def malformedItemShapeFault
    (shape : HeaderShape)
    (op : RawItemOpShape)
    (detail : String) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.item"
    detail := "item opcode " ++ op.kind.name ++ ": " ++ detail
    index := some op.opcode }

private def missingItemIntOperandFault
    (shape : HeaderShape)
    (op : RawItemOpShape)
    (occurrence : Nat)
    (operandIndex : Nat) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.item"
    detail :=
      "item opcode " ++ op.kind.name ++
        " did not receive integer occurrence " ++ toString occurrence ++
        " for operand slot " ++ toString operandIndex
    index := some op.opcode }

private def rawItemCursorOutcome
    (action : RawItemAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (effect : Option RawItemEffect := none)
    (prepared : Option RawItemPrepared := none) :
    RawItemOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some
      (TouhouFormal.classifyCursorTransfer
        rawPrefix.fileOffset rawPrefix.nextCursor bufferSize)
    effect := effect
    prepared := prepared }

private def resolveItemIntInput
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (inputShape : RawItemIntInputShape)
    (input : RawItemIntInput) :
    Except Fault RawItemResolvedIntInput := do
  let resolution <-
    match inputShape.policy with
    | .rawI32 => .ok (.rawI32 input.rawValue)
    | .intRValue => do
        let value <-
          resolveIntRValue
            shape
            rawPrefix
            inputShape.operandIndex
            input.rawValue
            input.hostValue
        .ok (.intRValue value)
  .ok { shape := inputShape, resolution := resolution }

private def intShapeAt
    (shape : HeaderShape)
    (op : RawItemOpShape)
    (index : Nat) : Except Fault RawItemIntInputShape :=
  match op.intInputs[index]? with
  | some input => .ok input
  | none =>
      .error
        (malformedItemShapeFault
          shape op ("missing integer input shape " ++ toString index))

private def intInputAt
    (shape : HeaderShape)
    (op : RawItemOpShape)
    (operands : RawItemOperands)
    (occurrence : Nat)
    (operandIndex : Nat) : Except Fault RawItemIntInput :=
  match operands.intInputs[occurrence]? with
  | some input => .ok input
  | none =>
      .error
        (missingItemIntOperandFault shape op occurrence operandIndex)

private def resolveIntOccurrence
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawItemOpShape)
    (operands : RawItemOperands)
    (occurrence : Nat)
    (inputShape : RawItemIntInputShape) :
    Except Fault RawItemResolvedIntInput := do
  let input <- intInputAt shape op operands occurrence inputShape.operandIndex
  resolveItemIntInput shape rawPrefix inputShape input

private def validateRoles
    (shape : HeaderShape)
    (op : RawItemOpShape)
    (expected : List RawItemIntRole) : Except Fault Unit := do
  if op.intInputs.map (fun input => input.role) != expected then
    .error
      (malformedItemShapeFault
        shape op "integer roles do not match source argument order")
  else
    .ok ()

private def prepareSpawnLoop
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawItemOpShape)
    (operands : RawItemOperands)
    (loopKind : RawItemLoopKind) :
    Except Fault RawItemPrepared := do
  validateRoles shape op [.count]
  let countShape <- intShapeAt shape op 0
  let count <- resolveIntOccurrence shape rawPrefix op operands 0 countShape
  let effect :=
    { loopSpawn :=
        some
          { kind := loopKind
            count := count.resolution.value
            spreadFullWidth := op.spreadFullWidth
            spreadHalfWidth := op.spreadHalfWidth
            powerThreshold := op.powerThreshold } }
  .ok
    { op := op
      intResolutions := [count]
      effect := effect }

private def prepareSpawnSingle
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawItemOpShape)
    (operands : RawItemOperands) :
    Except Fault RawItemPrepared := do
  validateRoles shape op [.itemType]
  let itemShape <- intShapeAt shape op 0
  let itemType <- resolveIntOccurrence shape rawPrefix op operands 0 itemShape
  let effect :=
    { singleSpawn :=
        some
          { itemType := itemType.resolution.value
            itemStateDefault := op.itemStateDefault } }
  .ok
    { op := op
      intResolutions := [itemType]
      effect := effect }

private def prepareSetItemDropType
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawItemOpShape)
    (operands : RawItemOperands) :
    Except Fault RawItemPrepared := do
  validateRoles shape op [.itemType]
  let itemShape <- intShapeAt shape op 0
  let itemType <- resolveIntOccurrence shape rawPrefix op operands 0 itemShape
  let effect :=
    { stateWrite := some { itemDropType := some itemType.resolution.value } }
  .ok
    { op := op
      intResolutions := [itemType]
      effect := effect }

private def prepareSetItemDropCounts
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawItemOpShape)
    (operands : RawItemOperands) :
    Except Fault RawItemPrepared := do
  validateRoles shape op [.pointCount, .powerOrPointCount]
  let pointShape <- intShapeAt shape op 0
  let powerShape <- intShapeAt shape op 1
  let pointCount <- resolveIntOccurrence shape rawPrefix op operands 0 pointShape
  let powerCount <- resolveIntOccurrence shape rawPrefix op operands 1 powerShape
  let effect :=
    { stateWrite :=
        some
          { pointItemDropCount := some pointCount.resolution.value
            powerOrPointItemDropCount := some powerCount.resolution.value } }
  .ok
    { op := op
      intResolutions := [pointCount, powerCount]
      effect := effect }

def rawItemPrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawItemOpShape)
    (operands : RawItemOperands) :
    Except Fault RawItemPrepared := do
  match op.kind with
  | .spawnLoop loopKind =>
      prepareSpawnLoop shape rawPrefix op operands loopKind
  | .spawnSingle =>
      prepareSpawnSingle shape rawPrefix op operands
  | .setItemDropType =>
      prepareSetItemDropType shape rawPrefix op operands
  | .setItemDropCounts =>
      prepareSetItemDropCounts shape rawPrefix op operands

def rawItemStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawItemOperands) :
    Except Fault RawItemOutcome :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      if currentTime != rawPrefix.time then
        .ok { action := .yielded }
      else do
        let difficultyPass <-
          rawDifficultyPass shape rawShape rawPrefix activeMask overrideMask maxBits
        if !difficultyPass then
          .ok (rawItemCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok (rawItemCursorOutcome .vmError rawPrefix bufferSize)
        else
          match rawShape.findItemOp? rawPrefix.opcode with
          | none => .ok (rawItemCursorOutcome .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <- rawItemPrepare shape rawPrefix op operands
              .ok
                (rawItemCursorOutcome
                  .advanced
                  rawPrefix
                  bufferSize
                  (some prepared.effect)
                  (some prepared))

end TouhouFormal.ECL
