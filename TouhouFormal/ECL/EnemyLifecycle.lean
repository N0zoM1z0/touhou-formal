import TouhouFormal.Core.Word
import TouhouFormal.ECL.Instruction
import TouhouFormal.ECL.Operand
import TouhouFormal.ECL.Step

namespace TouhouFormal.ECL

structure RawEnemyLifecycleIntInput where
  rawValue : Int := 0
  hostValue : Int := 0
deriving Repr, DecidableEq

structure RawEnemyLifecycleFloatInput where
  rawBits : Int := 0
  hostBits : Int := 0
deriving Repr, DecidableEq

structure RawEnemyLifecycleVector3Bits where
  x : Int := 0
  y : Int := 0
  z : Int := 0
deriving Repr, DecidableEq

structure RawEnemyLifecycleRuntime where
  parentLife : Int := 1
  enemyPositionBits : RawEnemyLifecycleVector3Bits := {}
  relativePositionResultBits : RawEnemyLifecycleVector3Bits := {}
deriving Repr, DecidableEq

structure RawEnemyLifecycleOperands where
  intInputs : List RawEnemyLifecycleIntInput := []
  floatInputs : List RawEnemyLifecycleFloatInput := []
  runtime : RawEnemyLifecycleRuntime := {}
deriving Repr, DecidableEq

inductive RawEnemyLifecycleIntResolution where
  | rawI32 : Int -> RawEnemyLifecycleIntResolution
  | rawI16 : Int -> RawEnemyLifecycleIntResolution
  | intRValue : RawIntOperandResolution -> RawEnemyLifecycleIntResolution
deriving Repr, DecidableEq

def RawEnemyLifecycleIntResolution.value :
    RawEnemyLifecycleIntResolution -> Int
  | .rawI32 value => value
  | .rawI16 value => value
  | .intRValue value => value.value

inductive RawEnemyLifecycleFloatResolution where
  | rawBits : Int -> RawEnemyLifecycleFloatResolution
  | floatRValue : RawFloatOperandResolution -> RawEnemyLifecycleFloatResolution
deriving Repr, DecidableEq

def RawEnemyLifecycleFloatResolution.bits :
    RawEnemyLifecycleFloatResolution -> Int
  | .rawBits value => value
  | .floatRValue value => value.value

structure RawEnemyLifecycleResolvedIntInput where
  shape : RawEnemyLifecycleIntInputShape
  resolution : RawEnemyLifecycleIntResolution
deriving Repr, DecidableEq

structure RawEnemyLifecycleResolvedFloatInput where
  shape : RawEnemyLifecycleFloatInputShape
  resolution : RawEnemyLifecycleFloatResolution
deriving Repr, DecidableEq

structure RawEnemySpawnPosition where
  mode : RawEnemySpawnPositionMode
  resolvedPacketBits : RawEnemyLifecycleVector3Bits
  enemyPositionBits : RawEnemyLifecycleVector3Bits
  finalPositionBits : RawEnemyLifecycleVector3Bits
deriving Repr, DecidableEq

structure RawEnemySpawnRequest where
  subId : Int
  hostCallSubId : Int
  position : RawEnemySpawnPosition
  life : Int
  itemDrop : Int
  hostItemDrop : Int
  score : Int
  contextCopy : RawEnemySpawnContextCopy
  poolSearchSlots : Nat
  runSpawnedEclImmediately : Bool := true
deriving Repr, DecidableEq

structure RawEnemyRemoveAllEffect where
  implementation : RawEnemyRemoveAllImplementation
  poolSearchSlots : Nat
  scoreMax : Int
  initialScore : Int
  mayCallDeathCallbacks : Bool
  skipsNoDeathFlag : Bool
  maySpawnPointItems : Bool
  detachesParentChains : Bool
deriving Repr, DecidableEq

structure RawEnemyLifecycleEffect where
  spawnRequest : Option RawEnemySpawnRequest := none
  spawnSuppressedByParentLife : Bool := false
  removeAll : Option RawEnemyRemoveAllEffect := none
deriving Repr, DecidableEq

inductive RawEnemyLifecycleAction where
  | yielded
  | skipped
  | advanced
  | vmError
deriving Repr, DecidableEq

structure RawEnemyLifecyclePrepared where
  op : RawEnemyLifecycleOpShape
  intResolutions : List RawEnemyLifecycleResolvedIntInput := []
  floatResolutions : List RawEnemyLifecycleResolvedFloatInput := []
  effect : RawEnemyLifecycleEffect
deriving Repr, DecidableEq

structure RawEnemyLifecycleOutcome where
  action : RawEnemyLifecycleAction
  targetCursor : Option Int := none
  cursorClass : Option TouhouFormal.CursorClass := none
  effect : Option RawEnemyLifecycleEffect := none
  prepared : Option RawEnemyLifecyclePrepared := none
deriving Repr, DecidableEq

private def missingRawInstrShapeFault (shape : HeaderShape) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.enemyLifecycle"
    detail := "profile does not define a raw ECL instruction wire shape" }

private def malformedEnemyLifecycleShapeFault
    (shape : HeaderShape)
    (op : RawEnemyLifecycleOpShape)
    (detail : String) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.enemyLifecycle"
    detail := "enemy-lifecycle opcode " ++ op.kind.name ++ ": " ++ detail
    index := some op.opcode }

private def missingEnemyLifecycleIntOperandFault
    (shape : HeaderShape)
    (op : RawEnemyLifecycleOpShape)
    (occurrence : Nat)
    (operandIndex : Nat) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.enemyLifecycle"
    detail :=
      "enemy-lifecycle opcode " ++ op.kind.name ++
        " did not receive integer occurrence " ++ toString occurrence ++
        " for operand slot " ++ toString operandIndex
    index := some op.opcode }

private def missingEnemyLifecycleFloatOperandFault
    (shape : HeaderShape)
    (op : RawEnemyLifecycleOpShape)
    (occurrence : Nat)
    (operandIndex : Nat) : Fault :=
  { kind := .invalidInstruction
    title := shape.title
    component := "EclRun.enemyLifecycle"
    detail :=
      "enemy-lifecycle opcode " ++ op.kind.name ++
        " did not receive float occurrence " ++ toString occurrence ++
        " for operand slot " ++ toString operandIndex
    index := some op.opcode }

private def rawEnemyLifecycleCursorOutcome
    (action : RawEnemyLifecycleAction)
    (rawPrefix : RawInstrPrefix)
    (bufferSize : Nat)
    (effect : Option RawEnemyLifecycleEffect := none)
    (prepared : Option RawEnemyLifecyclePrepared := none) :
    RawEnemyLifecycleOutcome :=
  { action := action
    targetCursor := some rawPrefix.nextCursor
    cursorClass := some
      (TouhouFormal.classifyCursorTransfer
        rawPrefix.fileOffset rawPrefix.nextCursor bufferSize)
    effect := effect
    prepared := prepared }

private def signedI16 (value : Int) : Int :=
  TouhouFormal.word16BitsToInt (TouhouFormal.toWord16Bits value)

private def signedI8 (value : Int) : Int :=
  let bits := TouhouFormal.toWord32Bits value % 256
  if bits < 128 then bits else bits - 256

private def resolveEnemyLifecycleIntInput
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (inputShape : RawEnemyLifecycleIntInputShape)
    (input : RawEnemyLifecycleIntInput) :
    Except Fault RawEnemyLifecycleResolvedIntInput := do
  let resolution <-
    match inputShape.policy with
    | .rawI32 => .ok (.rawI32 input.rawValue)
    | .rawI16 => .ok (.rawI16 (signedI16 input.rawValue))
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

private def resolveEnemyLifecycleFloatInput
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (inputShape : RawEnemyLifecycleFloatInputShape)
    (input : RawEnemyLifecycleFloatInput) :
    Except Fault RawEnemyLifecycleResolvedFloatInput := do
  let resolution <-
    match inputShape.policy with
    | .rawBits => .ok (.rawBits input.rawBits)
    | .floatRValue => do
        let value <-
          resolveFloatRValue
            shape
            rawPrefix
            inputShape.operandIndex
            input.rawBits
            input.hostBits
        .ok (.floatRValue value)
  .ok { shape := inputShape, resolution := resolution }

private def intShapeAt
    (shape : HeaderShape)
    (op : RawEnemyLifecycleOpShape)
    (index : Nat) : Except Fault RawEnemyLifecycleIntInputShape :=
  match op.intInputs[index]? with
  | some input => .ok input
  | none =>
      .error
        (malformedEnemyLifecycleShapeFault
          shape op ("missing integer input shape " ++ toString index))

private def floatShapeAt
    (shape : HeaderShape)
    (op : RawEnemyLifecycleOpShape)
    (index : Nat) : Except Fault RawEnemyLifecycleFloatInputShape :=
  match op.floatInputs[index]? with
  | some input => .ok input
  | none =>
      .error
        (malformedEnemyLifecycleShapeFault
          shape op ("missing float input shape " ++ toString index))

private def intInputAt
    (shape : HeaderShape)
    (op : RawEnemyLifecycleOpShape)
    (operands : RawEnemyLifecycleOperands)
    (occurrence : Nat)
    (operandIndex : Nat) : Except Fault RawEnemyLifecycleIntInput :=
  match operands.intInputs[occurrence]? with
  | some input => .ok input
  | none =>
      .error
        (missingEnemyLifecycleIntOperandFault
          shape op occurrence operandIndex)

private def floatInputAt
    (shape : HeaderShape)
    (op : RawEnemyLifecycleOpShape)
    (operands : RawEnemyLifecycleOperands)
    (occurrence : Nat)
    (operandIndex : Nat) : Except Fault RawEnemyLifecycleFloatInput :=
  match operands.floatInputs[occurrence]? with
  | some input => .ok input
  | none =>
      .error
        (missingEnemyLifecycleFloatOperandFault
          shape op occurrence operandIndex)

private def resolveIntOccurrence
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawEnemyLifecycleOpShape)
    (operands : RawEnemyLifecycleOperands)
    (occurrence : Nat)
    (inputShape : RawEnemyLifecycleIntInputShape) :
    Except Fault RawEnemyLifecycleResolvedIntInput := do
  let input <-
    intInputAt shape op operands occurrence inputShape.operandIndex
  resolveEnemyLifecycleIntInput shape rawPrefix inputShape input

private def resolveFloatOccurrence
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawEnemyLifecycleOpShape)
    (operands : RawEnemyLifecycleOperands)
    (occurrence : Nat)
    (inputShape : RawEnemyLifecycleFloatInputShape) :
    Except Fault RawEnemyLifecycleResolvedFloatInput := do
  let input <-
    floatInputAt shape op operands occurrence inputShape.operandIndex
  resolveEnemyLifecycleFloatInput shape rawPrefix inputShape input

private def expectedSpawnIntRoles : List RawEnemyLifecycleIntRole :=
  [.subId, .life, .itemDrop, .score]

private def expectedSpawnFloatRoles : List RawEnemyLifecycleFloatRole :=
  [.positionX, .positionY, .positionZ]

private def validateSpawnShape
    (shape : HeaderShape)
    (op : RawEnemyLifecycleOpShape) : Except Fault Unit := do
  if op.intInputs.map (fun input => input.role) != expectedSpawnIntRoles then
    .error
      (malformedEnemyLifecycleShapeFault
        shape op "spawn integer roles do not match source packet order")
  else if op.floatInputs.map (fun input => input.role) !=
      expectedSpawnFloatRoles then
    .error
      (malformedEnemyLifecycleShapeFault
        shape op "spawn float roles do not match source packet order")
  else
    .ok ()

private def prepareSpawn
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawEnemyLifecycleOpShape)
    (positionMode : RawEnemySpawnPositionMode)
    (operands : RawEnemyLifecycleOperands) :
    Except Fault RawEnemyLifecyclePrepared := do
  if op.spawnRequiresPositiveParentLife &&
      !(decide (0 < operands.runtime.parentLife)) then
    .ok
      { op := op
        effect := { spawnSuppressedByParentLife := true } }
  else do
    validateSpawnShape shape op
    let subIdShape <- intShapeAt shape op 0
    let lifeShape <- intShapeAt shape op 1
    let itemShape <- intShapeAt shape op 2
    let scoreShape <- intShapeAt shape op 3
    let posXShape <- floatShapeAt shape op 0
    let posYShape <- floatShapeAt shape op 1
    let posZShape <- floatShapeAt shape op 2
    let subId <- resolveIntOccurrence shape rawPrefix op operands 0 subIdShape
    let life <- resolveIntOccurrence shape rawPrefix op operands 1 lifeShape
    let itemDrop <- resolveIntOccurrence shape rawPrefix op operands 2 itemShape
    let score <- resolveIntOccurrence shape rawPrefix op operands 3 scoreShape
    let posX <- resolveFloatOccurrence shape rawPrefix op operands 0 posXShape
    let posY <- resolveFloatOccurrence shape rawPrefix op operands 1 posYShape
    let posZ <- resolveFloatOccurrence shape rawPrefix op operands 2 posZShape
    let packetPosition :=
      { x := posX.resolution.bits
        y := posY.resolution.bits
        z := posZ.resolution.bits }
    let finalPosition :=
      match positionMode with
      | .absolute => packetPosition
      | .relativeToEnemy => operands.runtime.relativePositionResultBits
    let subIdValue := subId.resolution.value
    let itemValue := itemDrop.resolution.value
    let request :=
      { subId := subIdValue
        hostCallSubId :=
          if op.hostSubIdTruncatesToI16 then
            signedI16 subIdValue
          else
            subIdValue
        position :=
          { mode := positionMode
            resolvedPacketBits := packetPosition
            enemyPositionBits := operands.runtime.enemyPositionBits
            finalPositionBits := finalPosition }
        life := life.resolution.value
        itemDrop := itemValue
        hostItemDrop :=
          if op.hostItemDropTruncatesToI8 then
            signedI8 itemValue
          else
            itemValue
        score := score.resolution.value
        contextCopy := op.contextCopy
        poolSearchSlots := op.poolSearchSlots }
    let effect := { spawnRequest := some request }
    .ok
      { op := op
        intResolutions := [subId, life, itemDrop, score]
        floatResolutions := [posX, posY, posZ]
        effect := effect }

private def removeMaySpawnPointItems
    (implementation : RawEnemyRemoveAllImplementation) : Bool :=
  match implementation with
  | .inlineTH06Loop => false
  | .removeAllEnemies | .killAllNonBossEnemies => true

private def removeSkipsNoDeathFlag
    (implementation : RawEnemyRemoveAllImplementation) : Bool :=
  match implementation with
  | .killAllNonBossEnemies => true
  | .inlineTH06Loop | .removeAllEnemies => false

private def removeDetachesParentChains
    (implementation : RawEnemyRemoveAllImplementation) : Bool :=
  match implementation with
  | .killAllNonBossEnemies => true
  | .inlineTH06Loop | .removeAllEnemies => false

private def prepareRemoveAll
    (op : RawEnemyLifecycleOpShape) : RawEnemyLifecyclePrepared :=
  let remove :=
    { implementation := op.removeImplementation
      poolSearchSlots := op.poolSearchSlots
      scoreMax := op.removeScoreMax
      initialScore := op.removeInitialScore
      mayCallDeathCallbacks := true
      skipsNoDeathFlag := removeSkipsNoDeathFlag op.removeImplementation
      maySpawnPointItems := removeMaySpawnPointItems op.removeImplementation
      detachesParentChains :=
        removeDetachesParentChains op.removeImplementation }
  { op := op
    effect := { removeAll := some remove } }

def rawEnemyLifecyclePrepare
    (shape : HeaderShape)
    (rawPrefix : RawInstrPrefix)
    (op : RawEnemyLifecycleOpShape)
    (operands : RawEnemyLifecycleOperands) :
    Except Fault RawEnemyLifecyclePrepared := do
  match op.kind with
  | .spawn positionMode =>
      prepareSpawn shape rawPrefix op positionMode operands
  | .removeAllNonBoss =>
      .ok (prepareRemoveAll op)

def rawEnemyLifecycleStep
    (shape : HeaderShape)
    (currentTime : Int)
    (activeMask overrideMask maxBits bufferSize : Nat)
    (rawPrefix : RawInstrPrefix)
    (operands : RawEnemyLifecycleOperands) :
    Except Fault RawEnemyLifecycleOutcome :=
  match shape.rawInstrShape with
  | none => .error (missingRawInstrShapeFault shape)
  | some rawShape =>
      if currentTime != rawPrefix.time then
        .ok { action := .yielded }
      else do
        let difficultyPass <-
          rawDifficultyPass shape rawShape rawPrefix activeMask overrideMask maxBits
        if !difficultyPass then
          .ok (rawEnemyLifecycleCursorOutcome .skipped rawPrefix bufferSize)
        else if rawShape.unimplementedOpcode == some rawPrefix.opcode then
          .ok (rawEnemyLifecycleCursorOutcome .vmError rawPrefix bufferSize)
        else
          match rawShape.findEnemyLifecycleOp? rawPrefix.opcode with
          | none =>
              .ok (rawEnemyLifecycleCursorOutcome .advanced rawPrefix bufferSize)
          | some op => do
              let prepared <-
                rawEnemyLifecyclePrepare shape rawPrefix op operands
              .ok
                (rawEnemyLifecycleCursorOutcome
                  .advanced
                  rawPrefix
                  bufferSize
                  (some prepared.effect)
                  (some prepared))

end TouhouFormal.ECL
